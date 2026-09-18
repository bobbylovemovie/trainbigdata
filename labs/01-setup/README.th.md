# Lab 1 -- ติดตั้งและเตรียมเครื่อง

[English](README.md) | **ภาษาไทย**

เอกสารนี้เขียนให้ละเอียดที่สุด เพื่อให้นักศึกษาที่เปิด repo นี้ครั้งแรก
ทำตามได้เองทั้งหมดโดยไม่ต้องถามใคร ทำตามทีละขั้นตอนตามลำดับ อย่าข้าม

ทำเอกสารนี้**ก่อนวันเรียน** ถ้าเป็นไปได้ เพราะขั้นตอนดาวน์โหลดใช้เวลา
และใช้ Wi-Fi ห้องเรียนไม่ได้เสมอไป

---

## ภาพรวม: กำลังจะติดตั้งอะไร

```text
เครื่องคุณ (Windows หรือ macOS)
        |
        v
   Docker Desktop   <- โปรแกรมที่รัน "เครื่อง Linux เสมือน" ในเครื่องคุณ
        |
        v
   trainbigdata:2026   <- ระบบ Big Data ทั้งชุด (Hadoop, Hive, HBase, Spark, ...)
                           ที่ผู้สอนเตรียมไว้ให้แล้ว ดาวน์โหลดมาใช้ได้เลย
```

คุณ**ไม่ต้อง**ติดตั้ง Java, Hadoop, Python หรืออะไรเองทั้งสิ้น ทุกอย่าง
อยู่ใน "กล่อง" (container) ที่ดาวน์โหลดมาสำเร็จรูปแล้ว หน้าที่คุณมีแค่:

1. ติดตั้ง Docker Desktop กับ Git (ทำครั้งเดียว)
2. โคลน (clone) repo นี้
3. สั่ง 2 คำสั่งเพื่อดาวน์โหลดและเปิดระบบ
4. ตรวจสอบว่าพร้อมใช้งาน
5. เข้าไปทำ lab

---

## สิ่งที่ต้องมีก่อนเริ่ม

- เครื่อง Windows 10/11 หรือ macOS (Intel หรือ Apple Silicon/M1-M4 ก็ได้)
- RAM อย่างน้อย 8 GB (แนะนำ 16 GB)
- พื้นที่ว่างในดิสก์อย่างน้อย 15 GB
- อินเทอร์เน็ตสำหรับดาวน์โหลดครั้งแรก (ไฟล์รวมประมาณ 3 GB)

---

## ขั้นตอนที่ 1: ติดตั้ง Docker Desktop

### macOS

1. เปิดเว็บ https://www.docker.com/products/docker-desktop/
2. กดปุ่ม **Download for Mac**
   - ถ้าเครื่องเป็น Mac รุ่นใหม่ (M1/M2/M3/M4, ชิป Apple Silicon) เลือก
     **Apple Chip**
   - ถ้าเป็น Mac รุ่นเก่า (ก่อนปี 2020, ชิป Intel) เลือก **Intel Chip**
   - เช็คแบบชัวร์ ๆ ได้ที่เมนู Apple () มุมซ้ายบน -> **About This Mac**
     ดูช่อง "Chip" หรือ "Processor"
3. เปิดไฟล์ `.dmg` ที่ดาวน์โหลดมา แล้วลาก **Docker.app** ไปที่โฟลเดอร์
   **Applications** ตามที่หน้าต่างบอก
4. เปิด Docker จาก Applications (ครั้งแรกอาจมีเตือนเรื่องความปลอดภัย
   ให้กด **Open**)
5. รอสัญลักษณ์ปลาวาฬ () ขึ้นที่แถบเมนูด้านบนขวาของจอ แล้วรอจนไอคอน
   หยุดเคลื่อนไหว (แปลว่า Docker พร้อมใช้งานแล้ว)
6. เปิด **Terminal** (หา "Terminal" ใน Spotlight ด้วย Cmd+Space) แล้ว
   พิมพ์เพื่อทดสอบ:

   ```bash
   docker --version
   docker compose version
   ```

   ต้องขึ้นเลขเวอร์ชัน ไม่ใช่ error

### Windows

