# Lab 2 -- HDFS

[ภาษาไทย](README.th.md) | **English**

Every student's files live under `/user/student` in HDFS.

```bash
cp /course/datasets/PG2600.txt ~/PG2600.txt

hadoop fs -mkdir -p /user/student/input
hadoop fs -put PG2600.txt /user/student/input/
hadoop fs -ls /user/student/input
hadoop fs -cat /user/student/input/PG2600.txt | head -20
```

Remove and re-upload:

```bash
hadoop fs -rm /user/student/input/*
hadoop fs -put PG2600.txt /user/student/input/
```

NameNode web UI: http://localhost:9870 (bind host set in `.env`).
