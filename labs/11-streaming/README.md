# Lab 11 -- Spark Streaming

[ภาษาไทย](README.th.md) | **English**

This lab uses **Structured Streaming** (`streaming_wordcount.py`), the
current API for processing data that arrives continuously rather than
sitting in a file.

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
