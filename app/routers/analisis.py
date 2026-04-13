from fastapi import APIRouter, UploadFile, File, Form
import base64
import os
import pandas as pd
from openai import OpenAI
from app.services.ml_model import model_ai 
from app.database import get_db_connection

router = APIRouter()
endpoint = "https://models.inference.ai.azure.com"

@router.post("/analisis-pendapatan/")
async def analisis_pendapatan(
    file: UploadFile = File(...), 
    kebutuhan_dinamis: int = Form(0)
):
    token = os.getenv("GITHUB_TOKEN")
    client_ai = OpenAI(base_url=endpoint, api_key=token)
    
    pendapatan = 0

    try:
        image_bytes = await file.read()
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        mime_type = file.content_type 
        
        if not mime_type or mime_type == "application/octet-stream":
            if file.filename and file.filename.lower().endswith(".png"):
                mime_type = "image/png"
            else:
                mime_type = "image/jpeg" 
                
        image_data_uri = f"data:{mime_type};base64,{image_base64}"

        prompt_text = """
        Anda adalah asisten keuangan cerdas. Tolong perhatikan struk pendapatan Gojek ini. 
        Tugas Anda adalah menemukan "Total Pendapatan" (Angka nominal yang paling besar, biasanya terletak di atas dan berwarna hijau terang).
        PENTING: 
        - JANGAN mengembalikan teks lain.
        - JANGAN menyertakan 'Rp' atau titik/koma.
        - KEMBALIKAN HANYA ANGKA BULAT.
        """

        response = client_ai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt_text},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": image_data_uri,
                                "detail": "low"
                            }
                        }
                    ]
                }
            ],
            max_tokens=50
        )
        
        teks_hasil = response.choices[0].message.content.strip()
        pendapatan = int(''.join(filter(str.isdigit, teks_hasil)))
            
    except Exception as e:
        print(f"Detail Error API: {str(e)}")
        return {"status": "gagal", "pesan": f"Gagal membaca struk. Server AI menolak."}

    kebutuhan = kebutuhan_dinamis
    surplus = pendapatan - kebutuhan

    if surplus <= 0:
        rekomendasi = "Fokus penuhi kebutuhan pokok. Belum ada alokasi investasi."
    else:
        data_prediksi = pd.DataFrame([[surplus]], columns=['Surplus'])
        prediksi = model_ai.predict(data_prediksi)
        rekomendasi = prediksi[0]

    # Menyimpan ke Database XAMPP (MySQL)
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            query = "INSERT INTO riwayat_analisis (pendapatan, kebutuhan, surplus, rekomendasi) VALUES (%s, %s, %s, %s)"
            values = (pendapatan, kebutuhan, surplus, rekomendasi)
            cursor.execute(query, values)
            conn.commit() 
            cursor.close()
            conn.close()
            print("Berhasil! 1 baris data baru telah dicatat di XAMPP.")
    except Exception as db_err:
        print(f"Waduh, gagal mencatat ke database: {db_err}")

    return {
        "status": "sukses",
        "pendapatan_terdeteksi": pendapatan,
        "kebutuhan_harian": kebutuhan,
        "surplus": surplus,
        "rekomendasi_investasi": rekomendasi
    }

# FUNGSI WAJIB UNTUK BUKU BESAR (Jangan Dihapus)
@router.get("/riwayat/")
async def get_riwayat():
    try:
        conn = get_db_connection()
        if conn:
            # dictionary=True agar data keluar dalam format JSON yang rapi
            cursor = conn.cursor(dictionary=True) 
            cursor.execute("SELECT * FROM riwayat_analisis ORDER BY tanggal DESC")
            hasil = cursor.fetchall()
            cursor.close()
            conn.close()
            return {"status": "sukses", "data": hasil}
    except Exception as e:
        print(f"Gagal mengambil data: {e}")
        return {"status": "gagal", "pesan": "Database bermasalah"}
    
    return {"status": "sukses", "data": []}