# Lab 2 -- HDFS

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

เรียนรู้คำสั่งพื้นฐานของ HDFS (Hadoop Distributed File System) -- ระบบ
ไฟล์แบบกระจายที่เป็นหัวใจของ Hadoop ทุกอย่างใน Big Data ecosystem
(MapReduce, Hive, Spark) อ่าน/เขียนข้อมูลผ่านระบบนี้

ของเก่า (คอร์ส Cloudera) ใช้โฟลเดอร์ `/user/cloudera` สำหรับเก็บไฟล์ของ
ผู้ใช้ แต่ sandbox นี้ใช้ **`/user/student`** แทน (ชื่อผู้ใช้ Linux ใน
container คือ `student`)

## ก่อนเริ่ม

เข้าไปใน container ก่อน (ถ้ายังไม่ได้เข้า):

```bash
docker compose exec bigdata bash
```

## ขั้นตอนที่ 1: เตรียมไฟล์ตัวอย่าง

ไฟล์ตัวอย่างที่จะใช้คือ `PG2600.txt` (หนังสือ "War and Peace" จาก
Project Gutenberg แปลงเป็น text ล้วน ขนาดประมาณ 3 MB) ถูกเก็บไว้ใน image
แล้วที่ `/course/datasets/` ไม่ต้องดาวน์โหลดจากอินเทอร์เน็ต:

```bash
cp /course/datasets/PG2600.txt ~/PG2600.txt
```

คำสั่งนี้คัดลอกไฟล์จากตำแหน่งกลาง (`/course/datasets`) มาไว้ที่โฟลเดอร์
บ้านของคุณ (`~` คือ `/home/student`) เผื่อจะแก้ไข/ใช้ซ้ำในขั้นตอนอื่น

## ขั้นตอนที่ 2: สร้างโฟลเดอร์ใน HDFS

```bash
hadoop fs -mkdir -p /user/student/input
```

- `hadoop fs` คือคำสั่งหลักสำหรับสั่งงาน HDFS (มีหน้าตาคล้าย Linux `ls`,
  `mkdir`, `cp` แต่ทำงานกับ HDFS แทน filesystem ปกติของเครื่อง)
- `-mkdir` สร้างโฟลเดอร์
- `-p` แปลว่าสร้างโฟลเดอร์แม่ (`/user/student`) ให้อัตโนมัติถ้ายังไม่มี
  (เหมือน `mkdir -p` ใน Linux ปกติ)

## ขั้นตอนที่ 3: อัปโหลดไฟล์เข้า HDFS

```bash
hadoop fs -put PG2600.txt /user/student/input/
```

`-put` คือคำสั่งอัปโหลดไฟล์จากเครื่อง (local filesystem ของ container)
เข้าไปใน HDFS -- นี่คือขั้นตอนสำคัญที่สุดของ lab นี้: **ข้อมูลต้องอยู่ใน
HDFS ก่อน ถึงจะให้ MapReduce/Hive/Spark ประมวลผลได้**

## ขั้นตอนที่ 4: ตรวจสอบว่าอัปโหลดสำเร็จ

```bash
hadoop fs -ls /user/student/input
```

ผลลัพธ์ที่ควรเห็น (ตัวเลขวันที่/ขนาดไฟล์อาจต่างกันไป):

```text
Found 1 items
-rw-r--r--   1 student supergroup    3258392 2026-09-17 10:00 /user/student/input/PG2600.txt
```

ถ้าเห็นแบบนี้แปลว่าไฟล์อยู่ใน HDFS จริงแล้ว (ไม่ใช่แค่ในเครื่อง)

## ขั้นตอนที่ 5: อ่านไฟล์จาก HDFS

```bash
hadoop fs -cat /user/student/input/PG2600.txt | head -20
```

`-cat` พิมพ์เนื้อหาไฟล์ออกมา (เหมือน `cat` ของ Linux) แต่ดึงข้อมูลมาจาก
HDFS ต่อท่อ (`|`) เข้า `head -20` เพื่อดูแค่ 20 บรรทัดแรก (ไฟล์เต็มยาวเกิน
จะเลื่อนไม่ทัน) ควรเห็นข้อความภาษาอังกฤษเปิดเรื่อง War and Peace

## ขั้นตอนที่ 6 (ทางเลือก): ลบและอัปโหลดใหม่

เผื่อกรณีอยากล้างแล้วเริ่มใหม่:

```bash
hadoop fs -rm /user/student/input/*
hadoop fs -put PG2600.txt /user/student/input/
```

`-rm` ลบไฟล์ใน HDFS (ไม่ใช่ลบไฟล์ในเครื่อง -- `~/PG2600.txt` ยังอยู่)

## ดู Web UI ของ NameNode

เปิด browser ไปที่ http://localhost:9870 จะเห็นหน้าเว็บแสดงสถานะ HDFS
(พื้นที่ใช้ไป, DataNode ที่เชื่อมต่ออยู่, browse ไฟล์ได้ผ่านเมนู
**Utilities -> Browse the file system**)

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `mkdir: Cannot create directory ... Name node is in safe mode` | HDFS เพิ่งเปิดยังไม่พร้อม รอสัก 30 วินาทีแล้วลองใหม่ หรือเช็คด้วย `hdfs dfsadmin -safemode get` |
| `No such file or directory` ตอน `-put` | เช็คว่าคุณ `cp` ไฟล์จาก `/course/datasets/` มาที่ `~/PG2600.txt` ในขั้นตอนที่ 1 แล้วจริง ด้วย `ls ~/PG2600.txt` |

## สรุป

ตอนนี้คุณมีไฟล์อยู่ใน HDFS ที่ `/user/student/input/PG2600.txt` แล้ว --
lab ถัดไป (**Lab 3 -- MapReduce**) จะใช้ไฟล์นี้ตัวเดียวกันมาทำ WordCount
