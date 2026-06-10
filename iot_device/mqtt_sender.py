import time
import random
import json
import paho.mqtt.client as mqtt

# --- CONFIGURACIÓN INDUSTRIAL ---
BROKER = "broker.hivemq.com"
PORT = 1883
TOPIC_TELEMETRIA = "smat/fisi/estacion/1/lecturas"

client = mqtt.Client()

print("🛰️ Conectando al Broker MQTT...")
client.connect(BROKER, PORT, 60)

def simular_sensor():
    print(f"🚀 Sensor activo. Publicando en el topic: {TOPIC_TELEMETRIA}")
    while True:
        # Simulamos la lectura de un sensor (ej. nivel de agua entre 10cm y 90cm)
        valor_lectura = round(random.uniform(10.5, 90.0), 2)
        
        # Formateamos el paquete JSON que espera nuestro sistema
        payload = {
            "estacion_id": 1,  # Asegúrate de tener una estación con ID 1 en tu DB
            "valor": valor_lectura
        }
        
        # Publicamos el mensaje en el Broker
        client.publish(TOPIC_TELEMETRIA, json.dumps(payload))
        print(f"📡 [MQTT Publisher] Enviado: {payload}")
        
        # Enviar telemetría cada 5 segundos
        time.sleep(5)

if __name__ == "__main__":
    try:
        simular_sensor()
    except KeyboardInterrupt:
        print("\n🛑 Sensor apagado por el operador.")
