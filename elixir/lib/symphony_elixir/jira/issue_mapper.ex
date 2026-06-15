defmodule SymphonyElixir.Jira.IssueMapper do
  @moduledoc """
  Converts Jira Cloud issue payloads into the tracker-independent issue model.
  """

  alias SymphonyElixir.Issue
  alias SymphonyElixir.Jira.ADF

  @priority_ranks %{
    "highest" => 1,
    "blocker" => 1,
    "critical" => 1,
    "high" => 2,
    "major" => 2,
    "medium" => 3,
    "normal" => 3,
    "low" => 4,
    "minor" => 4,
    "lowest" => 5,
    "trivial" => 5
  }

  @spec from_jira_issue(map(), keyword()) :: Issue.t() | nil
  def from_jira_issue(issue, opts \\ [])

  def from_jira_issue(%{"fields" => fields} = issue, opts) when is_map(fields) do
    assignee = Map.get(fields, "assignee")
    key = Map.get(issue, "key")

    %Issue{
      id: string_value(Map.get(issue, "id")),
      identifier: key,
      title: string_value(Map.get(fields, "summary")),
      description: ADF.to_text(Map.get(fields, "description")),
      priority: parse_priority(Map.get(fields, "priority")),
      state: get_in(fields, ["status", "name"]),
      branch_name: key,
      url: issue_url(issue, Keyword.get(opts, :site)),
      assignee_id: assignee_field(assignee, "accountId"),
      blocked_by: extract_blockers(fields),
      labels: extract_labels(fields),
      assigned_to_worker: assigned_to_worker?(assignee, Keyword.get(opts, :assignee)),
      created_at: parse_datetime(Map.get(fields, "created")),
      updated_at: parse_datetime(Map.get(fields, "updated"))
    }
  end

  def from_jira_issue(_issue, _opts), do: nil

  @doc false
  @spec from_jira_issue_for_test(map(), keyword()) :: Issue.t() | nil
  def from_jira_issue_for_test(issue, opts \\ []), do: from_jira_issue(issue, opts)

  defp issue_url(%{"key" => key}, site) when is_binary(key) and is_binary(site) do
    site
    |> String.trim_trailing("/")
    |> Kernel.<>("/browse/#{key}")
  end

  defp issue_url(%{"self" => self_url}, _site) when is_binary(self_url), do: self_url
  defp issue_url(_issue, _site), do: nil

  defp assignee_field(%{} = assignee, field) when is_binary(field), do: assignee[field]
  defp assignee_field(_assignee, _field), do: nil

  defp assigned_to_worker?(_assignee, nil), do: true

  defp assigned_to_worker?(%{} = assignee, configured_assignee) when is_binary(configured_assignee) do
    configured = normalize_match_value(configured_assignee)

    [
      assignee["accountId"],
      assignee["emailAddress"],
      assignee["displayName"]
    ]
    |> Enum.map(&normalize_match_value/1)
    |> Enum.any?(&(&1 == configured))
  end

  defp assigned_to_worker?(_assignee, _configured_assignee), do: false

  defp extract_labels(%{"labels" => labels}) when is_list(labels) do
    labels
    |> Enum.flat_map(fn
      label when is_binary(label) -> [label]
      _ -> []
    end)
    |> Enum.map(&(String.trim(&1) |> String.downcase()))
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp extract_labels(_fields), do: []

  defp extract_blockers(%{"issuelinks" => links}) when is_list(links) do
    Enum.flat_map(links, &blockers_from_link/1)
  end

  defp extract_blockers(_fields), do: []

  defp blockers_from_link(%{"type" => type, "inwardIssue" => issue}) when is_map(type) and is_map(issue) do
    if blocking_relation?(type["outward"]) do
      [linked_issue(issue)]
    else
      []
    end
  end

  defp blockers_from_link(%{"type" => type, "outwardIssue" => issue}) when is_map(type) and is_map(issue) do
    if blocked_by_relation?(type["inward"]) do
      [linked_issue(issue)]
    else
      []
    end
  end

  defp blockers_from_link(_link), do: []

  defp linked_issue(%{} = issue) do
    %{
      id: string_value(issue["id"]),
      identifier: issue["key"],
      state: get_in(issue, ["fields", "status", "name"])
    }
  end

  defp blocking_relation?(value) when is_binary(value) do
    normalized = String.downcase(value)
    String.contains?(normalized, "block") or String.contains?(normalized, "depend")
  end

  defp blocking_relation?(_value), do: false

  defp blocked_by_relation?(value) when is_binary(value) do
    normalized = String.downcase(value)
    String.contains?(normalized, "block") or String.contains?(normalized, "depend")
  end

  defp blocked_by_relation?(_value), do: false

  defp parse_priority(%{"name" => name}) when is_binary(name) do
    name
    |> String.trim()
    |> String.downcase()
    |> then(&Map.get(@priority_ranks, &1))
  end

  defp parse_priority(%{"id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {priority, ""} -> priority
      _ -> nil
    end
  end

  defp parse_priority(_priority), do: nil

  defp parse_datetime(nil), do: nil

  defp parse_datetime(raw) when is_binary(raw) do
    normalized = String.replace(raw, ~r/([+-]\d{2})(\d{2})$/, "\\1:\\2")

    case DateTime.from_iso8601(normalized) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp parse_datetime(_raw), do: nil

  defp normalize_match_value(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
  end

  defp normalize_match_value(_value), do: nil

  defp string_value(value) when is_binary(value), do: value
  defp string_value(value) when is_integer(value), do: Integer.to_string(value)
  defp string_value(_value), do: nil
end
