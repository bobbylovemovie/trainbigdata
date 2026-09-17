#!/bin/bash
# Simple, student-facing readiness check. Not the deep developer test
# (that's scripts/smoke-test.sh) -- this just answers "am I ready for lab?"
# with a short, friendly report. Run from the repo root:
#   ./scripts/student-check.sh
set -uo pipefail
cd "$(dirname "$0")/.."

echo "Big Data Management Lab"
echo
echo "Checking environment..."
echo

fail() {
  echo "[FAIL] $1"
  echo
  shift
  for line in "$@"; do echo "$line"; done
  echo
  exit 1
}

# 1. Docker installed
if ! command -v docker >/dev/null 2>&1; then
  fail "Docker installed" \
    "Docker is not installed." \
    "Install Docker Desktop: https://www.docker.com/products/docker-desktop/" \
    "Then run this script again."
fi
echo "[PASS] Docker installed"

# 2. Docker daemon running
if ! docker info >/dev/null 2>&1; then
  fail "Docker daemon running" \
    "Docker is installed but not running." \
    "Please start Docker Desktop and run:" \
    "" \
    "  ./scripts/student-check.sh"
fi
echo "[PASS] Docker daemon running"

# 3. Docker Compose available
if ! docker compose version >/dev/null 2>&1; then
  fail "Docker Compose available" \
    "Docker Compose (the 'docker compose' command) is not available." \
    "Update Docker Desktop to a recent version, or install the Compose plugin."
fi
echo "[PASS] Docker Compose available"

# 4. Big Data image available
IMG=$(docker compose config --images 2>/dev/null | head -1)
if [ -z "$IMG" ] || ! docker image inspect "$IMG" >/dev/null 2>&1; then
  fail "Big Data image available" \
    "The course image has not been downloaded yet." \
    "Please run:" \
    "" \
    "  docker compose pull" \
    "" \
    "then run this script again."
fi
echo "[PASS] Big Data image available"

# 5. Container running
if ! docker compose ps --status running --services 2>/dev/null | grep -qx bigdata; then
  fail "Big Data container running" \
    "The lab container is not running." \
    "Please run:" \
    "" \
    "  docker compose up -d" \
    "" \
    "then run this script again."
fi
echo "[PASS] Big Data container running"

run_in() { docker compose exec -T bigdata bash -c "$1" >/dev/null 2>&1; }

if ! run_in "hadoop version"; then
  fail "Hadoop available" \
    "The container is running but Hadoop isn't responding yet." \
    "It may still be starting up -- wait 30 seconds and try again." \
    "If this persists, run: docker compose restart"
fi
echo "[PASS] Hadoop available"

if ! run_in "for i in \$(seq 1 20); do hdfs dfsadmin -safemode get 2>/dev/null | grep -q OFF && exit 0; sleep 3; done; exit 1"; then
  fail "HDFS available" \
    "HDFS is still starting up (this can take a minute on first boot)." \
    "Wait a bit and run this script again." \
    "If this persists, run: docker compose exec bigdata labctl status"
fi
echo "[PASS] HDFS available"

if ! run_in "yarn node -list -all"; then
  fail "YARN available" \
    "YARN isn't responding." \
    "Run: docker compose exec bigdata labctl status"
fi
echo "[PASS] YARN available"

if ! run_in "java -version"; then
  fail "Java available" "Something is wrong inside the container. Try: docker compose restart"
fi
echo "[PASS] Java available"

if ! run_in "spark-submit --version"; then
  fail "Spark available" "Something is wrong inside the container. Try: docker compose restart"
fi
echo "[PASS] Spark available"

echo
echo "Environment READY"
echo
echo "You can start LAB 02 -- HDFS."
