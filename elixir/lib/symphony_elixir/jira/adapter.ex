defmodule SymphonyElixir.Jira.Adapter do
  @moduledoc """
  Jira Cloud tracker adapter.

  The first implementation supports read-only Jira polling. Writes stay disabled until the Jira
  write phase adds comment and transition support.
  """

  @behaviour SymphonyElixir.Tracker

  alias SymphonyElixir.Jira.Client

  @write_not_implemented {:error, :jira_write_not_implemented}

  @spec fetch_candidate_issues() :: {:ok, [term()]} | {:error, term()}
  def fetch_candidate_issues, do: client_module().fetch_candidate_issues()

  @spec fetch_issues_by_states([String.t()]) :: {:ok, [term()]} | {:error, term()}
  def fetch_issues_by_states(states), do: client_module().fetch_issues_by_states(states)

  @spec fetch_issue_states_by_ids([String.t()]) :: {:ok, [term()]} | {:error, term()}
  def fetch_issue_states_by_ids(issue_ids), do: client_module().fetch_issue_states_by_ids(issue_ids)

  @spec create_comment(String.t(), String.t()) :: {:error, :jira_write_not_implemented}
  def create_comment(_issue_id, _body), do: @write_not_implemented

  @spec update_issue_state(String.t(), String.t()) :: {:error, :jira_write_not_implemented}
  def update_issue_state(_issue_id, _state_name), do: @write_not_implemented

  defp client_module do
    Application.get_env(:symphony_elixir, :jira_client_module, Client)
  end
end
