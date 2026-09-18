# Lab 6 -- Apache Flume (แนวคิด Ingestion แบบเก่า)

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

Flume ยังติดตั้งอยู่ใน image นี้ (`/opt/flume`) เพราะติดตั้งง่ายและเสถียร
ดี และแนวคิดที่มันสอน -- **agent** ที่รันค้างไว้ตลอดเวลา คอยรับข้อมูล
ที่ไหลเข้ามาแล้วส่งเข้า HDFS ผ่าน pipeline แบบ source/channel/sink -- ยัง
มีประโยชน์ให้เห็นภาพ แม้ตัว Flume เองจะไม่มีการพัฒนาต่อจากทีมต้นน้ำแล้วก็
ตาม ให้มอง lab นี้เป็น **แนวคิด ingestion แบบเก่า** ไม่ใช่เครื่องมือที่
แนะนำให้ใช้จริงในปัจจุบัน

> **Lab 7 -- Kafka** คือตัวทดแทนสมัยใหม่ของบทบาท "agent" นี้ ทำ lab นี้
> ก่อนแล้วค่อยไปเทียบกับ Kafka จะเห็นภาพชัดว่าทำไมวงการถึงเปลี่ยนมาใช้
> Kafka แทน

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

## ขั้นตอนที่ 1: อ่าน config ก่อนเริ่ม

ก่อนสั่งรัน agent ดูก่อนว่ากำลังจะรันอะไร นี่คือ pipeline ทั้งหมดที่
กำหนดไว้:

```bash
cat /opt/flume/conf/flume.conf
```

```properties
agent.sources = netsource
agent.sinks = hdfssink
agent.channels = memorychannel

agent.sources.netsource.type = netcat
agent.sources.netsource.bind = localhost
agent.sources.netsource.port = 3030
agent.sources.netsource.interceptors = ts
agent.sources.netsource.interceptors.ts.type = org.apache.flume.interceptor.TimestampInterceptor$Builder

agent.sinks.hdfssink.type = hdfs
agent.sinks.hdfssink.hdfs.path = hdfs://localhost:9000/user/student/flume/events
agent.sinks.hdfssink.hdfs.filePrefix = log
agent.sinks.hdfssink.hdfs.rollInterval = 0
agent.sinks.hdfssink.hdfs.rollCount = 5
agent.sinks.hdfssink.hdfs.fileType = DataStream

agent.channels.memorychannel.type = memory
agent.channels.memorychannel.capacity = 100
agent.channels.memorychannel.transactionCapacity = 100

agent.sources.netsource.channels = memorychannel
agent.sinks.hdfssink.channel = memorychannel
```

อ่านทีละส่วนตามแนวคิด 3 ส่วนของทุก Flume agent:

- **Source** (`agent.sources.netsource`): ข้อมูลเข้าทางไหน ชนิด `netcat`
  แปลว่า "ฟัง TCP port แล้วถือว่าแต่ละบรรทัดข้อความคือ 1 event" -- ในที่
  นี้คือ port `3030` บน `localhost`
- **Channel** (`agent.channels.memorychannel`): บัฟเฟอร์กลางระหว่าง
  source กับ sink ชนิด `memory` แปลว่า event ค้างอยู่ใน RAM จนกว่า sink
  จะดึงไปเขียนต่อ (ความจุ 100 event -- ถ้า sink เขียนตามไม่ทันจน channel
  เต็ม source จะหยุดรับข้อมูลใหม่ชั่วคราว) ยังมีชนิด `file` ให้เลือกด้วย
  สำหรับกรณีที่รับไม่ได้ถ้า event ที่ค้างอยู่หายไปตอนเครื่องล่ม
- **Sink** (`agent.sinks.hdfssink`): ข้อมูลออกไปที่ไหน ชนิด `hdfs` เขียน
  ไปที่ `hdfs.path` -- สังเกตว่าเป็น URI แบบ `hdfs://` เต็มรูปแบบ ไม่ใช่
  path ธรรมดาบนเครื่อง `rollCount = 5` แปลว่าปิดไฟล์ผลลัพธ์ปัจจุบันแล้ว
  เปิดไฟล์ใหม่ทุก ๆ 5 event (งานจริงมักตั้งให้ roll ตามขนาดไฟล์หรือเวลา
  แทน เพื่อให้ได้ batch ที่ใหญ่กว่านี้)

สองบรรทัดสุดท้าย (`agent.sources.netsource.channels = ...` และ
`agent.sinks.hdfssink.channel = ...`) คือส่วนที่เชื่อม source -> channel
-> sink เข้าด้วยกันจริง ๆ ถ้าไม่มีสองบรรทัดนี้ สามส่วนข้างบนจะแค่ถูก
ประกาศไว้เฉย ๆ ไม่ได้เชื่อมต่อกัน

## ขั้นตอนที่ 2: เปิด core ให้พร้อมก่อน

Flume ต้องเขียนข้อมูลลง HDFS ดังนั้น HDFS ต้องรันอยู่ (ปกติเปิดอัตโนมัติ
อยู่แล้ว เช็คได้ด้วย `labctl status`)

## ขั้นตอนที่ 3: เปิด terminal สองหน้าต่าง

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

## ขั้นตอนที่ 4: ส่งข้อมูลเข้าไปทดสอบ

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

## ขั้นตอนที่ 5: ตรวจสอบว่าข้อมูลไปถึง HDFS

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
| `nc: connect to localhost port 3030 ... Connection refused` | Flume agent (Terminal 1) ยังไม่เปิด หรือปิดไปแล้ว เปิดใหม่ตามขั้นตอนที่ 3 |
| `hadoop fs -ls` บอกว่าไม่มีไฟล์ | ยังไม่ได้พิมพ์อะไรผ่าน `nc` เลย หรือ Flume ยังไม่ flush ข้อมูลลง HDFS (รอสักครู่แล้วลองใหม่) |

## สรุป

คุณเห็นภาพ pipeline แบบ streaming ingestion (source -> channel -> sink)
แล้ว รวมถึงอ่าน config ไฟล์เดียวที่นิยาม pipeline ทั้งหมดได้เอง -- ไปต่อ
ที่ **Lab 7 -- Kafka** เพื่อดูว่าเครื่องมือสมัยใหม่แก้ปัญหาเดียวกันนี้
ต่างออกไปอย่างไร (และทำไมถึงมาแทน Flume ในงานจริง)
