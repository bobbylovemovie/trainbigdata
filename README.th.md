# trainbigdata:2026

[English](README.md) | **ภาษาไทย**

Big Data Sandbox แบบ single-node บน Docker สำหรับเรียนรู้แนวคิด Hadoop
ecosystem มาแทนที่ Cloudera QuickStart VM (VirtualBox) แบบเดิม

```text
Cloudera QuickStart VM  ->  Modern Docker Big Data Sandbox
```

นี่คือ **sandbox เพื่อการศึกษาแบบ single-node** ที่นักเรียนรันเองบนเครื่อง
ตัวเอง คนละ container ต่อคน -- ไม่ใช่ production architecture และไม่ใช่
platform หลายผู้ใช้ (ไม่มี JupyterHub, ไม่มี VPS, ไม่มีระบบ auth, ไม่มี
Kubernetes -- ดู "ขั้นตอนถัดไปสำหรับ multi-user" ด้านล่าง)

## ข้อกำหนดของเครื่อง

- Docker Desktop (Windows/macOS) หรือ Docker Engine + Compose plugin (Linux)
- Git
- ไม่ต้องใช้ VirtualBox ไม่ต้องใช้ Cloudera VM ไม่ต้องมี cloud account
- RAM ขั้นต่ำ 8 GB แนะนำ 16 GB (ดู "การใช้ทรัพยากร" ด้านล่าง)

## เริ่มต้นใช้งาน

```bash
git clone https://github.com/bobbylovemovie/trainbigdata.git
cd trainbigdata

docker compose pull
docker compose up -d
```

`pull` จะดาวน์โหลด image ที่ build ไว้แล้ว -- ไม่มีการ compile หรือติดตั้ง
อะไรบนเครื่องคุณเลย จากนั้นเช็คว่าพร้อมหรือยัง:

```bash
./scripts/student-check.sh
```

(Windows ที่ไม่มี Git Bash/WSL: ใช้ `.\scripts\student-check.ps1` ใน
PowerShell แทน)

เข้าไปใน lab:

```bash
docker compose exec bigdata bash
```

```bash
labctl status
```

คู่มือละเอียด (ภาษาไทย): `labs/01-setup/README.th.md` จากนั้นต่อด้วย
`labs/02-hdfs/README.th.md` (อ่านได้จากใน container ที่
`~/labs/02-hdfs/README.th.md` หรือผ่าน JupyterLab file browser ก็ได้ --
ทุก lab มีทั้งเวอร์ชันไทย/อังกฤษ สลับภาษาได้จากลิงก์บนสุดของแต่ละไฟล์)

จากจุดนี้ไป ทุกคำสั่งใน lab คือคำสั่ง Linux ที่รัน **ภายใน container**
เหมือนกันหมดไม่ว่าเครื่องคุณจะเป็น Windows, macOS หรือ Linux

JupyterLab (พื้นที่ทำงานผ่าน browser พร้อม terminal): http://localhost:8888
-- เป็นแค่ทางเลือกเสริม ไม่บังคับ ทุก lab ในคอร์สนี้ทำผ่าน
`docker compose exec bigdata bash` ได้ครบเหมือนกัน

## สถาปัตยกรรม

```text
Laptop
  |
  v
Docker (หนึ่ง container ต่อนักเรียนหนึ่งคน)
  |
  v
trainbigdata:2026
  |-- HDFS (NameNode + DataNode)
  |-- YARN (ResourceManager + NodeManager) + MapReduce
  |-- HBase
  |-- Hive (Metastore + HiveServer2, ใช้ MariaDB เป็น backend)
  |-- Spark (spark-shell / pyspark / spark-submit)
  |-- MariaDB (ฐานข้อมูล Hive metastore + lab การ ingest จาก RDBMS)
  `-- JupyterLab (พื้นที่ทำงานผ่าน browser + terminal)
