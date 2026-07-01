import requests
import time
import random

# --- CONFIGURACIÓN DEL SISTEMA ---
# Usa tu IP real configurada (192.168.0.114) o localhost si pruebas de forma interna en la PC
API_URL = "http://127.0.0.1:8000/lecturas/"     # mi IP 192.168.0.114
ESTACION_ID = 1  # ID de la estación que registraste en tu base de datos SQLite

# NOTA: Reemplaza esto por un token real generado en tu login (Semanas 4 y 6)
TOKEN = "token_secreto_unmsm_2026" 

def leer_sensor_emulado():
    """Simula una lectura del nivel de un río en centímetros (10.5 a 85.0 cm)"""
    return round(random.uniform(10.5, 85.0), 2)

def enviar_telemetria():
    print("--- Iniciando Emulación de Hardware IoT - SMAT ---")
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    }
    
    while True:
        lectura_actual = leer_sensor_emulado()
        
        # --- EL RETO DE LA SEMANA 9: Lógica de Alarma e Intervalo Dinámico ---
        if lectura_actual > 70.0:
            print(f"⚠️ [ALERTA] Umbral de inundación superado: {lectura_actual} cm")
            tiempo_espera = 2  # Modo de emergencia: envía datos cada 2 segundos
        else:
            print(f"✅ Nivel normal detectado: {lectura_actual} cm")
            tiempo_espera = 10  # Modo normal: envía datos cada 10 segundos
            
        # Payload JSON para enviar al backend
        payload = {
            "estacion_id": ESTACION_ID,
            "valor": lectura_actual
        }
        
        try:
            response = requests.post(API_URL, json=payload, headers=headers, timeout=5)
            if response.status_code == 201:
                print(f"📡 Telemetría enviada con éxito. Código: {response.status_code}")
            else:
                print(f"❌ Error del Servidor. Código: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"🚨 [CRÍTICO] No hay conexión con el servidor SMAT: {e}")
            
        # Pausa dinámica según el estado del sensor
        time.sleep(tiempo_espera)

if __name__ == "__main__":
    enviar_telemetria()


