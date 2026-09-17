#!/bin/bash
# Convenience wrapper. The canonical command is `docker compose up -d`;
# this just saves typing.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose up -d
echo
echo "Container starting. Check readiness with:"
echo "  ./scripts/student-check.sh"
