"""
Spark SQL lab: SparkSession + DataFrame + temp view, replacing the old
HiveContext(sc) style from the Cloudera-era course.

    spark-submit spark_sql_demo.py hdfs:///user/student/input/PG2600.txt
"""
import sys

from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split, lower, col

if __name__ == "__main__":
    input_path = sys.argv[1] if len(sys.argv) > 1 else "hdfs:///user/student/input/PG2600.txt"

    spark = (
        SparkSession.builder
        .appName("SparkSQLLab")
        .enableHiveSupport()  # talks to the shared Hive metastore; see labs/05-hive
        .getOrCreate()
    )

    lines = spark.read.text(input_path)
    words = lines.select(explode(split(lower(col("value")), r"\s+")).alias("word"))
    words = words.filter(col("word") != "")

    words.createOrReplaceTempView("words")

    top_words = spark.sql(
        "SELECT word, COUNT(*) AS n FROM words GROUP BY word ORDER BY n DESC LIMIT 20"
    )
    top_words.show()

    spark.stop()
