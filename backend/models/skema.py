from pydantic import BaseModel
from typing import Optional

class AnalisisResponse(BaseModel):
    status: str
    pesan: Optional[str] = None
    pendapatan_terdeteksi: Optional[int] = None
    kebutuhan_harian: Optional[int] = None
    surplus: Optional[int] = None
    rekomendasi_investasi: Optional[str] = None