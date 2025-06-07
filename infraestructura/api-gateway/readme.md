# PRESENTACIÓN ACTIVAD NRO. 1 - MÓDULO 6
# Universidad NUR - Diplomado en Arq. con Microservicios
# API Gateway con Kong OSS + JWT + PHP Login

Este proyecto configura un API Gateway con **Kong OSS**, una solución open source que permite gestionar, enrutar y asegurar APIs de forma centralizada y eficiente, donde:

- `/api/login`: endpoint público en PHP para generar el Bearer Token.
- `/api/users`: requiere JWT, redirige a `https://jsonplaceholder.typicode.com/users`
- `/api/posts`: requiere JWT, redirige a `https://jsonplaceholder.typicode.com/posts`

Todo se configura automáticamente al ejecutar `docker-compose up`.

---

## 📦 Contenido

- `php-login/`: Servicio PHP que expone `/api/login` y genera un JWT.
- `kong-config/`: Contiene el script que configura Kong automáticamente.
- `docker-compose.yml`: Orquesta todos los contenedores necesarios para que Kong funcione con el servicio PHP, una base de datos PostgreSQL, y una interfaz de administración.
- `kong-setup.sh`: Script que configura Kong (rutas, plugins, etc).

---

## ⚙️ Servicios definidos en `docker-compose.yml`

El archivo `docker-compose.yml` define los siguientes servicios:

- **kong-db**: Contenedor de PostgreSQL donde Kong almacena su configuración y estado.
- **kong-migrations**: Ejecuta las migraciones necesarias en la base de datos de Kong (sólo se ejecuta una vez).
- **kong**: Contenedor principal de Kong Gateway en su versión OSS. Expone los puertos necesarios para acceder a las APIs y a la administración.
- **konga** *(opcional)*: Interfaz web de administración para Kong (si está habilitada).
- **php-login**: Servicio PHP personalizado que expone el endpoint `/api/login` para autenticación y generación de tokens JWT.

---

## ▶️ Cómo ejecutar

```bash
docker-compose up --build -d
```
---
## 🌐 Rutas expuestas por defecto

Una vez levantado el entorno con `docker-compose up`, se habilitan las siguientes URLs:

- **Proxy de Kong (API Gateway)**: [http://localhost:8000](http://localhost:8000)  
  Acceso a los endpoints públicos y protegidos a través del gateway.

- **Kong Admin API**: [http://localhost:8001](http://localhost:8001)  
  Interfaz de administración vía API REST (no expone frontend).

- **Login endpoint (vía gateway)**: [http://localhost:8000/api/login](http://localhost:8000/api/login)  
  Devuelve un token JWT si las credenciales son válidas.

- **Users protegidos (vía gateway)**: [http://localhost:8000/api/users](http://localhost:8000/api/users)  
  Requiere un token válido en el header Authorization.

- **Posts protegidos (vía gateway)**: [http://localhost:8000/api/posts](http://localhost:8000/api/posts)  
  Requiere un token válido en el header Authorization.

---

## 🧪 Cómo probar los endpoints con Postman

1. **Importar colección**  
   Abra Postman e importe el archivo `gateway.postman_collection.json` incluido en el proyecto.

2. **Ejecutar `Login`**  
   Envíe una solicitud `POST` al endpoint `/api/login`.  Esto devolverá un token JWT. Puede usar el cuerpo por defecto (por ejemplo, el usuario de prueba que está definido):
```bash
    {
    "username": "admin",
    "password": "password123"
    }
```

3. **Guardar el token**  
   Copie el token JWT que devuelve el login. Este token es necesario para acceder a los endpoints protegidos.

4. **Probar endpoints protegidos**  
   - Abra las solicitudes `GET /api/users` o `GET /api/posts` dentro de la colección.
   - En la pestaña "Authorization" de la solicitud, seleccione el tipo **Bearer Token** y pegue el token obtenido en el paso anterior.
   - Envía la solicitud. Si el token es válido, obtendrá la respuesta desde el API de jsonplaceholder.

> ⚠️ Aseguerese de seguir el orden: primero `/api/login`, luego `/api/users` o `/api/posts` con el token cargado.

---

