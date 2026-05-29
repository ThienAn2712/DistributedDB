-- Demo Non-repeatable read tren Oracle distributed database.
-- Session A: chay tren connection giamdoc_cn3/giamdoc_cn3.
-- Session B: chay tren connection giamdoc_cn2/giamdoc_cn2.
-- Session B dung database link gd2_to_gd3 de cap nhat du lieu CN3 tu xa.

--------------------------------------------------------------------------------
-- 0. KIEM TRA DATABASE LINK TREN SESSION B - CN2
--------------------------------------------------------------------------------
-- Chay tren giamdoc_cn2:

SELECT db_link, username, host
FROM user_db_links
WHERE UPPER(db_link) LIKE 'GD2_TO_GD3%';

-- Neu chua co link thi chay tren giamdoc_cn2:
-- CREATE DATABASE LINK gd2_to_gd3
-- CONNECT TO giamdoc_cn3 IDENTIFIED BY giamdoc_cn3
-- USING 'GIAMDOC_CN3';

--------------------------------------------------------------------------------
-- 1. RESET DU LIEU BAN DAU - SESSION A, CN3
--------------------------------------------------------------------------------
-- Chay tren giamdoc_cn3:

UPDATE KHO_BAN
SET SoLuongTon = 62
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

COMMIT;

SELECT MaCN, MaSach, SoLuongTon, TrangThai
FROM KHO_BAN
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

--------------------------------------------------------------------------------
-- 2. READ COMMITTED: XAY RA NON-REPEATABLE READ
--------------------------------------------------------------------------------

-- SESSION A - CN3: doc lan 1.
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT MaCN, MaSach, SoLuongTon, TrangThai
FROM KHO_BAN
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

-- Dung lai o day. Chuyen qua Session B.

-- SESSION B - CN2: cap nhat CN3 qua database link va commit.
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE GIAMDOC_CN3.KHO_BAN@gd2_to_gd3
SET SoLuongTon = 70
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

COMMIT;

SELECT MaCN, MaSach, SoLuongTon, TrangThai
FROM GIAMDOC_CN3.KHO_BAN@gd2_to_gd3
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

-- SESSION A - CN3: quay lai doc lan 2.
-- Ket qua luc nay se doi tu 62 thanh 70.

SELECT MaCN, MaSach, SoLuongTon, TrangThai
FROM KHO_BAN
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

COMMIT;

--------------------------------------------------------------------------------
-- 3. SERIALIZABLE: NGAN NON-REPEATABLE READ
--------------------------------------------------------------------------------

-- SESSION A - CN3: reset du lieu.
UPDATE KHO_BAN
SET SoLuongTon = 62
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

COMMIT;

-- SESSION A - CN3: doc lan 1 voi SERIALIZABLE.
COMMIT;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT MaCN, MaSach, SoLuongTon, TrangThai
FROM KHO_BAN
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

-- Dung lai o day. Chuyen qua Session B.

-- SESSION B - CN2: cap nhat va commit.
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

UPDATE GIAMDOC_CN3.KHO_BAN@gd2_to_gd3
SET SoLuongTon = 80
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

COMMIT;

SELECT MaCN, MaSach, SoLuongTon, TrangThai
FROM GIAMDOC_CN3.KHO_BAN@gd2_to_gd3
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

-- SESSION A - CN3: quay lai doc lan 2.
-- Trong cung transaction SERIALIZABLE, ket qua van la 62.

SELECT MaCN, MaSach, SoLuongTon, TrangThai
FROM KHO_BAN
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';

COMMIT;

-- SESSION A - CN3: sau commit, transaction moi se thay gia tri 80.
SELECT MaCN, MaSach, SoLuongTon, TrangThai
FROM KHO_BAN
WHERE MaCN = 'CN003'
  AND MaSach = 'S0046';
