# Lab 5 -- Hive

[ภาษาไทย](README.th.md) | **English**

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
```

Don't drop it yet -- the next section uses this table to prove something
important about how Hive actually works.

## Hive isn't a real database -- it's folders on HDFS

The most common misconception starting out with Hive: **it has no storage
engine of its own** like MySQL/PostgreSQL do. What it actually does is
translate SQL into ordinary **folders and files** on HDFS --
`CREATE TABLE` creates a folder, `INSERT` writes a raw data file inside
it. (MariaDB, running underneath as the Hive Metastore, only stores
*schema metadata* -- column names and types -- never the actual data.)

Quit Beeline (`!quit`), back at bash, see it for yourself:

```bash
hadoop fs -ls /user/hive/warehouse
```

A folder named `test_tbl` is there -- **the same name as the table you
just created**, because it's the same thing.

Reconnect and insert a row:

```bash
beeline -u jdbc:hive2://localhost:10000/default
```

```sql
INSERT INTO test_tbl (id, country) VALUES (1, 'Thailand');
```

`!quit` again, then look inside the table's folder:

```bash
hadoop fs -ls /user/hive/warehouse/test_tbl
```

A new file appears (something like `000000_0`) -- **a plain text file**.
Read it directly, no Hive/SQL involved at all:

```bash
hadoop fs -cat /user/hive/warehouse/test_tbl/000000_0
```

You'll see `1,Thailand` -- the row you just inserted, stored as plain CSV
(matching `FIELDS TERMINATED BY ','` from the `CREATE TABLE`). **Direct
proof that Hive's `INSERT INTO` doesn't send SQL to a database somewhere
-- it just writes a text file to HDFS.**

### Or look at it in the browser (better for showing a whole class at once)

Open http://localhost:9870 -> **Utilities -> Browse the file system** ->
type in the path `/user/hive/warehouse` and hit enter. The folder list
*is* the table list. Click into any folder to see the same data files
`hadoop fs -ls` shows.

Drop the test table when you're done looking:

```sql
DROP TABLE test_tbl;
```

Then `hadoop fs -ls /user/hive/warehouse` again -- the `test_tbl` folder
is gone too (this was a managed table, not `EXTERNAL`, so Hive owns the
data and deletes the whole folder on `DROP TABLE`). Contrast this with the
next section's `EXTERNAL TABLE`, where `DROP TABLE` will **not** delete
the underlying files -- an external table only points at a folder, it
doesn't own it.

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
