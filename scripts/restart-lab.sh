#!/bin/bash
# Soft reset: restarts the container without deleting any data (HDFS,
# databases, your files under ~ all survive). Use this first if something
# in the lab seems stuck. For a full wipe, use ./scripts/reset-lab.sh instead.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose restart
echo
echo "Restarted. Check readiness with:"
echo "  ./scripts/student-check.sh"
