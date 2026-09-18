# Lab 5 -- Hive

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

เรียนรู้ Hive -- เครื่องมือที่ให้เขียน SQL มาสั่งงาน Hadoop แทนที่จะต้อง
เขียนโปรแกรม MapReduce เอง (เหมือน lab 3) เหมาะกับข้อมูลขนาดใหญ่ที่มี
โครงสร้างเป็นตาราง แล้วอยากใช้ SQL ที่คุ้นเคยมาวิเคราะห์

> คำสั่ง `hive` แบบ interactive CLI ของเดิมเลิกใช้แล้วในวงการจริง lab
> นี้ใช้ **HiveServer2 + Beeline** แทน (Beeline คือ client ที่เชื่อมต่อไป
> หา HiveServer2 ผ่านโปรโตคอล JDBC เหมือนที่โปรแกรม database client ทั่วไป
> ใช้เชื่อมต่อฐานข้อมูล)

## ขั้นตอนที่ 1: เปิด Hive

Hive **ไม่ได้เปิดอัตโนมัติ** เช่นเดียวกับ HBase ต้องสั่งเปิดก่อน:

```bash
docker compose exec bigdata labctl start hive
```

คำสั่งนี้จะเปิด MariaDB ให้ด้วยอัตโนมัติถ้ายังไม่เปิด (Hive ใช้ MariaDB
เป็นที่เก็บ metadata ของตาราง เรียกว่า Hive Metastore) แล้วเปิด Hive
Metastore service กับ HiveServer2 ตามลำดับ

เช็คสถานะ:

```bash
labctl status
```

ต้องเห็น `Hive           RUNNING` และ `MariaDB        RUNNING`

## ขั้นตอนที่ 2: เชื่อมต่อด้วย Beeline

```bash
beeline -u jdbc:hive2://localhost:10000/default
```

`jdbc:hive2://localhost:10000/default` คือ JDBC URL: เชื่อมต่อไปที่
HiveServer2 บน `localhost` port `10000` เลือกฐานข้อมูล (database) ชื่อ
`default` prompt จะเปลี่ยนเป็นประมาณ `0: jdbc:hive2://localhost:10000/default>`

## ขั้นตอนที่ 3: สร้างตารางทดสอบ

พิมพ์ทีละคำสั่งใน Beeline (อย่าลืม `;` ปิดท้ายทุกคำสั่ง แบบ SQL ทั่วไป):

```sql
CREATE TABLE test_tbl (
    id INT,
    country STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;
```

- `ROW FORMAT DELIMITED FIELDS TERMINATED BY ','` บอก Hive ว่าไฟล์ข้อมูล
  ดิบที่จะอ่านเข้าตารางนี้เป็นแบบ CSV (คั่นด้วยจุลภาค)
- `STORED AS TEXTFILE` บอกว่าเก็บเป็นไฟล์ข้อความธรรมดาบน HDFS (Hive
  รองรับ format อื่นด้วย เช่น Parquet, ORC แต่ TEXTFILE อ่านง่ายเข้าใจ
  ง่ายที่สุดสำหรับตอนเริ่มเรียน)

ดูรายชื่อตาราง:

```sql
SHOW TABLES;
```

ดูโครงสร้างตาราง:

```sql
DESCRIBE test_tbl;
```

ลองเพิ่มคอลัมน์ใหม่ (แก้ schema แบบไม่ต้องสร้างตารางใหม่):

```sql
ALTER TABLE test_tbl ADD COLUMNS (remarks STRING);
DESCRIBE test_tbl;
```

ควรเห็นคอลัมน์ `remarks` เพิ่มเข้ามาในผลลัพธ์รอบสอง

**อย่าเพิ่งลบตาราง** -- ไปทำขั้นตอนถัดไปก่อน ซึ่งใช้ `test_tbl` ตัวนี้
พิสูจน์แนวคิดสำคัญที่สุดอย่างหนึ่งของ Hive

## ขั้นตอนที่ 3.5: Hive ไม่ใช่ database จริง -- มันคือโฟลเดอร์บน HDFS

นี่คือสิ่งที่เข้าใจผิดกันบ่อยที่สุดตอนเริ่มเรียน Hive: **Hive ไม่ได้เก็บ
ข้อมูลด้วย storage engine ของตัวเองแบบ MySQL/PostgreSQL** สิ่งที่มันทำจริง
ๆ คือแปลคำสั่ง SQL ให้กลายเป็นการสร้าง**โฟลเดอร์**และ**ไฟล์**ธรรมดาบน
HDFS เท่านั้น -- `CREATE TABLE` = สร้างโฟลเดอร์, `INSERT` = สร้างไฟล์
ข้อมูลดิบไว้ข้างในโฟลเดอร์นั้น (ส่วน MariaDB ที่ใช้อยู่เบื้องหลัง
-- Hive Metastore -- เก็บแค่ "คำอธิบาย schema" เช่น ตารางนี้มีคอลัมน์
อะไรบ้าง ไม่ได้เก็บข้อมูลจริงเลย)

