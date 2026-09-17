# Lab 5 -- Hive

Start Hive first: `labctl start hive` (needs `core` and `mariadb` up,
which `labctl` handles for you).

The interactive `hive` CLI is deprecated upstream. This lab uses
HiveServer2 + Beeline instead.

```bash
beeline -u jdbc:hive2://localhost:10000/default
```

```sql
CREATE TABLE test_tbl (
    id INT,
    country STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

SHOW TABLES;
DESCRIBE test_tbl;
ALTER TABLE test_tbl ADD COLUMNS (remarks STRING);
DESCRIBE test_tbl;
DROP TABLE test_tbl;
```

## MovieLens: external table + partitions

```bash
mkdir -p ~/movielens_dataset && cd ~/movielens_dataset
unzip /course/datasets/ml-100k.zip
more ml-100k/u.user

hadoop fs -mkdir -p /user/student/movielens
hadoop fs -put ml-100k/u.user /user/student/movielens/

beeline -u jdbc:hive2://localhost:10000/default
```

```sql
CREATE EXTERNAL TABLE users (
    userid INT, age INT, gender STRING, occupation STRING, zipcode STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE
LOCATION '/user/student/movielens';

SELECT * FROM users LIMIT 10;

CREATE TABLE users_partition (
    userid INT, age INT, gender STRING, occupation STRING, zipcode STRING
)
PARTITIONED BY (year STRING);

INSERT INTO users_partition PARTITION (year='2019') SELECT * FROM users;
INSERT INTO users_partition PARTITION (year='2020') SELECT * FROM users;

SELECT * FROM users_partition WHERE year = '2020' LIMIT 10;
SHOW PARTITIONS users_partition;
```
