# Simple, student-facing readiness check for Windows PowerShell.
# Equivalent to scripts/student-check.sh. Run from the repo root:
#   .\scripts\student-check.ps1

Write-Host "Big Data Management Lab"
Write-Host ""
Write-Host "Checking environment..."
Write-Host ""

function Fail($title, [string[]]$lines) {
    Write-Host "[FAIL] $title"
    Write-Host ""
    foreach ($l in $lines) { Write-Host $l }
    Write-Host ""
    exit 1
}

# 1. Docker installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fail "Docker installed" @(
        "Docker is not installed.",
        "Install Docker Desktop: https://www.docker.com/products/docker-desktop/",
        "Then run this script again."
    )
}
Write-Host "[PASS] Docker installed"

# 2. Docker daemon running
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Fail "Docker daemon running" @(
        "Docker is installed but not running.",
        "Please start Docker Desktop and run:",
        "",
        "  .\scripts\student-check.ps1"
    )
}
Write-Host "[PASS] Docker daemon running"

# 3. Docker Compose available
docker compose version *> $null
if ($LASTEXITCODE -ne 0) {
    Fail "Docker Compose available" @(
        "Docker Compose (the 'docker compose' command) is not available.",
        "Update Docker Desktop to a recent version."
    )
}
Write-Host "[PASS] Docker Compose available"

# 4. Big Data image available
$img = (docker compose config --images 2>$null | Select-Object -First 1)
if (-not $img) { $img = "" }
docker image inspect $img *> $null
if (-not $img -or $LASTEXITCODE -ne 0) {
    Fail "Big Data image available" @(
        "The course image has not been downloaded yet.",
        "Please run:",
        "",
        "  docker compose pull",
        "",
        "then run this script again."
    )
}
Write-Host "[PASS] Big Data image available"

# 5. Container running
$running = docker compose ps --status running --services 2>$null
if (-not ($running -contains "bigdata")) {
    Fail "Big Data container running" @(
        "The lab container is not running.",
        "Please run:",
        "",
        "  docker compose up -d",
        "",
        "then run this script again."
    )
}
Write-Host "[PASS] Big Data container running"

function RunIn($cmd) {
    docker compose exec -T bigdata bash -c $cmd *> $null
    return ($LASTEXITCODE -eq 0)
}

if (-not (RunIn "hadoop version")) {
    Fail "Hadoop available" @(
        "The container is running but Hadoop isn't responding yet.",
        "It may still be starting up -- wait 30 seconds and try again.",
        "If this persists, run: docker compose restart"
    )
}
Write-Host "[PASS] Hadoop available"

if (-not (RunIn "for i in `$(seq 1 20); do hdfs dfsadmin -safemode get 2>/dev/null | grep -q OFF && exit 0; sleep 3; done; exit 1")) {
    Fail "HDFS available" @(
        "HDFS is still starting up (this can take a minute on first boot).",
        "Wait a bit and run this script again.",
        "If this persists, run: docker compose exec bigdata labctl status"
    )
}
Write-Host "[PASS] HDFS available"

if (-not (RunIn "yarn node -list -all")) {
    Fail "YARN available" @("YARN isn't responding.", "Run: docker compose exec bigdata labctl status")
}
Write-Host "[PASS] YARN available"

if (-not (RunIn "java -version")) {
    Fail "Java available" @("Something is wrong inside the container. Try: docker compose restart")
}
Write-Host "[PASS] Java available"

if (-not (RunIn "spark-submit --version")) {
    Fail "Spark available" @("Something is wrong inside the container. Try: docker compose restart")
}
Write-Host "[PASS] Spark available"

Write-Host ""
Write-Host "Environment READY"
Write-Host ""
Write-Host "You can start LAB 02 -- HDFS."