1. **ก่อนอื่น เช็คว่าเปิด WSL2 อยู่หรือยัง** (Docker Desktop บน Windows
   ต้องใช้ WSL2) เปิด **PowerShell** (คลิกขวาที่ปุ่ม Start -> เลือก
   "Windows PowerShell" หรือ "Terminal") แล้วพิมพ์:

   ```powershell
   wsl --version
   ```

   - ถ้าขึ้นเลขเวอร์ชัน แปลว่ามีแล้ว ข้ามไปข้อ 2 ได้เลย
   - ถ้าขึ้น error หรือบอกว่าไม่รู้จักคำสั่ง ให้พิมพ์คำสั่งนี้ (ต้องเปิด
     PowerShell แบบ **Run as Administrator** -- คลิกขวาที่ไอคอน
     PowerShell แล้วเลือก "Run as administrator"):

     ```powershell
     wsl --install
     ```

     แล้ว **รีสตาร์ทเครื่อง** ตามที่มันบอก

2. เปิดเว็บ https://www.docker.com/products/docker-desktop/
3. กดปุ่ม **Download for Windows**
4. เปิดไฟล์ `Docker Desktop Installer.exe` ที่ดาวน์โหลดมา
5. ในหน้าติดตั้ง ให้ติ๊กถูก **"Use WSL 2 instead of Hyper-V"** (ปกติจะ
   ติ๊กมาให้อยู่แล้วเป็นค่า default) แล้วกด **Ok** ติดตั้งจนเสร็จ
6. เมื่อติดตั้งเสร็จ เครื่องอาจขอให้ **Log out หรือ Restart** ทำตามนั้น
7. เปิด **Docker Desktop** จากเมนู Start รอจนไอคอน Docker ที่มุมขวาล่าง
   (system tray) นิ่ง ไม่กระพริบ
8. ถ้ามีหน้าต่างถามเรื่อง Docker Subscription Service Agreement ให้กด
   **Accept**
9. เปิด **PowerShell** แล้วทดสอบ:

   ```powershell
   docker --version
   docker compose version
   ```

   ต้องขึ้นเลขเวอร์ชัน ไม่ใช่ error

> **ถ้าเจอปัญหา "WSL 2 installation is incomplete"**: เปิดลิงก์ที่ Docker
> แจ้งไว้ในหน้าต่าง error (จะพาไปหน้าดาวน์โหลด WSL2 Linux kernel update
> package) ติดตั้งไฟล์นั้นแล้วลอง Docker Desktop ใหม่อีกครั้ง

---

## ขั้นตอนที่ 2: ติดตั้ง Git

### macOS

เปิด **Terminal** แล้วพิมพ์:

```bash
git --version
```

ถ้าเครื่องยังไม่มี Git ระบบจะเด้งหน้าต่างให้ติดตั้ง **Command Line
Developer Tools** อัตโนมัติ กด **Install** รอจนเสร็จ (ใช้เวลาไม่กี่นาที)
แล้วรัน `git --version` อีกครั้งเพื่อยืนยัน

### Windows

1. เปิดเว็บ https://git-scm.com/downloads
2. กด **Download for Windows**
3. เปิดไฟล์ที่ดาวน์โหลดมา แล้วกด **Next** ไปเรื่อย ๆ ด้วยค่า default
   ทั้งหมด (ไม่ต้องปรับอะไร) จนติดตั้งเสร็จ
4. เปิด **PowerShell ใหม่** (ปิดของเดิมแล้วเปิดใหม่ เพื่อให้ระบบรู้จัก
   คำสั่ง git) แล้วทดสอบ:

   ```powershell
   git --version
   ```

---

## ขั้นตอนที่ 3: โคลน repo

เปิด Terminal (macOS) หรือ PowerShell (Windows) แล้วรันคำสั่งเดียวกัน
ทั้งสอง OS:

```bash
git clone https://github.com/bobbylovemovie/trainbigdata.git
cd trainbigdata
```

คำสั่งนี้จะสร้างโฟลเดอร์ `trainbigdata` และดาวน์โหลดไฟล์คอร์สทั้งหมด
(เอกสาร lab, สคริปต์ต่าง ๆ) มาไว้ในนั้น -- ไฟล์พวกนี้เล็ก ไม่กี่ MB
ไม่ใช่ตัวระบบ Big Data (ตัวระบบจริงจะดาวน์โหลดแยกในขั้นตอนถัดไป)

