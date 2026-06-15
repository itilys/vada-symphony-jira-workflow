---
tracker:
  kind: jira
  endpoint: "$JIRA_SITE"
  email: "$JIRA_EMAIL"
  api_token: "$JIRA_API_TOKEN"
  project_key: "$JIRA_PROJECT_KEY"
  jql: "$JIRA_JQL"
  required_labels:
    - symphony
  active_states:
    - "Ready for Agent"
    - "Agent Running"
    - "Rework"
    - "Merging"
  terminal_states:
    - "Done"
    - "Cancelled"
    - "Canceled"
    - "Duplicate"
polling:
  interval_ms: 30000
workspace:
  root: "$SYMPHONY_WORKSPACE_ROOT"
server:
  host: "$SYMPHONY_HOST"
hooks:
  after_create: |
    git clone --depth 1 "$SOURCE_REPO_URL" .
    if [ -n "$SOURCE_REPO_REF" ]; then
      git fetch origin "$SOURCE_REPO_REF"
      git checkout FETCH_HEAD
    fi
    if command -v mise >/dev/null 2>&1 && [ -f mise.toml ]; then
      mise trust
      mise install
    fi
  before_run: |
    git status --short
agent:
  mode: "$SYMPHONY_AGENT_MODE"
  max_concurrent_agents: 1
  max_turns: 20
codex:
  command: "$CODEX_COMMAND"
  approval_policy: never
  thread_sandbox: workspace-write
  turn_sandbox_policy:
    type: workspaceWrite
    networkAccess: true
---

You are working on Jira issue {{ issue.identifier }}.

Title:
{{ issue.title }}

Current status:
{{ issue.state }}

Labels:
{{ issue.labels }}

URL:
{{ issue.url }}

Description:
{% if issue.description %}
{{ issue.description }}
{% else %}
No description provided.
{% endif %}

Rules:
- Work only inside the current workspace.
- Create or update a branch named from the Jira issue key.
- Create or update a GitHub PR for code changes.
- Keep a Jira workpad comment updated with progress, validation evidence, and the PR link.
- Move the Jira issue to Human Review only when validation is complete.
- If the issue is ambiguous or blocked, explain the blocker in Jira and stop.
