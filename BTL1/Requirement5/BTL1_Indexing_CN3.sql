
SET TIMING ON;
SET SERVEROUTPUT ON;

--------------------------------------------------------------------------------
-- T0 - Kiem tra database link
--------------------------------------------------------------------------------

SELECT db_link, username, host
FROM user_db_links
WHERE db_link IN ('GD3_TO_GD1', 'GD3_TO_GD2')
ORDER BY db_link;

SELECT USER AS remote_user_cn1
FROM dual@GD3_TO_GD1;

SELECT USER AS remote_user_cn2
FROM dual@GD3_TO_GD2;

--------------------------------------------------------------------------------
-- T1 - Tao index tren cac site phan tan
--------------------------------------------------------------------------------

BEGIN
    EXECUTE IMMEDIATE
        'CREATE INDEX idx_hd_ngaylap_manv ON GIAMDOC_CN3.HOADON (NgayLap, MaNV)';
    DBMS_OUTPUT.PUT_LINE('CN3: created IDX_HD_NGAYLAP_MANV');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('CN3: IDX_HD_NGAYLAP_MANV da ton tai');
        ELSE
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE
        'CREATE INDEX idx_kb_macn_soluong ON GIAMDOC_CN3.KHO_BAN (MaCN, SoLuongTon)';
    DBMS_OUTPUT.PUT_LINE('CN3: created IDX_KB_MACN_SOLUONG');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('CN3: IDX_KB_MACN_SOLUONG da ton tai');
        ELSE
            RAISE;
        END IF;
END;
/

BEGIN
    DBMS_UTILITY.EXEC_DDL_STATEMENT@GD3_TO_GD1(
        'CREATE INDEX idx_hd_ngaylap_manv ON GIAMDOC_CN1.HOADON (NgayLap, MaNV)'
    );
    DBMS_OUTPUT.PUT_LINE('CN1: created IDX_HD_NGAYLAP_MANV');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('CN1: IDX_HD_NGAYLAP_MANV da ton tai');
        ELSE
            DBMS_OUTPUT.PUT_LINE('CN1: loi tao IDX_HD_NGAYLAP_MANV - ' || SQLERRM);
        END IF;
END;
/

BEGIN
    DBMS_UTILITY.EXEC_DDL_STATEMENT@GD3_TO_GD1(
        'CREATE INDEX idx_kb_macn_soluong ON GIAMDOC_CN1.KHO_BAN (MaCN, SoLuongTon)'
    );
    DBMS_OUTPUT.PUT_LINE('CN1: created IDX_KB_MACN_SOLUONG');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('CN1: IDX_KB_MACN_SOLUONG da ton tai');
        ELSE
            DBMS_OUTPUT.PUT_LINE('CN1: loi tao IDX_KB_MACN_SOLUONG - ' || SQLERRM);
        END IF;
END;
/

BEGIN
    DBMS_UTILITY.EXEC_DDL_STATEMENT@GD3_TO_GD2(
        'CREATE INDEX idx_hd_ngaylap_manv ON GIAMDOC_CN2.HOADON (NgayLap, MaNV)'
    );
    DBMS_OUTPUT.PUT_LINE('CN2: created IDX_HD_NGAYLAP_MANV');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('CN2: IDX_HD_NGAYLAP_MANV da ton tai');
        ELSE
            DBMS_OUTPUT.PUT_LINE('CN2: loi tao IDX_HD_NGAYLAP_MANV - ' || SQLERRM);
        END IF;
END;
/

BEGIN
    DBMS_UTILITY.EXEC_DDL_STATEMENT@GD3_TO_GD2(
        'CREATE INDEX idx_kb_macn_soluong ON GIAMDOC_CN2.KHO_BAN (MaCN, SoLuongTon)'
    );
    DBMS_OUTPUT.PUT_LINE('CN2: created IDX_KB_MACN_SOLUONG');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('CN2: IDX_KB_MACN_SOLUONG da ton tai');
        ELSE
            DBMS_OUTPUT.PUT_LINE('CN2: loi tao IDX_KB_MACN_SOLUONG - ' || SQLERRM);
        END IF;
END;
/

--------------------------------------------------------------------------------
-- T2 - Kiem tra index tren cac site
--------------------------------------------------------------------------------

SELECT 'CN3' AS site, index_name, table_name
FROM user_indexes
WHERE index_name IN ('IDX_HD_NGAYLAP_MANV', 'IDX_KB_MACN_SOLUONG')

UNION ALL

SELECT 'CN1' AS site, index_name, table_name
FROM user_indexes@GD3_TO_GD1
WHERE index_name IN ('IDX_HD_NGAYLAP_MANV', 'IDX_KB_MACN_SOLUONG')

UNION ALL