---

## ขั้นตอนที่ 4: ดาวน์โหลดและเปิดระบบ

คำสั่งเหมือนกันทั้ง macOS (Terminal) และ Windows (PowerShell):

```bash
docker compose pull
```

คำสั่งนี้ดาวน์โหลด "กล่อง" ระบบ Big Data ทั้งชุด (ประมาณ 3 GB) -- ใช้เวลา
หลายนาทีขึ้นกับความเร็วเน็ต **ทำครั้งเดียวพอ ครั้งต่อไปไม่ต้องดาวน์โหลด
ซ้ำ** (นอกจากผู้สอนอัปเดต image ใหม่แล้วบอกให้ pull อีกรอบ)

เมื่อดาวน์โหลดเสร็จ เปิดระบบ:

```bash
docker compose up -d
```

`-d` แปลว่ารันแบบ background (ไม่บังคับให้ terminal ค้างอยู่หน้าจอนั้น)
คำสั่งนี้จะขึ้นข้อความสั้น ๆ แล้วคืน prompt ให้ใช้งานต่อได้เลย ระบบข้างใน
จะใช้เวลาประมาณ 30-60 วินาทีในการเริ่มการทำงานให้ครบ (HDFS, YARN,
MariaDB, JupyterLab)

---

## ขั้นตอนที่ 5: ตรวจสอบว่าพร้อมใช้งาน

### macOS

```bash
./scripts/student-check.sh
```

### Windows (PowerShell)

```powershell
.\scripts\student-check.ps1
```

> ถ้า PowerShell ฟ้อง error ว่า "running scripts is disabled on this
> system" ให้รันคำสั่งนี้ครั้งเดียวก่อน (อนุญาตให้รัน script ในเครื่องนี้
> ได้):
>
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```
>
> แล้วพิมพ์ `Y` ยืนยัน จากนั้นลองรัน `.\scripts\student-check.ps1` ใหม่

ผลลัพธ์ที่ต้องเห็น (ตัวอย่าง):

```text
Big Data Management Lab

Checking environment...

[PASS] Docker installed
[PASS] Docker daemon running
[PASS] Docker Compose available
[PASS] Big Data image available
[PASS] Big Data container running
[PASS] Hadoop available
[PASS] HDFS available
[PASS] YARN available
[PASS] Java available
[PASS] Spark available

Environment READY

You can start LAB 02 -- HDFS.
```

ถ้าเห็น **"Environment READY"** แปลว่าพร้อมทำ lab ต่อได้เลย ข้ามไป
"ขั้นตอนที่ 6"

**ถ้าเจอ `[FAIL]` ตรงไหน** สคริปต์จะบอกวิธีแก้ตรงจุดนั้นเป็นภาษาอังกฤษ
สั้น ๆ อยู่แล้ว สรุปที่เจอบ่อย:

| ข้อความที่เจอ | วิธีแก้ |
|---|---|
| `Docker daemon is not running` | เปิดโปรแกรม Docker Desktop ให้รันอยู่ (ดูไอคอนปลาวาฬ/Docker ที่แถบเมนูหรือ system tray) แล้วรันสคริปต์ใหม่ |
| `The course image has not been downloaded yet` | รัน `docker compose pull` แล้วรันสคริปต์ใหม่ |
| `The lab container is not running` | รัน `docker compose up -d` แล้วรันสคริปต์ใหม่ |
| `Hadoop isn't responding yet` | รอ 30 วินาทีแล้วลองใหม่ (ระบบข้างในยังเปิดไม่เสร็จ) |

---

## ขั้นตอนที่ 6: เข้าไปทำ lab

คำสั่งเหมือนกันทั้ง macOS และ Windows:

```bash
docker compose exec bigdata bash
```

