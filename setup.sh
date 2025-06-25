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

# Levanta el API Gateway con Kong
echo "Levantando API GATEWAY..."
docker-compose -f infraestructura/api-gateway/docker-compose.yml up -d --build 

# Levanta RabbitMQ con su UI de administración
echo "Levantando RABBITMQ..."
docker-compose -f infraestructura/rabbitmq/docker-compose.yml up -d --build 

# Levanta Consul 
echo "Levantando Service Dsicovery (Consul)..."
docker-compose -f infraestructura/consul/docker-compose.yml up -d --build 


echo "✅ Infraestructura iniciada correctamente."

echo "==============================="
echo " 🧹 Limpiando carpeta Repos/..."
echo "==============================="

# Borra todo el contenido de la carpeta Repos/ sin eliminar la carpeta en sí
rm -rf Repos/*
mkdir -p Repos  # Asegura que la carpeta Repos exista

echo "📁 Creando carpetas necesarias para los microservicios..."

# Crea carpetas vacías para los microservicios
mkdir -p repos/cocina
mkdir -p repos/contratacion
mkdir -p repos/evaluacion
mkdir -p repos/plan

echo "Clonando repositorios..."
source .env

echo "🐙 Clonando repositorios desde GitHub..."

# Clona los repositorios especificados en el archivo .env
git clone --branch $RAMA_EVALUACION $REPO_EVALUACION repos/evaluacion
git clone --branch $RAMA_PLAN_ALIMENTICIO $REPO_PLAN_ALIMENTICIO repos/plan
git clone $REPO_COCINA repos/cocina
#git clone $REPO_MICROSERVICIO2 Repos/Microservicio2

echo "🛠️ Levantando microservicios..."
sleep 5s
# Construye y levanta cada microservicio desde su propio docker-compose
(
  cd repos/evaluacion
  echo "🔧 Instalando Composer..."
  composer install 
  echo "🔧 Levantando Microservicio Evaluación Nutricional..."
  # docker-compose -f docker-compose-con-dockfile.yml up -d --build
  docker-compose up -d
)

(
  cd repos/plan
  echo "🔧 Levantando Microservicio Plan Alimenticio..."
  docker-compose -f docker-compose.yml up -d --build
)
 
 #(
   #cd repos/cocina
   #echo "🔧 Levantando Microservicio Cocina..."
   #docker-compose -f docker-compose.yml up -d --build
 #)

#(
#  cd Repos/Microservicio2
#  echo "🔧 Levantando Microservicio2..."
#  docker-compose up -d --build
#)

echo "✅ Todo el entorno está listo."