```

สองทางเข้า:

```text
Browser -> JupyterLab -> Terminal
docker compose exec bigdata bash -> Shell
```

daemon ทั้งหมดรันอยู่ใน container เดียว จัดการโดย `supervisord` ไม่มี SSH
ระหว่าง "node" -- process Hadoop/HBase/Hive แบบ pseudo-distributed ถูกสั่ง
รันตรง ๆ เป็น foreground supervisor program ซึ่งง่ายกว่าและเข้ากับ
container ได้ดีกว่าวิธีเดิมแบบ `start-dfs.sh`/SSH

## เวอร์ชันที่เลือกใช้

เลือกชุดเวอร์ชันที่เข้ากันได้และเสถียร (อิงจากเวอร์ชันที่ Apache Bigtop
จับคู่กัน) แทนที่จะใช้ "เวอร์ชันล่าสุดของทุกตัว":

| Component | เวอร์ชัน | หมายเหตุ |
|---|---|---|
| Java | OpenJDK 8 | เวอร์ชันมาตรฐานของ Hive 3.1.3; Hadoop 3.3/HBase 2.5/Spark 3.5 ก็ยังรองรับอยู่ |
| Hadoop | 3.3.6 | |
| HBase | 2.5.15 | สาย 2.x ตัวล่าสุดที่ยังดูแลอยู่ เข้ากับ Hadoop 3.3 |
| Hive | 3.1.3 | เวอร์ชันล่าสุดที่รองรับ Java 8 เต็มรูปแบบ และใช้ HiveQL แบบคลาสสิกตามที่คอร์สนี้สอน |
| Spark | 3.5.9 (`-bin-hadoop3`) | สาย Spark 3.x ตัวล่าสุด; Spark 4.x ถูกประเมินว่าใหม่/ยังไม่นิ่งพอสำหรับ stack การสอน ณ ตอนที่เขียน |
| Flume | 1.11.0 | แนวคิด ingestion แบบเก่า ดู labs/07 |
| MariaDB | แพ็กเกจของ Ubuntu 22.04 | ฐานข้อมูล Hive metastore + แหล่งข้อมูลของ lab การ ingest จาก RDBMS |
| JDBC driver | mariadb-java-client 3.4.1 | แทนที่ `mysql-connector-java-5.1.23.jar` ตัวเก่าที่อยู่ใน `legacy/Spark/` |

### จุดเข้ากันไม่ได้ที่เจอและแก้ไปแล้ว

รายการนี้ไม่ได้อยู่ในเอกสารทั่วไป และกินเวลา debug จริงพอสมควร เลยจดไว้
ตรงนี้แทนที่จะฝังไว้แค่ใน comment ของ config:

- **ZooKeeper ของ HBase เป็นคนละ process แยกต่างหาก** ปกติ
  `start-hbase.sh` จะรันให้อัตโนมัติ แต่เพราะ image นี้สั่งรันแต่ละ daemon
  ตรง ๆ (ไม่มี SSH ระหว่าง "node") จึงต้องมี supervisor program
  `hbase-zookeeper` แยกออกมา รันก่อน master/regionserver (ดูที่
  `docker/supervisor/supervisord.conf`)
- **ตัวจัดการ WAL แบบ async ของ HBase (ค่า default) พังกับคู่
  Hadoop/HBase ชุดนี้พอดี** `AsyncFSWALProvider` ใช้ reflection เจาะ class
  protobuf ภายในของ Hadoop ซึ่งพอมาเจอ Hadoop 3.3.6 ตัวนี้จะโยน
  `IllegalArgumentException: object is not an instance of declaring class`
  แก้โดยตั้ง `hbase.wal.provider=filesystem` (ตัวเขียนแบบ synchronous
  คลาสสิก) ใน `docker/config/hbase/hbase-site.xml`
- **MariaDB Connector/J 3.x ปฏิเสธ URL แบบ `jdbc:mysql://` โดย default**
  (เป็นการเปลี่ยนแปลงจากเรื่อง trademark โดยตั้งใจ) แต่ `MySQLDialect`
  ของ Spark เอง -- ซึ่ง quote identifier ได้ถูกต้อง -- จะทำงานเฉพาะ URL
  ที่ขึ้นต้นด้วย `jdbc:mysql:` เท่านั้น วิธีแก้ใน
  `labs/08-rdbms-ingestion/jdbc_to_hdfs.py` คือใช้
  `jdbc:mysql://...?permitMysqlScheme` ซึ่งตอบโจทย์ทั้งสองฝั่ง (ส่วน JDBC
  URL ของ Hive metastore ใช้ `jdbc:mariadb://` แทน เพราะ DataNucleus ไม่มี
  ปัญหาเรื่อง dialect-by-prefix แบบ Spark)
