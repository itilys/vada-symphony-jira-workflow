# Contributing

Thanks for helping build the Symphony Jira Cloud adapter.

This repository is upstream-first: changes should stay as close as possible to OpenAI Symphony unless
they are required for tracker abstraction, Jira Cloud support, tests, or documentation.

## Local Development

```bash
cd elixir
mise trust
mise install
mise exec -- mix setup
mise exec -- mix test
```

Use `make all` before opening a larger pull request when local dependencies are available.

## Pull Requests

Please include:

- the upstream Symphony SHA you started from;
- why any files outside Jira or tracker abstraction code changed;
- tests added or updated;
- compatibility notes for `tracker.kind: linear` and `tracker.kind: memory`;
- any security, secret-handling, or permission impact.

Do not commit Jira API tokens, `.env` files, real issue dumps, customer data, Codex auth files, or
workspace logs.
