# Lab 3 -- MapReduce

[ภาษาไทย](README.th.md) | **English**

`WordCount.java` in this folder uses the current Hadoop `mapreduce` API
and is prebuilt into `wordcount.jar` in this same folder during the
Docker image build -- nothing to compile yourself for the basic exercise.

```bash
hadoop fs -mkdir -p /user/student/input
hadoop fs -put -f /course/datasets/PG2600.txt /user/student/input/

hadoop jar ~/labs/03-mapreduce/wordcount.jar WordCount \
    /user/student/input /user/student/output/wordcount

hadoop fs -cat /user/student/output/wordcount/part-r-00000 | head -20
```

Inspect the job in the YARN UI: http://localhost:8088

To rebuild the jar yourself (e.g. after editing `WordCount.java`):

```bash
javac -classpath "$(hadoop classpath)" -d /tmp/wc-classes WordCount.java
jar -cvf wordcount.jar -C /tmp/wc-classes .
```
