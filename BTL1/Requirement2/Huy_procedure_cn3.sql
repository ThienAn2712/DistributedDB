--------------------------------------------------------------------------------
-- Procedure: Kiem tra ton kho cua mot dau sach tren ca 3 chi nhanh
-- Connection thuc thi: giamdoc_cn2/giamdoc_cn2
-- Database link su dung:
--   gd2_to_gd1: CN2 -> CN1
--   gd2_to_gd3: CN2 -> CN3
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_test_tonkho_3cn_v3 (
    p_masach IN VARCHAR2,
    p_result OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_result FOR
        SELECT 'CN01' AS MaCN, MaSach, SoLuongTon, TrangThai
        FROM KHO_BAN@gd2_to_gd1
        WHERE MaSach = p_masach

        UNION ALL

        SELECT 'CN02' AS MaCN, MaSach, SoLuongTon, TrangThai
        FROM KHO_BAN
        WHERE MaSach = p_masach

        UNION ALL

        SELECT 'CN03' AS MaCN, MaSach, SoLuongTon, TrangThai
        FROM KHO_BAN@gd2_to_gd3
        WHERE MaSach = p_masach;
END;
/

SHOW ERRORS PROCEDURE sp_test_tonkho_3cn_v3;

--------------------------------------------------------------------------------
-- Test case 1: Sach ton tai tren he thong
-- Ket qua mong doi: tra ve ton kho cua S0684 tai CN01, CN02, CN03.
--------------------------------------------------------------------------------

VARIABLE rc REFCURSOR;
EXEC sp_test_tonkho_3cn_v3('S0684', :rc);
PRINT rc;

--------------------------------------------------------------------------------
-- Test case 2: Sach ton tai tren he thong voi ma sach khac
-- Ket qua mong doi: tra ve ton kho cua S0046 tai CN01, CN02, CN03 neu co du lieu.
--------------------------------------------------------------------------------

VARIABLE rc2 REFCURSOR;
EXEC sp_test_tonkho_3cn_v3('S0046', :rc2);
PRINT rc2;

--------------------------------------------------------------------------------
-- Test case 3: Ma sach khong ton tai
-- Ket qua mong doi: khong co dong du lieu nao duoc tra ve, procedure khong bao loi.
--------------------------------------------------------------------------------

VARIABLE rc3 REFCURSOR;
EXEC sp_test_tonkho_3cn_v3('S9999', :rc3);
PRINT rc3;

--------------------------------------------------------------------------------
-- Test case 4: Dau vao NULL
-- Ket qua mong doi: khong co dong du lieu nao duoc tra ve, procedure khong bao loi.
--------------------------------------------------------------------------------

VARIABLE rc4 REFCURSOR;
EXEC sp_test_tonkho_3cn_v3(NULL, :rc4);
PRINT rc4;
