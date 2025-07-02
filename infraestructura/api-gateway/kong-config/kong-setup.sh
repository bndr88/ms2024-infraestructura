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

# echo "🔧 Creando servicio y ruta para login..."
# curl -s -X POST $KONG_URL/services --data name=login-service --data url=http://login-service/
# fail_on_error $? "crear servicio login"

# curl -s -X POST $KONG_URL/routes \
#   --data service.name=login-service \
#   --data paths[]=/api/login \
#   --data methods[]=POST
# fail_on_error $? "crear ruta login"

# curl -i -X POST $KONG_URL/routes \
#   --data name=evaluacion-route \
#   --data paths[]=/evaluacion \
#   --data service.name=evaluacion

# ----- Agregando seguridad con JWT ------
echo "👤 Creando consumer JWT..."
curl -s -X POST $KONG_URL/consumers --data username=admin
fail_on_error $? "crear consumer"

echo "🔑 Creando credenciales JWT para admin..."
curl -s -X POST $KONG_URL/consumers/admin/jwt \
  --data algorithm=HS256 \
  --data key=admin \
  --data secret=supersecretkey
fail_on_error $? "crear credencial JWT"

echo "\n";
echo "✅ ¡Kong configurado con éxito!"
