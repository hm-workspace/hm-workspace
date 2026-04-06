param(
    [switch]$Build
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$dockerDir = Join-Path $repoRoot "docker"
$composeFile = Join-Path $dockerDir "docker-compose.yml"
$envFile = Join-Path $dockerDir ".env"
$envExample = Join-Path $dockerDir ".env.example"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker CLI not found. Install Docker Desktop and ensure docker is on PATH."
}

try {
    docker info | Out-Null
}
catch {
    throw "Docker engine is not running. Start Docker Desktop and retry."
}

if (-not (Test-Path $envFile)) {
    if (-not (Test-Path $envExample)) {
        throw "Missing .env and .env.example in $dockerDir"
    }
    Copy-Item $envExample $envFile
    Write-Host "Created $envFile from template." -ForegroundColor Yellow
}

Push-Location $dockerDir
try {
    $args = @("compose", "--env-file", ".env", "-f", $composeFile, "up", "-d")
    if ($Build) {
        $args += "--build"
    }
    docker @args

    if ($LASTEXITCODE -ne 0) {
        Write-Host "\nDocker compose failed. Showing db-init logs for quick diagnosis:" -ForegroundColor Red
        docker compose --env-file .env -f $composeFile logs db-init --tail 200
        throw "Local stack startup failed. Review logs above."
    }

    Write-Host "\nLocal stack started." -ForegroundColor Green
    Write-Host "Gateway URL: http://localhost:5000" -ForegroundColor Cyan
}
finally {
    Pop-Location
}
