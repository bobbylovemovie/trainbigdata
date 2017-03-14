## LAB 2 Hadoop File System (HDFS)
```
$ mkdir guest1 
$ cd guest1 
$ wget https://github.com/bobbylovemovie/trainbigdata/raw/master/HDFS/PG2600.txt
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
$ wget https://github.com/bobbylovemovie/trainbigdata/raw/master/HDFS/wordcount.jar
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
```

## LAB 5 HIVE
```
$ hive
hive> CREATE TABLE TEST_TBL(ID INT,COUNTRY STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE ;
hive> SHOW TABLES;
hive> describe test_tbl;
hive > alter table test_tbl add columns (remarks STRING);
hive > describe test_tbl;
hive > drop table test_tbl;
hive > quit;
```
### Load Data From MovieLens To Hive 
```
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
hive> create external table users (userid int,age int,gender string,occupation string ,zipcode string) row format delimited fields terminated by '|' stored as textfile location '/user/cloudera/movielens' ;
hive > select * from users;

```





