#!/bin/bash
# Wipes all lab state (HDFS, HBase, Hive, MariaDB, student home) and starts
# a clean container. Run from the repo root.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "This will DELETE all student work, HDFS data, and databases in this lab."
read -rp "Type 'reset' to continue: " confirm
[ "$confirm" = "reset" ] || { echo "Aborted."; exit 1; }

docker compose down -v
docker compose up -d
echo "Lab reset. Run: docker compose exec bigdata bash"
