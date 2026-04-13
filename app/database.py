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
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS riwayat_analisis (
                id INT AUTO_INCREMENT PRIMARY KEY,
                tanggal TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                pendapatan INT,
                kebutuhan INT,
                surplus INT,
                rekomendasi VARCHAR(255)
            )
        """)
        conn.commit()
        cursor.close()
        conn.close()
        print("Buku Besar (Tabel Database) sudah siap!")

buat_tabel()