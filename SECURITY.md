# Security

This project is experimental software for trusted, self-hosted environments.

## Reporting

Please do not open public issues containing secrets, private Jira data, auth tokens, or exploit
details. Report security-sensitive findings privately to the project maintainers once a public
contact channel exists.

## Secrets

Never commit:

- Jira API tokens or OAuth credentials;
- Atlassian account emails used as service accounts;
- Codex auth files;
- GitHub tokens;
- raw Jira issue exports from private projects;
- raw ChatGPT conversations, private feedback payloads, app session IDs, or user telemetry;
- workspace logs containing proprietary code or personal data.

## ChatGPT App Feedback

Feedback intake must be consent-based. A ChatGPT App may suggest sending feedback, but it must not
silently upload conversation context, screenshots, device details, logs, or private app state.

Before feedback becomes a Jira candidate or Symphony work item, the user should be able to review
and edit the summary, confirm submission, and understand that the feedback may be used to create
implementation work.

## Runtime Posture

For pilots, use a dedicated Jira service account with project-scoped permissions, a dedicated
workspace root, conservative concurrency, and human review before merge.
