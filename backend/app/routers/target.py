from fastapi import APIRouter, Form
from app.database import get_db_connection

router = APIRouter()

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