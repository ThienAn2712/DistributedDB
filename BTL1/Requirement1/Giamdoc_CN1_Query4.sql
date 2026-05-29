--1 Tổng hợp danh sách tất cả nhân viên từ cả 3 chi nhánh thành một danh sách thống nhất.
SELECT MaNV, HoTen, GioiTinh, NgayVaoLam, MaCN
FROM  giamdoc_cn1.NHANVIEN

UNION

SELECT MaNV, HoTen, GioiTinh, NgayVaoLam, MaCN
FROM  NHANVIEN@gd1_to_gd2 

UNION

SELECT MaNV, HoTen, GioiTinh, NgayVaoLam, MaCN
FROM   NHANVIEN@gd1_to_gd3

ORDER BY MaCN, MaNV;

--3 Thống kê tổng doanh thu theo từng chi nhánh, chỉ hiển thị những chi nhánh có doanh thu trên 50 triệu.

SELECT cn_data.MaCN,
       SUM(cn_data.TongTien) AS DoanhThu_TongCong
FROM (
    SELECT nv.MaCN, hd.TongTien
    FROM  GIAMDOC_CN1.HOADON hd
    JOIN   GIAMDOC_CN1.NHANVIEN nv ON nv.MaNV = hd.MaNV

    UNION ALL

    SELECT nv.MaCN, hd.TongTien
    FROM   GIAMDOC_CN2.HOADON@gd1_to_gd2 hd
    JOIN   GIAMDOC_CN2.NHANVIEN@gd1_to_gd2 nv ON nv.MaNV = hd.MaNV

    UNION ALL

    SELECT nv.MaCN, hd.TongTien
    FROM   GIAMDOC_CN3.HOADON@gd1_to_gd3 hd
    JOIN   GIAMDOC_CN3.NHANVIEN@gd1_to_gd3 nv ON nv.MaNV = hd.MaNV
) cn_data
GROUP BY cn_data.MaCN
HAVING SUM(cn_data.TongTien) > 50000000
ORDER BY DoanhThu_TongCong DESC;


--4  tổng chi tiêu (SUM) và số lần mua hàng (COUNT) của từng khách hàng. Chỉ lọc ra các khách hàng đã chi tiêu trên 10 triệu đồng.

SELECT kh.MaKH,
       kh.HoTen,
       kh.SoDienThoai,
       COUNT(all_hd.MaHD) AS TongSoDonHang,
       SUM(all_hd.TongTien) AS TongChiTieuToanHeThong,
       ROUND(AVG(all_hd.TongTien), 2) AS GiaTriDonHangBinhQuan
FROM giamdoc_cn1.KHACHHANG kh
JOIN (
    -- Gom dữ liệu hóa đơn từ cả 3 chi nhánh
    SELECT MaHD, MaKH, TongTien FROM giamdoc_cn1.HOADON
    UNION ALL
    SELECT MaHD, MaKH, TongTien FROM giamdoc_cn2.HOADON@gd1_to_gd2
    UNION ALL
    SELECT MaHD, MaKH, TongTien FROM giamdoc_cn3.HOADON@gd1_to_gd3
) all_hd ON kh.MaKH = all_hd.MaKH
GROUP BY kh.MaKH, kh.HoTen, kh.SoDienThoai
HAVING SUM(all_hd.TongTien) > 10000000
ORDER BY TongChiTieuToanHeThong DESC;


