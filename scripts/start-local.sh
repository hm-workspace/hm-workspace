#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
DOCKER_DIR="$ROOT/docker"
ENV_FILE="$DOCKER_DIR/.env"
ENV_EXAMPLE="$DOCKER_DIR/.env.example"

echo "Starting local stack from $ROOT"
if [ ! -f "$ENV_FILE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "Created $ENV_FILE from template."
fi

if [ -f "$DOCKER_DIR/docker-compose.yml" ]; then
  docker compose --env-file "$ENV_FILE" -f "$DOCKER_DIR/docker-compose.yml" up -d --build
else
  echo "docker-compose file not found: $ROOT/docker/docker-compose.yml"
  exit 1
fi