- **DataNucleus ที่แถมมากับ Hive 3.1.3 สร้าง SQL ที่ผิดพลาดกับ MariaDB
  สำหรับ query metadata ของ partition/materialized-view ใด ๆ**: มันสร้าง
  `LIKE '...' ESCAPE '\'` โดยมี backslash ดิบที่ไม่ได้ escape ซึ่งการ parse
  string literal แบบ default ของ MariaDB จะปฏิเสธ แก้ด้วย
  `sessionVariables=sql_mode='NO_BACKSLASH_ESCAPES'` บน JDBC URL ของ
  metastore ใน `hive-site.xml` ถ้าไม่แก้ตรงนี้ แบบฝึกหัด partitioned table
  ใน `labs/05-hive` จะล้มเหลวทันที
- **การเก็บสถิติคอลัมน์อัตโนมัติของ Hive ก็พังกับ MariaDB/DataNucleus
  คู่นี้เหมือนกัน** (`JDOFatalInternalException` ตอน map field `bitVector`
  ที่เป็น BLOB) แก้ด้วย `hive.stats.autogather=false` ใน `hive-site.xml`
  นักเรียนยังรัน `ANALYZE TABLE` เองได้ตามปกติ
- **`labctl`/`supervisorctl` ขึ้น `PermissionError` ถ้าไม่ได้รันด้วย
  root** (นักเรียนคนหนึ่งเจอจากการเปิด terminal ผ่านหน้าเว็บ JupyterLab
  ซึ่งรันเป็น user `student` ไม่ใช่ root) ต้นเหตุคือ socket ที่ใช้คุมกับ
  supervisor ตั้งไว้ `chmod=0700` (root คนเดียวเข้าได้) แก้โดยเปลี่ยนเป็น
  `chmod=0666` ใน `docker/supervisor/supervisord.conf` -- เป็น tradeoff
  ที่รับได้เพราะ sandbox นี้ระบุไว้อยู่แล้วว่าเป็นแบบ local ผู้ใช้คนเดียว
  (ดูหัวข้อ "ความปลอดภัย" ด้านบน)

## สั่งงาน service: `labctl`

```bash
labctl status
labctl start core     # HDFS + YARN -- เริ่มตัวนี้ก่อน
labctl start hbase
labctl start hive      # จะเปิด MariaDB ให้ด้วยถ้ายังไม่เปิด
labctl stop hbase
```

`core`, `mariadb` และ `jupyter` เปิดเองอัตโนมัติตอน container start ส่วน
`hbase` กับ `hive` ไม่เปิดเอง เพื่อประหยัด RAM ตอนที่ session นั้นไม่ได้ใช้
-- เปิดเฉพาะตอนทำ lab 4, 5, 8, 10

## Lab ทั้งหมด

ทุก lab มีคู่มือละเอียดเป็นภาษาไทยอยู่ที่ `labs/<หมายเลข>/README.th.md`
(เช่น `labs/02-hdfs/README.th.md`) พร้อมคำอธิบายทีละคำสั่ง ตัวอย่างผล
ลัพธ์ และวิธีแก้ปัญหาที่เจอบ่อย

| # | Lab | หมายเหตุ |
|---|---|---|
| 01 | Setup | ติดตั้ง, pull image, `student-check`, เข้า container |
| 02 | HDFS | ใช้ `/user/student` ไม่ใช่ `/user/cloudera` |
| 03 | MapReduce | `WordCount` เวอร์ชันใหม่ (ดู migration guide) |
| 04 | HBase | เปลี่ยนชื่อ column family เป็น `personal_data`/`professional_data` |
| 05 | Hive | ใช้ Beeline แทน `hive` CLI; ตาราง MovieLens แบบ partitioned |
| 06 | Impala | เลิกใช้/ไม่บังคับ ไม่ได้ติดตั้ง -- ดู labs/06 |
| 07 | Flume | แนวคิด ingestion แบบเก่า มี Kafka เป็นตัวเลือกทดแทนในอนาคต |
| 08 | RDBMS ingestion | แทนที่ Sqoop: MariaDB -> Spark JDBC -> HDFS |
| 09 | PySpark | WordCount บน HDFS |
| 10 | Spark SQL | ใช้ `SparkSession` ไม่ใช่ `HiveContext` |
| 11 | Streaming | ใช้ Structured Streaming ไม่ใช่ DStreams |

## คู่มือ migration ของ lab

