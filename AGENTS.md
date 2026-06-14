# AGENTS.md - VaDa Symphony Jira Workflow

This file is the operating guide for humans and AI agents contributing to this
repository. It is intentionally public-safe: do not add private VaDa internal
processes, personal names, local machine paths, customer data, Jira tenant data,
Codex auth details, GitHub credentials, screenshots with private issue content,
or secrets.

## Purpose

VaDa Symphony Jira Workflow is an Open Source, upstream-first orchestration
project based on OpenAI Symphony. Its goal is to let teams use Jira Cloud as a
human-visible control plane for coding agents while keeping GitHub as the source
of truth for code, branches, pull requests, and CI.

The project is not an official OpenAI or Atlassian project. It preserves
OpenAI Symphony attribution and evolves the reference implementation with a thin
Jira Cloud adapter, environment-driven deployment, Docker packaging, tests, and
operational documentation.

## Repository Status

Status: **early engineering preview**

Expected work includes:

- keeping the OpenAI Symphony core close to upstream;
- improving the generic tracker substrate;
- implementing Jira Cloud read-only and write adapters;
- adding Jira fixtures and live-sandbox integration tests;
- hardening ENV/Docker deployment paths;
- documenting safe self-hosted pilots;
- preserving compatibility with `tracker.kind: linear` and `tracker.kind: memory`.

The current Jira adapter is a placeholder until Phase 2 adds real Jira Cloud
REST reads.

## Source of Truth

When documentation conflicts, prefer this order:

1. `README.md` for public project identity, goals, and user-facing quick start.
2. `UPSTREAM_SHA` for the pinned OpenAI Symphony base commit.
3. `docs/jira-cloud-adapter-plan.md` for roadmap and phase boundaries.
4. `docs/env-and-docker.md` for runtime ENV and Docker setup.
5. `docs/upstream-maintenance.md` for syncing and publishing rules.
6. `SECURITY.md` for security posture and secret-handling guidance.
7. `CONTRIBUTING.md` for contribution expectations.
8. `elixir/AGENTS.md` for Elixir-specific rules under `elixir/`.
9. Source code and tests for implemented behavior.
10. `.github/workflows/` for CI behavior.

If behavior changes in a user-visible or operator-visible way, update the
relevant docs in the same change.

## Public Repository Rules

This is a public Open Source repository. Before committing, check that the
change does not include:

- personal names, usernames, home directories, or local machine paths such as
  `/Users/...`, `/private/tmp/...`, or developer-specific folders;
- real Jira tenant names, project names, issue keys, account IDs, email
  addresses, comments, descriptions, attachments, or workflow data;
- real GitHub tokens, Jira API tokens, OAuth credentials, SSH private keys,
  Codex auth files, certificates, or deployment credentials;
- raw Jira issue exports from private projects;
- workspace logs containing private code, proprietary traces, or personal data;
- private VaDa internal runbooks, customer names, supplier names, infrastructure
  paths, or operational details that do not apply to this OSS project;
- screenshots that reveal private Jira content, browser tabs, filesystem paths,
  terminals with tokens, or real customer/project identifiers.

Use synthetic examples in docs and tests. Prefer placeholder values such as
`ABC-123`, `https://example.atlassian.net`, `agent@example.com`,
`your-org/your-repo`, and `project = ABC AND labels in (symphony)`.

## Operating Rules

### Do

- Read this file before making changes.
- Keep each change small, scoped, and traceable.
- Preserve the upstream-first design.
- Prefer adding Jira behavior behind the existing tracker boundary.
- Keep core orchestration changes rare, deliberate, and well tested.
- Keep docs aligned with behavior and deployment expectations.
- State assumptions, risks, and validation clearly.
- Add fixtures for API payload behavior instead of relying only on live services.
- Treat logs, workspaces, and issue payloads as potentially sensitive.

### Do Not

- Do not turn Jira into the scheduler or core state machine.
- Do not break Linear or memory tracker compatibility while adding Jira.
- Do not claim tests, builds, Docker builds, or live Jira checks that were not run.
- Do not add secrets or real `.env` files.
- Do not add broad dependencies, external services, or auth flows without explaining why.
- Do not mix unrelated refactors, adapter work, Docker work, and docs in one change.
- Do not imply this is an official OpenAI, Atlassian, Jira, or Codex product.
- Do not publish or commit generated workspaces, logs, `_build/`, `deps/`, `.env`,
  or private runtime artifacts.

## Branching

Use short, readable branch names tied to one goal:

- `feature/<short-name>` for product/runtime work;
- `fix/<short-name>` for bug fixes;
- `docs/<short-name>` for documentation-only work;
- `chore/<short-name>` for maintenance;
- `sync/openai-symphony-YYYYMMDD` for upstream sync work.

