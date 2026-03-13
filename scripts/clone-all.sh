#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME/hm-workspace}"
OWNER="${GITHUB_OWNER:-manojkumarmeda}"
PROTOCOL="${GIT_PROTOCOL:-https}"
mkdir -p "$ROOT"/{services,ui,platform}

repos=(
  "hm-api-gateway services"
  "hm-auth-service services"
  "hm-patient-service services"
  "hm-doctor-service services"
  "hm-appointment-service services"
  "hm-medical-records-service services"
  "hm-department-service services"
  "hm-staff-service services"
  "hm-notification-service services"
  "customer-portal ui"
  "admin-portal ui"
  "terraform-infra platform"
  "terraform-modules platform"
)

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
