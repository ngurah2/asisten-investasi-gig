import cv2
import pytesseract
import re

# 1. SETUP TESSERACT
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def proses_gambar_pendapatan(lokasi_gambar):
    print(f"\nMembaca file: {lokasi_gambar}")
    
    # 2. LOAD GAMBAR
    gambar = cv2.imread(lokasi_gambar)
    
    if gambar is None:
        print("Error: Gambar tidak ditemukan!")
        return None

    # --- PENTING: PROSES CROPPING (PEMOTONGAN) ---
    # hanya ingin mengambil area tengah atas, tempat "Rp76.600" biasanya berada.
    # Format cropping di OpenCV: gambar[y_awal:y_akhir, x_awal:x_akhir]
    # Angka ini adalah PERKIRAAN piksel.  mungkin perlu mengubah angka ini
    # tergantung dari resolusi screenshot HP.
    
    tinggi, lebar, _ = gambar.shape
    
    # Contoh pemotongan: Ambil bagian atas (sekitar 15% - 30% dari atas layar)
    # bisa mengatur ulang angka ini dengan coba-coba (trial and error)
    y_mulai = int(tinggi * 0.15) 
    y_selesai = int(tinggi * 0.35)
    
    gambar_terpotong = gambar[y_mulai:y_selesai, 0:lebar]

    # --- SIMPAN SEMENTARA GAMBAR POTONGAN UNTUK DICEK ---
    # File ini akan muncul di folder agar  bisa melihat apakah potongan kameranya sudah pas
    cv2.imwrite('hasil_potongan_sementara.jpg', gambar_terpotong)
    print("-> Gambar berhasil dipotong. Cek file 'hasil_potongan_sementara.jpeg' di folder proyek!")

    # 3. PRAPEMROSESAN WARNA
    gambar_gray = cv2.cvtColor(gambar_terpotong, cv2.COLOR_BGR2GRAY)
    
    # Thresholding: Paksa ubah warna menjadi hitam murni dan putih murni
    # Ini sangat membantu OCR agar tidak salah baca (contoh huruf S jadi angka 5)
    _, gambar_bersih = cv2.threshold(gambar_gray, 150, 255, cv2.THRESH_BINARY)

    # 4. BACA TEKS DENGAN KONFIGURASI KHUSUS
    # '--psm 6' menyuruh Tesseract untuk membaca teks sebagai satu blok kesatuan
    teks_kotor = pytesseract.image_to_string(gambar_bersih, config='--psm 6')
    print(f"-> Teks Mentah dari Potongan: {teks_kotor.strip()}")

    # 5. PEMBERSIHAN DATA (CLEANING) MENGGUNAKAN REGEX
    # Kita buat lebih pintar: Cari angka yang menempel dengan huruf "Rp"
    # Pola ini akan menemukan "Rp76.600" atau "Rp 76.600" dan mengambil angkanya saja
    angka_ditemukan = re.findall(r'Rp\s?(\d{1,3}(?:\.\d{3})*)', teks_kotor)

    if angka_ditemukan:
        # Ambil angka pertama yang menempel dengan 'Rp'
        nominal_bersih = angka_ditemukan[0].replace('.', '')
        
        # Pastikan nominal yang diambil logis (minimal ribuan)
        if len(nominal_bersih) >= 4: 
            return int(nominal_bersih)
        else:
            return None
    else:
        return None

# --- BAGIAN EKSEKUSI ---
# Panggil fungsi yang kita buat di atas
hasil_nominal = proses_gambar_pendapatan('dataset_gambar/tes1.jpeg')

print("\n=== HASIL AKHIR YANG AKAN MASUK KE AI ===")
if hasil_nominal:
    print(f"✅ Nominal Berhasil Diekstraksi: Rp {hasil_nominal}")
    print(f"Tipe Data: {type(hasil_nominal)} (Siap dihitung!)")
else:
    print("❌ Gagal menemukan nominal yang valid di area yang dipotong.")
print("=========================================\n")