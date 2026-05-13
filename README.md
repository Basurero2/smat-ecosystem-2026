# SMAT Ecosystem - Sistema de Monitoreo FISI

Sistema profesional de telemetría y alerta temprana para la gestión de estaciones de monitoreo y procesamiento de lecturas de sensores, desarrollado como parte de los Laboratorios 6 y 7.

## 🏗️ Arquitectura del Proyecto (Monorepo)

El proyecto está dividido en dos capas principales:

- **Backend (`/backend`)**: API RESTful construida con **FastAPI** y **Python**. Incluye persistencia de datos mediante **SQLite/SQLAlchemy** y seguridad de endpoints con **JWT (OAuth2)**.
- **Frontend Móvil (`/mobile`)**: Aplicación móvil desarrollada en **Flutter/Dart**. Implementa consumo de APIs, manejo de estado, persistencia de tokens de sesión y resiliencia ante fallos de conexión (Timeout, Pull-to-refresh).

## 🚀 Requisitos Previos

- [Python 3.10+](https://www.python.org/downloads/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dispositivo físico o emulador Android/iOS configurado.

---

## 🛠️ Instrucciones de Ejecución

### 1. Levantar el Servidor Backend

Abre una terminal, navega a la carpeta del backend y ejecuta:

```bash
# 1. Entrar al directorio
cd backend

# 2. Instalar las dependencias
pip install -r requirements.txt

# 3. Iniciar el servidor (la base de datos SQLite se creará automáticamente)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```


La documentación interactiva de Swagger estará disponible en:
👉 http://localhost:8000/docs

### 2. Ejecutar la Aplicación Móvil
Abre una nueva terminal (sin cerrar la del backend), navega a la carpeta móvil y despliega la app:



```bash
# 1. Entrar al directorio
cd mobile

# 2. Descargar dependencias de Dart
flutter pub get

# 3. Ejecutar la aplicación en el dispositivo conectado (o Chrome)
flutter run
```

### 🔐 Credenciales de Prueba
Para probar la aplicación móvil o autorizar peticiones en Swagger, utiliza cualquier usuario y contraseña en el formulario de Login (la validación en este entorno de laboratorio es demostrativa y genera el token de sesión automáticamente).

Autor: Juan Carlos Mamani Apaza
Institución: Universidad Nacional Mayor de San Marcos (UNMSM) - Facultad de Ingeniería de Sistemas e Informática (FISI)
