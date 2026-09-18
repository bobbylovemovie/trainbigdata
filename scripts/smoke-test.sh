#!/bin/bash
# Verifies the trainbigdata:2026 sandbox actually works end to end.
# Run from the host: ./scripts/smoke-test.sh
# (it re-execs itself inside the container over `docker compose exec`)
set -uo pipefail

if [ ! -f /.dockerenv ]; then
  cd "$(dirname "$0")/.."
  exec docker compose exec -T bigdata /usr/local/bin/smoke-test.sh
fi

# --- from here on we are inside the container ------------------------------

PASS=0
FAIL=0
FAILED_NAMES=()

check() {
  local name="$1"
  shift
  if "$@" >/tmp/smoke-test-last.log 2>&1; then
    echo "[PASS] $name"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $name"
    echo "       $(tail -n 3 /tmp/smoke-test-last.log | tr '\n' ' ')"
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("$name")
  fi
}

echo "=== trainbigdata:2026 smoke test ==="

check "Java"              bash -c 'java -version'
check "Hadoop command"    bash -c 'hadoop version'

check "HDFS NameNode"     bash -c '
  for i in $(seq 1 30); do
    hdfs dfsadmin -safemode get 2>/dev/null | grep -q OFF && exit 0
    sleep 3
  done
  exit 1
'

check "HDFS put/get" bash -c '
  set -e
  echo "smoke-test-hdfs-$$" > /tmp/smoke-in.txt
  hadoop fs -mkdir -p /tmp/smoketest
  hadoop fs -put -f /tmp/smoke-in.txt /tmp/smoketest/in.txt
  hadoop fs -cat /tmp/smoketest/in.txt | diff -q - /tmp/smoke-in.txt
'

check "YARN"              bash -c 'yarn node -list -all'

check "MapReduce WordCount" bash -c '
  set -e
  hadoop fs -rm -r -f /tmp/smoketest/mrout >/dev/null
  hadoop jar /course/labs/03-mapreduce/wordcount.jar WordCount \
      /tmp/smoketest/in.txt /tmp/smoketest/mrout
  hadoop fs -cat /tmp/smoketest/mrout/part-r-00000 | grep -q .
'

labctl start hbase >/dev/null 2>&1
cat >/tmp/smoke-hbase.rb <<'EOF'
if exists('smoketest_tbl')
  disable 'smoketest_tbl' rescue nil
  drop 'smoketest_tbl'
end
create 'smoketest_tbl', 'cf'
put 'smoketest_tbl', '1', 'cf:a', 'hello'
get 'smoketest_tbl', '1'
disable 'smoketest_tbl'
drop 'smoketest_tbl'
exit
EOF
check "HBase shell / table operation" bash -c '
  # On a cold start, HBase master init (procedure store replay, meta
  # assignment) competes with every other service starting at once and can
  # take a few minutes on a modest laptop -- see README "Resource usage".
  for i in $(seq 1 60); do
    hbase shell -n /tmp/smoke-hbase.rb 2>/dev/null | grep -q hello && exit 0
    sleep 5
  done
  exit 1
'

labctl start hive >/dev/null 2>&1
check "HiveServer2"       bash -c '
  for i in $(seq 1 40); do nc -z localhost 10000 && exit 0; sleep 3; done; exit 1
'
check "Beeline query"     bash -c '
  beeline -u jdbc:hive2://localhost:10000/default -e "SHOW DATABASES;" 2>/dev/null | grep -qi default
'

labctl start kafka >/dev/null 2>&1
check "Kafka broker"      bash -c '
  export JAVA_HOME=/usr/lib/jvm/default-java11
  for i in $(seq 1 30); do nc -z localhost 9092 && exit 0; sleep 3; done; exit 1
'
check "Kafka produce/consume" bash -c '
  set -e
  export JAVA_HOME=/usr/lib/jvm/default-java11
  kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic smoketest-topic >/dev/null 2>&1 || true
  kafka-topics.sh --bootstrap-server localhost:9092 --create --topic smoketest-topic --partitions 1 --replication-factor 1 >/dev/null
  echo "hello-kafka" | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic smoketest-topic >/dev/null
  timeout 15 kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic smoketest-topic --from-beginning --max-messages 1 2>/dev/null | grep -q hello-kafka
  kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic smoketest-topic >/dev/null 2>&1 || true
'

check "Spark"              bash -c 'spark-submit --version'
check "PySpark"            bash -c '
  cat > /tmp/smoke-pyspark.py <<PYEOF
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("smoke-pyspark").getOrCreate()
print(spark.range(10).count())
spark.stop()
PYEOF
  spark-submit /tmp/smoke-pyspark.py 2>/dev/null | grep -q "^10$"
'
check "Spark reading HDFS" bash -c '
  spark-submit /course/labs/09-pyspark/wordcount.py hdfs:///tmp/smoketest/in.txt 2>/dev/null | grep -q .
'

check "MariaDB"            bash -c 'mysqladmin ping --silent'

check "JDBC database -> Spark" bash -c '
  set -e
  mysql -u student -pstudent -e "
    CREATE DATABASE IF NOT EXISTS smoketest_db;
    CREATE TABLE IF NOT EXISTS smoketest_db.smoketest_tbl (id INT, country VARCHAR(50));
    DELETE FROM smoketest_db.smoketest_tbl;
    INSERT INTO smoketest_db.smoketest_tbl VALUES (1, \"Testland\");
  "
  hadoop fs -rm -r -f /tmp/smoketest/jdbcout >/dev/null
  spark-submit --jars /opt/mariadb-java-client.jar /course/labs/08-rdbms-ingestion/jdbc_to_hdfs.py \
      --db smoketest_db --table smoketest_tbl --output hdfs:///tmp/smoketest/jdbcout
  hadoop fs -ls /tmp/smoketest/jdbcout | grep -q parquet
'

check "JupyterLab"         bash -c 'curl -sf -o /dev/null http://localhost:8888/'

hadoop fs -rm -r -f /tmp/smoketest >/dev/null 2>&1
mysql -u student -pstudent -e "DROP DATABASE IF EXISTS smoketest_db;" >/dev/null 2>&1

echo "=================================="
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo "Failed: ${FAILED_NAMES[*]}"
  exit 1
fi
exit 0