```text
/user/cloudera              ->  /user/student
Hive CLI (`hive`)            ->  Beeline (`beeline`)
Sqoop                         ->  Spark JDBC (labs/08)
HiveContext(sc)               ->  SparkSession.builder.enableHiveSupport()
Spark Streaming (DStream)     ->  Structured Streaming
Impala                        ->  เลิกใช้/ไม่บังคับ (มี Trino เป็นตัวเลือกในอนาคต)
```

## Repository กับ Docker image

สองอย่างนี้อัปเดตแยกอิสระจากกัน:

```text
GitHub repository             Docker image
  คำสั่งสอนของคอร์ส              Java, Hadoop, HBase, Hive, Spark, Python
  labs/, datasets/               MariaDB, config การรันทั้งหมด
  docker-compose.yml, scripts

  git pull                      docker compose pull
```

- **`git pull`** ได้คำสั่งสอน lab และ dataset ที่อัปเดต
- **`docker compose pull`** ได้ runtime ที่อัปเดต ถ้าผู้สอน publish ไว้
  จากนั้น `docker compose up -d` เพื่อสลับไปใช้ตัวใหม่

ปกติไม่จำเป็นต้องทำทั้งสองอย่างพร้อมกัน

## การจัดเวอร์ชัน

`docker-compose.yml` ชี้ไปที่ tag เฉพาะเจาะจง ไม่ใช่ `latest` ที่เปลี่ยน
ตลอดเวลา:

```yaml
image: ${TRAINBIGDATA_IMAGE:-ghcr.io/bobbylovemovie/trainbigdata:2026}
```

`:2026` คือ tag ที่คลาสที่กำลังเรียนควรใช้ มันจะขยับก็ต่อเมื่อผู้สอนตั้งใจ
publish อัปเดตและบอกให้นักเรียน `docker compose pull` ถ้าคลาสรอบใดต้อง
ปักหมุดกับ build เดิมแม้ `:2026` จะขยับไปแล้ว ให้ตั้ง `TRAINBIGDATA_IMAGE`
ใน `.env` ให้ชี้ไปที่ tag แบบมีเลขระบุ (เช่น
`ghcr.io/bobbylovemovie/trainbigdata:2026.1`) -- ดูวิธี publish ได้ที่
`.github/workflows/build-image.yml`

## อัปเดตระหว่างเทอม

```text
ผู้สอนแก้เอกสาร lab -> git push -> นักเรียน: git pull
ผู้สอน publish image ใหม่ -> นักเรียน: docker compose pull && docker compose up -d
```

นักเรียนไม่ต้องติดตั้งหรือ build อะไรใหม่เองเลย

## Build image เอง (สำหรับ maintainer เท่านั้น)

นักเรียนไม่ควรต้องทำแบบนี้ `docker-compose.yml` ค่า default จะ pull
image ที่ build ไว้แล้วเท่านั้น การ build เองต้องใช้ override file แยก
ต่างหาก:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml build
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

`.github/workflows/build-image.yml` จะ build และ publish image จริงสำหรับ
`linux/amd64` + `linux/arm64` ผ่าน Buildx ตอน push เข้า `master` (tag
`:2026`) และตอน push tag แบบ `v2026.*` (tag แบบระบุเลขเจาะจง) -- ดู
รายละเอียด trigger และกฎการตั้ง tag ในไฟล์นั้น

## การสาธิตของผู้สอน

ผู้สอนใช้ image ตัวเดียวกันเป๊ะกับที่นักเรียนใช้ -- ไม่มี "build สำหรับ
ผู้สอน" แยกต่างหาก สิ่งที่สาธิตในห้องเรียนจึงตรงกับที่อยู่บนเครื่อง
นักเรียนทุกคนแน่นอน

## เช็คก่อนวันเรียนจริง

ส่งข้อความนี้ให้นักเรียนก่อนวันเรียน:

```text
ก่อนวันเรียน:
1. ติดตั้ง Docker Desktop
2. ติดตั้ง Git
3. git clone https://github.com/bobbylovemovie/trainbigdata.git
4. cd trainbigdata && docker compose pull && docker compose up -d
5. ./scripts/student-check.sh   (หรือ .\scripts\student-check.ps1 บน Windows)
6. ส่ง screenshot ที่ขึ้นว่า "Environment READY"
```

