# Asisten Investasi GIG (Versi 1.0) 🚀

Aplikasi berbasis web mobile untuk membantu menganalisis pendapatan harian dan memberikan rekomendasi investasi cerdas. Dibangun menggunakan arsitektur modular yang memisahkan Frontend (Flutter) dan Backend (Python FastAPI).

## 🛠️ Prasyarat (Wajib Diinstal)
Sebelum menjalankan proyek ini, pastikan komputer Anda sudah terinstal:
1. **Python 3.9+**
2. **Flutter SDK**
3. **Tesseract OCR untuk Windows** (Wajib untuk fitur scan gambar)
   - Download dan instal dari: [UB Mannheim Tesseract](https://github.com/UB-Mannheim/tesseract/wiki)
   - Pastikan terinstal di `C:\Program Files\Tesseract-OCR\tesseract.exe`
4. **XAMPP** (Untuk pengembangan database di masa depan)

## 🚀 Cara Menjalankan Aplikasi

### Bagian 1: Menjalankan Backend (Otak / AI)
1. Buka terminal dan masuk ke folder backend:
   ```bash
   cd backend