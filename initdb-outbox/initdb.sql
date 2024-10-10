-- สร้างสคีมา inventory
CREATE SCHEMA inventory;
SET search_path TO inventory;

-- สร้าง extension postgis (ถ้าจำเป็น)
CREATE EXTENSION IF NOT EXISTS postgis;

-- สร้างตาราง outbox ก่อน
CREATE TABLE inventory.outbox (
    id SERIAL NOT NULL PRIMARY KEY,
    product_id INT,
    event_type VARCHAR(50),
    payload JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'PENDING'
);

-- สร้างตาราง product
CREATE TABLE inventory.product (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    price NUMERIC
);

-- สร้างฟังก์ชัน trigger_product_to_outbox
CREATE OR REPLACE FUNCTION inventory.trigger_product_to_outbox()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO inventory.outbox (product_id, event_type, payload)
        VALUES (NEW.id, 'INSERT', row_to_json(NEW));
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO inventory.outbox (product_id, event_type, payload)
        VALUES (NEW.id, 'UPDATE', row_to_json(NEW));
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO inventory.outbox (product_id, event_type, payload)
        VALUES (OLD.id, 'DELETE', row_to_json(OLD));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- สร้าง Trigger
CREATE TRIGGER trigger_product_change
AFTER INSERT OR UPDATE OR DELETE ON inventory.product
FOR EACH ROW
EXECUTE FUNCTION inventory.trigger_product_to_outbox();

-- แทรกข้อมูลตัวอย่าง
INSERT INTO inventory.product (name, description, price) VALUES
('Product A', 'Description of Product A', 10.99);

-- เปลี่ยนการตั้งค่าของตาราง outbox ให้เป็น REPLICA IDENTITY FULL
ALTER TABLE inventory.outbox REPLICA IDENTITY FULL;