วิธีนี้ทำให้เจอปัญหาการติดตั้ง (firewall องค์กร, พื้นที่ดิสก์ไม่พอ,
Docker เวอร์ชันเก่า, WSL2 ยังไม่เปิดใช้งาน) ก่อนถึงเวลาเรียนจริง ไม่ใช่
มาเจอกลางคาบ

## ความเข้ากันได้กับ Windows

Docker Desktop บน Windows คือกลุ่มเป้าหมายหลักเทียบเท่า macOS/Linux
เพื่อให้พฤติกรรมเหมือนกันทุก OS:

- **ทุกคำสั่งของ lab รันภายใน container Linux** เข้าผ่าน
  `docker compose exec bigdata bash` ไม่มีคำสั่งไหนสมมติว่ารันบน host
  shell เลย พอเข้าไปข้างในแล้วปัญหาเรื่อง CRLF/LF, ตัวคั่น path, และสิทธิ์
  ไฟล์ต่าง ๆ จะหายไปเลย
- ส่วนที่ต้องเช็คบน host เพียงจุดเดียว (`student-check`) มีให้สองแบบ:
  `scripts/student-check.sh` (bash -- Git Bash/WSL/macOS/Linux) และ
  `scripts/student-check.ps1` (PowerShell ล้วน ไม่ต้องมี WSL)
- `.gitattributes` บังคับ line ending แบบ LF สำหรับ shell script และ
  config ไม่ว่าเครื่องที่ clone จะตั้งค่า `core.autocrlf` เป็นอะไร เพราะ
  ค่า default `autocrlf=true` ของ Windows จะทำให้บรรทัด shebang พัง
  (`#!/bin/bash\r` รันไม่ได้)
- path ของคอร์สภายใน container ตายตัว (`/course/labs`,
  `/course/datasets`, `/home/student`) -- ไม่มีคำสั่งสอน lab ไหนอ้างอิง
  path ของ host เช่น `C:\Users\...` หรือ `/Users/you/...` เลย

## Persistent storage และการ reset

Named volume จะเก็บ `/opt/hadoop/data` (HDFS), `/var/lib/mysql` (MariaDB +
Hive metastore) และ `/home/student` (ไฟล์, notebook, สำเนา lab ของคุณ) ไว้
ข้าม `docker compose down` / `up -d` และข้าม `docker compose restart`
ปกติด้วย

Reset มีสองระดับ สำหรับตอนที่มีอะไรพังกลาง lab:

```bash
./scripts/restart-lab.sh   # soft: restart service เก็บข้อมูลทั้งหมดไว้
./scripts/reset-lab.sh     # full: ล้าง HDFS/HBase/Hive/MariaDB/home ถามยืนยันก่อน
```

`reset-lab.sh` เทียบเท่ากับ `docker compose down -v && docker compose up
-d` แต่จะถามยืนยันก่อน เพราะมันลบงานจริงของนักเรียน

wrapper สั้น ๆ ของคำสั่ง `docker compose` มาตรฐาน (ไม่บังคับใช้ แค่พิมพ์
สั้นกว่า): `scripts/start.sh`, `scripts/stop.sh`

## ทดสอบสภาพแวดล้อม

มี script แยกสองตัว สำหรับคนละกลุ่มเป้าหมาย:

```bash
./scripts/student-check.sh    # สำหรับนักเรียน: "ฉันพร้อมเข้า lab หรือยัง?"
./scripts/smoke-test.sh       # สำหรับ dev: ทดสอบเชิงลึกแบบ end-to-end
```

`student-check.sh` เร็วและเป็นมิตร -- เช็ค Docker ติดตั้ง/รันอยู่, มี
image, container รันอยู่, Hadoop/HDFS/YARN/Java/Spark ตอบสนอง -- พร้อมข้อ
แนะนำวิธีแก้แบบภาษาคนสำหรับแต่ละจุดที่ fail ไม่มี stack trace ยาว ๆ นี่คือ
ตัวที่นักเรียน (และผู้สอนก่อนเข้าคลาส) ใช้

`smoke-test.sh` คือการทดสอบความถูกต้องจริงจัง: Java, Hadoop, HDFS (NameNode
+ put/get), YARN, MapReduce WordCount, HBase, HiveServer2 + Beeline, Spark,
PySpark, Spark-อ่าน-HDFS, MariaDB, JDBC-ไป-Spark ingestion, และ JupyterLab
จะ exit แบบ non-zero ถ้ามีจุดไหน fail รันตัวนี้หลังเปลี่ยน image ไม่ใช่
ก่อนทุกครั้งที่เข้า lab

