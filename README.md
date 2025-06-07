# 🧱 Proyecto de Infraestructura para Microservicios con Kong, RabbitMQ y Docker

Este proyecto configura una infraestructura base para ejecutar múltiples microservicios en contenedores Docker, gestionados a través de:

- 🧭 **Kong API Gateway** (como puerta de entrada y enrutamiento)
- 🐇 **RabbitMQ** (como sistema de mensajería entre microservicios)
- 🐳 **Docker Compose** para orquestar todos los servicios
- 🧬 Repositorios de microservicios clonados automáticamente desde GitHub

---

## 📁 Estructura del proyecto

project-root/
│
├── Infraestructura/
│ ├── api-gateway/ # Kong y su configuración
│ └── rabbitmq/ # Servicio de mensajería
│
├── Repos/
│ ├── Microservicio1/ # Repositorio clonado automáticamente
│ └── Microservicio2/ # Repositorio clonado automáticamente
│
├── setup.sh # Script para levantar toda la infraestructura (Git Bash o WSL)
├── teardown.sh # Script para detener y eliminar todos los servicios
├── setup.ps1 # Versión PowerShell de setup.sh para Windows
├── .env # URLs de los repositorios
└── README.md


---

## ⚙️ Requisitos

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- Git
- Git Bash (en Windows) o WSL/terminal Unix
- PowerShell (opcional para usuarios de Windows)

---

## 🚀 Levantar la infraestructura

### Opción 1 – En Linux / Git Bash (Windows)

chmod +x setup.sh
./setup.sh


### Opción 2 – En PowerShell (Windows)

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup.ps1

Este script:

Limpia la carpeta Repos/.

Clona los microservicios desde GitHub (definidos en .env).

Levanta:

Kong + base de datos PostgreSQL

RabbitMQ + UI web (http://localhost:15672)

Los microservicios desde sus propios docker-compose.yml

🧹 Detener y eliminar todo
bash
Copiar
./teardown.sh
Este script:

Ejecuta docker-compose down -v en cada uno de los servicios.

Elimina contenedores, redes y volúmenes creados por Docker Compose.

📝 Configuración de .env
env
Copiar
REPO_MICROSERVICIO1=https://github.com/usuario/Microservicio1.git
REPO_MICROSERVICIO2=https://github.com/usuario/Microservicio2.git
📌 Notas adicionales
El API Gateway Kong se levanta en los puertos:

Proxy: localhost:8000

Admin: localhost:8001

SSL: localhost:8443 / 8444

RabbitMQ UI estará disponible en: http://localhost:15672

Usuario: user

Contraseña: password

📥 Agregar más microservicios
Añade una nueva entrada en .env

Duplica las secciones correspondientes en setup.sh y teardown.sh

