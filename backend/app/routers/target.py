from fastapi import APIRouter, Form
from pydantic import BaseModel
from app.database import get_db_connection

router = APIRouter()

class TopUpRequest(BaseModel):
    target_id: int
    nominal: int

@router.post("/target/tambah/")
async def tambah_target(user_id: int = Form(...), nama: str = Form(...), nominal: int = Form(...), deadline: str = Form(...)):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO target_keuangan (user_id, nama_target, target_nominal, deadline) VALUES (%s, %s, %s, %s)", 
                       (user_id, nama, nominal, deadline))
        conn.commit()
        cursor.close()
        conn.close()
        return {"status": "sukses", "pesan": "Target berhasil ditambahkan!"}
    except Exception as e:
        return {"status": "gagal", "pesan": str(e)}

@router.get("/target/list/")
async def list_target(user_id: int):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM target_keuangan WHERE user_id=%s AND status='aktif'", (user_id,))
        data = cursor.fetchall()
        cursor.close()
        conn.close()
        return {"status": "sukses", "data": data}
    except Exception as e:
        return {"status": "gagal", "pesan": str(e)}

@router.post("/target/topup/")
async def topup_target(request: TopUpRequest):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # 1. Update total terkumpul di tabel utama
        sql_update = "UPDATE target_keuangan SET terkumpul = terkumpul + %s WHERE id = %s"
        cursor.execute(sql_update, (request.nominal, request.target_id))
        
        # 2. Catat riwayat penambahan dana ke tabel riwayat_target
        sql_insert = "INSERT INTO riwayat_target (target_id, nominal) VALUES (%s, %s)"
        cursor.execute(sql_insert, (request.target_id, request.nominal))
        
        conn.commit()
        cursor.close()
        conn.close()
        return {"status": "sukses", "pesan": "Dana berhasil dialokasikan"}
    except Exception as e:
        return {"status": "gagal", "pesan": str(e)}

# FITUR BARU: Mengambil riwayat alokasi dana dari sebuah target
@router.get("/target/history/")
async def history_target(target_id: int):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM riwayat_target WHERE target_id=%s ORDER BY tanggal DESC", (target_id,))
        data = cursor.fetchall()
        
        # Format tanggal menjadi string agar mudah dibaca JSON
        for row in data:
            if row['tanggal']:
                row['tanggal'] = row['tanggal'].strftime("%Y-%m-%d %H:%M:%S")
                
        cursor.close()
        conn.close()
        return {"status": "sukses", "data": data}
    except Exception as e:
        return {"status": "gagal", "pesan": str(e)}