**ออกจาก Beeline ก่อน** (`!quit`) กลับมาที่ bash แล้วลองดูด้วยตาตัวเอง:

```bash
hadoop fs -ls /user/hive/warehouse
```

จะเห็นโฟลเดอร์ชื่อ `test_tbl` โผล่อยู่ -- **ชื่อเดียวกับตารางที่เพิ่ง
สร้าง** เพราะมันคือสิ่งเดียวกัน

เชื่อมต่อ Beeline กลับเข้าไปใหม่แล้วใส่ข้อมูล:

```bash
beeline -u jdbc:hive2://localhost:10000/default
```

```sql
INSERT INTO test_tbl (id, country) VALUES (1, 'Thailand');
```

`!quit` ออกมาอีกครั้ง แล้วดูข้างในโฟลเดอร์ของตาราง:

```bash
hadoop fs -ls /user/hive/warehouse/test_tbl
```

จะเห็นไฟล์ใหม่โผล่มา (ชื่อประมาณ `000000_0`) -- **นั่นคือไฟล์ข้อความ
ธรรมดา** ลองอ่านดูตรง ๆ ได้เลยโดยไม่ผ่าน Hive/SQL เลย:

```bash
hadoop fs -cat /user/hive/warehouse/test_tbl/000000_0
```

ควรเห็น `1,Thailand` -- คือแถวข้อมูลที่เพิ่ง INSERT ไป เก็บเป็น CSV ธรรมดา
(ตรงกับที่ตอนสร้างตารางระบุไว้ว่า `FIELDS TERMINATED BY ','`) **นี่คือ
หลักฐานตรง ๆ ว่า `INSERT INTO` ของ Hive ไม่ได้ยิง SQL ไปเก็บในฐานข้อมูล
ที่ไหน แค่เขียนไฟล์ข้อความลง HDFS เท่านั้น**

### ดูผ่านหน้าเว็บแทนก็ได้ (เห็นภาพชัดกว่าสำหรับสอนในห้องเรียน)

เปิด browser ไปที่ http://localhost:9870 -> เมนู **Utilities -> Browse
the file system** -> พิมพ์ path `/user/hive/warehouse` แล้ว Enter จะเห็น
รายชื่อโฟลเดอร์ = รายชื่อตาราง Hive ทั้งหมดที่มีอยู่ คลิกเข้าไปในแต่ละ
โฟลเดอร์จะเห็นไฟล์ข้อมูลข้างในเหมือนกับที่เห็นผ่าน `hadoop fs -ls`
ทุกประการ -- เหมาะมากสำหรับเปิดฉายให้ทั้งห้องดูพร้อมกันตอนสอน

ลบตารางทดสอบทิ้งเมื่อดูจบแล้ว:

```sql
DROP TABLE test_tbl;
```

แล้วลอง `hadoop fs -ls /user/hive/warehouse` อีกครั้ง -- โฟลเดอร์
`test_tbl` จะหายไปด้วย (เพราะเป็นตารางแบบปกติ ไม่ใช่ `EXTERNAL TABLE`
Hive เป็นเจ้าของข้อมูลเต็มตัว จึงลบทั้งโฟลเดอร์ตอน `DROP TABLE`)
เปรียบเทียบกับขั้นตอนถัดไปที่ใช้ `EXTERNAL TABLE` ซึ่ง `DROP TABLE` จะ
**ไม่ลบไฟล์ข้อมูลจริง** -- ต่างกันตรงนี้เพราะ external table แค่ "ชี้"
ไปหาโฟลเดอร์ ไม่ได้เป็นเจ้าของ

## ขั้นตอนที่ 4: MovieLens -- External Table

ส่วนนี้คือแบบฝึกหัดใหญ่ที่สุดของ lab: โหลดข้อมูลจริง (MovieLens dataset
-- ข้อมูลผู้ใช้และการให้คะแนนหนังจากเว็บ MovieLens) เข้า Hive แล้ว query

**ออกจาก Beeline ก่อน** (พิมพ์ `!quit` หรือกด Ctrl+D) กลับมาที่ bash
ธรรมดา แล้วแตกไฟล์ dataset:

```bash
mkdir -p ~/movielens_dataset && cd ~/movielens_dataset
unzip /course/datasets/ml-100k.zip
more ml-100k/u.user
```

`more ml-100k/u.user` เปิดดูตัวอย่างข้อมูลดิบ (กด space เพื่อเลื่อนหน้า,
กด `q` เพื่อออก) จะเห็นข้อมูลคั่นด้วย `|` แต่ละบรรทัดคือผู้ใช้หนึ่งคน:
`userid|age|gender|occupation|zipcode`

อัปโหลดไฟล์ `u.user` เข้า HDFS:

```bash
hadoop fs -mkdir -p /user/student/movielens
hadoop fs -put ml-100k/u.user /user/student/movielens/
```

เชื่อมต่อ Beeline อีกครั้ง:

```bash
beeline -u jdbc:hive2://localhost:10000/default
```

สร้าง **external table** ที่ชี้ไปยังโฟลเดอร์ HDFS นั้นโดยตรง:

```sql
CREATE EXTERNAL TABLE users (
    userid INT, age INT, gender STRING, occupation STRING, zipcode STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '|'
STORED AS TEXTFILE
LOCATION '/user/student/movielens';
```

จุดสำคัญของ `EXTERNAL TABLE`: Hive แค่ "ชี้" ไปหาข้อมูลที่มีอยู่แล้วใน
`LOCATION` ที่ระบุ ไม่ได้ก็อปปี้ข้อมูลมาเก็บใหม่ และถ้าสั่ง `DROP TABLE`
ทีหลัง ไฟล์ข้อมูลจริงจะ**ไม่ถูกลบ** (ต่างจาก table แบบปกติที่ Hive เป็น
เจ้าของข้อมูลเต็มตัว) เหมาะกับกรณีที่มีข้อมูลอยู่แล้วและแค่อยากเอามา
query ผ่าน SQL

ลอง query ดู:

```sql
SELECT * FROM users LIMIT 10;
```

## ขั้นตอนที่ 5: ตารางแบบ Partition

Partition คือการแบ่งข้อมูลตารางออกเป็นกลุ่มย่อยตามค่าคอลัมน์ใดคอลัมน์
หนึ่ง (บ่อยครั้งคือ วันที่/ปี) เพื่อให้ query ที่กรองด้วยคอลัมน์นั้นเร็ว
ขึ้นมาก (Hive อ่านแค่ partition ที่เกี่ยวข้อง ไม่ต้องสแกนทั้งตาราง)

```sql
CREATE TABLE users_partition (
    userid INT, age INT, gender STRING, occupation STRING, zipcode STRING
)
PARTITIONED BY (year STRING);
```

`PARTITIONED BY (year STRING)` ทำให้ตารางนี้แบ่งเก็บข้อมูลเป็นโฟลเดอร์
ย่อยตามค่า `year` (สังเกตว่า `year` ไม่ได้อยู่ในรายชื่อคอลัมน์ข้อมูล
ด้านบน มันเป็น "คอลัมน์เสมือน" ที่มาจากโครงสร้าง partition)

ใส่ข้อมูลเข้า partition ปี 2019 (ก็อปข้อมูลจากตาราง `users` เดิม):

```sql
INSERT INTO users_partition PARTITION (year='2019') SELECT * FROM users;
SELECT * FROM users_partition;
```

ใส่ข้อมูลชุดเดียวกันเข้า partition ปี 2020 ด้วย (จำลองว่ามีข้อมูลหลายปี):

```sql
INSERT INTO users_partition PARTITION (year='2020') SELECT * FROM users;
```

ลอง query โดยกรองเฉพาะ partition เดียว:

```sql
SELECT * FROM users_partition WHERE year='2020';
```

ดูรายชื่อ partition ทั้งหมดที่มีอยู่:

```sql
SHOW PARTITIONS users_partition;
```

ออกจาก Beeline:

```sql
quit;
```

## ปิด Hive เมื่อทำเสร็จแล้ว

```bash
docker compose exec bigdata labctl stop hive
```

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `Could not open connection to jdbc:hive2://localhost:10000` | HiveServer2 ยังเปิดไม่เสร็จ เช็คด้วย `labctl status`, รอสักครู่แล้วลองใหม่ |
| `unzip: command not found` | ไม่ควรเกิดใน image ล่าสุด (มี `unzip` ติดตั้งไว้แล้ว) ถ้าเจอ แปลว่า image เก่าเกินไป ลอง `docker compose pull` ใหม่ |
| `INSERT INTO ... PARTITION` ค้างนานหรือ error แปลก ๆ | ตรวจว่าใช้ image เวอร์ชันล่าสุด (มีการแก้บั๊กความเข้ากันไม่ได้ระหว่าง Hive กับ MariaDB ไว้แล้ว ดูรายละเอียดใน README หลักหัวข้อ "จุดเข้ากันไม่ได้ที่เจอและแก้ไปแล้ว") |

## สรุป

คุณสร้างตาราง, โหลดข้อมูลจริงแบบ external table, และแบ่งข้อมูลเป็น
partition สำเร็จแล้ว -- ทักษะเหล่านี้คือแกนหลักของการทำ data warehouse
บน Hadoop นำไปต่อยอดได้ทั้งใน lab 8 (นำข้อมูลจาก RDBMS มาลง Hive) และ
lab 10 (query ข้อมูลเดียวกันนี้จาก Spark SQL ผ่าน Hive metastore ร่วมกัน)
