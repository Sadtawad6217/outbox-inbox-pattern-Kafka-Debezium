# README.md

## สรุปการทำงานของระบบ

ระบบนี้ออกแบบมาเพื่อเชื่อมต่อฐานข้อมูล PostgreSQL สองตัว (Postgres Outbox และ Postgres Inbox) ผ่าน Kafka โดยใช้ Debezium Connect เพื่อส่งข้อมูลจากฐานข้อมูลต้นทาง (Outbox) ไปยัง Kafka แล้วนำข้อมูลไปยังฐานข้อมูลปลายทาง (Inbox)

### ส่วนประกอบหลัก

1. **Zookeeper**  
   ทำหน้าที่จัดการ Kafka cluster  
   - เปิดพอร์ต: 2181, 2888, 3888

2. **Kafka**  
   ระบบการจัดการคิวข้อความ รับและส่งข้อมูลระหว่าง Postgres Outbox และ Inbox  
   - เปิดพอร์ต: 9092
   - เชื่อมต่อกับ Zookeeper (`ZOOKEEPER_CONNECT=zookeeper:2181`)

3. **Postgres Outbox (postgres-outbox)**  
   ฐานข้อมูลต้นทางที่เก็บข้อมูลเพื่อส่งไปยัง Kafka  
   - เปิดพอร์ต: 5433
   - ชื่อผู้ใช้: `postgres`
   - รหัสผ่าน: `postgres`
   - ใช้ Volume สำหรับตั้งค่าเริ่มต้น (`initdb-outbox`)

4. **Postgres Inbox (postgres-inbox)**  
   ฐานข้อมูลปลายทางที่รับข้อมูลจาก Kafka ผ่าน JDBC Sink  
   - เปิดพอร์ต: 5432
   - ชื่อผู้ใช้: `postgres`
   - รหัสผ่าน: `postgres`
   - ใช้ Volume สำหรับตั้งค่าเริ่มต้น (`initdb-inbox`)

5. **Debezium Connect**  
   ตัวเชื่อมต่อ PostgreSQL กับ Kafka เพื่อส่งข้อมูลการเปลี่ยนแปลงไปยัง Kafka  
   - เปิดพอร์ต: 8083, 5005
   - ใช้หัวข้อใน Kafka: `my_connect_configs`, `my_connect_offsets`, `my_source_connect_statuses`

6. **Kafdrop**  
   เครื่องมือ UI สำหรับตรวจสอบและจัดการ Kafka topics  
   - เปิดพอร์ต: 9000

### ขั้นตอนการทำงาน

```
+-----------------+
|   ตาราง product  | --> DB A
+-----------------+
         |
         v
   +-------------+
   |   trigger   |
   +-------------+
         |
         v
+-----------------+
|    ตาราง outbox  |
+-----------------+
         |
         v
+-----------------+
|    kafka topic  |
+-----------------+
         |
         v
   +----------------+
   |   ตาราง inbox  |
   +----------------+
         |
         v
   +-------------+
   |   trigger   |
   +-------------+
         |
         v
+-----------------+
|   ตาราง product  | --> DB B
+-----------------+
```

### ขั้นตอนการใช่งาน
## การตั้งค่า
ก่อนที่จะเริ่ม ต้องติดตั้ง Docker และ Docker Compose บนเครื่องของคุณ

1. กำหนดเวอร์ชัน Debezium:
   ```powershell
   $env:DEBEZIUM_VERSION = "latest"
   ```
2. รัน Docker Compose เพื่อเริ่มบริการทั้งหมด:
   ```powershell
   docker compose -f docker-compose.yaml up -d --build
   ```
3. ส่งการกำหนดค่าของ Source Connector:
   ```powershell
   curl -i -X POST -H "Accept: application/json" -H "Content-Type: application/json" http://localhost:8083/connectors/ -d @source.json
   ```
4. ส่งการกำหนดค่าของ Sink Connector:
   ```powershell
   curl -i -X POST -H "Accept: application/json" -H "Content-Type: application/json" http://localhost:8083/connectors/ -d @jdbc-sink.json
   ```
5. ถ้าหากต้องการหยุด Docker Compose เพื่อปิดบริการทั้งหมด:
   ```powershell
    docker-compose down 
   ```
