# Install And Smoke Test

Status: v0.1-alpha target

This guide validates the first safe runtime path:

- load configuration from ENV;
- connect to a Jira Cloud sandbox;
- read candidate issues with JQL;
- normalize issues for Symphony;
- prepare a workspace in `dry_run` mode;
- avoid Jira writes, GitHub writes, and Codex execution.

## Prerequisites

- A Jira Cloud sandbox project.
- A Jira account email and API token with browse permission for that project.
- One issue labeled `symphony` in a status included by `JIRA_JQL`.
- Elixir/Erlang through `mise`, or Docker.

Do not use a production Jira project for the first smoke test.

## Environment

```bash
cp .env.example .env
```

Edit `.env`:

```bash
JIRA_SITE=https://your-tenant.atlassian.net
JIRA_EMAIL=symphony-agent@example.com
JIRA_API_TOKEN=replace-with-jira-api-token
JIRA_PROJECT_KEY=ABC
JIRA_JQL=project = ABC AND labels in (symphony) AND status in ("Ready for Agent", "Rework") ORDER BY priority DESC, updated ASC
SYMPHONY_AGENT_MODE=dry_run
```

`SYMPHONY_AGENT_MODE=dry_run` is intentional. It lets Symphony prove the Jira/workspace loop without
starting Codex.

## Local Smoke Test

```bash
set -a
. ./.env
set +a

cd elixir
mise trust
mise install
mise exec -- mix setup
mise exec -- mix test
mise exec -- ./bin/symphony \
  --i-understand-that-this-will-be-running-without-the-usual-guardrails \
  ../examples/WORKFLOW.jira.env.md \
  --logs-root "$SYMPHONY_LOGS_ROOT" \
  --port "$SYMPHONY_PORT"
```

Expected behavior:

- Symphony validates Jira ENV values.
- Symphony polls Jira through read-only REST calls.
- Matching Jira issues are normalized to `SymphonyElixir.Issue`.
- In `dry_run`, Symphony prepares the workspace and runs workspace hooks.
- Symphony does not create Jira comments, transition issues, push code, or start Codex.

## Docker Smoke Test

Validate Compose interpolation:

```bash
SYMPHONY_ENV_FILE=.env.example docker compose --env-file .env.example config
```

Run:

```bash
docker compose up --build
```

The dashboard is available on `http://localhost:${SYMPHONY_PORT}`.

## What This Does Not Prove

- Jira comments.
- Jira transitions.
- Codex auth inside Docker.
- GitHub branch or PR creation.
- End-to-end implementation from a Jira issue.
- ChatGPT Apps feedback intake.

Those belong to later phases after the read-only smoke test is stable.
