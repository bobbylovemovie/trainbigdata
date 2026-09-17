# trainbigdata:2026

A single-node, Docker-based Big Data sandbox for learning Hadoop-ecosystem
concepts, replacing the old Cloudera QuickStart VM (VirtualBox).

```text
Cloudera QuickStart VM  ->  Modern Docker Big Data Sandbox
```

This is a **single-node educational sandbox**, not a production
architecture, and not a multi-user platform (no JupyterHub, no auth,
no Kubernetes -- see "Next steps" at the bottom).

## Requirements

- Docker Desktop, or Docker Engine + Docker Compose plugin
- No VirtualBox. No Cloudera VM.
- 4 CPU / 8 GB RAM given to Docker minimum, 6 CPU / 12-16 GB preferred
  (see "Resource usage" below)

## Quick start

```bash
git clone https://github.com/bobbylovemovie/trainbigdata.git
cd trainbigdata
docker compose up -d
docker compose exec bigdata bash
```

Inside the container:

```bash
labctl status
```

Then start with `labs/02-hdfs/README.md` (also readable at
`~/labs/02-hdfs/README.md` inside the container, or in the JupyterLab file
browser).

JupyterLab (browser workspace, with a terminal): http://localhost:8888

## Architecture

```text
Laptop
  |
  v
Docker (one container per student)
  |
  v
trainbigdata:2026
  |-- HDFS (NameNode + DataNode)
  |-- YARN (ResourceManager + NodeManager) + MapReduce
  |-- HBase
  |-- Hive (Metastore + HiveServer2, backed by MariaDB)
  |-- Spark (spark-shell / pyspark / spark-submit)
  |-- MariaDB (Hive metastore DB + the RDBMS-ingestion lab)
  `-- JupyterLab (browser workspace + terminal)
```

Two ways in:

```text
Browser -> JupyterLab -> Terminal
docker compose exec bigdata bash -> Shell
```

All daemons run inside one container, managed by `supervisord`. There is no
SSH between "nodes" -- pseudo-distributed Hadoop/HBase/Hive processes are
started directly as foreground supervisor programs, which is simpler and
more container-native than the classic `start-dfs.sh`/SSH approach.

## Selected versions

Chosen for a stable, mutually-compatible set (informed by the versions
Apache Bigtop pairs together) rather than "latest of everything":

| Component | Version | Notes |
|---|---|---|
| Java | OpenJDK 8 | Hive 3.1.3's official baseline; Hadoop 3.3/HBase 2.5/Spark 3.5 all still support it |
| Hadoop | 3.3.6 | |
| HBase | 2.5.15 | last actively maintained 2.x line, matches Hadoop 3.3 |
| Hive | 3.1.3 | last release with first-class Java 8 support and the classic HiveQL surface this course teaches |
| Spark | 3.5.9 (`-bin-hadoop3`) | last Spark 3.x line; Spark 4.x was judged too new/unproven for a teaching stack at time of writing |
| Flume | 1.11.0 | legacy ingestion concept, see labs/07 |
| MariaDB | Ubuntu 22.04 distro package | Hive metastore DB + RDBMS-ingestion lab source |
| JDBC driver | mariadb-java-client 3.4.1 | replaces the obsolete `mysql-connector-java-5.1.23.jar` in `legacy/Spark/` |

### Compatibility gotchas hit and fixed

These aren't obvious from the docs and cost real debugging time, so they're
recorded here rather than left implicit in config comments alone:

- **HBase's ZooKeeper is a separate process.** `start-hbase.sh` normally
  launches it for you; since this image runs each daemon directly (no SSH
  between "nodes"), it needed its own `hbase-zookeeper` supervisor program,
  started before master/regionserver (`docker/supervisor/supervisord.conf`).
- **HBase's default async WAL provider breaks on this exact Hadoop/HBase
  pairing.** `AsyncFSWALProvider` uses reflection against Hadoop's internal
  protobuf classes; it throws `IllegalArgumentException: object is not an
  instance of declaring class` against Hadoop 3.3.6 here. Fixed by setting
  `hbase.wal.provider=filesystem` (the classic synchronous writer) in
  `docker/config/hbase/hbase-site.xml`.
- **MariaDB Connector/J 3.x rejects `jdbc:mysql://` URLs by default**
  (a deliberate trademark-driven change) but Spark's built-in `MySQLDialect`
  -- which quotes identifiers correctly -- only activates for URLs that
  start with `jdbc:mysql:`. The fix used in `labs/08-rdbms-ingestion/
  jdbc_to_hdfs.py` is `jdbc:mysql://...?permitMysqlScheme`, which satisfies
  both. (Hive's metastore JDBC URL uses `jdbc:mariadb://` instead, since
  DataNucleus doesn't have Spark's dialect-by-prefix problem.)
- **Hive 3.1.3's bundled DataNucleus generates invalid SQL against
  MariaDB for any partition/materialized-view metadata query**: it emits
  `LIKE '...' ESCAPE '\'` with a raw, unescaped backslash, which MariaDB's
  default string-literal parsing rejects. Fixed with
  `sessionVariables=sql_mode='NO_BACKSLASH_ESCAPES'` on the metastore JDBC
  URL in `hive-site.xml`. Without this, `labs/05-hive`'s partitioned-table
  exercise fails outright.
- **Hive's automatic column-stats gathering also breaks against this
  MariaDB/DataNucleus combination** (`JDOFatalInternalException` mapping
  the stats `bitVector` BLOB field). Fixed with `hive.stats.autogather=false`
  in `hive-site.xml`; students can still run `ANALYZE TABLE` explicitly.

