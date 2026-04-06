#!/usr/bin/env sh
set -eu

SERVER="${DB_SERVER:-sqlserver}"
USER="${DB_USER:-sa}"
PASSWORD="${SA_PASSWORD:?SA_PASSWORD is required}"
APPLY_USER_SCRIPTS="${APPLY_USER_SCRIPTS:-false}"

if [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
  SQLCMD_BIN="/opt/mssql-tools18/bin/sqlcmd"
elif [ -x /opt/mssql-tools/bin/sqlcmd ]; then
  SQLCMD_BIN="/opt/mssql-tools/bin/sqlcmd"
else
  echo "[db-init] sqlcmd not found in container"
  exit 1
fi

log() {
  echo "[db-init] $1"
}

wait_for_sql() {
  log "Waiting for SQL Server at ${SERVER}..."
  i=0
  until "$SQLCMD_BIN" -C -S "${SERVER}" -U "${USER}" -P "${PASSWORD}" -Q "SELECT 1" >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -ge 60 ]; then
      log "SQL Server did not become ready in time"
      exit 1
    fi
    sleep 3
  done
  log "SQL Server is ready"
}

run_folder() {
  folder="$1"
  db="$2"

  if [ "$folder" = "/db/User" ] && [ "$APPLY_USER_SCRIPTS" != "true" ]; then
    log "Skipping user scripts for local SQL login mode"
    return 0
  fi

  if [ ! -d "$folder" ]; then
    return 0
  fi

  for file in "$folder"/*.sql; do
    [ -e "$file" ] || continue

    name=$(basename "$file")
    rel=$(echo "$file" | sed 's|^/db/||')

    # Skip full database export script that enables TDE; local setup does not configure encryption keys.
    if [ "$rel" = "Database/healthplus.sql" ]; then
      log "Skipping local-incompatible script: $rel"
      continue
    fi

    # Skip files that rely on Azure AD external provider users.
    if grep -Eqi "CREATE[[:space:]]+USER[[:space:]].*FROM[[:space:]]+EXTERNAL[[:space:]]+PROVIDER" "$file"; then
      log "Skipping Azure AD user script: $rel"
      continue
    fi

    log "Applying [$db] $rel"
    if [ "$folder" = "/db/Index" ] || [ "$folder" = "/db/Constraint" ]; then
      # Local schema dumps may include drifted optional performance/integrity scripts; continue boot when these fail.
      "$SQLCMD_BIN" -C -S "${SERVER}" -U "${USER}" -P "${PASSWORD}" -d "$db" -i "$file" || log "Warning: failed script skipped: $rel"
    else
      "$SQLCMD_BIN" -C -S "${SERVER}" -U "${USER}" -P "${PASSWORD}" -d "$db" -b -i "$file"
    fi
  done
}

wait_for_sql

run_folder /db/Database master
run_folder /db/User healthplus
run_folder /db/Table healthplus
run_folder /db/View healthplus
# Prefer canonical plural folder; keep singular for backward compatibility.
run_folder /db/StoredProcedures healthplus
run_folder /db/StoredProcedure healthplus
run_folder /db/Index healthplus
run_folder /db/Constraint healthplus
run_folder /db/Other/NoFK healthplus

log "Database initialization completed successfully"
