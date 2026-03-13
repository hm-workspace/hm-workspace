#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

echo "Starting local stack from $ROOT"
if [ -f "$ROOT/docker/docker-compose.yml" ]; then
  docker compose -f "$ROOT/docker/docker-compose.yml" up -d
else
  echo "docker-compose file not found: $ROOT/docker/docker-compose.yml"
  exit 1
fi
