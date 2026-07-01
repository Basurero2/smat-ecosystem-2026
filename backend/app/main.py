from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from pydantic import BaseModel 
from . import models, database 

# Inicialización de la Base de Datos
models.Base.metadata.create_all(bind=database.engine)

# --- ESQUEMAS PYDANTIC DE VALIDACIÓN ---
class EstacionCreate(BaseModel):
    id: int
    nombre: str
    ubicacion: str

# NUEVO: Modelo Pydantic para recibir las lecturas en el cuerpo (Body) de la petición JSON
class LecturaCreate(BaseModel):
    estacion_id: int
    valor: float

# --- METADATOS DE DOCUMENTACIÓN ---
app = FastAPI(
    title="SMAT - Sistema de Monitoreo FISI UNMSM",
    description="""
    ## API Profesional de Telemetría y Alerta Temprana
    Esta API permite gestionar estaciones de monitoreo y procesar lecturas de sensores con seguridad avanzada.
    """,
    version="1.6.2",
    contact={"name": "Juan Carlos", "email": "juan.mamania@unmsm.edu.pe"}
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- CONFIGURACIÓN DE SEGURIDAD ---
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

@app.post("/login", tags=["Seguridad"], summary="Obtener token de acceso")
async def login():
    return {"access_token": "token_secreto_unmsm_2026", "token_type": "bearer"}

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- ENDPOINTS PROTEGIDOS ---

@app.post("/estaciones/", status_code=status.HTTP_201_CREATED, tags=["Gestión"], summary="Registrar nueva estación")
def crear_estacion(estacion: EstacionCreate, 
                    db: Session = Depends(get_db), 
                    token: str = Depends(oauth2_scheme)): 
    if token != "token_secreto_unmsm_2026":
        raise HTTPException(status_code=401, detail="No autorizado")
    
    existe = db.query(models.Estacion).filter(models.Estacion.id == estacion.id).first()
    if existe:
        raise HTTPException(status_code=400, detail="El ID ya existe")
    
    nueva = models.Estacion(id=estacion.id, nombre=estacion.nombre, ubicacion=estacion.ubicacion)
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva

# MODIFICADO: Ahora el endpoint recibe el payload del JSON usando el esquema LecturaCreate
@app.post("/lecturas/", status_code=201, tags=["Telemetría"], summary="Registrar lectura de sensor")
def registrar_lectura(lectura: LecturaCreate, # <-- CAMBIO CLAVE: Cambiado de campos sueltos al modelo estructurado
                      db: Session = Depends(get_db),
                      token: str = Depends(oauth2_scheme)):
    
    # Validación de token si tu laboratorio lo requiere para telemetría
    if token != "token_secreto_unmsm_2026":
        raise HTTPException(status_code=401, detail="No autorizado")

    # Buscamos usando el objeto pydantic: lectura.estacion_id
    estacion = db.query(models.Estacion).filter(models.Estacion.id == lectura.estacion_id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    # Insertamos en la BD usando los datos del payload recibido
    nueva = models.Lectura(estacion_id=lectura.estacion_id, valor=lectura.valor)
    db.add(nueva)
    db.commit()
    return {"status": "Lectura guardada", "valor": lectura.valor}

# --- ENDPOINTS DE CONSULTA ---

@app.get("/estaciones/{id}/historial", tags=["Reportes Históricos"], summary="Promedio y lista de lecturas")
def obtener_historial(id: int, db: Session = Depends(get_db)):
    estacion = db.query(models.Estacion).filter(models.Estacion.id == id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    lecturas = db.query(models.Lectura).filter(models.Lectura.estacion_id == id).all()
    valores = [l.valor for l in lecturas]
    promedio = sum(valores) / len(valores) if valores else 0
    
    return {
        "estacion": estacion.nombre,
        "conteo": len(valores),
        "promedio": round(promedio, 2),
        "lecturas": valores
    }

# En tu main.py, dentro de app/main.py
@app.get("/estaciones/", tags=["Gestión"])
def listar_con_lecturas(db: Session = Depends(get_db)):
    # Trae todas las estaciones
    estaciones = db.query(models.Estacion).all()
    lista_final = []
    for est in estaciones:
        # Obtiene la última lectura registrada para esta estación
        ultima = db.query(models.Lectura).filter(models.Lectura.estacion_id == est.id).order_by(models.Lectura.id.desc()).first()
        lista_final.append({
            "id": est.id,
            "nombre": est.nombre,
            "ubicacion": est.ubicacion,
            "ultima_lectura": ultima.valor if ultima else 0.0 # <--- ESTO ES LO QUE VERÁ FLUTTER
        })
    return lista_final