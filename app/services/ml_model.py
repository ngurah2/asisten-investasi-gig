import pandas as pd
from sklearn.tree import DecisionTreeClassifier

def siapkan_model_ai():
    print("Memuat dan melatih model AI Rekomendasi...")
    # Pastikan file dataset_investasi.csv ada di tempat yang tepat
    df = pd.read_csv('dataset_investasi.csv')
    X = df[['Surplus']]
    y = df['Rekomendasi']
    model_ai = DecisionTreeClassifier()
    model_ai.fit(X, y)
    print("Sistem AI siap menerima permintaan!")
    return model_ai

model_ai = siapkan_model_ai()