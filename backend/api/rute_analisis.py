from fastapi import APIRouter, UploadFile, File
from services.ocr_service import ekstrak_nominal
from services.ml_service import ml_engine
from models.skema import AnalisisResponse

router = APIRouter()

# Kita gunakan rute '/analisis' agar konsisten
@router.post("/analisis", response_model=AnalisisResponse)
async def analisis_pendapatan(file: UploadFile = File(...)):
    try:
        image_bytes = await file.read()
        pendapatan = ekstrak_nominal(image_bytes)

        if not pendapatan:
            return AnalisisResponse(status="gagal", pesan="Nominal tidak ditemukan.")

        kebutuhan_harian = 50000
        surplus = pendapatan - kebutuhan_harian
        rekomendasi = ml_engine.prediksi(surplus)

        return AnalisisResponse(
            status="sukses",
            pendapatan_terdeteksi=pendapatan,
            kebutuhan_harian=kebutuhan_harian,
            surplus=surplus,
            rekomendasi_investasi=rekomendasi
        )
    except Exception as e:
        return AnalisisResponse(status="gagal", pesan=str(e))