SELECT 'CN2' AS site, index_name, table_name
FROM user_indexes@GD3_TO_GD2
WHERE index_name IN ('IDX_HD_NGAYLAP_MANV', 'IDX_KB_MACN_SOLUONG')
ORDER BY site, table_name, index_name;

SELECT 'CN3' AS site, index_name, column_name, column_position
FROM user_ind_columns
WHERE index_name IN ('IDX_HD_NGAYLAP_MANV', 'IDX_KB_MACN_SOLUONG')

UNION ALL

SELECT 'CN1' AS site, index_name, column_name, column_position
FROM user_ind_columns@GD3_TO_GD1
WHERE index_name IN ('IDX_HD_NGAYLAP_MANV', 'IDX_KB_MACN_SOLUONG')

UNION ALL

SELECT 'CN2' AS site, index_name, column_name, column_position
FROM user_ind_columns@GD3_TO_GD2
WHERE index_name IN ('IDX_HD_NGAYLAP_MANV', 'IDX_KB_MACN_SOLUONG')
ORDER BY site, index_name, column_position;

--------------------------------------------------------------------------------
-- T3 - Query 1 phan tan truoc khi ap dung index
--------------------------------------------------------------------------------

SELECT /* Q1_DISTRIBUTED_BEFORE_L1 */
       COUNT(*) AS SoHoaDonTheoNgay
FROM (
    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN1.HOADON@GD3_TO_GD1 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN2.HOADON@GD3_TO_GD2 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN3.HOADON hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'
);

SELECT /* Q1_DISTRIBUTED_BEFORE_L2 */
       COUNT(*) AS SoHoaDonTheoNgay
FROM (
    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN1.HOADON@GD3_TO_GD1 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN2.HOADON@GD3_TO_GD2 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN3.HOADON hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'
);

SELECT /* Q1_DISTRIBUTED_BEFORE_L3 */
       COUNT(*) AS SoHoaDonTheoNgay
FROM (
    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN1.HOADON@GD3_TO_GD1 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN2.HOADON@GD3_TO_GD2 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ FULL(hd) */ hd.MaNV
    FROM GIAMDOC_CN3.HOADON hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'
);

--------------------------------------------------------------------------------
-- T4 - Query 1 phan tan sau khi ap dung index
--------------------------------------------------------------------------------

SELECT /* Q1_DISTRIBUTED_AFTER_L1 */
       COUNT(*) AS SoHoaDonTheoNgay
FROM (
    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN1.HOADON@GD3_TO_GD1 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN2.HOADON@GD3_TO_GD2 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN3.HOADON hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'
);

SELECT /* Q1_DISTRIBUTED_AFTER_L2 */
       COUNT(*) AS SoHoaDonTheoNgay
FROM (
    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN1.HOADON@GD3_TO_GD1 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN2.HOADON@GD3_TO_GD2 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN3.HOADON hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'
);

SELECT /* Q1_DISTRIBUTED_AFTER_L3 */
       COUNT(*) AS SoHoaDonTheoNgay
FROM (
    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN1.HOADON@GD3_TO_GD1 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN2.HOADON@GD3_TO_GD2 hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */ hd.MaNV
    FROM GIAMDOC_CN3.HOADON hd
    WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
      AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00'
);

--------------------------------------------------------------------------------
-- T5 - Query 2 phan tan truoc khi ap dung index
--------------------------------------------------------------------------------

SELECT /* Q2_DISTRIBUTED_BEFORE_L1 */
       COUNT(*) AS SoSachSapHetHang
FROM (
    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN1.KHO_BAN@GD3_TO_GD1 kb
    WHERE kb.MaCN = 'CN001'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN2.KHO_BAN@GD3_TO_GD2 kb
    WHERE kb.MaCN = 'CN002'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN3.KHO_BAN kb
    WHERE kb.MaCN = 'CN003'
      AND kb.SoLuongTon <= 5
);

SELECT /* Q2_DISTRIBUTED_BEFORE_L2 */
       COUNT(*) AS SoSachSapHetHang
FROM (
    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN1.KHO_BAN@GD3_TO_GD1 kb
    WHERE kb.MaCN = 'CN001'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN2.KHO_BAN@GD3_TO_GD2 kb
    WHERE kb.MaCN = 'CN002'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN3.KHO_BAN kb
    WHERE kb.MaCN = 'CN003'
      AND kb.SoLuongTon <= 5
);

SELECT /* Q2_DISTRIBUTED_BEFORE_L3 */
       COUNT(*) AS SoSachSapHetHang
FROM (
    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN1.KHO_BAN@GD3_TO_GD1 kb
    WHERE kb.MaCN = 'CN001'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN2.KHO_BAN@GD3_TO_GD2 kb
    WHERE kb.MaCN = 'CN002'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ FULL(kb) */ kb.MaSach
    FROM GIAMDOC_CN3.KHO_BAN kb
    WHERE kb.MaCN = 'CN003'
      AND kb.SoLuongTon <= 5
);

