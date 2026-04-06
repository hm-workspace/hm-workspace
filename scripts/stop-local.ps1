param(
    [switch]$PurgeData
)

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
    $args = @("compose", "--env-file", $envFile, "-f", $composeFile, "down")
    if ($PurgeData) {
        $args += "-v"
    }
    docker @args
    if ($PurgeData) {
        Write-Host "Local stack stopped and volumes removed." -ForegroundColor Green
    }
    else {
        Write-Host "Local stack stopped." -ForegroundColor Green
    }
}
finally {
    Pop-Location
}
