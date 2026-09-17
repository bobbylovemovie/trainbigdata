"""
Structured Streaming word count -- modern replacement for the old DStream
example (kept for reference at legacy/Spark/StreamingWordCount_dstream.py).

Terminal 1:
    nc -lk 9999
Terminal 2:
    spark-submit streaming_wordcount.py
Then type words into terminal 1 and watch counts update in terminal 2.
"""
from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split, col

if __name__ == "__main__":
    spark = SparkSession.builder.appName("StructuredStreamingWordCount").getOrCreate()
    spark.sparkContext.setLogLevel("WARN")

    lines = (
        spark.readStream
        .format("socket")
        .option("host", "localhost")
        .option("port", 9999)
        .load()
    )

    words = lines.select(explode(split(col("value"), r"\s+")).alias("word"))
    words = words.filter(col("word") != "")
    counts = words.groupBy("word").count()

    query = (
        counts.writeStream
        .outputMode("complete")
        .format("console")
        .start()
    )

    query.awaitTermination()
