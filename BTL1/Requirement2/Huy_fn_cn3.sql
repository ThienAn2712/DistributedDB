-- Function tinh doanh thu theo the loai tren ca 3 chi nhanh.
-- Chay bang user giamdoc_cn3.
-- Yeu cau database link:
--   gd3_to_gd1: CN3 -> CN1
--   gd3_to_gd2: CN3 -> CN2

SET DEFINE OFF;

CREATE OR REPLACE FUNCTION fn_doanhthu_theloai (
    p_theloai IN VARCHAR2,
    p_tu_ngay IN DATE,
    p_den_ngay IN DATE
) RETURN VARCHAR2
IS
    v_cn1 NUMBER := 0;
    v_cn2 NUMBER := 0;
    v_cn3 NUMBER := 0;
    v_tong_doanh_thu NUMBER := 0;
    v_ket_qua VARCHAR2(100);
BEGIN
    IF p_theloai IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'The loai khong duoc de trong');
    END IF;

    IF p_tu_ngay IS NULL OR p_den_ngay IS NULL OR p_tu_ngay > p_den_ngay THEN
        RAISE_APPLICATION_ERROR(-20002, 'Khoang ngay khong hop le');
    END IF;

    SELECT NVL(SUM(ct.SoLuong * s.GiaBan), 0)
    INTO v_cn1
    FROM HOADON@gd3_to_gd1 h
    JOIN CHITIET_HD@gd3_to_gd1 ct ON ct.MaHD = h.MaHD
    JOIN SACH@gd3_to_gd1 s ON s.MaSach = ct.MaSach
    WHERE UPPER(TRIM(s.TheLoai)) = UPPER(TRIM(p_theloai))
      AND h.NgayLap >= CAST(p_tu_ngay AS TIMESTAMP)
      AND h.NgayLap < CAST(p_den_ngay + 1 AS TIMESTAMP);

    SELECT NVL(SUM(ct.SoLuong * s.GiaBan), 0)
    INTO v_cn2
    FROM HOADON@gd3_to_gd2 h
    JOIN CHITIET_HD@gd3_to_gd2 ct ON ct.MaHD = h.MaHD
    JOIN SACH@gd3_to_gd2 s ON s.MaSach = ct.MaSach
    WHERE UPPER(TRIM(s.TheLoai)) = UPPER(TRIM(p_theloai))
      AND h.NgayLap >= CAST(p_tu_ngay AS TIMESTAMP)
      AND h.NgayLap < CAST(p_den_ngay + 1 AS TIMESTAMP);

    SELECT NVL(SUM(ct.SoLuong * s.GiaBan), 0)
    INTO v_cn3
    FROM HOADON h
    JOIN CHITIET_HD ct ON ct.MaHD = h.MaHD
    JOIN SACH s ON s.MaSach = ct.MaSach
    WHERE UPPER(TRIM(s.TheLoai)) = UPPER(TRIM(p_theloai))
      AND h.NgayLap >= CAST(p_tu_ngay AS TIMESTAMP)
      AND h.NgayLap < CAST(p_den_ngay + 1 AS TIMESTAMP);

    v_tong_doanh_thu := v_cn1 + v_cn2 + v_cn3;
    v_ket_qua := TO_CHAR(v_tong_doanh_thu, '999,999,999,999') || ' VND';

    RETURN v_ket_qua;
END fn_doanhthu_theloai;
/

SHOW ERRORS FUNCTION fn_doanhthu_theloai;

SELECT fn_doanhthu_theloai(
    'Giao duc',
    DATE '2025-01-01',
    DATE '2025-12-31'
) AS TongDoanhThu
FROM dual;

