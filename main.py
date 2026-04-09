from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, UploadFile, File
import cv2
import pytesseract
import re
import pandas as pd
from sklearn.tree import DecisionTreeClassifier
import shutil
import os

# Inisialisasi Aplikasi API
app = FastAPI(title="API Investasi Gig Economy")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Mengizinkan pesanan dari alamat web mana pun
    allow_credentials=True,
    allow_methods=["*"],  # Mengizinkan semua jenis perintah (POST, GET, dll)
    allow_headers=["*"],
)

# --- 1. SETUP TESSERACT & ML MODEL ---
# PENTING: Pastikan alamat Tesseract ini sesuai dengan laptop Anda
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

print("Memuat dan melatih model AI...")
df = pd.read_csv('dataset_investasi.csv')
X = df[['Surplus']]
y = df['Rekomendasi']
model_ai = DecisionTreeClassifier()
model_ai.fit(X, y)
print("Model AI siap menerima permintaan!")

# --- 2. ENDPOINT API ---
@app.post("/analisis-pendapatan/")
async def analisis_pendapatan(file: UploadFile = File(...)):
    # A. Simpan file gambar sementara
    lokasi_sementara = f"temp_{file.filename}"
    with open(lokasi_sementara, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # B. PROSES OCR
    gambar = cv2.imread(lokasi_sementara)
    tinggi, lebar, _ = gambar.shape
    
    y_mulai = int(tinggi * 0.15)
    y_selesai = int(tinggi * 0.35)
    gambar_terpotong = gambar[y_mulai:y_selesai, 0:lebar]
    
    gambar_gray = cv2.cvtColor(gambar_terpotong, cv2.COLOR_BGR2GRAY)
    _, gambar_bersih = cv2.threshold(gambar_gray, 150, 255, cv2.THRESH_BINARY)

    teks_kotor = pytesseract.image_to_string(gambar_bersih, config='--psm 6')
    angka_ditemukan = re.findall(r'Rp\s?(\d{1,3}(?:\.\d{3})*)', teks_kotor)

    # Hapus file sementara
    os.remove(lokasi_sementara)

    if not angka_ditemukan:
        return {"status": "gagal", "pesan": "Nominal tidak ditemukan pada gambar."}

    nominal_bersih = angka_ditemukan[0].replace('.', '')
    pendapatan = int(nominal_bersih)

    # C. PROSES MACHINE LEARNING
    kebutuhan_harian = 50000
    surplus = pendapatan - kebutuhan_harian

    if surplus <= 0:
        rekomendasi = "Fokus penuhi kebutuhan pokok. Belum ada alokasi investasi."
    else:
        data_prediksi = pd.DataFrame([[surplus]], columns=['Surplus'])
        prediksi = model_ai.predict(data_prediksi)
        rekomendasi = prediksi[0]

    # D. KEMBALIKAN HASIL JSON
    return {
        "status": "sukses",
        "pendapatan_terdeteksi": pendapatan,
        "kebutuhan_harian": kebutuhan_harian,
        "surplus": surplus,
        "rekomendasi_investasi": rekomendasi
    }