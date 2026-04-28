# GIM - Gig Investasi Management 🚀

Sebuah proyek aplikasi cerdas berbasis **Flutter** yang dirancang khusus sebagai *Personal Financial Advisor* untuk pekerja modern, mulai dari *gig worker* (driver ojol/kurir), karyawan bulanan, hingga *freelancer* berbasis proyek.

Aplikasi ini tidak sekadar mencatat pengeluaran, tetapi memanfaatkan **AI (OpenAI GPT-4o-mini)** untuk menganalisis struk, mengklasifikasikan pengeluaran riil, dan memberikan saran alokasi dana menggunakan logika *Progressive Budgeting*.

---

## ✨ Fitur Utama (Versi 2.0 Stable)

### 🤖 1. AI-Powered Financial Advisor
- **OCR Smart Scan:** Ekstraksi total pendapatan otomatis dari struk kertas atau laporan digital (PDF/Screenshot).
- **Progressive Budgeting Logic:** AI memberikan saran alokasi dana secara dinamis berdasarkan nominal pendapatan dan "Sisa Uang" murni, bukan rasio statis.
- **Smart Validation:** AI mampu menganalisis konteks waktu secara spesifik untuk pendapatan berbasis proyek (validasi input hari/minggu/bulan/tahun).

### 💼 2. Fleksibilitas Manajemen
- Dukungan model pemasukan: **Harian, Mingguan, Bulanan,** dan **Proyek / Freelance**.
- Buku besar dinamis dengan filter rentang waktu cerdas.

### 📊 3. UI/UX & Keamanan Terintegrasi
- **Secure Authentication:** Sistem Login dan Registrasi akun pengguna yang terenkripsi (SHA-256) dan terhubung ke database MySQL.
- **Ergonomic Dashboard:** Visualisasi data interaktif menggunakan `fl_chart` (Pie Chart & Bar Chart) lengkap dengan fitur pemilih bulan (*Month Picker*).
- **Bottom Navigation & Profile:** Navigasi bawah yang ramah jempol (Beranda, Dashboard, Riwayat, Profil) dengan manajemen sesi (*Session Management*) menggunakan `shared_preferences`.

---

## 🛠️ Stack Teknologi
- **Frontend:** Flutter (Dart)
- **Backend:** FastAPI (Python)
- **Database:** MySQL
- **AI/ML:** OpenAI API & Scikit-Learn

---

## 🚀 Getting Started

Proyek ini adalah titik awal untuk aplikasi Flutter Anda. Pastikan untuk mengimpor file `query.txt` ke dalam database SQL Anda sebelum menjalankan backend.

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)

Untuk bantuan lebih lanjut, kunjungi [online documentation](https://docs.flutter.dev/).

---
*Developed with ☕️ in Mengwi, Bali.*