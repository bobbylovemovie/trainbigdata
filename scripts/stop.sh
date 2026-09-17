#!/bin/bash
# Stops the container without deleting any data. Convenience wrapper around
# `docker compose stop`.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose stop
