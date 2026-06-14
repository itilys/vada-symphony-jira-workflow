defmodule SymphonyElixir.Jira.Adapter do
  @moduledoc """
  Jira Cloud tracker adapter placeholder.

  The adapter is selected explicitly by `tracker.kind: jira`; read/write support is implemented in
  the Jira phases after the generic tracker substrate.
  """

  @behaviour SymphonyElixir.Tracker

  @not_implemented {:error, :jira_adapter_not_implemented}

  @spec fetch_candidate_issues() :: {:error, :jira_adapter_not_implemented}
  def fetch_candidate_issues, do: @not_implemented

  @spec fetch_issues_by_states([String.t()]) :: {:error, :jira_adapter_not_implemented}
  def fetch_issues_by_states(_states), do: @not_implemented

  @spec fetch_issue_states_by_ids([String.t()]) :: {:error, :jira_adapter_not_implemented}
  def fetch_issue_states_by_ids(_issue_ids), do: @not_implemented

  @spec create_comment(String.t(), String.t()) :: {:error, :jira_adapter_not_implemented}
  def create_comment(_issue_id, _body), do: @not_implemented

  @spec update_issue_state(String.t(), String.t()) :: {:error, :jira_adapter_not_implemented}
  def update_issue_state(_issue_id, _state_name), do: @not_implemented
end
