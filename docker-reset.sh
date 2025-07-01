#!/bin/bash

set -e

echo "🔧 Deteniendo el servicio Docker..."
sudo systemctl stop docker

echo "🧨 Borrando todos los datos de Docker..."
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

echo "🚀 Reiniciando el servicio Docker..."
sudo systemctl start docker

echo "✅ Docker ha sido reiniciado. Verificando estado..."

echo -e "\n📦 Contenedores:"
docker ps -a

echo -e "\n🖼️ Imágenes:"
docker images -a

echo -e "\n🗃️ Volúmenes:"
docker volume ls

echo -e "\n🌐 Redes:"
docker network ls

echo -e "\n✔️ Docker ha sido reseteado completamente."
