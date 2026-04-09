import pandas as pd
from sklearn.tree import DecisionTreeClassifier

print("1. Membaca Dataset Investasi...")
# Membaca file CSV yang baru saja kita buat
df = pd.read_csv('dataset_investasi.csv')

# Memisahkan Fitur (Data yang dihitung) dan Target (Hasil Rekomendasi)
# melatih AI berdasarkan angka 'Surplus'
X = df[['Surplus']] 
y = df['Rekomendasi']

print("2. Melatih AI (Decision Tree Model)...")
# Inisialisasi dan melatih model Decision Tree
model_ai = DecisionTreeClassifier()
model_ai.fit(X, y)
print("✅ AI Selesai Dilatih!\n")

# --- SIMULASI PENGGABUNGAN DENGAN OCR ---
print("==================================================")
print("     SISTEM PENDUKUNG KEPUTUSAN INVESTASI GIG     ")
print("==================================================")

# Anggap ini angka yang baru saja ditarik dari ocr_engine.py 
pendapatan_hari_ini = 76600 

#asumsikan kebutuhan pokok harian/bensin/makan adalah 50.000
kebutuhan_harian = 50000 
surplus_hari_ini = pendapatan_hari_ini - kebutuhan_harian

print(f"Pendapatan Terdeteksi (OCR) : Rp {pendapatan_hari_ini}")
print(f"Estimasi Kebutuhan Harian   : Rp {kebutuhan_harian}")
print(f"Sisa/Surplus Dana           : Rp {surplus_hari_ini}")

# Jika surplus kurang dari 0 (rugi/pas-pasan)
if surplus_hari_ini <= 0:
    print("\n💡 REKOMENDASI SISTEM:")
    print("Fokus penuhi kebutuhan pokok hari ini. Belum ada alokasi untuk investasi.")
else:
    # Meminta AI memprediksi dengan menyertakan nama kolom agar Sklearn untuk membantu mengambil keputusan
    data_prediksi = pd.DataFrame([[surplus_hari_ini]], columns=['Surplus'])
    prediksi = model_ai.predict(data_prediksi)
    
    print("\n💡 REKOMENDASI SISTEM (BERBASIS MACHINE LEARNING):")
    print(f"Berdasarkan surplus Anda, instrumen yang tepat adalah: {prediksi[0]}")
print("==================================================")