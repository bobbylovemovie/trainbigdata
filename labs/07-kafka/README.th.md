# Lab 7 -- Apache Kafka

**ภาษาไทย** | [English](README.md)

## ทำไม Lab 6 เดิม (Impala) ถึงถูกแทนที่

คอร์สเดิมสมัย Cloudera มี Impala อยู่ตรงนี้ แต่ตัดสินใจ**ตัดออกไปเลย**
ไม่เก็บไว้เป็นแค่เอกสารอ้างอิงด้วยซ้ำ เพราะ Impala ผูกติดกับการแพ็กเกจของ
Cloudera ค่อนข้างแน่น ต้องเพิ่ม daemon ระดับ JVM อีกหลายตัว (catalogd,
statestored, impalad) พร้อมระบบแคช metadata ของตัวเองซ้อนทับ Hive
metastore ตัวเดิม -- เป็นภาระหนักเกินไปสำหรับ sandbox แบบ single-node ที่
เน้นการเรียนรู้ ในขณะที่เป้าหมายการเรียนรู้เดิม ("SQL แบบ interactive ที่
เร็ว") ถูกครอบคลุมอยู่แล้วโดย Hive/Beeline (Lab 5) และ Spark SQL (Lab 10)
ถ้าต้องการ SQL engine เฉพาะทางที่เร็วในอนาคต **Trino**
(https://trino.io) คือตัวทดแทนสมัยใหม่ที่เหมาะสม -- ยังไม่ได้ทำใน lab นี้

ส่วน **Kafka** คือตัวทดแทนสมัยใหม่โดยตรงของสิ่งที่ **Lab 6 -- Flume**
สอนไว้: process ที่รันค้างไว้ตลอดเวลาเพื่อรับข้อมูลที่ไหลเข้ามาต่อเนื่อง
ถ้ายังไม่ได้ทำ Lab 6 แนะนำให้ทำก่อน -- lab นี้จะเข้าใจง่ายขึ้นมากถ้าเอาไป
เทียบกับ Flume

## Kafka กับ Flume ต่างกันยังไง (ภาพเดียวจบ)

```text
Flume:  producer -> agent (source/channel/sink) -> ปลายทางเดียว (HDFS)

Kafka:  producer -> topic (log ที่คงทน ทำสำเนาไว้) -> ผู้บริโภคหลายราย
                                                       แต่ละรายอ่านอิสระ
                                                       ต่อกัน เล่นซ้ำได้
```

จุดต่างหลัก: channel ของ Flume เป็นแค่บัฟเฟอร์ชั่วคราว มีไว้ส่งข้อมูล
จาก source ไปยัง sink ที่ตั้งค่าไว้ตัวเดียวเท่านั้น ส่วน topic ของ Kafka
คือ **log ที่คงทน** (durable log) ที่ consumer อ่านได้อิสระ ตามจังหวะของ
ตัวเอง และ**เล่นย้อนกลับจากจุดเริ่มต้นได้ทุกเมื่อ** นี่คือเหตุผลที่ Kafka
ใช้เป็น message bus กลางที่มี consumer อิสระหลายตัวพร้อมกันได้ (เช่น งาน
หนึ่งโหลดเข้า HDFS, อีกงานคอย alert, อีกงานป้อน dashboard) แทนที่จะเป็น
pipeline ตายตัวเส้นเดียวแบบ Flume

sandbox นี้รัน Kafka แบบ **KRaft mode** -- Kafka จัดการ metadata ของ
ตัวเองภายใน ไม่ต้องมี process ZooKeeper แยกต่างหาก (เป็นค่า default
สมัยใหม่ตั้งแต่ Kafka 3.x และเป็นโหมดเดียวที่ Kafka 4.x รองรับด้วย)

## ขั้นตอนที่ 1: เปิด Kafka

```bash
docker compose exec bigdata labctl start kafka
```

Kafka ต้องการ Java 11 ขึ้นไป (ของทุกอย่างในสมอกอื่นในคอร์สนี้ตรึงไว้ที่
Java 8 เพื่อความเข้ากันได้กับ Hive -- ดู README หัวข้อ "เวอร์ชันที่
เลือกใช้") ดังนั้น `JAVA_HOME` ของมันถูกตั้งแยกไว้แล้วโดย
`labctl`/supervisord ไม่ต้องทำอะไรเพิ่มเอง เช็คว่าเปิดสำเร็จ:

```bash
docker compose exec bigdata labctl status
```

ควรเห็น `Kafka           RUNNING`

## ขั้นตอนที่ 2: สร้าง topic

```bash
export JAVA_HOME=/usr/lib/jvm/default-java11
kafka-topics.sh --bootstrap-server localhost:9092 \
    --create --topic student-events --partitions 1 --replication-factor 1
```

> คำสั่ง `kafka-*.sh` ทุกตัวใน lab นี้ต้อง export `JAVA_HOME` แบบเดียวกัน
> นี้ก่อนเสมอ (ของอื่นในคอร์สนี้ไม่ต้อง เฉพาะ CLI tool ของ Kafka เท่านั้น)
> ถ้าเปิด terminal ใหม่ ต้อง export ซ้ำอีกครั้ง

`--partitions 1` ใช้ค่าน้อยสุดเพื่อความง่ายตอนสาธิต งานจริงมักใช้หลาย
partition เพื่อกระจายงานให้ consumer หลายตัวทำงานคู่ขนานกันได้
`--replication-factor 1` ถูกต้องแล้วสำหรับที่นี่เพราะมี broker เดียว --
Kafka cluster งานจริงมักใช้ 3

ดูรายชื่อ topic เพื่อยืนยัน:

```bash
kafka-topics.sh --bootstrap-server localhost:9092 --list
```

ดูรายละเอียด (partition, leader, replica):

```bash
kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic student-events
```

## ขั้นตอนที่ 3: ส่งข้อความ (produce)

```bash
kafka-console-producer.sh --bootstrap-server localhost:9092 --topic student-events
```

โหมดนี้เป็นแบบ interactive -- พิมพ์ข้อความ กด Enter ก็ถูก publish ทันที
ลองพิมพ์สักสองสามบรรทัด:

```text
hello kafka
this is message two
event three
```

กด `Ctrl+D` (หรือ `Ctrl+C`) เพื่อออกจาก producer เมื่อพิมพ์เสร็จ

## ขั้นตอนที่ 4: อ่านข้อความ (consume)

เปิด **terminal ที่สอง** (`docker compose exec bigdata bash` แล้ว
`export JAVA_HOME=/usr/lib/jvm/default-java11` อีกครั้ง):

```bash
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic student-events --from-beginning
```

`--from-beginning` เล่นย้อนกลับทุกข้อความที่เคย publish เข้า topic นี้
ทั้งหมด ไม่ใช่แค่ข้อความใหม่ -- **นี่คือความต่างสำคัญจาก netcat source
ของ Flume** ซึ่งเห็นแค่ข้อมูลที่ส่งมาตอนที่มันเชื่อมต่ออยู่เท่านั้น Kafka
เก็บ log ไว้ (ตั้งค่า `log.retention.hours=24` ใน sandbox นี้) ดังนั้น
consumer ที่เริ่มช้า หรือ restart ใหม่ ก็ไม่เสียข้อมูลไปเลย

ปล่อย consumer นี้ให้รันค้างไว้ แล้วกลับไปที่ **Terminal 1** ส่งข้อความ
เพิ่มอีกสองสามข้อความ -- ดูมันโผล่ขึ้นที่ terminal consumer แบบ real-time
กด `Ctrl+C` เพื่อหยุด consume

## ขั้นตอนที่ 5: ดูพฤติกรรม replay ด้วยตาตัวเอง

หยุด consumer (`Ctrl+C`) แล้วเปิดใหม่ด้วยคำสั่งเดิม:

```bash
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic student-events --from-beginning
```

**ข้อความทุกตัวจาก ขั้นตอนที่ 3 โผล่ขึ้นมาอีกครั้ง** เรียงลำดับเดิม แม้
consumer จะเป็น process ใหม่เอี่ยมก็ตาม นี่คือพฤติกรรม durable-log ที่
channel แบบ in-memory ของ Flume ให้ไม่ได้เลย -- channel ของ Flume เป็นแค่
บัฟเฟอร์ที่ว่างเปล่าทันทีที่ sink ดึงข้อมูลออกไปหมด ไม่มีอะไรเหลือให้
เล่นซ้ำ

ลองอีกรอบแบบ**ไม่ใส่** `--from-beginning`:

```bash
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic student-events
```

จะไม่มีอะไรขึ้นเลยจนกว่าจะ produce ข้อความใหม่ -- ถ้าไม่ใส่
`--from-beginning` consumer จะเห็นแค่ข้อความที่ publish *หลังจาก* ที่
เชื่อมต่อเท่านั้น (นี่คือค่า default และตรงกับพฤติกรรมของ consumer ส่วน
ใหญ่ในงานจริง: มันจำตำแหน่งของตัวเองไว้ สนใจแค่ข้อมูลใหม่)

## ขั้นตอนที่ 6: ล้างข้อมูล

```bash
kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic student-events
```

## ปิด Kafka เมื่อทำเสร็จแล้ว

```bash
docker compose exec bigdata labctl stop kafka
```

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `kafka-topics.sh: command not found` | ลืม `export JAVA_HOME=/usr/lib/jvm/default-java11` ก่อน หรือ Kafka ไม่อยู่ใน `PATH` ของ shell ใหม่ -- ลองใช้ path เต็ม `/opt/kafka/bin/kafka-topics.sh` แทน |
| `Error: A JNI error has occurred` / error เรื่องเวอร์ชัน | ลืม export `JAVA_HOME` ตามข้างบน -- ถ้าไม่ตั้ง script ของ Kafka จะไปใช้ Java 8 ของ container ซึ่ง Kafka 3.x ปฏิเสธ |
| `Connection to node -1 could not be established` | Kafka ยังเปิดไม่เสร็จ เช็คด้วย `labctl status` ว่าขึ้น `Kafka RUNNING` แล้วหรือยัง ถ้าเพิ่งเปิด รอสัก 10-15 วินาทีแล้วลองใหม่ |

## สรุป

คุณเห็นเหตุผลหลักที่ Kafka มาแทน Flume ในบทบาทนี้แล้ว: **log ที่คงทน
เล่นซ้ำได้** พร้อม consumer อิสระหลายตัว แทนที่จะเป็นบัฟเฟอร์ใช้ครั้ง
เดียวที่ต่อสายตรงไปปลายทางเดียว แนวคิดเดียวกันนี้คือรากฐานของ Kafka
Connect (connector แบบ source/sink ที่มาแทนงานที่ Flume agent เคยทำ) และ
การป้อนข้อมูลเข้า Spark Structured Streaming (Lab 11) จาก Kafka topic
แทนที่จะเป็น socket ดิบ ๆ แบบในงานจริง
