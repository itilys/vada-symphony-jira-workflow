# Environment And Docker

This project is moving toward an environment-driven runtime so local tests, Docker, and deployment
use the same configuration surface.

## Files

- `.env.example` lists the runtime variables.
- `examples/WORKFLOW.jira.env.md` is the Jira workflow template that reads those variables.
- `Dockerfile` builds the Elixir reference runtime with the pinned `mise.toml` versions.
- `docker-compose.yml` runs Symphony with `.env`, mounted workspaces, mounted logs, and the dashboard port.

## Local ENV Smoke Test

```bash
cp .env.example .env
# Edit .env with a Jira sandbox project and a safe source repo.

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

## Docker Smoke Test

```bash
cp .env.example .env
# Edit .env first.

docker compose up --build
```

The dashboard is available on `http://localhost:${SYMPHONY_PORT}`.

To validate Compose interpolation without creating a real `.env`:

```bash
SYMPHONY_ENV_FILE=.env.example docker compose --env-file .env.example config
```

## Notes

- The current Jira adapter is still a placeholder. Real Jira read-only calls start in Phase 2.
- The image does not install or authenticate Codex yet. Before dispatching real agent work, provide
  a working `CODEX_COMMAND` and auth mechanism in the container/runtime.
- Prefer an HTTPS `SOURCE_REPO_URL` for the first container smoke test. Use SSH only after mounting
  the required keys and known hosts into the container.
- Do not commit `.env`; only commit `.env.example`.
