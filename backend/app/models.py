from sqlalchemy import Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import relationship
from .database import Base

class Estacion(Base):
    __tablename__ = "estaciones"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, index=True)
    ubicacion = Column(String)
    
    # Relación: Una estación tiene muchas lecturas
    lecturas = relationship("Lectura", back_populates="estacion")

class Lectura(Base):
    __tablename__ = "lecturas"
    
    id = Column(Integer, primary_key=True, index=True)
    valor = Column(Float)
    
    # Llave foránea: Define la relación física con la tabla estaciones
    estacion_id = Column(Integer, ForeignKey("estaciones.id"))
    
    # Relación inversa: Una lectura pertenece a una estación
    estacion = relationship("Estacion", back_populates="lecturas")