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
  cp -r /course/labs /home/student/labs
  chown -R student:student /home/student/labs
fi

if [ ! -d /opt/hadoop/data/nn/current ]; then
  echo "[entrypoint] formatting HDFS namenode (first run, or volume was reset)"
  su student -c "/opt/hadoop/bin/hdfs namenode -format -force -nonInteractive"
fi

if [ ! -f /opt/hadoop/data/kafka-logs/meta.properties ]; then
  echo "[entrypoint] formatting Kafka KRaft storage (first run, or volume was reset)"
  KAFKA_CLUSTER_ID=$(su student -c "JAVA_HOME=$JAVA11_HOME /opt/kafka/bin/kafka-storage.sh random-uuid")
  su student -c "JAVA_HOME=$JAVA11_HOME /opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server.properties"
fi

exec "$@"
