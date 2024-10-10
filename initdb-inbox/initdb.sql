-- สร้างตาราง inbox
CREATE TABLE public.inbox (
    event_type text NULL,
    payload text NULL,
    product_id int4 NULL,
    created_at int8 DEFAULT 0 NULL,
    id int4 DEFAULT 0 NOT NULL,
    status text DEFAULT 'PENDING'::text NULL,
    CONSTRAINT inbox_pkey PRIMARY KEY (id)
);

-- สร้างตาราง product
CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    description TEXT,
    price NUMERIC
);

-- Trigger เพื่อนำข้อมูลจาก inbox กลับไปยังตาราง product
CREATE OR REPLACE FUNCTION trigger_inbox_to_product()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.event_type = 'INSERT') THEN
        IF NEW.payload IS NOT NULL THEN
            INSERT INTO product (id, name, description, price)
            VALUES (
                (NEW.payload::json->>'id')::INT, 
                NEW.payload::json->>'name', 
                NEW.payload::json->>'description', 
                (NEW.payload::json->>'price')::NUMERIC
            );
        END IF;

    ELSIF (NEW.event_type = 'UPDATE') THEN
        IF NEW.payload IS NOT NULL THEN
            UPDATE product
            SET name = NEW.payload::json->>'name',
                description = NEW.payload::json->>'description',
                price = (NEW.payload::json->>'price')::NUMERIC
            WHERE id = (NEW.payload::json->>'id')::INT;
        END IF;

    ELSIF (NEW.event_type = 'DELETE') THEN
        DELETE FROM product
        WHERE id = (NEW.payload::json->>'id')::INT;
    END IF;

    -- อัปเดตสถานะใน inbox
    UPDATE inbox
    SET status = 'PROCESSED'
    WHERE id = NEW.id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- สร้าง Trigger
CREATE TRIGGER trigger_inbox_change
AFTER INSERT ON inbox
FOR EACH ROW
EXECUTE FUNCTION trigger_inbox_to_product();
