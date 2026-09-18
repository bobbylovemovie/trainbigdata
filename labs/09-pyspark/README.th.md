# Lab 9 -- Spark / PySpark

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

เรียนรู้ Apache Spark ผ่าน Python (PySpark) -- เครื่องมือประมวลผลข้อมูล
ขนาดใหญ่ที่เร็วกว่า MapReduce ดั้งเดิมมาก (ประมวลผลในหน่วยความจำเป็นหลัก
แทนที่จะเขียน/อ่านดิสก์ทุกขั้นตอนแบบ MapReduce) และเขียนโค้ดสั้นกว่า
MapReduce มาก (lab 3 ใช้ Java เต็มไฟล์ ในขณะที่ lab นี้ใช้ Python 3-4
บรรทัด)

## ขั้นตอนที่ 1: เปิด PySpark shell แบบ interactive

```bash
pyspark
```

จะเห็นโลโก้ ASCII ของ Spark ขึ้นมา แล้ว prompt เปลี่ยนเป็น `>>>` (Python
interactive shell ปกติ) แต่มีตัวแปรพิเศษ `sc` (SparkContext) และ `spark`
(SparkSession) เตรียมไว้ให้อัตโนมัติแล้ว ไม่ต้องสร้างเอง

## ขั้นตอนที่ 2: ทำ WordCount แบบ interactive

พิมพ์ทีละบรรทัดใน shell:

```python
from operator import add

file = sc.textFile("hdfs:///user/student/input/PG2600.txt")

wc = (
    file.flatMap(lambda x: x.split())
        .map(lambda x: (x, 1))
        .reduceByKey(add)
)

wc.take(20)
```

อธิบายทีละขั้น:

- `sc.textFile(...)` อ่านไฟล์จาก HDFS เข้ามาเป็น RDD (Resilient
  Distributed Dataset -- โครงสร้างข้อมูลพื้นฐานของ Spark ที่กระจายอยู่
  หลาย partition) ต้องมีไฟล์นี้ใน HDFS แล้ว (ทำ lab 2 มาก่อน)
- `.flatMap(lambda x: x.split())` แยกแต่ละบรรทัดออกเป็นคำ ๆ (เหมือน
  Map step ของ MapReduce)
- `.map(lambda x: (x, 1))` แปลงแต่ละคำให้เป็นคู่ `(คำ, 1)`
- `.reduceByKey(add)` รวมค่าของคำที่ซ้ำกัน (บวกเลข 1 เข้าด้วยกัน) --
  เทียบเท่ากับ Reduce step ของ MapReduce
- `.take(20)` ดึงผลลัพธ์ 20 รายการแรกออกมาแสดง (คำสั่งที่ทำให้ Spark
  ประมวลผลจริง -- ก่อนหน้านี้ทุกบรรทัดเป็นแค่การ "วางแผน" ยังไม่รันจริง
  จนกว่าจะมีคำสั่งแบบนี้เรียกใช้ผลลัพธ์)

ควรเห็น list ของคู่ `(คำ, จำนวนครั้ง)` แสดงออกมา 20 รายการ

ออกจาก shell ด้วย:

```python
exit()
```

## ขั้นตอนที่ 3: รันแบบไม่ interactive (spark-submit)

การพิมพ์ทีละบรรทัดเหมาะกับตอนทดลอง แต่งานจริงมักเขียนเป็นไฟล์ `.py`
แล้วสั่งรันทีเดียว โฟลเดอร์นี้มี `wordcount.py` ที่ทำสิ่งเดียวกับ
ขั้นตอนที่ 2 ไว้ให้แล้ว:

```bash
spark-submit ~/labs/09-pyspark/wordcount.py hdfs:///user/student/input/PG2600.txt
```

พารามิเตอร์ท้ายคำสั่งคือ path ไฟล์ HDFS ที่จะให้ประมวลผล (ถ้าไม่ใส่ จะใช้
ค่า default เดียวกันนี้อัตโนมัติ)

## ขั้นตอนที่ 4 (เสริม): ลองแบบ Scala ด้วย

Spark ใช้ได้ทั้ง Python และ Scala เนื้อหาเดียวกันเขียนด้วย Scala:

```bash
spark-shell
```

```scala
val file = sc.textFile("hdfs:///user/student/input/PG2600.txt")
val wc = file.flatMap(_.split(" ")).map((_, 1)).reduceByKey(_ + _)
wc.take(20).foreach(println)
```

ออกจาก shell ด้วย `:quit` หรือ Ctrl+D

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `Path does not exist: hdfs://.../PG2600.txt` | ยังไม่ได้ทำ lab 2 (อัปโหลดไฟล์เข้า HDFS) มาก่อน |
| `pyspark` ค้างนานตอนเริ่ม | ปกติถ้าเป็นครั้งแรกหลัง container เพิ่งเปิด (JVM ต้อง warm up) รอสักครู่ |

## สรุป

คุณทำ WordCount ด้วย Spark สำเร็จแล้วทั้งแบบ interactive และแบบ script
พร้อมเห็นว่าโค้ดสั้นกว่า MapReduce (lab 3) มาก แต่ทำงานบนหลักการเดียวกัน
lab ถัดไป (**Lab 10 -- Spark SQL**) จะสอนวิธีใช้ SQL แทน RDD API แบบนี้
