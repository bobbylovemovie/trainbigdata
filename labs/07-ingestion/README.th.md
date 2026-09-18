# Lab 7 -- Apache Flume (แนวคิด Ingestion แบบเก่า)

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

Flume ยังติดตั้งอยู่ใน image นี้ (`/opt/flume`) เพราะติดตั้งง่ายและเสถียร
ดี และแนวคิดที่มันสอน -- **agent** ที่รันค้างไว้ตลอดเวลา คอยรับข้อมูล
ที่ไหลเข้ามาแล้วส่งเข้า HDFS ผ่าน pipeline แบบ source/channel/sink -- ยัง
มีประโยชน์ให้เห็นภาพ แม้ตัว Flume เองจะไม่มีการพัฒนาต่อจากทีมต้นน้ำแล้วก็
ตาม ให้มอง lab นี้เป็น **แนวคิด ingestion แบบเก่า** ไม่ใช่เครื่องมือที่
แนะนำให้ใช้จริงในปัจจุบัน

> ถ้าอยากได้ตัวอย่าง streaming ingestion แบบสมัยใหม่ในอนาคต **Apache
> Kafka** คือตัวทดแทนที่เหมาะกับบทบาทของ "agent" นี้ ยังไม่เพิ่มเข้ามาใน
> เฟสนี้เพื่อรักษาขนาดของ sandbox ให้เล็กที่สุดเท่าที่จำเป็น

## แนวคิด pipeline ของ Flume

```text
คุณพิมพ์ข้อความผ่าน telnet/nc (source)
        |
        v
Flume agent (channel เก็บบัฟเฟอร์ไว้ชั่วคราวในหน่วยความจำ)
        |
        v
เขียนลง HDFS (sink) แบบต่อเนื่อง
```

## ขั้นตอนที่ 1: เปิด core ให้พร้อมก่อน

Flume ต้องเขียนข้อมูลลง HDFS ดังนั้น HDFS ต้องรันอยู่ (ปกติเปิดอัตโนมัติ
อยู่แล้ว เช็คได้ด้วย `labctl status`)

## ขั้นตอนที่ 2: เปิด terminal สองหน้าต่าง

lab นี้ต้องใช้ 2 terminal พร้อมกัน (ทั้งสองหน้าต่างต้อง `docker compose
exec bigdata bash` เข้ามาแยกกันคนละหน้าต่าง)

**Terminal ที่ 1 -- เปิด Flume agent:**

```bash
flume-ng agent \
    --conf /opt/flume/conf \
    --conf-file /opt/flume/conf/flume.conf \
    --name agent -Dflume.root.logger=INFO,console
```

จะเห็น log พิมพ์ต่อเนื่องไม่หยุด (agent รอรับข้อมูลอยู่) **ปล่อยหน้าต่าง
นี้ทิ้งไว้แบบนี้ ไม่ต้องปิด**

## ขั้นตอนที่ 3: ส่งข้อมูลเข้าไปทดสอบ

**Terminal ที่ 2 -- เชื่อมต่อผ่าน netcat:**

```bash
nc localhost 3030
```

พิมพ์ข้อความอะไรก็ได้แล้วกด Enter เช่น:

```text
hello flume
this is a test line
```

ทุกบรรทัดที่พิมพ์จะถูกส่งไปที่ Flume agent (Terminal ที่ 1 จะมี log ขึ้น
ตอนรับ event ใหม่) กด `Ctrl+C` เพื่อออกจาก `nc` เมื่อพิมพ์ทดสอบพอแล้ว

## ขั้นตอนที่ 4: ตรวจสอบว่าข้อมูลไปถึง HDFS

กลับมาที่ Terminal ไหนก็ได้ (เปิดหน้าต่างที่ 3 หรือ `Ctrl+C` ที่ Terminal
1 เพื่อหยุด agent ก่อนก็ได้ ถ้าอยากดูผลลัพธ์):

```bash
hadoop fs -ls /user/student/flume/events
hadoop fs -cat /user/student/flume/events/*
```

ควรเห็นข้อความที่พิมพ์ไปใน Terminal ที่ 2 ปรากฏอยู่ในไฟล์ที่ Flume เขียน
ลง HDFS ให้อัตโนมัติ

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `nc: connect to localhost port 3030 ... Connection refused` | Flume agent (Terminal 1) ยังไม่เปิด หรือปิดไปแล้ว เปิดใหม่ตามขั้นตอนที่ 2 |
| `hadoop fs -ls` บอกว่าไม่มีไฟล์ | ยังไม่ได้พิมพ์อะไรผ่าน `nc` เลย หรือ Flume ยังไม่ flush ข้อมูลลง HDFS (รอสักครู่แล้วลองใหม่) |

## สรุป

คุณเห็นภาพ pipeline แบบ streaming ingestion (source -> channel -> sink)
แล้ว -- แนวคิดเดียวกันนี้คือรากฐานของระบบ ingestion สมัยใหม่อย่าง Kafka
Connect ด้วยเช่นกัน ไปต่อที่ **Lab 8 -- RDBMS Ingestion** ซึ่งเป็นแนวทาง
สมัยใหม่กว่าสำหรับการดึงข้อมูลเข้า Hadoop
