#!/bin/sh

KONG_URL="http://kong:8001"

fail_on_error() {
  if [ "$1" -ne 0 ]; then
    echo "❌ Error en paso: $2"
    exit 1
  fi
}

echo "⏳ Esperando 10 segundos para asegurar que Kong esté completamente disponible..."
sleep 10

echo "⌛ Esperando respuesta de Kong..."
until curl -s $KONG_URL/status | grep -q "database"; do
  echo "🔁 Esperando que Kong esté listo..."
  sleep 2
done

echo "🚀 Kong disponible. Iniciando configuración..."

echo "🔧 Creando servicio y ruta para login..."
curl -s -X POST $KONG_URL/services --data name=login-service --data url=http://login-service/
fail_on_error $? "crear servicio login"

curl -s -X POST $KONG_URL/routes \
  --data service.name=login-service \
  --data paths[]=/api/login \
  --data methods[]=POST
fail_on_error $? "crear ruta login"

echo "🔧 Creando servicio y ruta para users..."
curl -s -X POST $KONG_URL/services --data name=users-service --data url=https://jsonplaceholder.typicode.com/users
fail_on_error $? "crear servicio users"

curl -s -X POST $KONG_URL/routes \
  --data service.name=users-service \
  --data paths[]=/api/users
fail_on_error $? "crear ruta users"

echo "🔧 Creando servicio y ruta para posts..."
curl -s -X POST $KONG_URL/services --data name=posts-service --data url=https://jsonplaceholder.typicode.com/posts
fail_on_error $? "crear servicio posts"

curl -s -X POST $KONG_URL/routes \
  --data service.name=posts-service \
  --data paths[]=/api/posts
fail_on_error $? "crear ruta posts"

echo "🔧 Creando servicio y ruta para paciente..."
curl -s -X POST $KONG_URL/services \
  --data name=paciente-service \
  --data url=http://host.docker.internal:8081/
fail_on_error $? "crear servicio paciente"

curl -s -X POST $KONG_URL/routes \
  --data service.name=paciente-service \
  --data paths[]=/paciente/add \
  --data strip_path=false \
  --data methods[]=POST
fail_on_error $? "crear ruta paciente"

echo "👤 Creando consumer JWT..."
curl -s -X POST $KONG_URL/consumers --data username=admin
fail_on_error $? "crear consumer"

echo "🔑 Creando credenciales JWT para admin..."
curl -s -X POST $KONG_URL/consumers/admin/jwt \
  --data algorithm=HS256 \
  --data key=admin \
  --data secret=supersecretkey
fail_on_error $? "crear credencial JWT"

echo "🔐 Activando plugin JWT en users-service..."
curl -s -X POST $KONG_URL/services/users-service/plugins --data name=jwt
fail_on_error $? "activar plugin JWT para users"

echo "🔐 Activando plugin JWT en posts-service..."
curl -s -X POST $KONG_URL/services/posts-service/plugins --data name=jwt
fail_on_error $? "activar plugin JWT para posts"

echo "🔐 Activando plugin JWT en paciente-service..."
curl -s -X POST $KONG_URL/services/paciente-service/plugins --data name=jwt
fail_on_error $? "activar plugin JWT para PACIENTES"

echo "✅ ¡Kong configurado con éxito!"
