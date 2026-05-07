from fastapi import APIRouter, UploadFile, File, Form, Query
import base64
import os
import hashlib 
import pandas as pd
from openai import OpenAI
from app.services.ml_model import model_ai 
from app.database import get_db_connection

router = APIRouter()
endpoint = "https://models.inference.ai.azure.com"

# --- FUNGSI KEAMANAN ---
def hash_password(password: str):
    return hashlib.sha256(password.encode()).hexdigest()

# --- ENDPOINT LOGIN & REGISTER ---
@router.post("/register/")
async def register(nama: str = Form(...), email: str = Form(...), password: str = Form(...)):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        hashed_pw = hash_password(password)
        cursor.execute("INSERT INTO users (nama, email, password) VALUES (%s, %s, %s)", (nama, email, hashed_pw))
        conn.commit()
        cursor.close()
        conn.close()
        return {"status": "sukses", "pesan": "Registrasi berhasil!"}
    except Exception as e:
        return {"status": "gagal", "pesan": "Email sudah terdaftar atau terjadi kesalahan."}

@router.post("/login/")
async def login(email: str = Form(...), password: str = Form(...)):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        hashed_pw = hash_password(password)
        cursor.execute("SELECT id, nama, email FROM users WHERE email=%s AND password=%s", (email, hashed_pw))
        user = cursor.fetchone()
        cursor.close()
        conn.close()

        if user:
            # TAMBAHAN: Kini backend mengembalikan 'id' user ke Flutter
            return {"status": "sukses", "data": {"id": user["id"], "nama": user["nama"], "email": user["email"]}}
        else:
            return {"status": "gagal", "pesan": "Email atau password salah."}
    except Exception as e:
        return {"status": "gagal", "pesan": "Database error."}

# --- ENDPOINT ANALISIS ---
@router.post("/analisis-pendapatan/")
async def analisis_pendapatan(
    user_id: int = Form(...), # TAMBAHAN: Menerima ID User
    file: UploadFile = File(...), 
    kebutuhan_dinamis: int = Form(0),
    rincian: str = Form(""),
    tipe_pendapatan: str = Form("Harian"), 
    lama_waktu: str = Form("") 
):
    token = os.getenv("GITHUB_TOKEN")
    client_ai = OpenAI(base_url=endpoint, api_key=token)
    pendapatan = 0

    try:
        image_bytes = await file.read()
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        mime_type = file.content_type or "image/jpeg"
        if mime_type == "application/octet-stream":
            mime_type = "image/png" if file.filename.lower().endswith(".png") else "image/jpeg"
        image_data_uri = f"data:{mime_type};base64,{image_base64}"

        prompt_baca = "Temukan 'Total Pendapatan' dari struk ini. Kembalikan HANYA angka bulat saja tanpa teks lain."
        response_baca = client_ai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": [{"type": "text", "text": prompt_baca}, {"type": "image_url", "image_url": {"url": image_data_uri, "detail": "low"}}]}]
        )
        pendapatan = int(''.join(filter(str.isdigit, response_baca.choices[0].message.content.strip())))
    except Exception as e:
        return {"status": "gagal", "pesan": f"Gagal membaca struk. Error: {e}"}

    surplus = pendapatan - kebutuhan_dinamis

    try:
        prompt_budget = f"Saya baru mendapat penghasilan dengan tipe '{tipe_pendapatan}' sebesar Rp {pendapatan}."
        if tipe_pendapatan == "Proyek / Freelance" and lama_waktu != "":
            prompt_budget += f" Uang ini harus dikelola agar cukup untuk memenuhi kebutuhan hidup selama {lama_waktu} ke depan."
        
        prompt_budget += """ 
        Berikan saran manajemen keuangan singkat (pembagian % dan nominal Rupiah) untuk:
        1. Kebutuhan Pokok
        2. Kebutuhan Sekunder/Hiburan
        3. Tabungan/Investasi
        Sesuaikan persentasenya dengan logika yang sehat berdasarkan nominal dan durasi bertahan hidup (jika ada). Jika pendapatan besar, perkecil proporsi Kebutuhan Pokok dan besarkan Investasi (Progressive Budgeting).
        Jawab dengan format poin-poin singkat tanpa basa-basi (maksimal 4 baris).
        """
        response_budget = client_ai.chat.completions.create(model="gpt-4o-mini", messages=[{"role": "user", "content": prompt_budget}], max_tokens=200)
        saran_budget = response_budget.choices[0].message.content.strip()
    except Exception:
        saran_budget = "Gunakan metode 50/30/20 untuk Pokok, Sekunder, dan Investasi."

    if surplus <= 0:
        rekomendasi_ml = "Tidak ada sisa dana. Fokus penuhi kebutuhan pokok dan siapkan dana darurat."
    else:
        data_prediksi = pd.DataFrame([[surplus]], columns=['Surplus'])
        rekomendasi_ml = model_ai.predict(data_prediksi)[0]

    rekomendasi_final = f"📊 Rencana Alokasi AI:\n{saran_budget}\n\n🎯 Saran Instrumen (Sisa Kas): {rekomendasi_ml}"

    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            # TAMBAHAN: Memasukkan user_id ke database
            query = "INSERT INTO riwayat_analisis (user_id, pendapatan, kebutuhan, rincian, surplus, rekomendasi) VALUES (%s, %s, %s, %s, %s, %s)"
            values = (user_id, pendapatan, kebutuhan_dinamis, rincian, surplus, rekomendasi_final)
            cursor.execute(query, values)
            conn.commit() 
            cursor.close()
            conn.close()
    except Exception as db_err:
        print(f"Database Error: {db_err}")

    return {
        "status": "sukses", "pendapatan_terdeteksi": pendapatan, "kebutuhan_harian": kebutuhan_dinamis, "rincian": rincian, "surplus": surplus, "rekomendasi_investasi": rekomendasi_final
    }

@router.get("/riwayat/")
async def get_riwayat(user_id: int): # TAMBAHAN: Menerima query user_id
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor(dictionary=True) 
            # TAMBAHAN: Menarik riwayat khusus untuk user yang sedang login saja
            cursor.execute("SELECT * FROM riwayat_analisis WHERE user_id=%s ORDER BY tanggal DESC", (user_id,))
            hasil = cursor.fetchall()
            cursor.close()
            conn.close()
            return {"status": "sukses", "data": hasil}
    except Exception as e:
        return {"status": "gagal", "pesan": "Database bermasalah"}
    return {"status": "sukses", "data": []}