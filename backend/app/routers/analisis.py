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
    kebutuhan_dinamis: int = Form(0),
    rincian: str = Form(""),
    tipe_pendapatan: str = Form("Harian"), 
    lama_waktu: int = Form(0) 
):
    token = os.getenv("GITHUB_TOKEN")
    client_ai = OpenAI(base_url=endpoint, api_key=token)
    
    pendapatan = 0

    try:
        # 1. PROSES BACA GAMBAR
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

    # 2. AI SEBAGAI MANAJER KEUANGAN (ANALISIS RINCIAN & SISA UANG)
    try:
        prompt_budget = f"""
        Saya baru mendapat penghasilan tipe '{tipe_pendapatan}' sebesar Rp {pendapatan}.
        """
        if tipe_pendapatan == "Proyek / Freelance" and lama_waktu > 0:
            prompt_budget += f"Uang ini harus dikelola untuk bertahan hidup selama {lama_waktu} hari ke depan.\n"
        
        prompt_budget += f"""
        Berikut adalah daftar pengeluaran riil yang BARU SAJA saya keluarkan hari ini:
        {rincian}
        Total pengeluaran: Rp {kebutuhan_dinamis}.
        Sisa uang saat ini (Surplus): Rp {surplus}.

        Tugas Anda sebagai Manajer Keuangan AI:
        1. Evaluasi Pengeluaran Riil: Kelompokkan pengeluaran di atas (contoh: Makan/Bensin -> Kebutuhan Pokok Operasional, Ban Bocor/Sakit -> Darurat/Mendesak, Pinjaman Teman -> Sosial/Lainnya). Beri sedikit apresiasi/teguran apakah pengeluaran ini sudah bijak.
        2. Rencana SISA UANG: Berikan saran alokasi (dalam nominal) HANYA untuk sisa uang (Rp {surplus}) dengan aturan Progressive Budgeting (jika pendapatan <5jt pakai 50/30/20, jika belasan/puluhan juta perkecil % pokok dan besarkan % investasi).
        
        Jawab dengan format poin-poin bernomor yang sangat singkat, padat, dan langsung ke intinya. Maksimal 5 baris poin.
        """

        response_budget = client_ai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt_budget}],
            max_tokens=250
        )
        saran_budget = response_budget.choices[0].message.content.strip()
    except Exception:
        saran_budget = "Gagal memuat saran manajemen keuangan dari AI."

    # 3. ML MODEL: REKOMENDASI INVESTASI LOKAL (Berdasarkan Sisa Uang)
    if surplus <= 0:
        rekomendasi_ml = "Tidak ada sisa dana untuk investasi. Prioritaskan kestabilan kas darurat."
    else:
        data_prediksi = pd.DataFrame([[surplus]], columns=['Surplus'])
        rekomendasi_ml = model_ai.predict(data_prediksi)[0]

    # GABUNGAN HASIL ANALISIS
    rekomendasi_final = f"📊 Analisis & Alokasi AI:\n{saran_budget}\n\n🎯 Saran Instrumen (Sisa Kas): {rekomendasi_ml}"

    # 4. SIMPAN KE DATABASE
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            query = "INSERT INTO riwayat_analisis (pendapatan, kebutuhan, rincian, surplus, rekomendasi) VALUES (%s, %s, %s, %s, %s)"
            values = (pendapatan, kebutuhan_dinamis, rincian, surplus, rekomendasi_final)
            cursor.execute(query, values)
            conn.commit() 
            cursor.close()
            conn.close()
    except Exception as db_err:
        print(f"Database Error: {db_err}")

    return {
        "status": "sukses",
        "pendapatan_terdeteksi": pendapatan,
        "kebutuhan_harian": kebutuhan_dinamis,
        "rincian": rincian,
        "surplus": surplus,
        "rekomendasi_investasi": rekomendasi_final
    }

@router.get("/riwayat/")
async def get_riwayat():
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor(dictionary=True) 
            cursor.execute("SELECT * FROM riwayat_analisis ORDER BY tanggal DESC")
            hasil = cursor.fetchall()
            cursor.close()
            conn.close()
            return {"status": "sukses", "data": hasil}
    except Exception as e:
        return {"status": "gagal", "pesan": "Database bermasalah"}
    return {"status": "sukses", "data": []}