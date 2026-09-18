# Lab 8 -- RDBMS Ingestion (replaces Apache Sqoop)

[ภาษาไทย](README.th.md) | **English**

Apache Sqoop is retired. The learning objective survives:

```text
Relational Database (MariaDB)
        |  JDBC
        v
Spark
        |
        v
HDFS / Hive / Parquet
```

## 1. Create the source data in MariaDB

Lab credentials: `student` / `student` (local sandbox only).

```bash
mysql -h localhost -u student -pstudent
```

```sql
CREATE DATABASE test_mysql_db;
USE test_mysql_db;

CREATE TABLE country_tbl (id INT NOT NULL, country VARCHAR(50), PRIMARY KEY (id));
INSERT INTO country_tbl VALUES (1, 'USA');
INSERT INTO country_tbl VALUES (2, 'CANADA');
INSERT INTO country_tbl VALUES (3, 'Mexico');
INSERT INTO country_tbl VALUES (4, 'Brazil');
INSERT INTO country_tbl VALUES (61, 'Japan');
INSERT INTO country_tbl VALUES (65, 'Singapore');
INSERT INTO country_tbl VALUES (66, 'Thailand');

SELECT * FROM country_tbl;
```

## 2. Read it with Spark, write it to HDFS

`jdbc_to_hdfs.py` (this folder) does the JDBC read + HDFS write. The
MariaDB JDBC driver is already in the image at `/opt/mariadb-java-client.jar`.

```bash
spark-submit --jars /opt/mariadb-java-client.jar \
    ~/labs/08-rdbms-ingestion/jdbc_to_hdfs.py \
    --db test_mysql_db --table country_tbl \
    --output hdfs:///user/student/ingest/country_tbl
```

```bash
hadoop fs -ls /user/student/ingest/country_tbl
```

## 3. Optional: also register as a Hive table

```bash
spark-submit --jars /opt/mariadb-java-client.jar \
    ~/labs/08-rdbms-ingestion/jdbc_to_hdfs.py \
    --db test_mysql_db --table country_tbl \
    --output hdfs:///user/student/ingest/country_tbl \
    --as-hive-table country
```

```bash
beeline -u jdbc:hive2://localhost:10000/default -e "SELECT * FROM country;"
```
