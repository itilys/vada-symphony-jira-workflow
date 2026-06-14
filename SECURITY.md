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
- workspace logs containing proprietary code or personal data.

## Runtime Posture

For pilots, use a dedicated Jira service account with project-scoped permissions, a dedicated
workspace root, conservative concurrency, and human review before merge.