## Service control: `labctl`

```bash
labctl status
labctl start core     # HDFS + YARN -- start this first
labctl start hbase
labctl start hive      # also brings up MariaDB if needed
labctl stop hbase
```

`core` and `mariadb` and `jupyter` autostart with the container. `hbase` and
`hive` do not, to save RAM when a session doesn't need them -- start them
only for labs 4, 5, 8, 10.

## Labs

| # | Lab | Notes |
|---|---|---|
| 02 | HDFS | `/user/student`, not `/user/cloudera` |
| 03 | MapReduce | modern `WordCount` (see migration guide) |
| 04 | HBase | column families renamed `personal_data`/`professional_data` |
| 05 | Hive | Beeline, not the `hive` CLI; MovieLens partitioned tables |
| 06 | Impala | deprecated/optional, not installed -- see labs/06 |
| 07 | Flume | legacy ingestion concept, Kafka noted as future replacement |
| 08 | RDBMS ingestion | replaces Sqoop: MariaDB -> Spark JDBC -> HDFS |
| 09 | PySpark | WordCount over HDFS |
| 10 | Spark SQL | `SparkSession`, not `HiveContext` |
| 11 | Streaming | Structured Streaming, not DStreams |

## Lab migration guide

```text
/user/cloudera              ->  /user/student
Hive CLI (`hive`)            ->  Beeline (`beeline`)
Sqoop                         ->  Spark JDBC (labs/08)
HiveContext(sc)               ->  SparkSession.builder.enableHiveSupport()
Spark Streaming (DStream)     ->  Structured Streaming
Impala                        ->  deprecated/optional (Trino noted as a future option)
```

## Persistent storage & reset

Named volumes persist `/opt/hadoop/data` (HDFS), `/var/lib/mysql` (MariaDB
+ Hive metastore) and `/home/student` (your files, notebooks, lab copies)
across `docker compose down` / `up -d`.

To wipe everything and start clean:

```bash
./scripts/reset-lab.sh
# or, equivalently and without the confirmation prompt:
docker compose down -v && docker compose up -d
```

## Smoke tests

```bash
./scripts/smoke-test.sh
```

Checks Java, Hadoop, HDFS (NameNode + put/get), YARN, MapReduce WordCount,
HBase, HiveServer2 + Beeline, Spark, PySpark, Spark-reads-HDFS, MariaDB,
JDBC-to-Spark ingestion, and JupyterLab. Exits non-zero if anything fails.

## Resource usage

Target: 4 CPU / 8 GB RAM minimum, 6+ CPU / 12-16 GB preferred. YARN is
tuned down (`yarn.nodemanager.resource.memory-mb=3072`,
`mapreduce.{map,reduce}.memory.mb=512`) to fit a laptop. HBase and Hive are
not autostarted, specifically to save RAM when a lab doesn't need them.
See `.env.example` for `MEM_LIMIT` and per-service port overrides.

Measured on an Apple M2 (8 CPU / 16 GB host, Docker Desktop with 8 GB given
to the VM), idle after startup:

| State | RAM used |
|---|---|
| `core` + MariaDB + JupyterLab (default boot) | ~2.2 GB |
| everything running (`labctl start all`) | ~3.4 GB |

Image size: ~2.9 GB.

## Security

This is a local, single-user educational sandbox -- not hardened for
multi-tenant or internet-facing use.

- All ports bind to `127.0.0.1` by default (see `.env.example`).
- Lab credentials are intentionally simple and local-only:
  `student` / `student` (MariaDB + Linux user), `hive` / `hive` (internal
  Hive metastore service account, not meant for direct student use).
- No TLS, no Kerberos, no real secrets are baked into the image.

## Compatibility

Built and tested on **macOS (Apple Silicon / arm64)**. The image also
builds for **linux/amd64** (base image and all installed components are
multi-arch), but amd64 has not been run end-to-end for this phase --
report issues if you hit any.

**Known arm64 limitation:** Hadoop's official binary tarball ships prebuilt
native libraries (`libhadoop.so`) for amd64 only. On arm64 the JVM falls
back to Java implementations of compression/CRC -- fully functional for
this course's labs, just somewhat slower on large data. Not an issue at the
scale used here (a few MB per lab).

## Known limitations / intentionally left as legacy

- **Impala**: not installed (see labs/06). Trino noted as a possible future
  addition, not implemented.
- **Flume**: included but explicitly labeled a legacy ingestion concept
  (labs/07); Kafka noted as a future replacement, not implemented.
- **Sqoop**: not installed (retired upstream); replaced by labs/08.
- The original `org.myorg.WordCount` jar (`legacy/HDFS/wordcount.jar`) is
  kept for reference only; `labs/03-mapreduce` ships a rebuilt, modern
  replacement (see that lab's README for why).
- `legacy/Spark/*.jar` (old MySQL connector, Oracle JDBC driver, Impala JDBC
  driver, Twitter/Spark-Streaming-Twitter jars) are unused historical
  artifacts from the old course, kept only for reference.

## Next step toward multi-user / JupyterHub

Out of scope for this phase by design. When it's time: front this same
image's Hadoop/Hive/Spark services with JupyterHub + per-user containers
(likely `DockerSpawner`, one lab container per student, sharing a common
HDFS/YARN backend rather than one full stack per user), add per-user auth,
and move from `docker compose` to an orchestrator if concurrent student
count requires it. None of that is needed to validate the environment
itself, which is this phase's actual goal.
