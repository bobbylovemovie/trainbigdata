#!/bin/bash
# One-shot supervisor program: waits for HDFS + MariaDB, then provisions the
# infrastructure students rely on (not the lab exercises themselves):
#   - HDFS /tmp, /user/hive/warehouse, /user/student
#   - the Hive metastore database + schema
#   - a MariaDB account students use for the ingestion lab (labs/08)
set -uo pipefail

log() { echo "[bootstrap] $*"; }

log "waiting for HDFS namenode..."
until su student -c "/opt/hadoop/bin/hdfs dfsadmin -safemode get" 2>/dev/null | grep -q OFF; do
  sleep 3
done
log "HDFS is up"

su student -c "/opt/hadoop/bin/hdfs dfs -mkdir -p /tmp /user/hive/warehouse /user/student"
su student -c "/opt/hadoop/bin/hdfs dfs -chmod 1777 /tmp /user/hive/warehouse"

log "waiting for MariaDB..."
until mysqladmin ping --silent 2>/dev/null; do
  sleep 2
done
log "MariaDB is up"

mysql -u root <<'SQL'
CREATE DATABASE IF NOT EXISTS metastore;
CREATE USER IF NOT EXISTS 'hive'@'localhost' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'localhost';

-- Educational lab credential, local sandbox only. See README "Security".
CREATE USER IF NOT EXISTS 'student'@'%' IDENTIFIED BY 'student';
GRANT ALL PRIVILEGES ON *.* TO 'student'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

MARKER=/var/lib/mysql/.hive_schema_done
if [ ! -f "$MARKER" ]; then
  log "initializing Hive metastore schema"
  su student -c "/opt/hive/bin/schematool -dbType mysql -initSchema" && touch "$MARKER"
else
  log "Hive metastore schema already initialized"
fi

log "bootstrap complete"
