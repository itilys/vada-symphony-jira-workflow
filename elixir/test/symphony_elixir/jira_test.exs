defmodule SymphonyElixir.JiraTest do
  use SymphonyElixir.TestSupport

  alias SymphonyElixir.Jira.{ADF, Client, IssueMapper}

  test "ADF converter extracts readable text from common nodes" do
    adf = %{
      "type" => "doc",
      "version" => 1,
      "content" => [
        %{
          "type" => "heading",
          "attrs" => %{"level" => 2},
          "content" => [%{"type" => "text", "text" => "Setup"}]
        },
        %{
          "type" => "paragraph",
          "content" => [
            %{"type" => "text", "text" => "Clone the repo"},
            %{"type" => "hardBreak"},
            %{"type" => "text", "text" => "Run tests"}
          ]
        },
        %{
          "type" => "bulletList",
          "content" => [
            %{"type" => "listItem", "content" => [%{"type" => "paragraph", "content" => [%{"type" => "text", "text" => "First"}]}]},
            %{"type" => "listItem", "content" => [%{"type" => "paragraph", "content" => [%{"type" => "text", "text" => "Second"}]}]}
          ]
        }
      ]
    }

    assert ADF.to_text(adf) == "Setup\n\nClone the repo\nRun tests\n\n- First\n- Second"
    assert ADF.to_text(%{"type" => "doc", "content" => []}) == nil
  end

  test "issue mapper normalizes Jira issue payloads" do
    issue =
      jira_issue("10001", "ABC-123", %{
        "summary" => "Add smoke test",
        "description" => %{
          "type" => "doc",
          "version" => 1,
          "content" => [
            %{"type" => "paragraph", "content" => [%{"type" => "text", "text" => "Make it safe."}]}
          ]
        },
        "status" => %{"name" => "Ready for Agent"},
        "priority" => %{"name" => "High"},
        "labels" => ["Symphony", "Backend"],
        "assignee" => %{"accountId" => "agent-123", "displayName" => "Agent"},
        "created" => "2026-06-15T08:00:00.000+0000",
        "updated" => "2026-06-15T09:30:00.000+0000",
        "issuelinks" => [
          %{
            "type" => %{"outward" => "blocks", "inward" => "is blocked by"},
            "inwardIssue" => jira_issue("10000", "ABC-100", %{"status" => %{"name" => "In Progress"}})
          }
        ]
      })

    normalized = IssueMapper.from_jira_issue_for_test(issue, site: "https://example.atlassian.net", assignee: "agent-123")

    assert normalized.id == "10001"
    assert normalized.identifier == "ABC-123"
    assert normalized.title == "Add smoke test"
    assert normalized.description == "Make it safe."
    assert normalized.priority == 2
    assert normalized.state == "Ready for Agent"
    assert normalized.branch_name == "ABC-123"
    assert normalized.url == "https://example.atlassian.net/browse/ABC-123"
    assert normalized.assignee_id == "agent-123"
    assert normalized.assigned_to_worker == true
    assert normalized.labels == ["symphony", "backend"]
    assert [%{id: "10000", identifier: "ABC-100", state: "In Progress"}] = normalized.blocked_by
    assert %DateTime{} = normalized.created_at
    assert %DateTime{} = normalized.updated_at
  end

  test "client builds JQL for project states and issue lookups" do
    assert Client.project_states_jql_for_test("ABC", ["Ready for Agent", "Rework"]) ==
             ~S[project = ABC AND status in ("Ready for Agent", "Rework") ORDER BY priority DESC, updated ASC]

    assert Client.issue_lookup_jql_for_test(["10001", "ABC-2"]) ==
             ~S[(id in (10001) OR issuekey in ("ABC-2"))]
  end

  test "client searches Jira JQL with pagination and maps issues" do
    write_jira_workflow!()
    parent = self()

    request_fun = fn endpoint, payload, headers ->
      send(parent, {:jira_request, endpoint, payload, headers})

      body =
        case payload["nextPageToken"] do
          nil ->
            %{
              "isLast" => false,
              "nextPageToken" => "page-2",
              "issues" => [jira_issue("10001", "ABC-1", %{"summary" => "First", "status" => %{"name" => "Ready for Agent"}})]
            }

          "page-2" ->
            %{
              "isLast" => true,
              "issues" => [jira_issue("10002", "ABC-2", %{"summary" => "Second", "status" => %{"name" => "Ready for Agent"}})]
            }
        end

      {:ok, %{status: 200, body: body}}
    end

    assert {:ok, issues} = Client.search_jql_for_test("project = ABC", request_fun: request_fun)
    assert Enum.map(issues, & &1.identifier) == ["ABC-1", "ABC-2"]

    assert_receive {:jira_request, "https://example.atlassian.net", first_payload, first_headers}
    assert first_payload["jql"] == "project = ABC"
    assert first_payload["maxResults"] == 50
    assert "summary" in first_payload["fields"]
    assert {"Accept", "application/json"} in first_headers
    assert {"Content-Type", "application/json"} in first_headers
    assert {"Authorization", "Basic " <> Base.encode64("agent@example.com:jira-token")} in first_headers

    assert_receive {:jira_request, "https://example.atlassian.net", %{"nextPageToken" => "page-2"}, _headers}
  end

  test "client surfaces Jira API status errors without leaking credentials" do
    write_jira_workflow!()

    request_fun = fn _endpoint, _payload, _headers ->
      {:ok, %{status: 401, body: %{"errorMessages" => ["Unauthorized"]}}}
    end

    assert {:error, {:jira_api_status, 401}} =
             Client.search_jql_for_test("project = ABC", request_fun: request_fun)
  end

  test "dry-run agent mode prepares workspace and skips Codex startup" do
    test_root =
      Path.join(
        System.tmp_dir!(),
        "symphony-elixir-dry-run-#{System.unique_integer([:positive])}"
      )

    try do
      workspace_root = Path.join(test_root, "workspaces")

      write_workflow_file!(Workflow.workflow_file_path(),
        workspace_root: workspace_root,
        agent_mode: "dry_run",
        hook_after_create: "touch after_create.txt",
        hook_before_run: "touch before_run.txt",
        hook_after_run: "touch after_run.txt",
        codex_command: "definitely-not-installed app-server"
      )

      issue = %Issue{
        id: "10001",
        identifier: "ABC-1",
        title: "Dry run",
        description: "Prepare workspace without Codex",
        state: "Ready for Agent",
        labels: ["symphony"]
      }

      assert :ok = AgentRunner.run(issue, self())
      assert_receive {:codex_worker_update, "10001", %{event: :dry_run_completed, timestamp: %DateTime{}}}

      workspace = Path.join(workspace_root, "ABC-1")
      assert File.exists?(Path.join(workspace, "after_create.txt"))
      assert File.exists?(Path.join(workspace, "before_run.txt"))
      assert File.exists?(Path.join(workspace, "after_run.txt"))
    after
      File.rm_rf(test_root)
    end
  end

  defp write_jira_workflow! do
    write_workflow_file!(Workflow.workflow_file_path(),
      tracker_kind: "jira",
      tracker_endpoint: "https://example.atlassian.net",
      tracker_api_token: nil,
      tracker_jira_api_token: "jira-token",
      tracker_email: "agent@example.com",
      tracker_project_slug: nil,
      tracker_project_key: "ABC",
      tracker_jql: "project = ABC"
    )
  end

  defp jira_issue(id, key, fields) do
    %{
      "id" => id,
      "key" => key,
      "self" => "https://example.atlassian.net/rest/api/3/issue/#{id}",
      "fields" => fields
    }
  end
end
