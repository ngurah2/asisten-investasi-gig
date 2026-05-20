from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import analisis, target  # Tambahan: Impor target
import app.database 

# 1. Panggil brankas .env
load_dotenv()

# 2. Inisialisasi Aplikasi Utama
app = FastAPI(title="API GIM - Gig Investasi Manajemen")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],  
    allow_headers=["*"],
)

# 3. Hubungkan laci-laci API ke aplikasi utama
app.include_router(analisis.router)
app.include_router(target.router)  # Tambahan: Registrasi router target

# Endpoint tes jalur
@app.get("/")
def cek_kesehatan():
    return {"status": "Mantap! Server GIM berjalan dengan arsitektur modular dan fitur Target Keuangan siap digunakan!"}