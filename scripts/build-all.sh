#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

services=(
  "hm-api-gateway"
  "hm-auth-service"
  "hm-patient-service"
  "hm-doctor-service"
  "hm-appointment-service"
  "hm-medical-records-service"
  "hm-department-service"
  "hm-staff-service"
  "hm-notification-service"
)

for s in "${services[@]}"; do
  if [ -d "$ROOT/services/$s" ]; then
    echo "Building $s"
    (cd "$ROOT/services/$s" && dotnet build)
  else
    echo "Skipping missing service: $s"
  fi
done
