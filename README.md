# HM Workspace

Central workspace structure for Health Management repositories.

## Layout

```text
hm-workspace/
  services/
    hm-api-gateway
    hm-auth-service
    hm-patient-service
    hm-doctor-service
    hm-appointment-service
    hm-medical-records-service
    hm-department-service
    hm-staff-service
    hm-notification-service
  ui/
    customer-portal
    admin-portal
  platform/
    terraform-infra
  scripts/
    clone-all.sh
    start-local.sh
    build-all.sh
  repos.json
  docker/
    docker-compose.yml
```

## GitHub Repositories

Owner: `hm-workspace`

### Services

- `https://github.com/hm-workspace/hm-api-gateway`
- `https://github.com/hm-workspace/hm-auth-service`
- `https://github.com/hm-workspace/hm-patient-service`
- `https://github.com/hm-workspace/hm-doctor-service`
- `https://github.com/hm-workspace/hm-appointment-service`
- `https://github.com/hm-workspace/hm-medical-records-service`
- `https://github.com/hm-workspace/hm-department-service`
- `https://github.com/hm-workspace/hm-staff-service`
- `https://github.com/hm-workspace/hm-notification-service`

### UI

- `https://github.com/hm-workspace/customer-portal`
- `https://github.com/hm-workspace/admin-portal`

### Platform

- `https://github.com/hm-workspace/terraform-infra`

## Quick Start

Run from Git Bash / WSL on Windows.

### Clone all repos

```bash
cd hm-workspace/scripts
./clone-all.sh "C:/work/hm-workspace"
```

Defaults:
- `GITHUB_OWNER=hm-workspace`
- `GIT_PROTOCOL=https`
- `REPOS_MANIFEST=../repos.json`

`clone-all.sh` reads repo definitions from `repos.json`.

Optional overrides:

```bash
GITHUB_OWNER=hm-workspace GIT_PROTOCOL=ssh ./clone-all.sh "$HOME/hm-workspace"
```

### Build all service repos

```bash
cd hm-workspace/scripts
./build-all.sh
```

`build-all.sh` reads service repos from `repos.json` (`group: services`).

### Start local docker stack

```bash
cd hm-workspace/scripts
./start-local.sh
```

## Notes

- Every repo has `.vscode/mcp.json` configured.
- Current GitHub visibility is `public`; you can switch to `private` later from repository settings.
- Scripts require `jq` to parse `repos.json`.
