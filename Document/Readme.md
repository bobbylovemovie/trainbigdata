## LAB 2 Hadoop File System (HDFS)
- mkdir guest1 
- cd guest1 \n
- wget https://github.com/bobbylovemovie/trainbigdata/raw/master/HDFS/PG2600.txt
- hadoop fs -mkdir /user/cloudera/input
- hadoop fs -ls /user/cloudera/input
- hadoop fs -rm /user/cloudera/input/\*
- hadoop fs -put PG2600.txt /user/cloudera/input/
- hadoop fs -ls /user/cloudera/input

Open Web Browser : http://quickstart.cloudera:8888
