### trainbigdata
Data Source Training Big Data

## LAB 2 Hadoop File System (HDFS)
```
$ mkdir guest1 
$ cd guest1 
$ wget http://s3-ap-southeast-1.amazonaws.com/bobbylovemovie/TrainBigdata/PG2600.txt
$ hadoop fs -mkdir /user/cloudera/input
$ hadoop fs -ls /user/cloudera/input
$ hadoop fs -rm /user/cloudera/input/*
$ hadoop fs -put PG2600.txt /user/cloudera/input/
$ hadoop fs -ls /user/cloudera/input
Open Web Browser : http://quickstart.cloudera:8888
```

## LAB 3 MapReduce
```
$ cd guest1 
$ wget http://s3-ap-southeast-1.amazonaws.com/bobbylovemovie/TrainBigdata/wordcount.jar
$ hadoop jar wordcount.jar org.myorg.WordCount /user/cloudera/input/* /user/cloudera/output/wordcount
```

## LAB 4 HBASE
```
$ hbase shell
  hbase(main):001:0> create 'employee', 'personal data', 'professional data'
  hbase(main):002:0> list
  hbase(main):003:0> put 'employee','1','personal data:name','raju'
  hbase(main):005:0> put 'employee','1','personal data:city','hyderabad'
  hbase(main):006:0> put 'employee','1','professional data:designation','manager'
  hbase(main):007:0> put 'employee','1','professional data:salary','5000'
  
  hbase(main):025:0> put 'employee','2','personal data:name','bobby'
  hbase(main):026:0> exit
```

## LAB 5 HIVE
```
$ hive
hive > CREATE TABLE TEST_TBL(ID INT,COUNTRY STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE ;
hive > SHOW TABLES;
hive > describe test_tbl;
hive > alter table test_tbl add columns (remarks STRING);
hive > describe test_tbl;
hive > drop table test_tbl;
hive > quit;
```
### Load Data From MovieLens To Hive 
```
$ cd \

$ mkdir movielens_dataset
$ cd movielens_dataset
$ wget http://files.grouplens.org/datasets/movielens/ml-100k.zip
$ unzip ml-100k.zip
$ more ml-100k/u.user

$ cd ml-100k
$ hadoop fs -mkdir /user/cloudera/movielens
$ hadoop fs -put u.user /user/cloudera/movielens
$ hadoop fs -ls /user/cloudera/movielens
$ hive
hive > create external table users (userid int,age int,gender string,occupation string ,zipcode string) row format delimited      fields terminated by '|' stored as textfile location '/user/cloudera/movielens' ;
hive > select * from users;
hive > quit;

```
## LAB 6 IMPALA
```
$ impala-shell
[quickstart.cloudera:21000] > invalidate metadata;
[quickstart.cloudera:21000] > select * from users;
[quickstart.cloudera:21000] > exit;

```
## LAB 7 APACHE FLUME
```

$ cd /etc/flume-ng/conf/
$ sudo rm flume.conf
$ sudo wget http://s3-ap-southeast-1.amazonaws.com/bobbylovemovie/TrainBigdata/flume.conf
$ cat flume.conf

** start flume-service **
$ sudo service flume-ng-agent restart

** start flume Agent **
$ sudo flume-ng agent --conf /etc/flume-ng/conf/ --conf-file /etc/flume-ng/conf/flume.conf --name agent -Dflume.root.logger=INFO,console

** Open New Terminal **
*****install from rpm file
$ wget http://s3-ap-southeast-1.amazonaws.com/bobbylovemovie/TrainBigdata/telnet-0.17-48.el6.x86_64.rpm
$ sudo rpm -Uvh telnet-0.17-48.el6.x86_64.rpm

$ telnet localhost 3030

```
## LAB 8 APACHE SQOOP
```
** Configuring MySQL On Cloudera.Quickstart **
$ sudo /usr/bin/mysql_secure_installation
  ********************************************************
  Enter current password for root (enter for none): cloudera
  OK, successfully used password, moving on...
  Set root password? [Y/n] N
  Remove anonymous users? [Y/n] Y
  Disallow root login remotely? [Y/n] N
  Remove test database and access to it [Y/n] Y
  Reload privilege tables now? [Y/n] Y
  All done!
  
** Running MySQL **
$ mysql -uroot -p"cloudera"
mysql> show databases;
mysql> CREATE DATABASE test_mysql_db;
mysql> USE test_mysql_db;
mysql> CREATE TABLE country_tbl(id INT NOT NULL, country VARCHAR(50), PRIMARY KEY (id));
mysql> INSERT INTO country_tbl VALUES(1, 'USA');
mysql> INSERT INTO country_tbl VALUES(2, 'CANADA');
mysql> INSERT INTO country_tbl VALUES(3, 'Mexico');
mysql> INSERT INTO country_tbl VALUES(4, 'Brazil');
mysql> INSERT INTO country_tbl VALUES(61, 'Japan');
mysql> INSERT INTO country_tbl VALUES(65, 'Singapore');
mysql> INSERT INTO country_tbl VALUES(66, 'Thailand');
mysql> SELECT * FROM country_tbl;
mysql> exit;

** Importing data from MySQL to HDFS **
$ sqoop import --connect jdbc:mysql://localhost/test_mysql_db --username root --password cloudera --table country_tbl --target-dir /user/cloudera/test_table -m 1

** Importing data from MySQL to HIVE **
$ sqoop import --connect jdbc:mysql://localhost/test_mysql_db --username root --password cloudera --table country_tbl --hive-import --hive-table country -m 1
** Reviewing data from Hive Table **
$ hive
hive> show tables;
hive> select * from country;
hive> quit;

** Importing data from MySQL to HBase **
$ sqoop import --connect jdbc:mysql://localhost/test_mysql_db --username root --password cloudera --table country_tbl --hbase-table country --column-family hbase_country_cf --hbase-row-key id --hbase-create-table -m 1
** Reviewing data from Hive Table **
$ hbase shell
hbase(main):001:0> list
hbase(main):002:0> scan 'country'
hbase(main):003:0> exit

```
## LAB 9 SPARK
```
** Start Spark-shell **
$ spark-shell
scala> sc
scala> val file = sc.textFile("hdfs:///user/cloudera/input/PG2600.txt")
scala> val wc = file.flatMap(l => l.split(" ")).map(word =>(word,1)).reduceByKey(_ + _)
scala> wc.saveAsTextFile("hdfs:///user/cloudera/output/wordcountScala")
scala> exit;

** Spark Program in Python: WordCount **
$ pyspark
  >>> from operator import add
  >>> file =sc.textFile("hdfs:///user/cloudera/input/PG2600.txt")
  >>> wc = file.flatMap(lambda x: x.split(' ')).map(lambda x:(x,1)).reduceByKey(add)
  >>> wc.saveAsTextFile("hdfs:///user/cloudera/output/wordcountPython")
  >>> exit()
  
** Loading data from MySQL **
$ cd \
$ mkdir spark
$ cd spark
$ wget http://s3-ap-southeast-1.amazonaws.com/bobbylovemovie/TrainBigdata/mysql-connector-java-5.1.23.jar

$ spark-shell --jars mysql-connector-java-5.1.23.jar
$ scala> :paste
val url="jdbc:mysql://localhost:3306/test_mysql_db"
val username = "root"
val password = "cloudera"
import org.apache.spark.rdd.JdbcRDD
import java.sql.{Connection, DriverManager, ResultSet}
Class.forName("com.mysql.jdbc.Driver").newInstance
val myRDD = new JdbcRDD( sc, () =>
DriverManager.getConnection(url,username,password) ,
"SELECT * FROM country_tbl LIMIT ?, ?", 0, 5, 2, r =>r.getString("id") + ", " +
r.getString("country"))
myRDD.count
myRDD.foreach(println)

scala> myRDD.saveAsTextFile("hdfs:///user/cloudera/output/mysqlFromSpark")
scala> exit;
```

