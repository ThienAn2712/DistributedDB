-- 03_insert_data_cn3.sql
-- File master de nap du lieu site Chi nhanh 3.
-- Chay bang user/schema du lieu cua CN3, vi du: giamdoc_cn3.
--
-- Neu SQL Developer khong nhan duong dan tuong doi, hay chay lan luot 3 file con:
--   03_insert_data_cn3_01_core.sql
--   03_insert_data_cn3_02_hoadon.sql
--   03_insert_data_cn3_03_chitiet_hd.sql

SET DEFINE OFF;

@03_insert_data_cn3_01_core.sql
@03_insert_data_cn3_02_hoadon.sql
@03_insert_data_cn3_03_chitiet_hd.sql

SELECT 'CHINHANH' AS table_name, COUNT(*) AS row_count FROM CHINHANH
UNION ALL SELECT 'SACH', COUNT(*) FROM SACH
UNION ALL SELECT 'KHACHHANG', COUNT(*) FROM KHACHHANG
UNION ALL SELECT 'NHANVIEN', COUNT(*) FROM NHANVIEN
UNION ALL SELECT 'KHO_NHAP', COUNT(*) FROM KHO_NHAP
UNION ALL SELECT 'KHO_BAN', COUNT(*) FROM KHO_BAN
UNION ALL SELECT 'HOADON', COUNT(*) FROM HOADON
UNION ALL SELECT 'CHITIET_HD', COUNT(*) FROM CHITIET_HD;

