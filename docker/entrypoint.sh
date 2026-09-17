#!/bin/bash
# One-time, idempotent setup that must run before supervisord starts any daemon.
set -euo pipefail

chown -R student:student /opt/hadoop/data /home/student

# /run is tmpfs and not persisted -- mariadb's socket directory must be
# recreated on every container start (normally done by systemd/init scripts,
# which we don't run here).
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d /home/student/labs ]; then
  echo "[entrypoint] seeding ~/labs from the image (first run for this student-home volume)"
  cp -r /opt/labs /home/student/labs
  chown -R student:student /home/student/labs
fi

if [ ! -d /opt/hadoop/data/nn/current ]; then
  echo "[entrypoint] formatting HDFS namenode (first run, or volume was reset)"
  su student -c "/opt/hadoop/bin/hdfs namenode -format -force -nonInteractive"
fi

exec "$@"
