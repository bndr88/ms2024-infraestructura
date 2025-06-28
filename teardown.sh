#!/bin/bash

set -e

echo "======================================"
echo " 🛑 Deteniendo y eliminando servicios..."
echo "======================================"

# Infraestructura: Kong API Gateway
if [ -f infraestructura/api-gateway/docker-compose.yml ]; then
  echo "🔻 Apagando API Gateway (Kong)..."
  docker-compose -f infraestructura/api-gateway/docker-compose.yml down -v
fi

# Infraestructura: RabbitMQ
if [ -f infraestructura/rabbitmq/docker-compose.yml ]; then
  echo "🔻 Apagando RabbitMQ..."
  docker-compose -f infraestructura/rabbitmq/docker-compose.yml down -v
fi

# Infraestructura: Consul
if [ -f infraestructura/consul/docker-compose.yml ]; then
  echo "🔻 Apagando Consul..."
  docker-compose -f infraestructura/consul/docker-compose.yml down -v
fi

# Infraestructura: consul-to-kong
if [ -f infraestructura/consul/docker-compose.yml ]; then
  echo "🔻 Apagando consul-to-kong..."
  docker-compose -f infraestructura/consul-to-kong/docker-compose.yml down -v
fi

# Microservicio Evaluación Nutiricional
if [ -f repos/evaluacion/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio Evaluación Nutricional..."
  (cd repos/evaluacion && docker-compose -f docker-compose-con-dockfile.yml down -v)
fi

# Microservicio Plan Alimenticio
if [ -f repos/plan/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio2..."
  (cd repos/plan && docker-compose -f docker-compose.yml down -v)
fi

# Microservicio Cocina
if [ -f repos/cocina/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio Cocina..."
  (cd repos/cocina && docker-compose -f docker-compose.yml down -v)
fi

# Microservicio2
#if [ -f Repos/Microservicio2/docker-compose.yml ]; then
#  echo "🔻 Apagando Microservicio2..."
#  (cd Repos/Microservicio2 && docker-compose down -v)
#fi

echo "✅ Todos los servicios han sido detenidos y limpiados con volúmenes eliminados."

