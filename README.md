# VaDa Symphony Jira Workflow

Open Source reference runtime for a self-coding workflow inspired by
[OpenAI Symphony](https://github.com/openai/symphony), adapted to use Jira Cloud as the work
control plane.

This repository starts from the OpenAI Symphony Elixir reference implementation and evolves it
upstream-first: Symphony remains the orchestration core, while this project adds a thin Jira Cloud
adapter, environment-driven deployment, Docker packaging, and operational documentation for real
pilots.

> [!IMPORTANT]
> This is not an official OpenAI or Atlassian project. It is an independent Open Source project that
> builds on the public OpenAI Symphony codebase and keeps upstream attribution intact.

## What This Project Is

VaDa Symphony Jira Workflow turns Jira issues into isolated implementation runs:

1. Jira Cloud holds work items, workflow states, comments, and human handoff.
2. Symphony polls eligible issues and creates one workspace per issue.
3. Codex runs inside that workspace with the project workflow prompt.
4. GitHub remains the source of truth for code, branches, pull requests, and CI.
5. Jira receives progress, validation evidence, blocker notes, and review handoff.

The immediate goal is a self-hosted pilot that can be run locally or in Docker against a Jira Cloud
sandbox project and a safe GitHub repository.

## Relationship To OpenAI Symphony

OpenAI Symphony describes an orchestration pattern where project work is turned into isolated,
autonomous implementation runs. This repository keeps that model and the upstream Elixir reference
implementation as the base.

Upstream tracking:

- Upstream repository: <https://github.com/openai/symphony>
- Upstream specification: <https://github.com/openai/symphony/blob/main/SPEC.md>
- Pinned upstream commit: [`UPSTREAM_SHA`](UPSTREAM_SHA)
- License: Apache License 2.0, preserved from upstream in [`LICENSE`](LICENSE)
- Attribution: see [`NOTICE`](NOTICE)

Our changes should stay concentrated around tracker abstraction, Jira Cloud support, ENV/Docker
runtime setup, tests, and operational documentation.

## Current Status

Status: early engineering preview.

Completed:

- Open Source project baseline: license, notice, contributing guide, security notes.
- Generic tracker issue model: `SymphonyElixir.Issue`.
- Explicit tracker adapter selection for `memory`, `linear`, and `jira`.
- Jira config validation and environment variable resolution.
- ENV-first Jira workflow template.
- Docker and Docker Compose scaffolding.
- Test coverage for the Jira substrate and ENV workflow.

Not yet implemented:

- Real Jira Cloud REST reads.
- Jira issue normalization from live API payloads.
- ADF description/comment conversion.
- Jira comments, workpad updates, and transitions.
- Agent-side constrained Jira tool.
- End-to-end live Jira pilot.

## Repository Map

- [`elixir/`](elixir/) - Symphony Elixir reference runtime plus tracker abstraction work.
- [`examples/WORKFLOW.jira.env.md`](examples/WORKFLOW.jira.env.md) - ENV-driven Jira workflow.
- [`.env.example`](.env.example) - runtime variables for local and Docker tests.
- [`Dockerfile`](Dockerfile) - container image for the Elixir runtime.
- [`docker-compose.yml`](docker-compose.yml) - local container runtime with workspaces and logs.
- [`docs/jira-cloud-adapter-plan.md`](docs/jira-cloud-adapter-plan.md) - implementation plan.
- [`docs/env-and-docker.md`](docs/env-and-docker.md) - ENV and Docker guide.
- [`docs/upstream-maintenance.md`](docs/upstream-maintenance.md) - syncing and publishing guide.
- [`AGENTS.md`](AGENTS.md) - operating guide for humans and AI agents.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) - contribution rules.
- [`SECURITY.md`](SECURITY.md) - security posture and secret-handling guidance.

## Quick Start

Install the Elixir/Erlang versions pinned by `elixir/mise.toml`:

```bash
cd elixir
mise trust
mise install
mise exec -- mix setup
```

Run the local verification suite:

```bash
cd elixir
mise exec -- mix format --check-formatted
mise exec -- mix test
mise exec -- mix compile --warnings-as-errors
```

Expected current result:

```text
246 tests, 0 failures, 2 skipped
```

## ENV-Driven Runtime

Create a local environment file:

```bash
cp .env.example .env
```

Edit `.env` with your Jira sandbox project, safe source repository, workspace path, and logs path.

Validate Docker Compose interpolation without creating or exposing real secrets:

```bash
SYMPHONY_ENV_FILE=.env.example docker compose --env-file .env.example config
```

Run the local ENV workflow:

```bash
set -a
. ./.env
set +a

cd elixir
mise exec -- ./bin/symphony \
  --i-understand-that-this-will-be-running-without-the-usual-guardrails \
  ../examples/WORKFLOW.jira.env.md \
  --logs-root "$SYMPHONY_LOGS_ROOT" \
  --port "$SYMPHONY_PORT"
```

Run with Docker:

```bash
docker compose up --build
```

See [`docs/env-and-docker.md`](docs/env-and-docker.md) for details.

## Roadmap

Phase 0: Open Source baseline.

- Upstream pinning.
- OSS docs and security posture.
- ENV/Docker scaffolding.

Phase 1: Generic tracker substrate.

- Generic issue model.
- Explicit adapter selection.
- Jira config validation.

Phase 2: Jira read-only adapter.

- Jira REST client.
- Enhanced JQL search.
- Pagination.
- Fixtures.
- Jira issue normalization.
- ADF description to Markdown/text.

Phase 3: Jira write adapter.

- Comments.
- Workpad updates.
- Transition resolution.
- Error handling and log sanitization.

Phase 4: Agent tooling.

- Constrained Jira tool for Codex app-server or MCP.
- Current-issue-only write policy.
- Audit trail.

Phase 5: Live pilot.

- One Jira Cloud sandbox project.
- One GitHub repository.
- One `symphony` label.
- Human review before merge.

## Open Source Posture

This project is Apache 2.0 licensed and intended to remain Open Source. Contributions should keep
the upstream-first design intact and avoid turning Jira into the core scheduler.

Do not commit:

- `.env` files;
- Jira API tokens or OAuth credentials;
- Codex auth files;
- GitHub tokens;
- raw private Jira issue exports;
- workspace logs containing private code or personal data.

## Maintainer Notes

The intended public home for this project is:

<https://github.com/itilys/vada-symphony-jira-workflow>

Why: the name keeps the VaDa identity, makes the Symphony relationship obvious, and describes the
Jira control-plane focus without implying this is an official OpenAI project.

When syncing with OpenAI Symphony, keep `UPSTREAM_SHA` current and document any non-Jira changes in
the pull request.
