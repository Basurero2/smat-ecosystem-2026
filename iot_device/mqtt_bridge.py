import json
import requests
import paho.mqtt.client as mqtt

# --- CONFIGURACIÓN ---
BROKER = "broker.hivemq.com"
PORT = 1883
TOPIC_SUBSCRIPCION = "smat/fisi/estacion/+/lecturas" # El '+' es un comodín (wildcard)
API_URL = "http://localhost:8000/lecturas/" # URL de tu FastAPI local

# Función que se ejecuta cuando nos conectamos exitosamente al Broker
def on_connect(client, userdata, flags, rc):
    print(f"🔗 Conectado al Broker con código de resultado: {rc}")
    client.subscribe(TOPIC_SUBSCRIPCION)
    print(f"📥 Escuchando mensajes en el canal: {TOPIC_SUBSCRIPCION}")

# Función que se ejecuta cada vez que llega un mensaje MQTT
def on_message(client, userdata, msg):
    try:
        # 1. Decodificar el mensaje recibido del sensor
        data = json.loads(msg.payload.decode())
        print(f"\n📩 [MQTT Bridge] Mensaje recibido del Broker: {data}")
        
        # 2. Reenviar el dato a la API de FastAPI mediante HTTP POST
        # Nota: Como tu endpoint '/lecturas/' pide query parameters o JSON, 
        # le pasamos los parámetros exactamente como los configuraste.
        response = requests.post(
            API_URL, 
            params={"estacion_id": data["estacion_id"], "valor": data["valor"]}
        )
        
        if response.statusCode == 201 or response.statusCode == 200:
            print(f"✅ Persistencia Exitosa en FastAPI: {response.json()}")
        else:
            print(f"❌ Error en FastAPI [Código {response.statusCode}]: {response.text}")
            
    except Exception as e:
        print(f"🚨 Error crítico procesando el puente: {e}")

# Inicializar cliente MQTT del Bridge
bridge = mqtt.Client()
bridge.on_connect = on_connect
bridge.on_message = on_message

print("🔀 Iniciando el Puente de Integración Industrial...")
bridge.connect(BROKER, PORT, 60)

# Mantiene el script escuchando permanentemente de forma asíncrona
bridge.loop_forever()