## การใช้ทรัพยากร

เป้าหมาย: ขั้นต่ำ 4 CPU / 8 GB RAM แนะนำ 6+ CPU / 12-16 GB YARN ถูกปรับลด
ค่า (`yarn.nodemanager.resource.memory-mb=3072`,
`mapreduce.{map,reduce}.memory.mb=512`) ให้พอดีกับ laptop HBase และ Hive
ไม่เปิดอัตโนมัติ เพื่อประหยัด RAM ตอนที่ lab ไม่ได้ต้องการ ดู
`.env.example` สำหรับ `MEM_LIMIT` และการปรับ port แต่ละ service

วัดจาก Apple M2 (host 8 CPU / 16 GB, Docker Desktop ให้ VM 8 GB) ตอนว่าง
หลัง startup:

| สถานะ | RAM ที่ใช้ |
|---|---|
| `core` + MariaDB + JupyterLab (ค่า default ตอน boot) | ~2.2 GB |
| เปิดทุกอย่าง (`labctl start all`) | ~3.4 GB |

ขนาด image: ~2.9 GB ทุกอย่างพอดีกับค่า default `MEM_LIMIT=6g` สบาย ๆ --
laptop RAM 8 GB ก็พอ 16 GB จะสบายมาก

**เปิดใช้เฉพาะสิ่งที่ lab ตอนนั้นต้องการ** ไม่มีอะไรบังคับให้ HBase หรือ
Hive ต้องค้างไว้หลังใช้เสร็จ:

| Lab | เปิดด้วย | ปิดเมื่อเสร็จ |
|---|---|---|
| 02 HDFS, 03 MapReduce, 09 PySpark, 10 Spark SQL*, 11 Streaming | `core` (default) | -- |
| 04 HBase | `labctl start hbase` | `labctl stop hbase` |
| 05 Hive, 08 RDBMS ingestion | `labctl start hive` | `labctl stop hive` |

\* ตัวอย่างเสริมที่เชื่อม Hive ใน labs/10 ต้องเปิด `hive` ด้วย

```bash
docker compose exec bigdata labctl stop hbase
docker compose exec bigdata labctl stop hive
```

## ความปลอดภัย

นี่คือ sandbox เพื่อการศึกษาแบบ local ผู้ใช้คนเดียว -- ไม่ได้ทำให้แข็งแรง
สำหรับใช้งานแบบ multi-tenant หรือเปิดสู่อินเทอร์เน็ต

- ทุก port bind กับ `127.0.0.1` โดย default (ดู `.env.example`)
- credential ของ lab ตั้งใจให้ง่ายและใช้ได้แค่ในเครื่อง:
  `student` / `student` (MariaDB + Linux user), `hive` / `hive` (service
  account ภายในของ Hive metastore ไม่ได้มีไว้ให้นักเรียนใช้ตรง ๆ)
- ไม่มี TLS ไม่มี Kerberos ไม่มี secret จริงฝังอยู่ใน image

## ความเข้ากันได้ของ platform

Build และ **ทดสอบ end-to-end ครบถ้วน** (build + smoke test 15 จุด หลายรอบ
จาก volume ที่ล้างใหม่ รวมถึง pull และรัน image จริงที่ publish แล้วคือ
`ghcr.io/bobbylovemovie/trainbigdata:2026`) บน **macOS (Apple Silicon /
arm64)**

`.github/workflows/build-image.yml` รันสำเร็จแล้วและ publish manifest
แบบ multi-arch จริง -- ยืนยันด้วย `docker manifest inspect` ที่แสดงทั้ง
`amd64` และ `arm64` อยู่ใน `ghcr.io/bobbylovemovie/trainbigdata:2026` และ
`docker pull` ธรรมดาก็ทำงานได้โดยไม่ต้อง authenticate (package เป็น
public แล้ว) สิ่งที่ **ยังไม่ได้รับการยืนยันอิสระ** คือการรัน amd64 build
นี้แบบ end-to-end บนเครื่อง amd64 จริงหรือ Windows Docker Desktop --
session นี้มีแต่เครื่อง arm64 ให้ทดสอบ ตัว image ควรใช้ได้บนนั้น (base
Ubuntu 22.04 และทุก component ที่ติดตั้งมี official build สำหรับ amd64
และครึ่ง amd64 ของ manifest ก็ build ผ่านไม่มี error) แต่ "ควรใช้ได้" ไม่
เท่ากับ "ยืนยันแล้ว" -- แจ้งปัญหาได้ถ้าเจอ

