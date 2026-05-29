from __future__ import annotations

import os
from datetime import datetime, date
from decimal import Decimal
from typing import Any, Dict, Iterable, List

import oracledb
from pymongo import MongoClient

from airflow import DAG
from airflow.operators.python import PythonOperator


# =========================
# Configuration
# =========================

ORACLE_HOST = os.getenv("ORACLE_HOST")
ORACLE_PORT = int(os.getenv("ORACLE_PORT", "1521"))
ORACLE_SID = os.getenv("ORACLE_SID")
ORACLE_USER = os.getenv("ORACLE_USER")
ORACLE_PASSWORD = os.getenv("ORACLE_PASSWORD")

MONGO_CONN = os.getenv("MONGO_CONN", "mongodb://admin:admin@mongodb:27017/")
MONGO_DB_NAME = "bookstore"

BATCH_SIZE = int(os.getenv("BATCH_SIZE", "1000"))


# Nguồn dữ liệu:
# - CN2: local
# - CN1: qua DB LINK gd2_to_gd1
# - CN3: qua DB LINK gd2_to_gd3
BRANCH_SOURCES = [
    {
        "sourceBranch": "CN002",
        "suffix": ""
    },
    {
        "sourceBranch": "CN001",
        "suffix": "@gd2_to_gd1"
    },
    {
        "sourceBranch": "CN003",
        "suffix": "@gd2_to_gd3"
    }
]


# =========================
# Helper functions
# =========================

def get_oracle_connection():
    if not ORACLE_HOST or not ORACLE_SID or not ORACLE_USER or not ORACLE_PASSWORD:
        raise ValueError(
            "Missing Oracle config. Please set ORACLE_HOST, ORACLE_PORT, "
            "ORACLE_SID, ORACLE_USER, ORACLE_PASSWORD."
        )

    dsn = oracledb.makedsn(
        ORACLE_HOST,
        ORACLE_PORT,
        sid=ORACLE_SID
    )

    return oracledb.connect(
        user=ORACLE_USER,
        password=ORACLE_PASSWORD,
        dsn=dsn
    )


def get_mongo_db():
    client = MongoClient(MONGO_CONN)
    return client[MONGO_DB_NAME]


def convert_value(value: Any) -> Any:
    if isinstance(value, Decimal):
        if value == value.to_integral_value():
            return int(value)
        return float(value)

    if isinstance(value, datetime):
        return value

    if isinstance(value, date):
        return datetime(value.year, value.month, value.day)

    return value


def reset_collection(collection):
    """
    Xóa dữ liệu cũ nhưng giữ lại indexes đã tạo ở Step 2.
    """
    collection.delete_many({})


def insert_many_in_batches(collection, docs: Iterable[Dict[str, Any]], batch_size: int = BATCH_SIZE):
    batch: List[Dict[str, Any]] = []

    for doc in docs:
        clean_doc = {key: convert_value(value) for key, value in doc.items()}
        batch.append(clean_doc)

        if len(batch) >= batch_size:
            collection.insert_many(batch, ordered=False)
            batch.clear()

    if batch:
        collection.insert_many(batch, ordered=False)


def build_union_query(table_name: str, columns: List[str]) -> str:
    """
    Tạo query UNION ALL cho 3 nguồn:
    - local CN2
    - CN1 qua gd2_to_gd1
    - CN3 qua gd2_to_gd3
    """
    select_parts = []

    col_text = ", ".join(columns)

    for src in BRANCH_SOURCES:
        branch = src["sourceBranch"]
        suffix = src["suffix"]

        select_parts.append(
            f"""
            SELECT
                '{branch}' AS SourceBranch,
                {col_text}
            FROM {table_name}{suffix}
            """
        )

    return "\nUNION ALL\n".join(select_parts)


# =========================
# Migration tasks
# =========================

def migrate_sach():
    """
    SACH là bảng nhân bản ở 3 chi nhánh.
    Chỉ load 1 lần từ CN2 local để tránh trùng _id.
    """
    ora = get_oracle_connection()
    db = get_mongo_db()

    col = db.sach
    reset_collection(col)

    cur = ora.cursor()
    cur.execute("""
        SELECT
            MaSach,
            TenSach,
            TacGia,
            TheLoai,
            NhaXuatBan,
            GiaBan
        FROM SACH
    """)

    def docs():
        for row in cur:
            yield {
                "_id": str(row[0]),
                "tenSach": row[1],
                "tacGia": row[2],
                "theLoai": row[3],
                "nhaXuatBan": row[4],
                "giaBan": float(row[5] or 0)
            }

    insert_many_in_batches(col, docs())

    print(f"sach: {col.count_documents({})} documents")

    cur.close()
    ora.close()