Examples:

```text
feature/jira-read-only-client
docs/env-docker-runtime
fix/jira-config-validation
sync/openai-symphony-20260614
```

Do not reuse an old branch for a new scope.

## Pull Requests

Each PR should include:

- goal;
- scope;
- upstream OpenAI Symphony SHA;
- files outside Jira/tracker/ENV/docs/tests changed, with rationale;
- privacy and secret-handling check;
- compatibility notes for `linear`, `memory`, and `jira`;
- risks and assumptions;
- validation performed;
- follow-up work, if any.

Prefer one PR per logical change. If you notice unrelated cleanup while working,
open a separate PR.

Use the template in `.github/pull_request_template.md`.

## Validation Gate

Before calling work done, run the relevant checks.

For most changes:

```bash
cd elixir
mise exec -- mix format --check-formatted
mise exec -- mix test
mise exec -- mix compile --warnings-as-errors
```

For larger changes or before release-quality handoff:

```bash
cd elixir
make all
```

For Docker/ENV changes:

```bash
SYMPHONY_ENV_FILE=.env.example docker compose --env-file .env.example config
```

If a check cannot be run, state why in the PR or final report. Do not present a
check as passing unless it actually ran.

## CI/CD

The repository inherits GitHub Actions from OpenAI Symphony:

- `.github/workflows/make-all.yml` runs the Elixir quality gate on pushes and PRs
  to `main`.
- `.github/workflows/pr-description-lint.yml` validates PR body format.

When modifying CI, document the reason and avoid introducing private runners,
private secrets, or organization-specific assumptions into public workflows.

## ENV And Docker Rules

- `.env.example` is public and must contain only placeholders.
- `.env` and `.env.*` are private local files and must not be committed.
- `examples/WORKFLOW.jira.env.md` should remain runnable from ENV only.
- Keep `SYMPHONY_WORKSPACE_ROOT` and `SYMPHONY_LOGS_ROOT` configurable.
- Prefer HTTPS `SOURCE_REPO_URL` for first Docker smoke tests unless SSH keys are
  mounted explicitly.
- Docker support is a deployment scaffold; do not imply production hardening until
  runbooks, secrets, metrics, and rollback paths exist.

## Upstream Maintenance

OpenAI Symphony is the upstream source for the orchestration core.

When syncing:

- fetch OpenAI Symphony as `upstream`;
- keep Itilys as `origin`;
- update `UPSTREAM_SHA`;
- isolate sync work from Jira feature work when possible;
- run the validation gate after resolving conflicts.

See `docs/upstream-maintenance.md` for commands and push guidance.

## Architecture Notes

Important paths:

```text
elixir/
  lib/symphony_elixir/          Elixir runtime
  lib/symphony_elixir/jira/     Jira Cloud adapter work
  lib/symphony_elixir/linear/   Existing Linear support
  test/symphony_elixir/         Tests
examples/
  WORKFLOW.jira.env.md          ENV-driven Jira workflow
docs/
  jira-cloud-adapter-plan.md
  env-and-docker.md
  upstream-maintenance.md
```

Key implementation expectations:

- `SymphonyElixir.Issue` is the tracker-independent issue shape.
- `SymphonyElixir.Tracker` is the adapter boundary.
- `tracker.kind: jira` must not silently fall back to Linear.
- Jira Cloud REST code should live under `elixir/lib/symphony_elixir/jira/`.
- Jira API tests should prefer sanitized fixtures.
- Real Jira tests should be explicit, opt-in, and sandbox-only.
- The orchestrator owns scheduling, claims, retries, workspaces, and cleanup.

## Security Expectations

When changing Jira, Codex, GitHub, Docker, ENV, or workspace behavior, document:

- what external service is called;
- which credentials are required;
- whether data is logged or written to disk;
- how errors are sanitized;
- whether the operation can mutate Jira, GitHub, or a workspace;
- what limits, allowlists, or state checks prevent accidental broad action.

Ask before adding:

- OAuth flows;
- public app/Marketplace behavior;
- telemetry or cloud sync;
- write access beyond the current Jira issue;
- cross-project Jira automation;
- deletion of comments/issues/workspaces;
- credential storage;
- production deployment automation.

## Completion Checklist

Before closing a task:

- [ ] correct branch or explicit maintainer direction;
- [ ] one logical change only;
- [ ] public/privacy check completed;
- [ ] generated/private files excluded;
- [ ] upstream attribution preserved;
- [ ] docs updated if behavior changed;
- [ ] tests/builds run, or limitations explained;
- [ ] Docker/ENV validation run if runtime config changed;
- [ ] push/PR status explicitly stated.
