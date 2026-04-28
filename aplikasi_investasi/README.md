# GIM - Gig Investasi Management 🚀

**GIM (Gig Investasi Management)** adalah aplikasi asisten keuangan pribadi cerdas yang dirancang khusus untuk pekerja modern, mulai dari *gig worker* (seperti driver ojol), karyawan bulanan, hingga *freelancer* berbasis proyek. 

Dibangun dengan **Flutter** dan didukung oleh kecerdasan buatan (**OpenAI GPT-4o-mini**), aplikasi ini tidak sekadar mencatat pengeluaran, tetapi bertindak sebagai *Personal Financial Advisor* yang mampu menganalisis struk, mengklasifikasikan pengeluaran, dan memberikan rekomendasi investasi yang sehat berdasarkan prinsip *Progressive Budgeting*.

---

## ✨ Fitur Utama (V2 Update - April 2026)

### 🤖 1. AI-Powered Financial Advisor
- **OCR Smart Scan:** Memindai dan mengekstrak total pendapatan secara otomatis dari struk kertas maupun laporan digital (PDF/Screenshot) menggunakan teknologi OpenAI Vision.
- **Progressive Budgeting Logic:** AI tidak lagi menggunakan rasio kaku (seperti 50/30/20). Saran alokasi dana (Pokok, Sekunder, Investasi) dihitung secara dinamis berdasarkan nominal pendapatan, durasi waktu proyek, dan pengeluaran riil pengguna.
- **Surplus Analysis:** Analisis manajemen keuangan difokuskan pada "Sisa Uang" murni setelah pengeluaran wajib dipenuhi.

### 💼 2. Fleksibilitas Tipe Pendapatan
Mendukung berbagai model pemasukan pengguna:
- **Harian & Mingguan:** Cocok untuk evaluasi kas cepat.
- **Bulanan:** Untuk manajemen gaji rutin.
- **Proyek / Freelance:** Dilengkapi parameter **Lama Waktu Proyek** (dengan validasi input presisi) agar AI dapat menghitung rasio bertahan hidup selama masa pengerjaan proyek.

### 📊 3. Dashboard Analytics & Buku Besar
- **Bottom Navigation Bar:** Antarmuka ergonomis untuk navigasi cepat antar halaman (Beranda, Dashboard, Riwayat).
- **Interactive Charts:** Menggunakan `fl_chart` untuk memvisualisasikan Proporsi Keuangan (Pie Chart) dan Tren 7 Transaksi Terakhir (Bar Chart).
- **Time-Range Filtering & Month Picker:** Filter data riwayat dan grafik secara *real-time* berdasarkan periode (Harian, Mingguan, Bulanan) lengkap dengan fitur pemilih bulan spesifik.

---

## 🛠️ Stack Teknologi

- **Frontend:** Flutter (Dart)
- **Backend:** FastAPI (Python)
- **Database:** MySQL (via XAMPP)
- **AI / Machine Learning:** - OpenAI API (GPT-4o-mini) untuk OCR dan Analisis Anggaran.
  - Scikit-Learn (Decision Tree Classifier) untuk rekomendasi instrumen investasi lokal (RDPU, RDPT, Saham).
- **Charting:** `fl_chart`

---

## 🚀 Memulai Proyek (Getting Started)

Proyek ini merupakan titik awal untuk aplikasi Flutter berbasis AI. 

### Prasyarat
- Flutter SDK terinstal.
- Server XAMPP berjalan (Apache & MySQL).
- Backend FastAPI aktif di `localhost:8000`.

### Cara Menjalankan Aplikasi
1. *Clone repository* ini.
2. Buka terminal pada direktori proyek.
3. Jalankan perintah untuk mengunduh dependensi:
   ```bash
   flutter pub get