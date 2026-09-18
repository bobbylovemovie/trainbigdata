# trainbigdata:2026

**English** | [ภาษาไทย](README.th.md)

A single-node, Docker-based Big Data sandbox for learning Hadoop-ecosystem
concepts, replacing the old Cloudera QuickStart VM (VirtualBox).

```text
Cloudera QuickStart VM  ->  Modern Docker Big Data Sandbox
```

This is a **single-node educational sandbox** students run locally, one
container per laptop -- not a production architecture, and not a
multi-user platform (no JupyterHub, no VPS, no auth, no Kubernetes --
see "Next step toward multi-user" at the bottom).

## Requirements

- Docker Desktop (Windows/macOS), or Docker Engine + Compose plugin (Linux)
- Git
- No VirtualBox. No Cloudera VM. No cloud account.
- 8 GB laptop RAM minimum, 16 GB preferred (see "Resource usage" below)

## Quick start

```bash
git clone https://github.com/bobbylovemovie/trainbigdata.git
cd trainbigdata

docker compose pull
docker compose up -d
```

`pull` downloads the pre-built course image -- nothing is compiled or
installed on your machine. Then check you're ready:

```bash
./scripts/student-check.sh
```

(Windows without Git Bash/WSL: `.\scripts\student-check.ps1` in PowerShell.)

Enter the lab:

```bash
docker compose exec bigdata bash
```

```bash
labctl status
```

Full walkthrough: `labs/01-setup/README.md`. Then continue with
`labs/02-hdfs/README.md` (also readable at `~/labs/02-hdfs/README.md`
inside the container, or in the JupyterLab file browser).

From here on, every lab command is a Linux command run **inside the
container** -- identical whether your laptop is Windows, macOS, or Linux.

JupyterLab (browser workspace, with a terminal): http://localhost:8888 --
a convenience, not required; every lab in this course also works entirely
from `docker compose exec bigdata bash`.

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
| 01 | Setup | install, pull, `student-check`, enter the container |
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

## Repository vs. Docker image

Two different things update independently:

```text
GitHub repository            Docker image
  course instructions          Java, Hadoop, HBase, Hive, Spark, Python
  labs/, datasets/               MariaDB, all runtime configuration
  docker-compose.yml, scripts

  git pull                     docker compose pull
```

- **`git pull`** gets updated lab instructions and datasets.
- **`docker compose pull`** gets an updated runtime, if the instructor
  published one. Then `docker compose up -d` to switch to it.

You will not usually need to do both at once.

## Versioning

`docker-compose.yml` points at a specific tag, not a moving `latest`:

```yaml
image: ${TRAINBIGDATA_IMAGE:-ghcr.io/bobbylovemovie/trainbigdata:2026}
```

`:2026` is the tag a running class is expected to use; it only moves when
the instructor deliberately publishes an update and the class is told to
`docker compose pull`. If a specific class run needs to stay pinned to an
exact build even as `:2026` moves forward, point `.env`'s
`TRAINBIGDATA_IMAGE` at a dated/numbered tag instead (e.g.
`ghcr.io/bobbylovemovie/trainbigdata:2026.1`) -- see
`.github/workflows/build-image.yml` for how those get published.

## Updating during the semester

```text
Instructor edits lab docs -> git push -> student: git pull
Instructor publishes a new image -> student: docker compose pull && docker compose up -d
```

Students never need to reinstall or rebuild anything themselves.

## Building the image yourself (maintainers only)

Students should never need this. The default `docker-compose.yml` only
pulls the pre-built image; building it locally is a separate, explicit
step using the dev override:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml build
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

`.github/workflows/build-image.yml` builds and publishes the real image
for `linux/amd64` + `linux/arm64` via Buildx on push to `master` (tag
`:2026`) and on pushed `v2026.*` tags (a pinned numbered tag) -- see that
file for exact triggers and tag rules.

## Instructor demonstration

The instructor uses the exact same image students do -- there is no
separate "instructor build." What you demo in class is guaranteed to match
what's on every student's laptop.

## Pre-class verification

Send this to students before the session:

```text
Before class:
1. Install Docker Desktop
2. Install Git
3. git clone https://github.com/bobbylovemovie/trainbigdata.git
4. cd trainbigdata && docker compose pull && docker compose up -d
5. ./scripts/student-check.sh   (or .\scripts\student-check.ps1 on Windows)
6. Send a screenshot showing "Environment READY"
```

This surfaces install problems (corporate firewalls, low disk space, old
Docker versions, WSL2 not enabled) before class time, not during it.

## Windows compatibility

Docker Desktop on Windows is a first-class target. To keep behavior
identical across Windows/macOS/Linux:

- **Every lab command runs inside the Linux container**, entered via
  `docker compose exec bigdata bash`, never assumed to run on the host
  shell. This sidesteps CRLF/LF, path-separator, and permission
  differences entirely once you're inside.
- The one host-side check (`student-check`) is provided both ways:
  `scripts/student-check.sh` (bash -- Git Bash/WSL/macOS/Linux) and
  `scripts/student-check.ps1` (native PowerShell, no WSL required).
