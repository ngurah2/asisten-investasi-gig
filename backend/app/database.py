import mysql.connector

def get_db_connection():
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",      
            password="",      
            database="db_investasi"
        )
        return conn
    except Exception as e:
        print(f"Gagal terhubung ke Database: {e}")
        return None

def buat_tabel():
    conn = get_db_connection()
    if conn:
        cursor = conn.cursor()
        
        # 1. Buat tabel users terlebih dahulu
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                nama VARCHAR(100),
                email VARCHAR(100) UNIQUE,
                password VARCHAR(255)
            )
        """)
        
        # 2. Buat tabel riwayat_analisis yang tersambung ke tabel users
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS riwayat_analisis (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT,
                tanggal TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                pendapatan INT,
                kebutuhan INT,
                rincian TEXT,
                surplus INT,
                rekomendasi TEXT,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
        """)
        conn.commit()
        cursor.close()
        conn.close()
        print("Buku Besar (Tabel Database) sudah siap dengan Relasi User_ID!")

buat_tabel()