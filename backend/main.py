from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.rute_analisis import router as analisis_router

app = FastAPI()

# Satpam Keamanan (CORS) - Harus di atas router!
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analisis_router)

@app.get("/")
def check():
    return {"status": "Backend V1 Siap!"}