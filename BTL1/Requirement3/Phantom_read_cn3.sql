-- Demo Phantom Read.
-- Chay tren user giamdoc_cn2 theo hai session khac nhau.

SET DEFINE OFF;

--------------------------------------------------------------------------------
-- 0. CHUAN BI DU LIEU DEMO TREN CN2
--------------------------------------------------------------------------------

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE phantom_demo PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

CREATE TABLE phantom_demo (
    id NUMBER PRIMARY KEY,
    macn VARCHAR2(15),
    gia_tri NUMBER,
    ghi_chu VARCHAR2(100)
);

INSERT INTO phantom_demo (id, macn, gia_tri, ghi_chu)
VALUES (1, 'CN002', 100, 'Dong ban dau tren CN2');

COMMIT;

SELECT *
FROM phantom_demo
ORDER BY id;

--------------------------------------------------------------------------------
-- 1. READ COMMITTED: XAY RA PHANTOM READ
--------------------------------------------------------------------------------

-- SESSION A:
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT COUNT(*) AS so_dong_lan_1
FROM phantom_demo
WHERE macn = 'CN002'
  AND gia_tri >= 100;

-- Dung lai o day, chuyen sang Session B.

-- SESSION B:
INSERT INTO phantom_demo (id, macn, gia_tri, ghi_chu)
VALUES (2, 'CN002', 150, 'Dong phantom moi chen');

COMMIT;

SELECT *
FROM phantom_demo
ORDER BY id;

-- SESSION A: chay lai dung cau SELECT cu.
SELECT COUNT(*) AS so_dong_lan_2
FROM phantom_demo
WHERE macn = 'CN002'
  AND gia_tri >= 100;

COMMIT;

--------------------------------------------------------------------------------
-- 2. SERIALIZABLE: TRANSACTION A KHONG THAY DONG PHANTOM TRONG CUNG SNAPSHOT
--------------------------------------------------------------------------------

-- SESSION A:
COMMIT;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT COUNT(*) AS so_dong_lan_1
FROM phantom_demo
WHERE macn = 'CN002'
  AND gia_tri >= 100;

-- Dung lai o day, chuyen sang Session B.

-- SESSION B:
INSERT INTO phantom_demo (id, macn, gia_tri, ghi_chu)
VALUES (3, 'CN002', 200, 'Dong test serializable');

COMMIT;

-- SESSION A:
SELECT COUNT(*) AS so_dong_lan_2
FROM phantom_demo
WHERE macn = 'CN002'
  AND gia_tri >= 100;

COMMIT;

--------------------------------------------------------------------------------
-- 3. DON DU LIEU DEMO
--------------------------------------------------------------------------------

DROP TABLE phantom_demo PURGE;

