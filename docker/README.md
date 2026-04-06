# HM Workspace Docker Guide

## Overview

This folder contains Docker Compose configuration for running the local Hospital Management stack.

## Prerequisites

- Docker Desktop running
- Ports available on host machine

## Start

From this folder:

```powershell
docker compose --env-file .env -f docker-compose.yml up -d
```

## Stop

From this folder:

```powershell
docker compose --env-file .env -f docker-compose.yml down
```

## SQL Server Connection

Use these values from host tools such as SSMS:

- Server: `localhost,11433`
- Username: `sa`
- Password: value from `.env` (`SA_PASSWORD`)
- Trust server certificate: enabled

## Troubleshooting: SQL Login Failed on localhost,1433

Symptom:

- SSMS shows login failure for `sa` even though container checks pass.

Cause:

- Host machine may already have a local SQL Server instance using port `1433`.
- SSMS can connect to the host SQL instance instead of the Docker SQL instance.

Resolution:

1. Use a non-conflicting host port in `.env`:
   - `SQLSERVER_PORT=11433`
2. Restart the stack so the new mapping is applied:

```powershell
docker compose --env-file .env -f docker-compose.yml down
docker compose --env-file .env -f docker-compose.yml up -d
```

3. Connect from SSMS using `localhost,11433`.

## Verify SQL Server Container Endpoint

```powershell
docker compose --env-file .env -f docker-compose.yml ps
docker exec hm-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "<SA_PASSWORD>" -C -Q "SELECT 1"
```

If the sqlcmd test succeeds but SSMS fails, re-check SSMS server name and ensure it is not using cached `localhost,1433` settings.
