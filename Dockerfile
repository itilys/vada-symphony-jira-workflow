# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

ARG MISE_VERSION=v2026.6.6
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    MISE_DATA_DIR=/opt/mise/data \
    MISE_CACHE_DIR=/opt/mise/cache \
    MISE_CONFIG_DIR=/etc/mise \
    MISE_STATE_DIR=/opt/mise/state \
    MIX_HOME=/opt/mix \
    HEX_HOME=/opt/hex \
    MIX_ENV=prod \
    SYMPHONY_WORKFLOW_FILE=/app/examples/WORKFLOW.jira.env.md \
    SYMPHONY_HOST=0.0.0.0 \
    SYMPHONY_PORT=4000 \
    SYMPHONY_WORKSPACE_ROOT=/workspaces \
    SYMPHONY_LOGS_ROOT=/logs

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    unzip \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  case "${TARGETARCH:-amd64}" in \
    amd64) mise_arch="x64" ;; \
    arm64) mise_arch="arm64" ;; \
    *) echo "Unsupported Docker architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac; \
  curl -fsSL "https://github.com/jdx/mise/releases/download/${MISE_VERSION}/mise-${MISE_VERSION}-linux-${mise_arch}" -o /usr/local/bin/mise; \
  chmod +x /usr/local/bin/mise; \
  mkdir -p "$MISE_DATA_DIR" "$MISE_CACHE_DIR" "$MISE_CONFIG_DIR" "$MISE_STATE_DIR" "$MIX_HOME" "$HEX_HOME" /workspaces /logs

WORKDIR /app
COPY . .

WORKDIR /app/elixir
RUN mise trust /app/elixir/mise.toml \
  && mise install \
  && mise exec -- mix local.hex --force \
  && mise exec -- mix local.rebar --force \
  && mise exec -- mix deps.get --only prod \
  && mise exec -- mix escript.build

EXPOSE 4000

CMD ["sh", "-lc", "mise exec -- ./bin/symphony --i-understand-that-this-will-be-running-without-the-usual-guardrails \"$SYMPHONY_WORKFLOW_FILE\" --logs-root \"$SYMPHONY_LOGS_ROOT\" --port \"$SYMPHONY_PORT\""]
