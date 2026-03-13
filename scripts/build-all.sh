#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
MANIFEST="${REPOS_MANIFEST:-$ROOT/repos.json}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq and retry."
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "Manifest not found: $MANIFEST"
  exit 1
fi

mapfile -t services < <(jq -r '.repositories[] | select(.group == "services") | .name' "$MANIFEST")

for s in "${services[@]}"; do
  if [ -d "$ROOT/services/$s" ]; then
    echo "Building $s"
    (cd "$ROOT/services/$s" && dotnet build)
  else
    echo "Skipping missing service: $s"
  fi
done
