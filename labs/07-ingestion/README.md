# Lab 7 -- Apache Flume (Legacy Ingestion Concept)

[ภาษาไทย](README.th.md) | **English**

Flume is included in the image (`/opt/flume`) because it remained easy and
stable to install alongside the rest of the stack, and the concept it
teaches -- a long-running **agent** moving streaming events into HDFS via a
source/channel/sink pipeline -- is still worth seeing even though Flume
itself has no active upstream development. Treat this lab as a **legacy
ingestion concept**, not a currently-recommended production tool.

If a modern streaming ingestion example is wanted in a future phase,
**Apache Kafka** is the natural replacement for the "agent" role. Not added
in this phase to keep the sandbox footprint minimal.

```bash
flume-ng agent \
    --conf /opt/flume/conf \
    --conf-file /opt/flume/conf/flume.conf \
    --name agent -Dflume.root.logger=INFO,console
```

In a second terminal:

```bash
nc localhost 3030
```

Type some lines, then check HDFS:

```bash
hadoop fs -ls /user/student/flume/events
hadoop fs -cat /user/student/flume/events/*
```
