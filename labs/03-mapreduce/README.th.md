# Lab 3 -- MapReduce

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

รันโปรแกรม **WordCount** ตัวอย่างคลาสสิกของ MapReduce -- นับจำนวนคำแต่ละ
คำที่ปรากฏในไฟล์ข้อความ โดยให้ YARN เป็นตัวจัดสรรทรัพยากรและรันงานแบบ
กระจาย (distributed) จริง ไม่ใช่แค่ script เดี่ยว ๆ

> jar ตัวเดิมจากคอร์ส Cloudera (`org.myorg.WordCount`, คอมไพล์ปี 2013 ด้วย
> Hadoop API รุ่นเก่ามาก) เก็บไว้อ้างอิงที่ `legacy/HDFS/wordcount.jar`
> เท่านั้น ตัวที่ใช้จริงใน lab นี้คือเวอร์ชันใหม่ที่เขียนด้วย Hadoop
> MapReduce API ปัจจุบัน (ดูซอร์สได้ที่ `WordCount.java` ในโฟลเดอร์นี้)
> ซึ่งถูก compile ไว้ล่วงหน้าเป็น `wordcount.jar` ตั้งแต่ตอน build image
> แล้ว ไม่ต้อง compile เอง

## ก่อนเริ่ม

ต้องทำ **Lab 2 -- HDFS** ให้เสร็จก่อน (ต้องมีไฟล์ `PG2600.txt` อยู่ใน
HDFS แล้ว) และต้องเข้า container อยู่:

```bash
docker compose exec bigdata bash
```

## ขั้นตอนที่ 1: เตรียมข้อมูลนำเข้า (ถ้ายังไม่ได้ทำ Lab 2)

```bash
hadoop fs -mkdir -p /user/student/input
hadoop fs -put -f /course/datasets/PG2600.txt /user/student/input/
```

`-f` (force) แปลว่าเขียนทับได้เลยถ้ามีไฟล์ชื่อนี้อยู่แล้ว ปลอดภัยที่จะรัน
ซ้ำได้แม้ทำ Lab 2 ไปแล้ว

## ขั้นตอนที่ 2: รันงาน MapReduce

```bash
hadoop jar ~/labs/03-mapreduce/wordcount.jar WordCount \
    /user/student/input /user/student/output/wordcount
```

อธิบายทีละส่วน:

- `hadoop jar <ไฟล์.jar> <ชื่อ class หลัก>` คือรูปแบบคำสั่งมาตรฐานสำหรับ
  สั่งรันโปรแกรม Java บน Hadoop
- `~/labs/03-mapreduce/wordcount.jar` คือไฟล์โปรแกรมที่ compile ไว้แล้ว
- `WordCount` คือชื่อ class ที่มีฟังก์ชัน `main()` อยู่ข้างใน jar
- พารามิเตอร์ตัวแรก (`/user/student/input`) คือ**โฟลเดอร์ข้อมูลนำเข้า**
  ใน HDFS (ต้องเป็นโฟลเดอร์ ไม่ใช่ไฟล์เดี่ยว เพราะ Hadoop จะอ่านทุกไฟล์
  ข้างในโฟลเดอร์นั้น)
- พารามิเตอร์ตัวที่สอง (`/user/student/output/wordcount`) คือ**โฟลเดอร์
  ผลลัพธ์** -- **ห้ามมีอยู่ก่อนแล้ว** ไม่งั้น Hadoop จะ error (เพื่อกัน
  การเขียนทับผลลัพธ์เก่าโดยไม่ตั้งใจ) ถ้ารันซ้ำต้องลบโฟลเดอร์เก่าก่อน
  (ดูขั้นตอนที่ 4)

ระหว่างรัน จะเห็น log ยาว ๆ พิมพ์ความคืบหน้าเป็นเปอร์เซ็นต์ของ map และ
reduce เช่น `map 100% reduce 100%` เมื่อจบจะขึ้นสรุปสถิติของงาน (จำนวน
บรรทัดที่ประมวลผล, เวลาที่ใช้ ฯลฯ)

## ขั้นตอนที่ 3: ดูผลลัพธ์

```bash
hadoop fs -cat /user/student/output/wordcount/part-r-00000 | head -20
```

`part-r-00000` คือไฟล์ผลลัพธ์จาก reducer ตัวที่ 0 (งานเล็กแบบนี้มักมี
reducer แค่ตัวเดียว ไฟล์เดียว) เนื้อหาข้างในเป็นคู่ `คำ<tab>จำนวนครั้ง`
เรียงตามลำดับตัวอักษร เช่น:

```text
"'A     1
"'ARE    1
"'About  1
```

## ขั้นตอนที่ 4: รันซ้ำ (ต้องลบผลลัพธ์เก่าก่อน)

```bash
hadoop fs -rm -r /user/student/output/wordcount
hadoop jar ~/labs/03-mapreduce/wordcount.jar WordCount \
    /user/student/input /user/student/output/wordcount
```

`-rm -r` ลบทั้งโฟลเดอร์แบบ recursive (ลบทุกไฟล์ข้างในด้วย)

## ดู job ที่รันบน YARN

เปิด browser ไปที่ http://localhost:8088 จะเห็นรายการ Application ที่
เคยรัน (สถานะ FINISHED/SUCCEEDED) คลิกเข้าไปดูรายละเอียด: จำนวน map/reduce
task, เวลาที่ใช้แต่ละ task, log ของแต่ละ task ได้ด้วย -- มีประโยชน์มากตอน
งานมีปัญหาแล้วอยากรู้ว่า task ไหน error

## (เสริม) คอมไพล์ jar เองใหม่

ถ้าอยากแก้โค้ด `WordCount.java` แล้วลองรันเวอร์ชันของตัวเอง:

```bash
cd ~/labs/03-mapreduce
javac -classpath "$(hadoop classpath)" -d /tmp/wc-classes WordCount.java
jar -cvf wordcount.jar -C /tmp/wc-classes .
```

`hadoop classpath` คือคำสั่งที่คืนค่า path ของ jar ไลบรารีทั้งหมดที่
Hadoop ต้องใช้ตอน compile (จำเป็นเพราะ `WordCount.java` เรียกใช้ class
จากไลบรารี Hadoop เช่น `Mapper`, `Reducer`)

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `org.apache.hadoop.mapred.FileAlreadyExistsException: Output directory ... already exists` | โฟลเดอร์ผลลัพธ์มีอยู่แล้ว ลบด้วย `hadoop fs -rm -r /user/student/output/wordcount` ก่อนรันใหม่ |
| `No such file or directory` ตอนอ่าน input | ยังไม่ได้ทำ Lab 2 หรือยังไม่ได้อัปโหลดไฟล์ตามขั้นตอนที่ 1 |
| งานค้างนาน ไม่จบสักที | เช็ค YARN UI (http://localhost:8088) ว่ามี Application อื่นค้างอยู่ไหม ทรัพยากร (memory) อาจไม่พอ ลองปิด HBase/Hive ที่ไม่ได้ใช้ด้วย `labctl stop hbase` / `labctl stop hive` |

## สรุป

คุณเพิ่งรันงาน MapReduce แบบกระจายจริงบน YARN สำเร็จแล้ว นี่คือรากฐานของ
ทุกอย่างใน Hadoop ecosystem -- Hive และ Spark ที่จะเรียนต่อไปก็ทำงานบน
หลักการเดียวกันนี้ (แค่มี layer ที่เขียนโค้ดง่ายกว่าครอบไว้)
