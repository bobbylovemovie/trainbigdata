# Lab 9 -- Spark / PySpark

```bash
pyspark
```

```python
from operator import add

file = sc.textFile("hdfs:///user/student/input/PG2600.txt")

wc = (
    file.flatMap(lambda x: x.split())
        .map(lambda x: (x, 1))
        .reduceByKey(add)
)

wc.take(20)
```

Non-interactive (`spark-submit`) version of the same exercise:

```bash
spark-submit ~/labs/09-pyspark/wordcount.py hdfs:///user/student/input/PG2600.txt
```

Scala, if wanted:

```bash
spark-shell
```

```scala
val file = sc.textFile("hdfs:///user/student/input/PG2600.txt")
val wc = file.flatMap(_.split(" ")).map((_, 1)).reduceByKey(_ + _)
wc.take(20).foreach(println)
```
