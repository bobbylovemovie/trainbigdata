# Lab 10 -- Spark SQL

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

เรียนรู้ Spark SQL -- วิธีใช้ SQL หรือ DataFrame API (ซึ่งอ่านง่ายกว่า
RDD API ที่ใช้ใน lab 9 มาก) มาประมวลผลข้อมูลบน Spark

> lab นี้ใช้ `SparkSession` ซึ่งเป็น entry point เดียวที่รวมทุก
> ความสามารถของ Spark (SQL, DataFrame, Streaming) ไว้ในที่เดียว

## ขั้นตอนที่ 1: เปิด PySpark shell

```bash
pyspark
```

## ขั้นตอนที่ 2: สร้าง SparkSession และอ่านข้อมูล

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("BigDataLab") \
    .enableHiveSupport() \
    .getOrCreate()

lines = spark.read.text("hdfs:///user/student/input/PG2600.txt")
lines.createOrReplaceTempView("lines")

spark.sql("SELECT * FROM lines LIMIT 10").show()
```

อธิบาย:

- `SparkSession.builder...getOrCreate()` สร้าง (หรือใช้ตัวที่มีอยู่แล้ว)
  SparkSession -- ใน `pyspark` shell จริง ๆ มีตัวแปร `spark` เตรียมไว้
  ให้แล้ว แต่เขียนแบบนี้เผื่อเอาไปใช้ในสคริปต์ `.py` ที่ต้องสร้างเอง
- `.enableHiveSupport()` เชื่อม Spark เข้ากับ Hive metastore ตัวเดียว
  กับที่ lab 05 ใช้ -- ทำให้ query ตารางที่สร้างจาก Beeline ได้จาก Spark
  ด้วย (และกลับกัน)
- `spark.read.text(...)` อ่านไฟล์ข้อความเข้ามาเป็น DataFrame (แต่ละ
  บรรทัดคือหนึ่งแถวในคอลัมน์ชื่อ `value`)
- `.createOrReplaceTempView("lines")` ตั้งชื่อ DataFrame นี้ว่า `lines`
  เพื่อให้เขียน SQL อ้างถึงมันได้เหมือนเป็นตารางฐานข้อมูล
- `spark.sql(...)` รัน SQL ธรรมดาได้เลย เหมือน query ฐานข้อมูลทั่วไป

## ขั้นตอนที่ 3: รัน demo แบบเต็ม (นับคำยอดฮิตด้วย SQL)

โฟลเดอร์นี้มี `spark_sql_demo.py` ที่ทำ WordCount แบบเดียวกับ lab 9 แต่
เขียนด้วย Spark SQL แทน RDD API:

```bash
spark-submit ~/labs/10-spark-sql/spark_sql_demo.py hdfs:///user/student/input/PG2600.txt
```

ผลลัพธ์จะแสดงตารางคำ 20 คำที่ปรากฏบ่อยที่สุดในไฟล์ พร้อมจำนวนครั้ง
เรียงจากมากไปน้อย

## ขั้นตอนที่ 4 (เสริม): เชื่อมกับตารางของ Hive

ถ้าทำ **Lab 5 -- Hive** ไว้ก่อนแล้ว (มีตาราง `users` จาก MovieLens) และ
เปิด Hive อยู่ (`labctl start hive`) ลอง query ข้ามมาจาก Spark ได้เลย:

```python
spark.sql("SHOW TABLES").show()
spark.sql("SELECT * FROM users LIMIT 10").show()
```

นี่คือจุดสำคัญ: **Hive metastore เป็นจุดกลางที่ทั้ง Beeline และ Spark
มองเห็นตารางเดียวกัน** ไม่ต้องโหลดข้อมูลซ้ำสองรอบ

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `Table or view not found: users` | ยังไม่ได้ทำ lab 5 หรือยังไม่ได้เปิด Hive ด้วย `labctl start hive` |
| ผลลัพธ์ `SELECT * FROM lines` ว่างเปล่า | ยังไม่ได้ทำ lab 2 (อัปโหลด `PG2600.txt` เข้า HDFS) |

## สรุป

คุณใช้ `SparkSession` ทำ Spark SQL และเห็นว่ามันเชื่อมกับ Hive metastore
เดียวกันได้อย่างไร้รอยต่อ -- lab ถัดไป
(**Lab 11 -- Streaming**) จะเปลี่ยนจากข้อมูลนิ่ง (batch) ไปเป็นข้อมูลที่
ไหลเข้ามาต่อเนื่อง (streaming)
