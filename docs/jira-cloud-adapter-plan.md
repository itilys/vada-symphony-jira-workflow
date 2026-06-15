# VaDa Symphony Jira Workflow Plan

Status: draft, with initial Jira read-only support implemented

VaDa Symphony Jira Workflow starts from OpenAI Symphony upstream and adds Jira Cloud support while
keeping the core scheduler and runner close to upstream. The first implementation target is a
self-hosted, single-tenant pilot, not a Marketplace app.

## Goals

- Keep Symphony's orchestration, workspace, runner, retry, and observability behavior upstream-first.
- Introduce a generic issue model so tracker adapters do not leak Linear-specific structs into core.
- Add `tracker.kind: jira` through the existing tracker boundary.
- Support Jira Cloud read/write flows in small phases: enhanced JQL search, issue normalization,
  comments, workpad updates, and transitions.
- Support a later ChatGPT Apps feedback intake loop where user-confirmed app feedback becomes a
  traceable Jira candidate before Symphony decides whether to run.
- Keep the project safe to publish as Open Source with sanitized fixtures and no bundled secrets.

## Non-Goals For The First Release

- Jira Data Center support.
- Atlassian Marketplace distribution.
- Multi-tenant hosting.
- A custom dashboard beyond Symphony's existing observability surface.
- Replacing human code review or CI gates.
- Silent ChatGPT App telemetry or automatic implementation without user confirmation.

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

- Implement a Jira REST client for enhanced JQL search. Initial implementation complete.
- Normalize Jira issues into `SymphonyElixir.Issue`. Initial implementation complete.
- Convert Jira ADF descriptions to text. Initial implementation complete.
- Extract labels, status, priority, assignee, issue links, and blockers.
- Keep read-only smoke tests runnable with `agent.mode: dry_run`.

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

## Phase 5A: Feedback Intake Specification

- Define the ChatGPT Apps feedback tool surface: `feedback.open`, `feedback.submit`, and
  `feedback.status`.
- Require editable feedback summaries and explicit user confirmation before any tracker write.
- Define feedback statuses, idempotency behavior, and sanitized fixtures.
- Keep the first implementation compatible with a local fake intake adapter.

## Phase 5B: Jira Feedback Intake

- Create Jira candidate issues from confirmed feedback using a dedicated label such as
  `symphony-feedback`.
- Store the feedback ID, source app, severity, type, user-reviewed summary, and Symphony decision
  status.
- Add `feedback.status` behavior backed by Jira metadata.
- Keep writes limited by ENV-configured Jira project allowlists.

## Phase 6: Symphony Feedback Analysis

- Deduplicate feedback and link duplicates.
- Classify feedback as bug, improvement, missing capability, confusing response, automation request,
  support, or out-of-scope.
- Decide whether feedback needs clarification, manual review, or can be accepted for work.
- Require human review for broad, risky, privacy-sensitive, or unclear requests.

## Phase 7: Controlled Implementation Runs

- Launch Symphony only for accepted, narrow, in-scope feedback.
- Create branches and pull requests through the normal GitHub workflow.
- Return PR and CI evidence to Jira before marking work ready for review.

## Phase 8: ChatGPT App Status And Validation Loop

- Let the ChatGPT App report received, triaged, running, PR-created, ready-for-review, completed, or
  declined statuses.
- Ask the user to validate whether the completed change addressed the original feedback.
- Route follow-up feedback through the same consent and Jira intake flow.

See [`feedback-to-symphony-loop.md`](feedback-to-symphony-loop.md) for the detailed target design.
