-- Procedure: Kiểm tra tồn kho của cả 3 chi nhánh 
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
-- Execute
SET LINESIZE 300;

VARIABLE rc REFCURSOR;

EXEC sp_test_tonkho_3cn_v3('S0015', :rc);

PRINT rc;






