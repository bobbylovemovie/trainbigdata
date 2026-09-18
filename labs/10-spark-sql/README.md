# Lab 10 -- Spark SQL

[ภาษาไทย](README.th.md) | **English**

This lab uses `SparkSession` + DataFrame + a temp view -- the current,
supported way to do Spark SQL.

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("BigDataLab") \
    .enableHiveSupport() \
    .getOrCreate()

lines = spark.read.text("hdfs:///user/student/input/PG2600.txt")
lines.createOrReplaceTempView("lines")

spark.sql("SELECT * FROM lines LIMIT 10").show()
```

Run the full demo (tokenizes the text and counts top words with Spark SQL):

```bash
spark-submit ~/labs/10-spark-sql/spark_sql_demo.py hdfs:///user/student/input/PG2600.txt
```

## Hive integration

`enableHiveSupport()` above points Spark at the same Hive metastore used by
labs/05 and labs/08 (see `hive.metastore.uris` in `hive-site.xml`), so tables
created in Beeline are visible from Spark SQL and vice versa:

```python
spark.sql("SHOW TABLES").show()
spark.sql("SELECT * FROM users LIMIT 10").show()  # from labs/05, if you ran it
```
