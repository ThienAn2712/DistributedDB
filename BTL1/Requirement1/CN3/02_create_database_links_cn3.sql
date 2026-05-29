-- 02_create_database_links_cn3.sql
-- Tao database link tu site CN3 sang CN1 va CN2.
--
-- Luu y: database link private thuoc tung user.
--   PHAN A chay bang user giamdoc_cn3.
--   PHAN B chay bang user quanlikho_cn3.
--   PHAN C chay bang user nhanvien_cn3.

SET DEFINE OFF;

--------------------------------------------------------------------------------
-- PHAN A - Chay bang user: giamdoc_cn3
--------------------------------------------------------------------------------

BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK gd3_to_gd1';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2024 THEN
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK gd3_to_gd1
CONNECT TO giamdoc_cn1 IDENTIFIED BY giamdoc_cn1
USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=26.30.167.151)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)))';

BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK gd3_to_gd2';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2024 THEN
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK gd3_to_gd2
CONNECT TO giamdoc_cn2 IDENTIFIED BY giamdoc_cn2
USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=26.2.30.229)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=xe)))';

SELECT db_link, username, host, created
FROM user_db_links
ORDER BY db_link;

--------------------------------------------------------------------------------
-- PHAN B - Chay bang user: quanlikho_cn3
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
USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=26.30.167.151)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)))';

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
USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=26.2.30.229)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=xe)))';

SELECT db_link, username, host, created
FROM user_db_links
ORDER BY db_link;

--------------------------------------------------------------------------------
-- PHAN C - Chay bang user: nhanvien_cn3
--------------------------------------------------------------------------------

BEGIN
    EXECUTE IMMEDIATE 'DROP DATABASE LINK nv3_to_nv1';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2024 THEN
            RAISE;
        END IF;
END;
/

CREATE DATABASE LINK nv3_to_nv1
CONNECT TO nv_read_cn1 IDENTIFIED BY nv_read_cn1
USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=26.30.167.151)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)))';

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
USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=26.2.30.229)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=xe)))';

SELECT db_link, username, host, created
FROM user_db_links
ORDER BY db_link;