**ข้อจำกัดที่รู้อยู่แล้วของ arm64:** binary tarball ทางการของ Hadoop มี
native library (`libhadoop.so`) สำหรับ amd64 เท่านั้น บน arm64 JVM จะ
fallback ไปใช้ implementation แบบ Java ล้วนสำหรับ compression/CRC --
ทำงานได้ครบทุกฟังก์ชันสำหรับ lab ของคอร์สนี้ แค่ช้ากว่านิดหน่อยกับข้อมูล
ขนาดใหญ่ ไม่ใช่ปัญหาที่ scale ที่ใช้ในคอร์สนี้ (ไม่กี่ MB ต่อ lab)

**ข้อจำกัดที่รู้อยู่แล้วของ CI:** การ cross-build `linux/arm64` ผ่าน QEMU
emulation บน runner แบบ `linux/amd64` ช้าสำหรับ stack ขนาดนี้ (การ build
arm64 แบบ native ของ session นี้เองใช้เวลา 15-75+ นาที แล้วแต่ความช้าของ
Apache mirror) ถ้า Actions workflow timeout ทางแก้ที่เหมาะคือแยกเป็น build
matrix ระหว่าง `ubuntu-latest` (amd64) แบบ native กับ runner
`ubuntu-24.04-arm` ของ GitHub ที่เป็น native เช่นกัน แล้วรวมเป็น manifest
เดียวด้วย `docker buildx imagetools create` -- ยังไม่ได้ทำเพราะเพิ่มความ
ซับซ้อนที่ยังไม่คุ้มจนกว่าจะยืนยันว่า QEMU ใช้ไม่ได้จริง

## ข้อจำกัดที่รู้อยู่แล้ว / จงใจเก็บไว้เป็นของเก่า

- **Impala**: ไม่ได้ติดตั้ง (ดู labs/06) มี Trino เป็นตัวเลือกเสริมใน
  อนาคต ยังไม่ได้ทำ
- **Flume**: ติดตั้งไว้แต่ระบุชัดว่าเป็นแนวคิด ingestion แบบเก่า
  (labs/07) มี Kafka เป็นตัวเลือกทดแทนในอนาคต ยังไม่ได้ทำ
- **Sqoop**: ไม่ได้ติดตั้ง (upstream เลิกดูแลแล้ว) แทนที่ด้วย labs/08
- jar ตัวเดิม `org.myorg.WordCount` (`legacy/HDFS/wordcount.jar`) เก็บไว้
  เพื่ออ้างอิงเท่านั้น `labs/03-mapreduce` มีเวอร์ชัน rebuild ใหม่ให้ (ดู
  README ของ lab นั้นว่าทำไม)
- `legacy/Spark/*.jar` (MySQL connector ตัวเก่า, Oracle JDBC driver,
  Impala JDBC driver, jar ของ Twitter/Spark-Streaming-Twitter) เป็นของ
  เก่าจากคอร์สเดิมที่ไม่ได้ใช้แล้ว เก็บไว้อ้างอิงเท่านั้น

## ขั้นตอนถัดไปสำหรับ multi-user / JupyterHub

ตั้งใจไม่รวมไว้ในเฟสนี้ เมื่อถึงเวลา: เอา JupyterHub มาครอบ service
Hadoop/Hive/Spark ชุดเดิมนี้ + container แยกต่อผู้ใช้ (น่าจะใช้
`DockerSpawner`, container lab แยกต่อนักเรียนหนึ่งคน ใช้ backend
HDFS/YARN ร่วมกันแทนที่จะแยก stack เต็มต่อคน), เพิ่มระบบ auth ต่อผู้ใช้,
และย้ายจาก `docker compose` ไปใช้ orchestrator ถ้าจำนวนนักเรียนพร้อมกัน
ต้องการ ทั้งหมดนี้ไม่จำเป็นสำหรับการพิสูจน์ว่า environment นี้ใช้งานได้
ซึ่งคือเป้าหมายจริงของเฟสนี้