def migrate_khachhang():
    """
    KHACHHANG là bảng nhân bản ở 3 chi nhánh.
    Chỉ load 1 lần từ CN2 local để tránh trùng _id.
    """
    ora = get_oracle_connection()
    db = get_mongo_db()

    col = db.khachhang
    reset_collection(col)

    cur = ora.cursor()
    cur.execute("""
        SELECT
            MaKH,
            HoTen,
            GioiTinh,
            NgaySinh,
            DiaChi,
            SoDienThoai
        FROM KHACHHANG
    """)

    def docs():
        for row in cur:
            yield {
                "_id": str(row[0]),
                "hoTen": row[1],
                "gioiTinh": row[2],
                "ngaySinh": convert_value(row[3]),
                "diaChi": row[4],
                "soDienThoai": row[5]
            }

    insert_many_in_batches(col, docs())

    print(f"khachhang: {col.count_documents({})} documents")

    cur.close()
    ora.close()


def migrate_chinhanh():
    """
    CHINHANH là bảng phân tán.
    Load cả CN1 + CN2 + CN3.
    """
    ora = get_oracle_connection()
    db = get_mongo_db()

    col = db.chinhanh
    reset_collection(col)

    query = build_union_query(
        table_name="CHINHANH",
        columns=[
            "MaCN",
            "TenCN",
            "DiaChi"
        ]
    )

    cur = ora.cursor()
    cur.execute(query)

    def docs():
        for row in cur:
            source_branch = str(row[0])

            yield {
                "_id": str(row[1]),
                "maCN": str(row[1]),
                "tenCN": row[2],
                "diaChi": row[3],
                "sourceBranch": source_branch,
                "kho": []
            }

    insert_many_in_batches(col, docs())

    print(f"chinhanh: {col.count_documents({})} documents")

    cur.close()
    ora.close()


def migrate_nhanvien():
    """
    NHANVIEN là bảng phân tán.
    Load cả CN1 + CN2 + CN3.
    Vì bạn đã kiểm tra MaNV không trùng, giữ _id = MaNV.
    """
    ora = get_oracle_connection()
    db = get_mongo_db()

    col = db.nhanvien
    reset_collection(col)

    query = build_union_query(
        table_name="NHANVIEN",
        columns=[
            "MaNV",
            "HoTen",
            "GioiTinh",
            "NgaySinh",
            "SoDienThoai",
            "NgayVaoLam",
            "MaCN"
        ]
    )

    cur = ora.cursor()
    cur.execute(query)

    def docs():
        for row in cur:
            source_branch = str(row[0])

            yield {
                "_id": str(row[1]),
                "maNV": str(row[1]),
                "hoTen": row[2],
                "gioiTinh": row[3],
                "ngaySinh": convert_value(row[4]),
                "soDienThoai": row[5],
                "ngayVaoLam": convert_value(row[6]),
                "maCN": str(row[7]) if row[7] is not None else None,
                "sourceBranch": source_branch
            }

    insert_many_in_batches(col, docs())

    print(f"nhanvien: {col.count_documents({})} documents")

    cur.close()
    ora.close()


def migrate_kho_nhap():
    """
    KHO_NHAP là bảng phân tán.
    Load cả CN1 + CN2 + CN3 vào collection kho_nhap.
    Không đặt _id thủ công, để MongoDB tự tạo ObjectId.
    """
    ora = get_oracle_connection()
    db = get_mongo_db()

    col = db.kho_nhap
    reset_collection(col)

    query = build_union_query(
        table_name="KHO_NHAP",
        columns=[
            "MaCN",
            "MaSach",
            "NgayNhap",
            "SoLuongNhap",
            "GiaNhap"
        ]
    )

    cur = ora.cursor()
    cur.execute(query)

    def docs():
        for row in cur:
            source_branch = str(row[0])

            yield {
                "sourceBranch": source_branch,
                "maCN": str(row[1]),
                "maSach": str(row[2]),
                "ngayNhap": convert_value(row[3]),
                "soLuongNhap": int(row[4] or 0),
                "giaNhap": float(row[5] or 0)
            }

    insert_many_in_batches(col, docs())

    print(f"kho_nhap: {col.count_documents({})} documents")

    cur.close()
    ora.close()


