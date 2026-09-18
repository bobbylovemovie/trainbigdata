# Lab 11 -- Spark Streaming

[ภาษาไทย](README.th.md) | **English**

The old DStream-based example (`legacy/Spark/StreamingWordCount_dstream.py`)
uses an API Spark itself has deprecated in favor of **Structured
Streaming**. This lab uses that instead: `streaming_wordcount.py`.

Terminal 1:

```bash
nc -lk 9999
```

Terminal 2:

```bash
spark-submit ~/labs/11-streaming/streaming_wordcount.py
```

Type words into terminal 1; terminal 2 prints updated word counts on every
micro-batch.
