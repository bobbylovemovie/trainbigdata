# Lab 8 -- RDBMS Ingestion (แทนที่ Apache Sqoop)

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

Apache Sqoop (เครื่องมือมาตรฐานเดิมสำหรับย้ายข้อมูลจากฐานข้อมูล
relational เข้า Hadoop) ถูก retire ไปแล้วในวงการจริง แต่เป้าหมายการเรียน
รู้ยังสำคัญเหมือนเดิม:

```text
ฐานข้อมูล Relational (MariaDB)
        |  JDBC
        v
Spark
        |
        v
HDFS / Hive / Parquet
```

แทนที่จะใช้ Sqoop lab นี้ใช้ **Spark อ่านข้อมูลผ่าน JDBC โดยตรง** แล้ว
เขียนผลลัพธ์ลง HDFS -- เป็นวิธีที่งานจริงในปัจจุบันนิยมใช้มากกว่า Sqoop
ด้วยซ้ำ เพราะ Spark คือเครื่องมือที่ยังพัฒนาต่อเนื่องอยู่

## ขั้นตอนที่ 1: เปิด Hive (ซึ่งจะเปิด MariaDB ให้ด้วย)

```bash
docker compose exec bigdata labctl start hive
```

## ขั้นตอนที่ 2: สร้างข้อมูลต้นทางใน MariaDB

เข้า container แล้วเชื่อมต่อ MariaDB ด้วย client ธรรมดา:

```bash
docker compose exec bigdata bash
mysql -h localhost -u student -pstudent
```

> credential `student` / `student` เป็น credential สำหรับ lab เท่านั้น
> ใช้ได้แค่ในเครื่องคุณเอง ไม่ได้เปิดสู่อินเทอร์เน็ต

พิมพ์คำสั่ง SQL ต่อไปนี้ทีละคำสั่งใน `mysql` prompt:

```sql
CREATE DATABASE test_mysql_db;
USE test_mysql_db;

CREATE TABLE country_tbl (id INT NOT NULL, country VARCHAR(50), PRIMARY KEY (id));
INSERT INTO country_tbl VALUES (1, 'USA');
INSERT INTO country_tbl VALUES (2, 'CANADA');
INSERT INTO country_tbl VALUES (3, 'Mexico');
INSERT INTO country_tbl VALUES (4, 'Brazil');
INSERT INTO country_tbl VALUES (61, 'Japan');
INSERT INTO country_tbl VALUES (65, 'Singapore');
INSERT INTO country_tbl VALUES (66, 'Thailand');

SELECT * FROM country_tbl;
```

ควรเห็นตารางข้อมูล 7 แถวแสดงออกมา ยืนยันว่าสร้างข้อมูลต้นทางสำเร็จแล้ว
พิมพ์ `exit` เพื่อออกจาก `mysql` client

## ขั้นตอนที่ 3: อ่านข้อมูลด้วย Spark แล้วเขียนลง HDFS

สคริปต์ `jdbc_to_hdfs.py` (อยู่ในโฟลเดอร์นี้) ทำหน้าที่อ่านผ่าน JDBC แล้ว
เขียนผลลัพธ์เป็นไฟล์ Parquet ลง HDFS ให้ครบในคำสั่งเดียว driver ของ
MariaDB ถูกเตรียมไว้ให้แล้วที่ `/opt/mariadb-java-client.jar`:

```bash
spark-submit --jars /opt/mariadb-java-client.jar \
    ~/labs/08-rdbms-ingestion/jdbc_to_hdfs.py \
    --db test_mysql_db --table country_tbl \
    --output hdfs:///user/student/ingest/country_tbl
```

อธิบายพารามิเตอร์:

- `--jars /opt/mariadb-java-client.jar` บอก Spark ให้โหลด driver JDBC
  ของ MariaDB เข้ามาด้วย (จำเป็น เพราะ Spark ไม่มี driver นี้ติดตัวมา
  โดย default)
- `--db` / `--table` คือฐานข้อมูลและตารางต้นทางใน MariaDB
- `--output` คือ path ปลายทางบน HDFS

ระหว่างรัน สคริปต์จะพิมพ์ตารางข้อมูลที่อ่านมาได้ (ผ่าน `df.show()`) ให้ดู
ด้วย ก่อนจะเขียนลง HDFS

## ขั้นตอนที่ 4: ตรวจสอบผลลัพธ์

```bash
hadoop fs -ls /user/student/ingest/country_tbl
```

ควรเห็นไฟล์ `.parquet` หลายไฟล์ (Spark เขียนแบบแบ่ง partition) อยู่ใน
โฟลเดอร์นั้น

## ขั้นตอนที่ 5 (เสริม): ลงทะเบียนเป็นตาราง Hive ด้วย

ถ้าอยากให้ query ผ่าน Beeline/Hive SQL ได้ด้วย เพิ่ม flag
`--as-hive-table`:

```bash
spark-submit --jars /opt/mariadb-java-client.jar \
    ~/labs/08-rdbms-ingestion/jdbc_to_hdfs.py \
    --db test_mysql_db --table country_tbl \
    --output hdfs:///user/student/ingest/country_tbl \
    --as-hive-table country
```

ลอง query จาก Beeline:

```bash
beeline -u jdbc:hive2://localhost:10000/default -e "SELECT * FROM country;"
```

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `Access denied for user 'student'@'localhost'` | เช็คว่าพิมพ์ password `student` ถูกต้อง (ตัวพิมพ์เล็กทั้งหมด) |
| `Table 'test_mysql_db.country_tbl' doesn't exist` | ยังไม่ได้ทำขั้นตอนที่ 2 ให้ครบ หรือพิมพ์ชื่อฐานข้อมูล/ตารางผิด |
| `The driver could not open a JDBC connection` | ลืมใส่ `--jars /opt/mariadb-java-client.jar` ตอนสั่ง `spark-submit` |

## สรุป

คุณเพิ่งทำ pipeline "RDBMS -> Spark -> HDFS/Hive" ที่เป็นแนวทางมาตรฐาน
ของงาน data engineering ยุคปัจจุบันสำเร็จแล้ว โดยไม่ต้องพึ่ง Sqoop ที่
เลิกดูแลไปแล้วเลย