--------------------------------------------------------------------------------
-- T6 - Query 2 phan tan sau khi ap dung index
--------------------------------------------------------------------------------

SELECT /* Q2_DISTRIBUTED_AFTER_L1 */
       COUNT(*) AS SoSachSapHetHang
FROM (
    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN1.KHO_BAN@GD3_TO_GD1 kb
    WHERE kb.MaCN = 'CN001'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN2.KHO_BAN@GD3_TO_GD2 kb
    WHERE kb.MaCN = 'CN002'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN3.KHO_BAN kb
    WHERE kb.MaCN = 'CN003'
      AND kb.SoLuongTon <= 5
);

SELECT /* Q2_DISTRIBUTED_AFTER_L2 */
       COUNT(*) AS SoSachSapHetHang
FROM (
    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN1.KHO_BAN@GD3_TO_GD1 kb
    WHERE kb.MaCN = 'CN001'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN2.KHO_BAN@GD3_TO_GD2 kb
    WHERE kb.MaCN = 'CN002'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN3.KHO_BAN kb
    WHERE kb.MaCN = 'CN003'
      AND kb.SoLuongTon <= 5
);

SELECT /* Q2_DISTRIBUTED_AFTER_L3 */
       COUNT(*) AS SoSachSapHetHang
FROM (
    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN1.KHO_BAN@GD3_TO_GD1 kb
    WHERE kb.MaCN = 'CN001'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN2.KHO_BAN@GD3_TO_GD2 kb
    WHERE kb.MaCN = 'CN002'
      AND kb.SoLuongTon <= 5

    UNION ALL

    SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */ kb.MaSach
    FROM GIAMDOC_CN3.KHO_BAN kb
    WHERE kb.MaCN = 'CN003'
      AND kb.SoLuongTon <= 5
);

--------------------------------------------------------------------------------
-- T7 
--------------------------------------------------------------------------------

DELETE FROM plan_table
WHERE statement_id IN (
    'Q1_BEFORE_FULLSCAN',
    'Q1_AFTER_INDEX',
    'Q2_BEFORE_FULLSCAN',
    'Q2_AFTER_INDEX'
);

COMMIT;

--------------------------------------------------------------------------------
-- T8 - Plan Query 1
--------------------------------------------------------------------------------

EXPLAIN PLAN SET STATEMENT_ID = 'Q1_BEFORE_FULLSCAN' FOR
SELECT /*+ FULL(hd) */
       COUNT(*) AS SoHoaDonTheoNgay
FROM GIAMDOC_CN3.HOADON hd
WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
  AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q1_BEFORE_FULLSCAN', 'BASIC +PREDICATE'));

--------------------------------------------------------------------------------
-- T9 - Plan Query 1 sau khi ap dung index
--------------------------------------------------------------------------------

EXPLAIN PLAN SET STATEMENT_ID = 'Q1_AFTER_INDEX' FOR
SELECT /*+ INDEX_RS_ASC(hd IDX_HD_NGAYLAP_MANV) */
       COUNT(*) AS SoHoaDonTheoNgay
FROM GIAMDOC_CN3.HOADON hd
WHERE hd.NgayLap >= TIMESTAMP '2025-01-01 00:00:00'
  AND hd.NgayLap <  TIMESTAMP '2025-02-01 00:00:00';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q1_AFTER_INDEX', 'BASIC +PREDICATE'));

--------------------------------------------------------------------------------
-- T10 - Plan Query 2 truoc khi ap dung index
--------------------------------------------------------------------------------

EXPLAIN PLAN SET STATEMENT_ID = 'Q2_BEFORE_FULLSCAN' FOR
SELECT /*+ FULL(kb) */
       COUNT(*) AS SoSachSapHetHang
FROM GIAMDOC_CN3.KHO_BAN kb
WHERE kb.MaCN = 'CN003'
  AND kb.SoLuongTon <= 5;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q2_BEFORE_FULLSCAN', 'BASIC +PREDICATE'));

--------------------------------------------------------------------------------
-- T11 - Plan Query 2 sau khi ap dung index
--------------------------------------------------------------------------------

EXPLAIN PLAN SET STATEMENT_ID = 'Q2_AFTER_INDEX' FOR
SELECT /*+ INDEX_RS_ASC(kb IDX_KB_MACN_SOLUONG) */
       COUNT(*) AS SoSachSapHetHang
FROM GIAMDOC_CN3.KHO_BAN kb
WHERE kb.MaCN = 'CN003'
  AND kb.SoLuongTon <= 5;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'Q2_AFTER_INDEX', 'BASIC +PREDICATE'));