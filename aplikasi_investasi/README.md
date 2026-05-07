# GIM - Gig Investasi Management 🚀

Sebuah proyek aplikasi cerdas berbasis **Flutter** yang dirancang khusus sebagai *Personal Financial Advisor* untuk pekerja modern, mulai dari *gig worker* (driver ojol/kurir), karyawan bulanan, hingga *freelancer* berbasis proyek.

Aplikasi ini tidak sekadar mencatat pengeluaran, tetapi memanfaatkan **AI (OpenAI / GitHub Models)** untuk menganalisis struk, mengklasifikasikan pengeluaran riil, dan memberikan saran alokasi dana menggunakan logika *Progressive Budgeting*.

---

## ✨ Fitur Utama (Versi 2.0 Stable)

### 🤖 1. AI-Powered Financial Advisor
- **OCR Smart Scan:** Ekstraksi total pendapatan otomatis dari struk kertas atau laporan digital (PDF/Screenshot).
- **Progressive Budgeting Logic:** AI memberikan saran alokasi dana secara dinamis berdasarkan nominal pendapatan dan "Sisa Uang" murni (pembagian otomatis 50/30/20).
- **Smart Validation:** AI mampu menganalisis konteks waktu secara spesifik untuk pendapatan berbasis proyek.

### 💼 2. Fleksibilitas Manajemen
- Dukungan model pemasukan: **Harian, Mingguan, Bulanan,** dan **Proyek / Freelance**.
- Buku besar dinamis dengan filter rentang waktu cerdas.

### 📊 3. UI/UX & Keamanan Terintegrasi
- **Secure Authentication:** Sistem Login dan Registrasi akun pengguna yang terenkripsi (SHA-256) dan terhubung ke database MySQL.
- **Ergonomic Dashboard:** Visualisasi data interaktif menggunakan fl_chart (Pie Chart & Bar Chart).
- **Infinite Promo Carousel:** Banner informasi interaktif di halaman utama.

---

## 🛠️ Stack Teknologi
- **Frontend:** Flutter (Dart)
- **Backend:** FastAPI (Python)
- **Database:** MySQL (XAMPP)
- **AI/ML:** LLaMA / GPT via GitHub Models & Scikit-Learn

---

## 🚀 PANDUAN INSTALASI AWAL (SETUP PERTAMA KALI)

Ikuti langkah ini HANYA JIKA Anda baru pertama kali mengunduh proyek ini.

### Setup Database
1. Buka XAMPP, nyalakan **Apache** dan **MySQL**.
2. Buka browser: `http://localhost/phpmyadmin`
3. Buat database baru: `db_investasi`
4. Import file `query.txt` ke dalam database tersebut.

### Setup Environment
1. Buka CMD / Terminal di VS Code.
2. `cd C:\asisten-investasi-gig-2-asli\asisten-investasi-gig-2-asli\backend`
3. Buat mesin virtual Python: `python -m venv env`
4. Nyalakan mesin: `.\env\Scripts\activate`
5. Install pustaka: `pip install -r requirements.txt`
6. Buat file `.env` di dalam folder backend dan isikan: `GITHUB_TOKEN=isi_token_anda_disini`

---

## ⚡ PANDUAN STARTUP HARIAN (CARA MENYALAKAN APLIKASI)

**HUKUM WAJIB:** Ikuti langkah mutlak ini secara berurutan setiap kali laptop baru dihidupkan atau VS Code baru dibuka untuk memastikan sistem berjalan tanpa *error*.

### TAHAP 1: Menyalakan Database (Pondasi Data)
1. Buka aplikasi **XAMPP Control Panel**.
2. Klik tombol **Start** pada baris **MySQL** dan **Apache**.
3. Pastikan modul MySQL berubah menjadi blok hijau dengan angka Port (biasanya 3306).

### TAHAP 2: Menyalakan Server Backend (FastAPI / Python)
1. Buka **VS Code**, buka Terminal Baru (Sangat disarankan menggunakan *Command Prompt / CMD*, bukan PowerShell).
2. Langsung tembak masuk ke folder backend menggunakan *path* lengkap:
   ```cmd
   cd C:\asisten-investasi-gig-2-asli\asisten-investasi-gig-2-asli\backend
   ```
3. **WAJIB:** Hidupkan *Virtual Environment* (mesin Python) terlebih dahulu:
   
```cmd
   .\env\Scripts\activate
   ```
   *(Pastikan muncul tulisan `(env)` di ujung kiri terminal).*
4. Nyalakan server backend:
   ```cmd
   python -m uvicorn main:app --reload
   ```
   *(Tunggu sampai muncul tulisan "Application startup complete", "Buku Besar sudah siap", dan "Sistem AI siap menerima permintaan!").*

### TAHAP 3: Menyalakan Frontend (Tampilan Aplikasi Flutter)
1. Biarkan terminal Backend (Tahap 2) tetap menyala di latar belakang. Jangan pernah ditutup!
2. Buka **Terminal Baru** di VS Code (Klik ikon `+` di panel terminal).
3. Langsung tembak masuk ke folder aplikasi menggunakan *path* lengkap:
   ```cmd
   cd C:\asisten-investasi-gig-2-asli\asisten-investasi-gig-2-asli\aplikasi_investasi
   
```
4. Jalankan aplikasi di browser (Chrome) atau Emulator:
   ```cmd
   flutter run -d chrome
   ```

---
Developed with ☕️ in Mengwi, Bali.