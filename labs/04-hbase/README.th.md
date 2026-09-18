# Lab 4 -- HBase

**ภาษาไทย** | [English](README.md)

## เป้าหมายของ lab นี้

เรียนรู้พื้นฐานของ HBase -- ฐานข้อมูลแบบ NoSQL ที่เก็บข้อมูลเป็น
column-family บน HDFS เหมาะกับข้อมูลขนาดใหญ่มากที่ต้องการอ่าน/เขียนแบบ
random access เร็ว (ต่างจาก HDFS ที่เหมาะกับอ่านไฟล์ทั้งไฟล์แบบ
sequential)

## ขั้นตอนที่ 1: เปิด HBase

HBase **ไม่ได้เปิดอัตโนมัติ** ตอน container start (เพื่อประหยัด RAM
ตอนที่ไม่ได้ใช้) ต้องสั่งเปิดเองก่อน:

จากนอก container (Terminal/PowerShell ปกติ):

```bash
docker compose exec bigdata labctl start hbase
```

หรือถ้าอยู่ข้างใน container อยู่แล้ว:

```bash
labctl start hbase
```

คำสั่งนี้จะเปิด 3 process ตามลำดับ: ZooKeeper (ที่ HBase ใช้ประสานงาน
ภายใน) -> HBase Master -> HBase RegionServer ใช้เวลาประมาณ 10-30 วินาที
กว่าจะพร้อมเต็มที่ (ครั้งแรกหลัง container เพิ่งเปิดอาจนานกว่านั้นเพราะ
ทุก service แย่งกันเริ่มพร้อมกัน)

เช็คว่าเปิดสำเร็จ:

```bash
labctl status
```

ต้องเห็น `HBase           RUNNING`

## ขั้นตอนที่ 2: เข้า HBase shell

```bash
hbase shell
```

prompt จะเปลี่ยนเป็นประมาณ `hbase:001:0>` แปลว่าเข้ามาอยู่ใน shell
เฉพาะของ HBase แล้ว (ไม่ใช่ bash ปกติ) คำสั่งด้านล่างทั้งหมดพิมพ์ต่อใน
shell นี้

## ขั้นตอนที่ 3: สร้างตาราง

```text
create 'employee', 'personal_data', 'professional_data'
```

- `employee` คือชื่อตาราง
- `personal_data` และ `professional_data` คือชื่อ **column family** สอง
  กลุ่ม -- แนวคิดของ HBase คือแบ่งคอลัมน์เป็นกลุ่ม (family) ตั้งแต่ตอน
  สร้างตาราง แล้วค่อยใส่ "คอลัมน์ย่อย" (qualifier) เข้าไปในแต่ละ family
  ทีหลังได้อย่างอิสระโดยไม่ต้องแก้ schema ตาราง

ดูรายชื่อตารางทั้งหมดเพื่อยืนยันว่าสร้างสำเร็จ:

```text
list
```

## ขั้นตอนที่ 4: ใส่ข้อมูล (put)

```text
put 'employee','1','personal_data:name','raju'
put 'employee','1','personal_data:city','hyderabad'
put 'employee','1','professional_data:designation','manager'
put 'employee','1','professional_data:salary','5000'
```

รูปแบบคำสั่ง: `put '<ตาราง>','<row key>','<family>:<qualifier>','<ค่า>'`

- `'1'` คือ **row key** -- ตัวระบุแถวข้อมูล (เหมือน primary key) ทั้ง 4
  คำสั่งข้างบนใส่ค่าลงแถวเดียวกัน (row key = `'1'`) แต่คนละคอลัมน์
- `personal_data:name` คือ family `personal_data` คอลัมน์ย่อย `name`
  -- สังเกตว่าไม่ต้องประกาศคอลัมน์ `name` ไว้ล่วงหน้า ใส่ตอนไหนก็ได้

เพิ่มอีกหนึ่งแถวเพื่อให้มีข้อมูลหลายแถวไว้ทดสอบ:

```text
put 'employee','2','personal_data:name','bobby'
```

## ขั้นตอนที่ 5: อ่านข้อมูล (scan และ get)

ดูข้อมูลทั้งตาราง:

```text
scan 'employee'
```

ผลลัพธ์ตัวอย่าง:

```text
ROW    COLUMN+CELL
 1      column=personal_data:city, timestamp=..., value=hyderabad
 1      column=personal_data:name, timestamp=..., value=raju
 1      column=professional_data:designation, timestamp=..., value=manager
 1      column=professional_data:salary, timestamp=..., value=5000
 2      column=personal_data:name, timestamp=..., value=bobby
```

ดูข้อมูลเฉพาะแถวเดียว (row key `'1'`):

```text
get 'employee','1'
```

## ขั้นตอนที่ 6: ออกจาก shell

```text
exit
```

## ดู Web UI ของ HBase Master

เปิด browser ไปที่ http://localhost:16010 ดูสถานะ Master, RegionServer,
และรายชื่อตารางทั้งหมดได้

## ปิด HBase เมื่อทำเสร็จแล้ว (ประหยัด RAM)

```bash
docker compose exec bigdata labctl stop hbase
```

ไม่บังคับต้องปิด แต่ถ้าจะทำ lab อื่นที่ไม่ใช้ HBase ต่อ ปิดไว้จะประหยัด
RAM เครื่องได้พอสมควร (ดูตัวเลขจริงใน README หลักหัวข้อ "การใช้
ทรัพยากร")

## ถ้าเจอปัญหา

| อาการ | สาเหตุ/วิธีแก้ |
|---|---|
| `ERROR: Table already exists` ตอน `create` | มีตารางชื่อนี้ค้างจาก run ก่อนแล้ว ลบก่อนด้วย `disable 'employee'` แล้ว `drop 'employee'` แล้วค่อย `create` ใหม่ |
| shell ค้างนานตอนสั่ง `create` ครั้งแรก | ปกติถ้าเป็นครั้งแรกหลัง `labctl start hbase` (Master ยังเริ่มไม่เสร็จ) รอสัก 1-2 นาทีแล้วลองใหม่ ดูสถานะด้วย `labctl status` ว่า HBase RUNNING แล้วหรือยัง |
| `ZooKeeper GET could not be completed` | HBase เพิ่งเปิด ยังไม่เสถียรเต็มที่ รอสักครู่แล้วลองคำสั่งเดิมซ้ำ |

## สรุป

คุณสร้างตาราง, ใส่ข้อมูล, และอ่านข้อมูลใน HBase สำเร็จแล้ว -- นี่คือ
พื้นฐานเดียวกับที่ lab 8 (RDBMS ingestion) จะใช้ตอนดึงข้อมูลจาก MariaDB
มาเก็บไว้แบบกระจายบน Hadoop ecosystem
