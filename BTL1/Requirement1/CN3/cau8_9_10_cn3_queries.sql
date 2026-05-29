-- Cac cau truy van demo cho CN3.
-- Luu y:
--   1. Database link private nam theo tung user, nen quanlikho_cn3 va nhanvien_cn3
--      phai tu tao link rieng.
--   2. Cac bang local do schema giamdoc_cn3 so huu, nen user khac phai ghi
--      day du owner: giamdoc_cn3.TEN_BANG.
--   3. Ma chi nhanh trong data la CN003, khong phai CN03.
--   4. Neu truy van qua GIAMDOC_CN2_NEW bao ORA-12541 thi may/listener CN2
--      chua bat hoac TNS alias dang sai, khong phai loi cu phap SELECT.

SET DEFINE OFF;

--------------------------------------------------------------------------------
-- PHAN A - Chay 1 lan bang user: giamdoc_cn3
-- Cap them quyen can thiet cho Cau 10 vi nhanvien_cn3 can doc ten nhan vien.
--------------------------------------------------------------------------------

GRANT SELECT ON NHANVIEN TO nhanvien_cn3;

--------------------------------------------------------------------------------
-- PHAN B - Chay bang user: quanlikho_cn3
-- Tao database link rieng cho quanlikho_cn3.
-- Drop link cu neu co de script chay lai khong bi ORA-02011.
--------------------------------------------------------------------------------

BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK qlk3_to_qlk1';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2024 THEN
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK qlk3_to_qlk1
CONNECT TO qlk_read_cn1 IDENTIFIED BY qlk_read_cn1
USING 'GIAMDOC_CN1';

BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK qlk3_to_qlk2';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2024 THEN
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK qlk3_to_qlk2
CONNECT TO qlk_read_cn2 IDENTIFIED BY qlk_read_cn2
USING 'GIAMDOC_CN2_NEW';

-- Cau 8 - GROUP BY + MAX + MIN (Quan ly kho CN3)
-- So sanh gia nhap cao nhat va thap nhat cua tung dau sach tren 3 chi nhanh.

SELECT s.MaSach,
       s.TenSach,
       MIN(kn.GiaNhap) AS GiaNhapThapNhat,
       MAX(kn.GiaNhap) AS GiaNhapCaoNhat,
       MAX(kn.GiaNhap) - MIN(kn.GiaNhap) AS ChenhLechGia
FROM (
    SELECT MaSach, GiaNhap FROM giamdoc_cn1.KHO_NHAP@qlk3_to_qlk1
    UNION ALL
    SELECT MaSach, GiaNhap FROM giamdoc_cn2.KHO_NHAP@qlk3_to_qlk2
    UNION ALL
    SELECT MaSach, GiaNhap FROM giamdoc_cn3.KHO_NHAP
) kn
JOIN giamdoc_cn3.SACH s ON s.MaSach = kn.MaSach
GROUP BY s.MaSach, s.TenSach
HAVING MAX(kn.GiaNhap) - MIN(kn.GiaNhap) > 0
ORDER BY ChenhLechGia DESC;

--------------------------------------------------------------------------------
-- PHAN C - Chay bang user: nhanvien_cn3
-- Tao database link rieng cho nhanvien_cn3.
-- Cau 9 chi can xem hoa don CN2 va CN3, nen tao link sang CN2.
--------------------------------------------------------------------------------

BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK nv3_to_nv2';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2024 THEN
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK nv3_to_nv2
CONNECT TO nv_read_cn2 IDENTIFIED BY nv_read_cn2
USING 'GIAMDOC_CN2_NEW';

-- Cau 9 - INTERSECT + COUNT (Nhan vien CN3)
-- Dem so khach hang da mua hang tai ca CN2 lan CN3.

SELECT COUNT(*) AS SoKhachHangTrungThanh
FROM (
    SELECT MaKH FROM giamdoc_cn2.HOADON@nv3_to_nv2
    INTERSECT
    SELECT MaKH FROM giamdoc_cn3.HOADON
);

-- Cau 10 - GROUP BY + HAVING (Nhan vien CN3)
-- Tim nhan vien CN3 co doanh so ban vuot trung binh cua toan chi nhanh.

SELECT nv.MaNV,
       nv.HoTen,
       COUNT(hd.MaHD) AS SoHoaDon,
       SUM(hd.TongTien) AS TongDoanhSo
FROM giamdoc_cn3.NHANVIEN nv
JOIN giamdoc_cn3.HOADON hd ON hd.MaNV = nv.MaNV
WHERE nv.MaCN = 'CN003'
GROUP BY nv.MaNV, nv.HoTen
HAVING SUM(hd.TongTien) > (
    SELECT AVG(tong_nv)
    FROM (
        SELECT SUM(hd2.TongTien) AS tong_nv
        FROM giamdoc_cn3.HOADON hd2
        JOIN giamdoc_cn3.NHANVIEN nv2 ON nv2.MaNV = hd2.MaNV
        WHERE nv2.MaCN = 'CN003'
        GROUP BY hd2.MaNV
    )
)
ORDER BY TongDoanhSo DESC;
