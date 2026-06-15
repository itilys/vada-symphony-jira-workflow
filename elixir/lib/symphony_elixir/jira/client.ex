defmodule SymphonyElixir.Jira.Client do
  @moduledoc """
  Read-only Jira Cloud REST client.
  """

  require Logger

  alias SymphonyElixir.{Config, Issue}
  alias SymphonyElixir.Jira.IssueMapper

  @issue_page_size 50
  @max_error_body_log_bytes 1_000
  @issue_fields ~w(summary description status priority labels assignee issuelinks created updated)

  @spec fetch_candidate_issues() :: {:ok, [Issue.t()]} | {:error, term()}
  def fetch_candidate_issues do
    tracker = Config.settings!().tracker
    jql = tracker.jql || project_states_jql(tracker.project_key, tracker.active_states)
    search_jql(jql)
  end

  @spec fetch_issues_by_states([String.t()]) :: {:ok, [Issue.t()]} | {:error, term()}
  def fetch_issues_by_states(state_names) when is_list(state_names) do
    states =
      state_names
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    if states == [] do
      {:ok, []}
    else
      tracker = Config.settings!().tracker
      search_jql(project_states_jql(tracker.project_key, states))
    end
  end

  @spec fetch_issue_states_by_ids([String.t()]) :: {:ok, [Issue.t()]} | {:error, term()}
  def fetch_issue_states_by_ids(issue_ids) when is_list(issue_ids) do
    ids =
      issue_ids
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    case ids do
      [] ->
        {:ok, []}

      ids ->
        with {:ok, issues} <- search_jql(issue_lookup_jql(ids)) do
          {:ok, sort_issues_by_requested_ids(issues, ids)}
        end
    end
  end

  @doc false
  @spec search_jql_for_test(String.t(), keyword()) :: {:ok, [Issue.t()]} | {:error, term()}
  def search_jql_for_test(jql, opts), do: search_jql(jql, opts)

  @doc false
  @spec project_states_jql_for_test(String.t(), [String.t()]) :: String.t()
  def project_states_jql_for_test(project_key, states), do: project_states_jql(project_key, states)

  @doc false
  @spec issue_lookup_jql_for_test([String.t()]) :: String.t()
  def issue_lookup_jql_for_test(ids), do: issue_lookup_jql(ids)

  @spec search_jql(String.t(), keyword()) :: {:ok, [Issue.t()]} | {:error, term()}
  def search_jql(jql, opts \\ []) when is_binary(jql) and is_list(opts) do
    tracker = Config.settings!().tracker

    cond do
      !configured_endpoint?(tracker.endpoint) ->
        {:error, :missing_jira_endpoint}

      !is_binary(tracker.email) ->
        {:error, :missing_jira_email}

      !is_binary(tracker.api_token) ->
        {:error, :missing_jira_api_token}

      true ->
        request_fun = Keyword.get(opts, :request_fun, &post_search_request/3)
        do_search_jql(jql, tracker, request_fun, nil, [])
    end
  end

  defp do_search_jql(jql, tracker, request_fun, next_page_token, acc_issues) do
    payload = search_payload(jql, next_page_token)

    with {:ok, headers} <- jira_headers(tracker),
         {:ok, %{status: 200, body: body}} <- request_fun.(tracker.endpoint, payload, headers),
         {:ok, issues, page_info} <- decode_search_response(body, tracker) do
      updated_acc = prepend_page_issues(issues, acc_issues)

      case next_page_token(page_info) do
        {:ok, token} ->
          do_search_jql(jql, tracker, request_fun, token, updated_acc)

        :done ->
          {:ok, finalize_paginated_issues(updated_acc)}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:ok, response} ->
        Logger.error("Jira search request failed status=#{response.status} body=#{summarize_error_body(response.body)}")

        {:error, {:jira_api_status, response.status}}

      {:error, reason} ->
        Logger.error("Jira search request failed: #{inspect(reason)}")
        {:error, {:jira_api_request, reason}}
    end
  end

  defp search_payload(jql, nil) do
    %{
      "jql" => jql,
      "maxResults" => @issue_page_size,
      "fields" => @issue_fields
    }
  end

  defp search_payload(jql, next_page_token) when is_binary(next_page_token) do
    jql
    |> search_payload(nil)
    |> Map.put("nextPageToken", next_page_token)
  end

  defp decode_search_response(%{"issues" => issues} = body, tracker) when is_list(issues) do
    mapped_issues =
      issues
      |> Enum.map(&IssueMapper.from_jira_issue(&1, site: tracker.endpoint, assignee: tracker.assignee))
      |> Enum.reject(&is_nil/1)

    {:ok, mapped_issues, %{is_last: body["isLast"] == true, next_page_token: body["nextPageToken"]}}
  end

  defp decode_search_response(_body, _tracker), do: {:error, :jira_unknown_payload}

  defp next_page_token(%{is_last: true}), do: :done

  defp next_page_token(%{next_page_token: token}) when is_binary(token) and byte_size(token) > 0 do
    {:ok, token}
  end

  defp next_page_token(%{is_last: false}), do: {:error, :jira_missing_next_page_token}
  defp next_page_token(_page_info), do: :done

  defp post_search_request(endpoint, payload, headers) do
    endpoint
    |> rest_url("/rest/api/3/search/jql")
    |> Req.post(
      headers: headers,
      json: payload,
      connect_options: [timeout: 30_000],
      receive_timeout: 30_000
    )
  end

  defp jira_headers(tracker) do
    case {tracker.email, tracker.api_token} do
      {email, token} when is_binary(email) and is_binary(token) ->
        encoded = Base.encode64(email <> ":" <> token)

        {:ok,
         [
           {"Accept", "application/json"},
           {"Authorization", "Basic " <> encoded},
           {"Content-Type", "application/json"}
         ]}

      {nil, _token} ->
        {:error, :missing_jira_email}

      {_email, nil} ->
        {:error, :missing_jira_api_token}
    end
  end

  defp configured_endpoint?(endpoint) when is_binary(endpoint) do
    String.trim(endpoint) not in ["", "https://api.linear.app/graphql"]
  end

  defp configured_endpoint?(_endpoint), do: false

  defp project_states_jql(project_key, states) do
    "project = #{jql_project(project_key)} AND status in (#{jql_values(states)}) ORDER BY priority DESC, updated ASC"
  end

  defp issue_lookup_jql(ids) do
    {numeric_ids, issue_keys} = Enum.split_with(ids, &numeric?/1)

    [
      numeric_ids_jql(numeric_ids),
      issue_keys_jql(issue_keys)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" OR ")
    |> then(&("(" <> &1 <> ")"))
  end

  defp numeric_ids_jql([]), do: nil
  defp numeric_ids_jql(ids), do: "id in (#{Enum.join(ids, ", ")})"

  defp issue_keys_jql([]), do: nil
  defp issue_keys_jql(keys), do: "issuekey in (#{jql_values(keys)})"

  defp sort_issues_by_requested_ids(issues, requested_ids) do
    issue_order_index =
      requested_ids
      |> Enum.with_index()
      |> Map.new()

    fallback_index = map_size(issue_order_index)

    Enum.sort_by(issues, fn
      %Issue{id: issue_id, identifier: identifier} ->
        Map.get(issue_order_index, issue_id) ||
          Map.get(issue_order_index, identifier) ||
          fallback_index

      _ ->
        fallback_index
    end)
  end

  defp prepend_page_issues(issues, acc_issues) when is_list(issues) and is_list(acc_issues) do
    Enum.reverse(issues, acc_issues)
  end

  defp finalize_paginated_issues(acc_issues), do: Enum.reverse(acc_issues)

  defp jql_project(project_key) when is_binary(project_key) do
    if String.match?(project_key, ~r/^[A-Za-z][A-Za-z0-9_]*$/) do
      project_key
    else
      jql_quote(project_key)
    end
  end

  defp jql_project(project_key), do: jql_quote(to_string(project_key))

  defp jql_values(values) when is_list(values) do
    values
    |> Enum.map(&to_string/1)
    |> Enum.map(&jql_quote/1)
    |> Enum.join(", ")
  end

  defp jql_quote(value) when is_binary(value) do
    "\"" <> String.replace(value, "\"", "\\\"") <> "\""
  end

  defp numeric?(value) when is_binary(value), do: String.match?(value, ~r/^\d+$/)
  defp numeric?(_value), do: false

  defp rest_url(endpoint, path) do
    String.trim_trailing(endpoint, "/") <> path
  end

  defp summarize_error_body(body) when is_binary(body) do
    body
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> truncate_error_body()
    |> inspect()
  end

  defp summarize_error_body(body) do
    body
    |> inspect(limit: 20, printable_limit: @max_error_body_log_bytes)
    |> truncate_error_body()
  end

  defp truncate_error_body(body) when is_binary(body) do
    if byte_size(body) > @max_error_body_log_bytes do
      binary_part(body, 0, @max_error_body_log_bytes) <> "...<truncated>"
    else
      body
    end
  end
end
