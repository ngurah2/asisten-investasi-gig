import pandas as pd
import os
from sklearn.tree import DecisionTreeClassifier

class SistemPakarInvestasi:
    def __init__(self):
        # Mencari lokasi file CSV secara otomatis di folder backend
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        csv_path = os.path.join(base_dir, 'dataset_investasi.csv')
        
        if not os.path.exists(csv_path):
            raise FileNotFoundError(f"File {csv_path} tidak ditemukan! Pastikan sudah dipindah ke folder backend.")
            
        dataset = pd.read_csv(csv_path)
        X = dataset[['Surplus']].values
        y = dataset['Rekomendasi']

        self.model_ai = DecisionTreeClassifier(random_state=42)
        self.model_ai.fit(X, y)

    def prediksi(self, surplus):
        if surplus <= 0:
            return "Fokus penuhi kebutuhan pokok. Belum ada alokasi investasi."
        
        prediksi_hasil = self.model_ai.predict([[surplus]])
        return prediksi_hasil[0]

# Inisialisasi agar siap pakai
ml_engine = SistemPakarInvestasi()