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
if [ -f infraestructura/consul-to-kong/docker-compose.yml ]; then
  echo "🔻 Apagando consul-to-kong..."
  docker-compose -f infraestructura/consul-to-kong/docker-compose.yml down -v
fi

# Infraestructura: Observabilidad
if [ -f infraestructura/observabilidad/docker-compose.yml ]; then
  echo "🔻 Apagando observabilidad..."
  docker-compose -f infraestructura/observabilidad/docker-compose.yml down
fi

# Microservicio Identidad
if [ -f Repos/identidad/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio Identidad..."
  (cd Repos/identidad && docker-compose down -v)
fi

# Microservicio Evaluación Nutiricional
if [ -f Repos/evaluacion/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio Evaluación Nutricional..."
  (cd Repos/evaluacion && docker-compose down -v)
fi

# Microservicio Plan Alimenticio
if [ -f Repos/plan/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio Plan Alimenticio..."
  (cd Repos/plan && docker-compose -f docker-compose.yml down -v)
fi

# Microservicio Cocina
if [ -f Repos/cocina/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio Cocina..."
  (cd Repos/cocina && docker-compose -f docker-compose.yml down -v)
fi

# Microservicio Delivery
if [ -f Repos/cocina/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio Delivery..."
  (cd Repos/delivery && docker-compose -f docker-compose.yml down -v)
fi

# Microservicio Delivery
if [ -f Repos/contratacion/docker-compose.yml ]; then
  echo "🔻 Apagando Microservicio Contrato..."
  (cd Repos/contratacion && docker-compose -f docker-compose.yml down -v)
fi

# Microservicio2
#if [ -f Repos/Microservicio2/docker-compose.yml ]; then
#  echo "🔻 Apagando Microservicio2..."
#  (cd Repos/Microservicio2 && docker-compose down -v)
#fi

echo "✅ Todos los servicios han sido detenidos y limpiados con volúmenes eliminados."

