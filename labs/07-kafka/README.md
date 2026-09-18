# Lab 7 -- Apache Kafka

[ภาษาไทย](README.th.md) | **English**

## Why this replaced the old Lab 6 (Impala)

The original Cloudera-era course had Impala here. It's been dropped
entirely rather than kept as a placeholder: Impala is tightly coupled to
Cloudera's packaging, adds several more JVM daemons (catalogd,
statestored, impalad) and its own metadata-caching layer on top of the
same Hive metastore -- real operational weight for a single-node teaching
sandbox, for a learning objective ("fast interactive SQL") already
covered by Hive/Beeline (Lab 5) and Spark SQL (Lab 10). If a dedicated
fast SQL engine is wanted later, **Trino** (https://trino.io) is the
modern equivalent -- not implemented here.

**Kafka**, on the other hand, is the direct modern replacement for what
**Lab 6 -- Flume** taught: a long-running process that ingests a stream
of events. Do Lab 6 first if you haven't -- this lab makes the most sense
as a contrast to it.

## Kafka vs. Flume, in one picture

```text
Flume:  producer -> agent (source/channel/sink) -> ONE destination (HDFS)

Kafka:  producer -> topic (durable, replicated log) -> MANY consumers,
                                                        each reading
                                                        independently,
                                                        replayable
```

The core difference: Flume's channel is a transient buffer that exists
only to get data from its source to its one configured sink. Kafka's
topic is a **durable log** that consumers read from independently, at
their own pace, and can **replay from the beginning** at any time. That's
why Kafka works as a general-purpose message bus with many independent
consumers (e.g. one job loading to HDFS, another triggering alerts,
another feeding a dashboard) instead of one fixed pipeline.

This sandbox runs Kafka in **KRaft mode** -- Kafka manages its own
metadata internally, no separate ZooKeeper process needed (this is the
modern default since Kafka 3.x, and the only mode Kafka 4.x supports).

## Important: Kafka does not store data in HDFS

Easy to assume otherwise in a course built around Hadoop, so to be
explicit: **Kafka has its own storage layer.** It writes plain log-segment
files straight to local disk -- there is no NameNode, no DataNode, no
`hdfs://` URI anywhere in Kafka itself. Verify this after Step 3 below, once
you've produced a few messages:

```bash
ls /opt/hadoop/data/kafka-logs/student-events-0/
hadoop fs -ls /user/student/
```

The first command shows real `.log`/`.index` files sitting on the
container's local filesystem -- that's where your messages actually live.
The second command (HDFS) shows nothing related to Kafka at all, because
there's nothing there to show. (This sandbox's Kafka data happens to sit
on the same persisted Docker volume as HDFS's own data, purely so the
image doesn't need a second named volume -- that's a deployment
convenience, not a storage relationship. The two systems don't know
about each other.)

If you *do* want Kafka data to end up in HDFS, that's not automatic --
it's a separate, deliberate pipeline (e.g. Kafka Connect's HDFS sink
connector, or a Spark Structured Streaming job reading from Kafka and
writing to HDFS, extending what Lab 11 does with a raw socket). Kafka's
job is the durable log in between; getting data into HDFS is always a
second, explicit step.

## Step 1: Start Kafka

```bash
docker compose exec bigdata labctl start kafka
```

Kafka needs Java 11+ (everything else in this sandbox is pinned to Java
8 for Hive compatibility -- see README "Selected versions"), so its
`JAVA_HOME` is set independently by `labctl`/supervisord; you don't need
to do anything about that yourself. Check it came up:

```bash
docker compose exec bigdata labctl status
```

Should show `Kafka           RUNNING`.

## Step 2: Create a topic

```bash
export JAVA_HOME=/usr/lib/jvm/default-java11
kafka-topics.sh --bootstrap-server localhost:9092 \
    --create --topic student-events --partitions 1 --replication-factor 1
```

> Every `kafka-*.sh` command in this lab needs that same `JAVA_HOME`
> export first (it's not needed for anything else in this course -- just
> Kafka's own CLI tools). If you open a fresh terminal, export it again.

`--partitions 1` keeps this simple for the demo; production topics often
use many partitions to parallelize across consumers. `--replication-factor
1` is correct here because this is a single-node broker -- production
Kafka clusters typically use 3.

List topics to confirm:

```bash
kafka-topics.sh --bootstrap-server localhost:9092 --list
```

Describe it (partitions, leader, replicas):

```bash
kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic student-events
```

## Step 3: Produce messages

```bash
kafka-console-producer.sh --bootstrap-server localhost:9092 --topic student-events
```

This is interactive -- type a message, hit Enter, it's published. Try a
few:

```text
hello kafka
this is message two
event three
```

`Ctrl+D` (or `Ctrl+C`) to exit the producer when done.

## Step 4: Consume messages

In a **second terminal** (`docker compose exec bigdata bash`, then
`export JAVA_HOME=/usr/lib/jvm/default-java11` again):

```bash
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic student-events --from-beginning
```

`--from-beginning` replays every message ever published to this topic,
not just new ones -- **this is the key difference from Flume's netcat
source**, which only sees data sent while it's connected. Kafka keeps the
log around (`log.retention.hours=24` in this sandbox's config) so a
consumer that starts late, or restarts, doesn't lose anything.

Leave this consumer running, then go back to **Terminal 1** and produce
a few more messages -- watch them appear in the consumer terminal in
real time. `Ctrl+C` to stop consuming.

## Step 5: See the replay behavior for yourself

Stop the consumer (`Ctrl+C`) and start it again with the same command:

```bash
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic student-events --from-beginning
```

**Every message from Step 3 shows up again**, in the same order, even
though the consumer is a brand-new process. That's the durable-log
behavior Flume's in-memory channel cannot give you -- Flume's channel is
just a buffer that empties once the sink drains it; there is nothing left
to replay.

Now try it **without** `--from-beginning`:

```bash
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic student-events
```

Nothing appears until you produce something new -- without
`--from-beginning`, a consumer only sees messages published *after* it
connects (this is the default, and matches how most consumers behave in
production: they track their own position and only care about new data).

## Step 6: Clean up

```bash
kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic student-events
```

## Stop Kafka when you're done

```bash
docker compose exec bigdata labctl stop kafka
```

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `kafka-topics.sh: command not found` | Forgot `export JAVA_HOME=/usr/lib/jvm/default-java11` first, or Kafka isn't on `PATH` in a fresh shell -- try `/opt/kafka/bin/kafka-topics.sh` with the full path |
| `Error: A JNI error has occurred` / version error | Missing the `JAVA_HOME` export above -- Kafka's scripts pick up the container's default Java 8 otherwise, which Kafka 3.x rejects |
| `Connection to node -1 could not be established` | Kafka hasn't finished starting yet. `labctl status` should show `Kafka RUNNING`; if it just started, wait ~10-15 seconds and retry |

## Summary

You saw the core reason Kafka replaced Flume for this role: a **durable,
replayable log** with independent consumers, instead of a one-shot
buffer wired to a single destination. This is the same mental model
behind Kafka Connect (source/sink connectors that replace what
Flume agents used to do) and behind feeding Spark Structured Streaming
(Lab 11) from a Kafka topic instead of a raw socket in a real production
pipeline.