- `.gitattributes` forces LF line endings on shell scripts and configs
  regardless of the cloning machine's `core.autocrlf` setting, since a
  Windows default of `autocrlf=true` would otherwise corrupt shebang
  lines (`#!/bin/bash\r` fails to execute).
- Course paths inside the container are fixed (`/course/labs`,
  `/course/datasets`, `/home/student`) -- nothing in the lab instructions
  ever references a host path like `C:\Users\...` or `/Users/you/...`.

## Persistent storage & reset

Named volumes persist `/opt/hadoop/data` (HDFS), `/var/lib/mysql` (MariaDB
+ Hive metastore) and `/home/student` (your files, notebooks, lab copies)
across `docker compose down` / `up -d`, and across an ordinary
`docker compose restart`.

Two levels of reset, for when something breaks mid-lab:

```bash
./scripts/restart-lab.sh   # soft: restarts services, keeps all your data
./scripts/reset-lab.sh     # full: wipes HDFS/HBase/Hive/MariaDB/home, asks first
```

`reset-lab.sh` is equivalent to `docker compose down -v && docker compose
up -d` but asks for confirmation first, since it deletes real student work.

Convenience wrappers around the canonical `docker compose` commands (not
required, just shorter to type): `scripts/start.sh`, `scripts/stop.sh`.

## Testing the environment

Two different scripts, for two different audiences:

```bash
./scripts/student-check.sh    # student-facing: "am I ready for lab?"
./scripts/smoke-test.sh       # developer-facing: deep end-to-end test
```

`student-check.sh` is fast and friendly -- Docker installed/running, image
present, container running, Hadoop/HDFS/YARN/Java/Spark responding -- with
one plain-English fix suggested per failure, no stack traces. This is what
students (and instructors, before class) run.

`smoke-test.sh` is the real correctness test: Java, Hadoop, HDFS (NameNode
+ put/get), YARN, MapReduce WordCount, HBase, HiveServer2 + Beeline, Spark,
PySpark, Spark-reads-HDFS, MariaDB, JDBC-to-Spark ingestion, and JupyterLab.
Exits non-zero if anything fails. Run this after changing the image, not
before every lab session.

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

Image size: ~2.9 GB. Everything comfortably fits in the `MEM_LIMIT=6g`
default -- a laptop with 8 GB total RAM is enough, 16 GB is comfortable.

**Only run what the current lab needs.** Nothing forces HBase or Hive to
stay running once you're done with them:

| Lab | Start | Stop when done |
|---|---|---|
| 02 HDFS, 03 MapReduce, 09 PySpark, 10 Spark SQL*, 11 Streaming | `core` (default) | -- |
| 04 HBase | `labctl start hbase` | `labctl stop hbase` |
| 05 Hive, 08 RDBMS ingestion | `labctl start hive` | `labctl stop hive` |

\* labs/10's optional Hive-integration example needs `hive` running too.

```bash
docker compose exec bigdata labctl stop hbase
docker compose exec bigdata labctl stop hive
```

## Security

This is a local, single-user educational sandbox -- not hardened for
multi-tenant or internet-facing use.

- All ports bind to `127.0.0.1` by default (see `.env.example`).
- Lab credentials are intentionally simple and local-only:
  `student` / `student` (MariaDB + Linux user), `hive` / `hive` (internal
  Hive metastore service account, not meant for direct student use).
- No TLS, no Kerberos, no real secrets are baked into the image.

## Compatibility

Built and **fully tested end to end** (build + 15-check smoke test,
multiple times from a clean volume state, including pulling and running
the actual published `ghcr.io/bobbylovemovie/trainbigdata:2026` image) on
**macOS (Apple Silicon / arm64)**.

`.github/workflows/build-image.yml` has run successfully and published a
real multi-arch manifest -- confirmed with `docker manifest inspect`
listing both `amd64` and `arm64` variants at `ghcr.io/bobbylovemovie/
trainbigdata:2026`, and a plain `docker pull` of it works with no
authentication (the package is public). What is **not yet independently
confirmed** is running that amd64 build end-to-end on real amd64 hardware
or Windows Docker Desktop -- this session only had arm64 hardware to test
on. The image should work there (Ubuntu 22.04 base and every installed
component ship official amd64 builds, and the amd64 half of the manifest
built without error), but "should work" isn't "confirmed" -- report issues
if you hit any.

**Known arm64 limitation:** Hadoop's official binary tarball ships prebuilt
native libraries (`libhadoop.so`) for amd64 only. On arm64 the JVM falls
back to Java implementations of compression/CRC -- fully functional for
this course's labs, just somewhat slower on large data. Not an issue at the
scale used here (a few MB per lab).

**Known CI limitation:** cross-building `linux/arm64` under QEMU emulation
on a `linux/amd64` GitHub-hosted runner is slow for a stack this size (this
session's own arm64 build, native, took 15-75+ minutes depending on Apache
mirror load). If the Actions workflow times out, the practical fix is
splitting it into a build matrix across native `ubuntu-latest` (amd64) and
GitHub's native `ubuntu-24.04-arm` runners, then merging into one manifest
with `docker buildx imagetools create` -- not implemented yet since it adds
real complexity that isn't worth taking on before the QEMU path is even
confirmed to fail.

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
