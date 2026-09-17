"""
spark-submit version of the PySpark WordCount lab. Run interactively in
pyspark for the learning exercise (see README.md in this folder); this
script exists so the same logic can be run non-interactively:

    spark-submit wordcount.py hdfs:///user/student/input/PG2600.txt
"""
import sys
from operator import add

from pyspark.sql import SparkSession

if __name__ == "__main__":
    input_path = sys.argv[1] if len(sys.argv) > 1 else "hdfs:///user/student/input/PG2600.txt"

    spark = SparkSession.builder.appName("WordCount").getOrCreate()
    sc = spark.sparkContext

    file = sc.textFile(input_path)
    wc = (
        file.flatMap(lambda x: x.split())
            .map(lambda x: (x, 1))
            .reduceByKey(add)
    )

    for word, count in wc.take(20):
        print(f"{word}\t{count}")

    spark.stop()
