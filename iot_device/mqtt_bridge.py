import json
import requests
import paho.mqtt.client as mqtt

# --- CONFIGURACIÓN ---
BROKER = "broker.hivemq.com"
PORT = 1883
TOPIC_SUBSCRIPCION = "smat/fisi/estacion/+/lecturas"
API_URL = "http://127.0.0.1:8000"  # Usar la IP local fija asignada   IP de mi PC : 192.168.0.114

# --- VARIABLES DE CONTROL INDUSTRIAL ---
TOKEN_JWT = ""
CACHE_ULTIMAS_LECTURAS = {}  # Memoria caché interna para la lógica Deadband
UMBRAL_DEADBAND = 0.05       # 5% de cambio mínimo exigido (Lab 11.1)

# Función para autenticar el dispositivo de manera autónoma en el Backend
def obtener_token_jwt():
    global TOKEN_JWT
    try:
        print("🔑 Solicitando autenticación al servidor central...")
        # Cambiar por tus credenciales de prueba configuradas en el laboratorio
        payload = {"username": "admin", "password": "adminpassword"} 
        response = requests.post(f"{API_URL}/login", data=payload, timeout=5)
        
        if response.status_code == 200:
            TOKEN_JWT = response.json().get("access_token")
            print("✅ Token JWT obtenido y cargado en memoria exitosamente.")
        else:
            print(f"⚠️ Falló el login en backend. Código: {response.status_code}")
    except Exception as e:
        print(f"🚨 Error de red intentando autenticar: {e}")

# Callback de conexión al Broker
def on_connect(client, userdata, flags, rc):
    print(f"🔗 Conectado al Broker con código de resultado: {rc}")
    client.subscribe(TOPIC_SUBSCRIPCION)
    print(f"📥 Escuchando mensajes en el canal: {TOPIC_SUBSCRIPCION}")

# Callback de procesamiento de mensajes con Filtro Deadband e Ingesta Protegida
# --- CÓDIGO CORREGIDO ---
def on_message(client, userdata, msg):
    try:
        data = json.loads(msg.payload.decode())
        print(f"\n📩 [MQTT Bridge] Mensaje recibido: {data}")
        
        # EL CAMBIO ESTÁ AQUÍ:
        # FastAPI espera un JSON en el cuerpo, NO parámetros en la URL.
        # Asegúrate de que las claves 'estacion_id' y 'valor' coincidan 
        # exactamente con las definidas en tu modelo Pydantic del backend.
        payload = {
            "estacion_id": int(data["estacion_id"]), 
            "valor": float(data["valor"])
        }
        
        headers = {
            "Authorization": f"Bearer {TOKEN_JWT}",
            "Content-Type": "application/json"
        }
        
        # Enviar el payload en el cuerpo (json=payload)
        response = requests.post(
            f"{API_URL}/lecturas/", 
            json=payload, 
            headers=headers
        )
        
        if response.status_code in [200, 201]:
            print("✅ Ingesta exitosa.")
        else:
            print(f"❌ Error {response.status_code}: {response.text}")

    except Exception as e:
        print(f"🚨 Error: {e}")

# Inicializar cliente MQTT del Bridge
bridge = mqtt.Client()
bridge.on_connect = on_connect
bridge.on_message = on_message

print("🔀 Iniciando el Puente de Integración Híbrido...")
obtener_token_jwt()  # Autenticación inicial al arrancar el servicio daemon
bridge.connect(BROKER, PORT, 60)

# Mantiene el script escuchando permanentemente de forma asíncrona
bridge.loop_forever()