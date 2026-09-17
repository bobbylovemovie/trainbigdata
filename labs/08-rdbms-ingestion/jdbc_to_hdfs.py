"""
RDBMS -> Big Data ingestion, replacing the retired Apache Sqoop lab.

Old flow:   sqoop import --connect jdbc:mysql://... --table country_tbl ...
New flow:   MariaDB --JDBC--> Spark --> HDFS / Parquet (optionally Hive)

Usage:
    spark-submit --jars /opt/mariadb-java-client.jar jdbc_to_hdfs.py \
        --db test_mysql_db --table country_tbl \
        --output hdfs:///user/student/ingest/country_tbl
"""
import argparse

from pyspark.sql import SparkSession

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--db", required=True)
    parser.add_argument("--table", required=True)
    parser.add_argument("--user", default="student")
    parser.add_argument("--password", default="student")
    parser.add_argument("--output", required=True, help="HDFS path to write Parquet output")
    parser.add_argument("--as-hive-table", default=None, help="Optional: also register as this Hive table name")
    args = parser.parse_args()

    spark = (
        SparkSession.builder
        .appName("RDBMS-to-HDFS")
        .enableHiveSupport()
        .getOrCreate()
    )

    # Deliberately jdbc:mysql (not jdbc:mariadb): Spark only recognizes its
    # built-in MySQLDialect -- correct identifier quoting (backticks, not
    # ANSI double quotes) -- for URLs starting with "jdbc:mysql". MariaDB
    # Connector/J 3.x requires permitMysqlScheme to accept that prefix.
    jdbc_url = f"jdbc:mysql://{args.host}:3306/{args.db}?permitMysqlScheme"
    df = (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("dbtable", args.table)
        .option("user", args.user)
        .option("password", args.password)
        .option("driver", "org.mariadb.jdbc.Driver")
        .load()
    )

    df.show()
    df.write.mode("overwrite").parquet(args.output)
    print(f"Wrote {df.count()} rows to {args.output}")

    if args.as_hive_table:
        df.write.mode("overwrite").saveAsTable(args.as_hive_table)
        print(f"Registered Hive table: {args.as_hive_table}")

    spark.stop()