พอรันแล้ว prompt จะเปลี่ยนหน้าตา (ประมาณ `student@bigdata:~$`) แปลว่า
ตอนนี้คุณ**อยู่ข้างใน container Linux แล้ว** -- จากจุดนี้ไป ทุกคำสั่งใน
เอกสาร lab ทั้งหมด (lab 02 เป็นต้นไป) **เหมือนกันทุกตัวอักษรไม่ว่าคุณจะ
ใช้ Windows หรือ macOS** เพราะรันอยู่ในเครื่อง Linux เดียวกันข้างใน
container

ลองพิมพ์คำสั่งแรกดู:

```bash
labctl status
```

ควรเห็นสถานะ service ต่าง ๆ ประมาณนี้:

```text
HDFS           RUNNING
YARN           RUNNING
HBase          STOPPED
Hive           STOPPED
MariaDB        RUNNING
JupyterLab     RUNNING
```

`HBase` กับ `Hive` เป็น `STOPPED` ปกติ -- ตั้งใจให้ไม่เปิดอัตโนมัติเพื่อ
ประหยัด RAM เดี๋ยวจะเปิดตอนถึง lab ที่ต้องใช้ (ดูวิธีเปิดใน lab 04 และ
05)

เมื่อทำ lab เสร็จแต่ละครั้ง พิมพ์ `exit` เพื่อออกจาก container กลับมาที่
Terminal/PowerShell ปกติ (ตัว container ยังรันอยู่เบื้องหลัง ไม่ได้ปิด
แค่ออกจาก shell เท่านั้น)

---

## ทางเลือก: ใช้ JupyterLab ผ่าน browser

นอกจากเข้าทาง Terminal แล้ว ยังเปิดผ่าน browser ได้ด้วย:

เปิดเว็บเบราว์เซอร์ (Chrome, Edge, Safari อะไรก็ได้) ไปที่:

```text
http://localhost:8888
```

จะเห็นหน้า JupyterLab พร้อม file browser ทางซ้าย และมีปุ่มเปิด
**Terminal** ในนั้นได้เหมือนกัน (เมนู File -> New -> Terminal) ใช้แทน
`docker compose exec bigdata bash` ได้เลยถ้าสะดวกกว่า

> นี่เป็นแค่ทางเลือกเสริม ไม่บังคับ ทุก lab ทำผ่าน
> `docker compose exec bigdata bash` ได้ครบเหมือนกัน

---

## ถ้ามีอะไรพัง ทำยังไง

**รีสตาร์ทแบบไม่ลบข้อมูล** (ลองอันนี้ก่อนเสมอถ้ามีอะไรค้าง):

```bash
./scripts/restart-lab.sh        # macOS
docker compose restart          # Windows หรือใช้คำสั่งเดียวกันนี้ได้ทั้งคู่
```

**ล้างและเริ่มใหม่ทั้งหมด** (ลบงานทั้งหมดที่ทำใน HDFS/ฐานข้อมูล/ไฟล์
กลับไปเหมือนเพิ่งติดตั้งใหม่ -- ใช้เมื่อรีสตาร์ทธรรมดาแล้วไม่หาย):

```bash
./scripts/reset-lab.sh          # macOS -- จะถามยืนยันก่อนลบ
```

บน Windows ใช้คำสั่งเทียบเท่าตรง ๆ ได้เลย (ไม่มี prompt ยืนยัน ระวังก่อน
รัน เพราะลบข้อมูลจริง):

```powershell
docker compose down -v
docker compose up -d
```

---

## อัปเดตระหว่างเทอม

```bash
git pull                              # ได้เอกสาร lab ใหม่ล่าสุด
docker compose pull                   # ได้ image ใหม่ล่าสุด (ถ้าผู้สอน publish ไว้)
docker compose up -d
```

---

## สรุปคำสั่งทั้งหมดของ Lab 1 (รวดเดียว)

```bash
git clone https://github.com/bobbylovemovie/trainbigdata.git
cd trainbigdata

docker compose pull
docker compose up -d
```

macOS:
```bash
./scripts/student-check.sh
```

Windows:
```powershell
.\scripts\student-check.ps1
```

ทั้งสอง OS:
```bash
docker compose exec bigdata bash
labctl status
```

เห็น `Environment READY` และ `labctl status` แสดงผลได้ = พร้อมไปต่อ
**Lab 2 -- HDFS** แล้ว
