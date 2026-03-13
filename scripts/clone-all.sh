#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="${REPOS_MANIFEST:-$SCRIPT_DIR/../repos.json}"
ROOT="${1:-$HOME/hm-workspace}"
PROTOCOL="${GIT_PROTOCOL:-https}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install jq and retry."
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "Manifest not found: $MANIFEST"
  exit 1
fi

OWNER="${GITHUB_OWNER:-$(jq -r '.owner' "$MANIFEST")}"

mkdir -p "$ROOT"/{services,ui,platform}

mapfile -t repos < <(jq -r '.repositories[] | "\(.name) \(.group)"' "$MANIFEST")

for entry in "${repos[@]}"; do
  name="${entry%% *}"
  folder="${entry##* }"
  if [ "$PROTOCOL" = "ssh" ]; then
    url="git@github.com:${OWNER}/${name}.git"
  else
    url="https://github.com/${OWNER}/${name}.git"
  fi

  git clone "$url" "$ROOT/$folder/$name"
done