def migrate_hoadon_and_embedded_data():
    """
    Task này làm 2 việc:

    1. Load KHO_BAN từ cả 3 chi nhánh và nhúng vào chinhanh.kho.
    2. Load HOADON từ cả 3 chi nhánh và nhúng CHITIET_HD vào hoadon.chiTiet.

    Vì bạn đã kiểm tra MaHD không trùng giữa 3 chi nhánh,
    giữ _id = MaHD.
    """
    ora = get_oracle_connection()
    db = get_mongo_db()

    # =========================
    # 1. Embed KHO_BAN into chinhanh.kho
    # =========================
    kho_query = build_union_query(
        table_name="KHO_BAN",
        columns=[
            "MaCN",
            "MaSach",
            "SoLuongTon",
            "TrangThai"
        ]
    )

    kho_cur = ora.cursor()
    kho_cur.execute(kho_query)

    kho_by_branch: Dict[str, List[Dict[str, Any]]] = {}

    for row in kho_cur:
        source_branch = str(row[0])
        ma_cn = str(row[1])

        item = {
            "maSach": str(row[2]),
            "soLuongTon": int(row[3] or 0),
            "trangThai": row[4],
            "sourceBranch": source_branch
        }

        kho_by_branch.setdefault(ma_cn, []).append(item)

    for ma_cn, kho_items in kho_by_branch.items():
        db.chinhanh.update_one(
            {"_id": ma_cn},
            {"$set": {"kho": kho_items}}
        )

    total_kho_items = sum(len(items) for items in kho_by_branch.values())
    print(f"embedded kho into {len(kho_by_branch)} branches")
    print(f"total kho items embedded: {total_kho_items}")

    kho_cur.close()

    # =========================
    # 2. Load CHITIET_HD grouped by MaHD
    # =========================
    detail_select_parts = []

    for src in BRANCH_SOURCES:
        source_branch = src["sourceBranch"]
        suffix = src["suffix"]

        detail_select_parts.append(
            f"""
            SELECT
                '{source_branch}' AS SourceBranch,
                c.MaHD,
                c.MaSach,
                s.TenSach,
                c.SoLuong,
                s.GiaBan
            FROM CHITIET_HD{suffix} c
            JOIN SACH{suffix} s ON c.MaSach = s.MaSach
            """
        )

    detail_query = "\nUNION ALL\n".join(detail_select_parts)

    detail_cur = ora.cursor()
    detail_cur.execute(detail_query)

    detail_map: Dict[str, List[Dict[str, Any]]] = {}

    for row in detail_cur:
        source_branch = str(row[0])
        ma_hd = str(row[1])

        detail_map.setdefault(ma_hd, []).append({
            "maSach": str(row[2]),
            "tenSach": row[3],
            "soLuong": int(row[4] or 0),
            "donGia": float(row[5] or 0),
            "sourceBranch": source_branch
        })

    total_detail_items = sum(len(items) for items in detail_map.values())
    print(f"loaded details for {len(detail_map)} invoices")
    print(f"total detail items loaded: {total_detail_items}")

    detail_cur.close()

    # =========================
    # 3. Load employee -> branch map
    # =========================
    nv_query = build_union_query(
        table_name="NHANVIEN",
        columns=[
            "MaNV",
            "MaCN"
        ]
    )

    nv_cur = ora.cursor()
    nv_cur.execute(nv_query)

    nv_cn_map = {
        str(row[1]): str(row[2])
        for row in nv_cur
        if row[1] is not None and row[2] is not None
    }

    nv_cur.close()

    # =========================
    # 4. Migrate HOADON from all branches
    # =========================
    hoadon_col = db.hoadon
    reset_collection(hoadon_col)

    hd_query = build_union_query(
        table_name="HOADON",
        columns=[
            "MaHD",
            "MaKH",
            "MaNV",
            "NgayLap",
            "TongTien"
        ]
    )

    hd_cur = ora.cursor()
    hd_cur.execute(hd_query)

    def docs():
        for row in hd_cur:
            source_branch = str(row[0])
            ma_hd = str(row[1])
            ma_nv = str(row[3]) if row[3] is not None else None

            yield {
                "_id": ma_hd,
                "maHD": ma_hd,
                "maKH": str(row[2]) if row[2] is not None else None,
                "maNV": ma_nv,
                "maCN": nv_cn_map.get(ma_nv),
                "sourceBranch": source_branch,
                "ngayLap": convert_value(row[4]),
                "tongTien": float(row[5] or 0),
                "chiTiet": detail_map.get(ma_hd, [])
            }

    insert_many_in_batches(hoadon_col, docs())

    print(f"hoadon: {hoadon_col.count_documents({})} documents")

    hd_cur.close()
    ora.close()


# =========================
# DAG definition
# =========================

with DAG(
    dag_id="etl_oracle_to_mongo_3cn",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
    tags=["migration", "bookstore", "3-branches"],
) as dag:

    t_sach = PythonOperator(
        task_id="migrate_sach",
        python_callable=migrate_sach
    )

    t_khachhang = PythonOperator(
        task_id="migrate_khachhang",
        python_callable=migrate_khachhang
    )

    t_chinhanh = PythonOperator(
        task_id="migrate_chinhanh",
        python_callable=migrate_chinhanh
    )

    t_nhanvien = PythonOperator(
        task_id="migrate_nhanvien",
        python_callable=migrate_nhanvien
    )

    t_kho_nhap = PythonOperator(
        task_id="migrate_kho_nhap",
        python_callable=migrate_kho_nhap
    )

    t_hoadon = PythonOperator(
        task_id="migrate_hoadon_and_embedded_data",
        python_callable=migrate_hoadon_and_embedded_data
    )

    [t_sach, t_khachhang, t_chinhanh, t_nhanvien] >> t_hoadon
    [t_sach, t_chinhanh] >> t_kho_nhap