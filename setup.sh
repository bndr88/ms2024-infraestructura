#!/bin/bash

# Detiene el script si ocurre un error en cualquier línea
set -e

echo "🚀 Levantando infraestructura con Docker Compose..."
sleep 2s
# Crear red externa para Kong si no existe
echo "🔌 Verificando red externa kong-net..."
docker network inspect kong-net >/dev/null 2>&1 || docker network create kong-net

echo "🔌 Verificando red externa nur-network..."
docker network inspect nur-network >/dev/null 2>&1 || docker network create nur-network

echo "==============================="
echo " 🧹 Limpiando carpeta Repos/..."
echo "==============================="

# Borra todo el contenido de la carpeta Repos/ sin eliminar la carpeta en sí
rm -rf ./Repos/*
mkdir -p ./Repos  # Asegura que la carpeta Repos exista
source .env

echo "📁 Creando carpetas necesarias para los microservicios..."
# Crea carpetas vacías para los microservicios
mkdir -p ./Repos/identidad
mkdir -p ./Repos/cocina
mkdir -p ./Repos/contratacion
mkdir -p ./Repos/evaluacion
mkdir -p ./Repos/plan
mkdir -p ./Repos/delivery

echo "Levantando Servicio Identidad..."
git clone --branch $RAMA_IDENTIDAD $REPO_IDENTIDAD ./Repos/identidad
docker-compose -f ./Repos/identidad/docker-compose.yml up -d --build 

# Levanta el API Gateway con Kong
echo "Levantando API GATEWAY..."
docker-compose -f ./infraestructura/api-gateway/docker-compose.yml up -d --build 

# Levanta Consul 
echo "Levantando Service Dsicovery (Consul)..."
docker-compose -f ./infraestructura/consul/docker-compose.yml up -d --build 

# Levanta el sincronizador entre Consul y Kong
echo "Levantando sincronizador Consul -> Kong..."
docker-compose -f ./infraestructura/consul-to-kong/docker-compose.yml up -d --build

# Levanta RabbitMQ con su UI de administración
echo "Levantando RABBITMQ..."
docker-compose -f ./infraestructura/rabbitmq/docker-compose.yml up -d --build 

# Levanta las herramientas para Observabilidad
echo "Levantando Todo Para Observabilidad..."
docker compose -f ./infraestructura/observabilidad/docker-compose.yml up -d

echo "✅ Infraestructura iniciada correctamente."

echo "Clonando repositorios..."

echo "🐙 Clonando repositorios desde GitHub..."

# Clona los repositorios especificados en el archivo .env
git clone --branch $RAMA_EVALUACION $REPO_EVALUACION ./Repos/evaluacion
git clone --branch $RAMA_PLAN_ALIMENTICIO $REPO_PLAN_ALIMENTICIO ./Repos/plan
git clone --branch $RAMA_COCINA $REPO_COCINA Repos/cocina
git clone --branch $RAMA_DELIVERY $REPO_DELIVERY Repos/delivery
git clone --branch $RAMA_CONTRATO $REPO_CONTRATO Repos/contratacion
#git clone $REPO_MICROSERVICIO2 Repos/Microservicio2

echo "🛠️ Levantando microservicios..."
sleep 5s
# Construye y levanta cada microservicio desde su propio docker-compose
(
  cd ./Repos/evaluacion
  echo "🔧 Instalando Composer..."
  composer install 
  echo "🔧 Levantando Microservicio Evaluación Nutricional..."
  # docker-compose -f docker-compose-con-dockfile.yml up -d --build
  docker-compose up -d
)

(
  cd ./Repos/plan
  echo "🔧 Levantando Microservicio Plan Alimenticio..."
  docker-compose -f docker-compose.yml up -d --build
)
 
(
  cd ./Repos/cocina
  echo "🔧 Levantando Microservicio Cocina..."
  docker-compose -f docker-compose.yml up -d --build
)

(
  cd ./Repos/delivery
  echo "🔧 Levantando Microservicio Delivery..."
  docker-compose -f docker-compose.yml up -d --build
)

(
  cd ./Repos/contratacion
  echo "🔧 Levantando Microservicio Contratato..."
  docker-compose -f docker-compose.yml up -d --build
)

#(
#  cd ./Repos/Microservicio2
#  echo "🔧 Levantando Microservicio2..."
#  docker-compose up -d --build
#)

echo "✅ Todo el entorno está listo."
