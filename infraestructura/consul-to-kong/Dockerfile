FROM php:8.2-cli

# Instalar curl
RUN apt-get update && apt-get install -y curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY consul-to-kong.php .

# Script de loop infinito cada 60 segundos
CMD while true; do \
    echo "[*] Ejecutando sincronización con Consul y Kong..."; \
    php consul-to-kong.php; \
    echo "[*] Esperando 60 segundos..."; \
    sleep 60; \
done
