$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$dockerDir = Join-Path $repoRoot "docker"
$composeFile = Join-Path $dockerDir "docker-compose.yml"
$envFile = Join-Path $dockerDir ".env"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI not found. Install Docker Desktop and ensure docker is on PATH."
}

if (-not (Test-Path $envFile)) {
    $envFile = Join-Path $dockerDir ".env.example"
}

Push-Location $dockerDir
try {
    docker compose --env-file $envFile -f $composeFile ps
}
finally {
    Pop-Location
}
