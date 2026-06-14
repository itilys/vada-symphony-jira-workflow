# VaDa Symphony Jira Workflow Plan

Status: draft

VaDa Symphony Jira Workflow starts from OpenAI Symphony upstream and adds Jira Cloud support while
keeping the core scheduler and runner close to upstream. The first implementation target is a
self-hosted, single-tenant pilot, not a Marketplace app.

## Goals

- Keep Symphony's orchestration, workspace, runner, retry, and observability behavior upstream-first.
- Introduce a generic issue model so tracker adapters do not leak Linear-specific structs into core.
- Add `tracker.kind: jira` through the existing tracker boundary.
- Support Jira Cloud read/write flows in small phases: enhanced JQL search, issue normalization,
  comments, workpad updates, and transitions.
- Keep the project safe to publish as Open Source with sanitized fixtures and no bundled secrets.

## Non-Goals For The First Release

- Jira Data Center support.
- Atlassian Marketplace distribution.
- Multi-tenant hosting.
- A custom dashboard beyond Symphony's existing observability surface.
- Replacing human code review or CI gates.

## Phase 0: OSS Baseline

- Pin the upstream Symphony commit in `UPSTREAM_SHA`.
- Document project scope, contribution expectations, and security reporting.
- Preserve Apache 2.0 licensing and upstream attribution.
- Provide ENV/Docker scaffolding for local smoke tests and future deployment.

## Phase 1: Generic Tracker Substrate

- Add `SymphonyElixir.Issue` as the normalized issue struct for core.
- Keep Linear compatibility while moving core modules to the generic issue model.
- Make `Tracker.adapter/0` dispatch `memory`, `linear`, and `jira` explicitly.
- Validate the minimum Jira Cloud config before runtime dispatch.

## Phase 2: Jira Read-Only Adapter

- Implement a Jira REST client for enhanced JQL search.
- Normalize Jira issues into `SymphonyElixir.Issue`.
- Convert Jira ADF descriptions to Markdown/text.
- Extract labels, status, priority, assignee, issue links, and blockers.

## Phase 3: Jira Writes

- Convert simple Markdown/text to ADF for comments.
- Create and update Jira comments.
- Resolve available transitions dynamically and transition by destination status.
- Sanitize logs and return clear errors for auth, permissions, rate limits, invalid ADF, and missing transitions.

## Phase 4: Agent Tooling

- Add a constrained Jira tool for the Codex app-server runtime or migrate this surface to MCP if the
  app-server dynamic tool contract changes.
- Limit writes to the current issue and allowed workflow transitions.
- Record an audit trail for every write.

## Phase 5: Pilot

- Use one Jira Cloud sandbox project, one GitHub repository, and one `symphony` label.
- Start with small documentation, test, or narrowly scoped code issues.
- Require PR/CI evidence before moving Jira issues to human review.
