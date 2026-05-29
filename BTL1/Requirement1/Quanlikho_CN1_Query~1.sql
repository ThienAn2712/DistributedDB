-- Link cho Quản lý kho 

CREATE DATABASE LINK qlk1_to_qlk2 

CONNECT TO qlk_read_cn2 IDENTIFIED BY qlk_read_cn2 USING 'CN2_LINK'; 

CREATE DATABASE LINK qlk1_to_qlk3 

CONNECT TO qlk_read_cn3 IDENTIFIED BY qlk_read_cn3 USING 'CN3_LINK'; 

--Tìm các đầu sách có mặt trong kho của cả 3 chi nhánh (tồn kho > 0), giúp xác định sách phổ biến nhất toàn hệ thống.
-- Thực thi với user: quanlikho_cn1

SELECT s.MaSach, s.TenSach, s.TheLoai
FROM  giamdoc_cn1.KHO_BAN kb
JOIN   giamdoc_cn1.SACH s ON s.MaSach = kb.MaSach
WHERE  kb.SoLuongTon > 0

INTERSECT

SELECT s.MaSach, s.TenSach, s.TheLoai
FROM   giamdoc_cn2.KHO_BAN@qlk1_to_qlk2  kb
JOIN   giamdoc_cn1.SACH s ON s.MaSach = kb.MaSach
WHERE  kb.SoLuongTon > 0

INTERSECT

SELECT s.MaSach, s.TenSach, s.TheLoai
FROM   GIAMDOC_CN3.KHO_BAN@qlk1_to_qlk3 kb
JOIN   GIAMDOC_CN1.SACH  s ON s.MaSach = kb.MaSach
WHERE  kb.SoLuongTon > 0

