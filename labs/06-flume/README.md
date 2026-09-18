# Lab 6 -- Apache Flume (Legacy Ingestion Concept)

[ภาษาไทย](README.th.md) | **English**

Flume is included in the image (`/opt/flume`) because it remained easy and
stable to install alongside the rest of the stack, and the concept it
teaches -- a long-running **agent** moving streaming events into HDFS via a
source/channel/sink pipeline -- is still worth seeing even though Flume
itself has no active upstream development. Treat this lab as a **legacy
ingestion concept**, not a currently-recommended production tool.

**Lab 7 -- Kafka** covers the modern replacement for this same role.

## Read the config first

Before starting the agent, look at what you're about to run. This is the
whole pipeline definition:

```bash
cat /opt/flume/conf/flume.conf
```

```properties
agent.sources = netsource
agent.sinks = hdfssink
agent.channels = memorychannel

agent.sources.netsource.type = netcat
agent.sources.netsource.bind = localhost
agent.sources.netsource.port = 3030
agent.sources.netsource.interceptors = ts
agent.sources.netsource.interceptors.ts.type = org.apache.flume.interceptor.TimestampInterceptor$Builder

agent.sinks.hdfssink.type = hdfs
agent.sinks.hdfssink.hdfs.path = hdfs://localhost:9000/user/student/flume/events
agent.sinks.hdfssink.hdfs.filePrefix = log
agent.sinks.hdfssink.hdfs.rollInterval = 0
agent.sinks.hdfssink.hdfs.rollCount = 5
agent.sinks.hdfssink.hdfs.fileType = DataStream

agent.channels.memorychannel.type = memory
agent.channels.memorychannel.capacity = 100
agent.channels.memorychannel.transactionCapacity = 100

agent.sources.netsource.channels = memorychannel
agent.sinks.hdfssink.channel = memorychannel
```

Reading it top to bottom as the three pieces of every Flume agent:

- **Source** (`agent.sources.netsource`): where events come in. Type
  `netcat` means "listen on a TCP port and treat each line of text as one
  event" -- here, port `3030` on `localhost`.
- **Channel** (`agent.channels.memorychannel`): the buffer between source
  and sink. Type `memory` means events sit in RAM until the sink drains
  them (capacity 100 events -- if the sink falls behind and the channel
  fills up, the source blocks). A `file` channel exists too, for when you
  can't afford to lose buffered events on a crash.
- **Sink** (`agent.sinks.hdfssink`): where events go out. Type `hdfs`
  writes them to `hdfs.path` -- note this is a full `hdfs://` URI, not a
  local path. `rollCount = 5` means it closes the current output file and
  starts a new one every 5 events (production configs usually roll on
  size or time instead, for larger batches).

The last two lines (`agent.sources.netsource.channels = ...` and
`agent.sinks.hdfssink.channel = ...`) are what actually wires source ->
channel -> sink together; without them the three pieces above are just
declared, not connected.

## Run it

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
