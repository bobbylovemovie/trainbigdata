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
```

## LAB 4 HBASE
```
$ hbase shell
  hbase(main):001:0> create 'employee', 'personal data', 'professionaldata'
  hbase(main):002:0> list
  hbase(main):003:0> put 'employee','1','personal data:name','raju'
  hbase(main):005:0> put 'employee','1','personal data:city','hyderabad'
  hbase(main):006:0> put 'employee','1','professional data:designation','manager'
  hbase(main):007:0> put 'employee','1','professional data:salary','5000'
  
  hbase(main):025:0> put 'employee','2','personal data:name','bobby'
  
  
```

