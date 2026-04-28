import cv2
import numpy as np
import pytesseract
import re

# Ini adalah "kunci" yang menghubungkan Python dengan software Tesseract di laptop 
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def ekstrak_nominal(image_bytes):
    # Mengubah gambar dari Flutter menjadi format yang bisa dibaca OpenCV
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # Memotong gambar (cropping) di area atas tempat nominal biasanya berada
    tinggi, lebar, _ = img.shape
    y_mulai = int(tinggi * 0.15)
    y_selesai = int(tinggi * 0.35)
    gambar_terpotong = img[y_mulai:y_selesai, 0:lebar]

    # Membersihkan gambar (hitam putih) agar mudah dibaca AI
    gambar_gray = cv2.cvtColor(gambar_terpotong, cv2.COLOR_BGR2GRAY)
    _, gambar_bersih = cv2.threshold(gambar_gray, 150, 255, cv2.THRESH_BINARY)

    # Proses membaca teks menggunakan Tesseract
    teks_kotor = pytesseract.image_to_string(gambar_bersih, config='--psm 6')
    
    # Mencari pola angka yang berawalan 'Rp'
    angka_ditemukan = re.findall(r'Rp\s?(\d{1,3}(?:\.\d{3})*)', teks_kotor)

    if not angka_ditemukan:
        return None

    # Membersihkan titik (contoh: 150.000 menjadi 150000)
    nominal_bersih = angka_ditemukan[0].replace('.', '')
    return int(nominal_bersih)