## LAB 10 Spark SQL
```
** Link Hive Metastore with Spark-Shell **
$ spark-shell --jars mysql-connector-java-5.1.23.jar
scala > val sqlContext = new org.apache.spark.sql.hive.HiveContext(sc)
scala > sqlContext.sql("CREATE TABLE IF NOT EXISTS movie(userid STRING, movieid STRING, rating INT, timestamp STRING)  ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n'")
scala > sqlContext.sql("LOAD DATA LOCAL INPATH '/home/cloudera/movielens_dataset/ml-100k/u.data' INTO TABLE movie")
scala > val result = sqlContext.sql("SELECT * FROM movie")
scala > result.show()
scala > exit;

$ sudo cp /usr/lib/hive/conf/hive-site.xml /usr/lib/spark/conf/
$ spark-shell
scala > val sqlContext = new org.apache.spark.sql.hive.HiveContext(sc)
scala > sqlContext.sql("CREATE TABLE IF NOT EXISTS movie(userid STRING, movieid STRING, rating INT, timestamp STRING)    ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n'")
scala > sqlContext.sql("LOAD DATA LOCAL INPATH '/home/cloudera/movielens_dataset/ml-100k/u.data' INTO TABLE movie")
scala > val result = sqlContext.sql("SELECT * FROM movie")
scala > result.show()
scala > exit;

```

## LAB 11 Spark Streaming
```
$ cd spark
$ wget http://s3-ap-southeast-1.amazonaws.com/bobbylovemovie/TrainBigdata/StreamingWordCount.py

** Run Python Spark **
$ spark-submit StreamingWordCount.py

** Running the netcat server on another window
$ nc -lk 9999
```
