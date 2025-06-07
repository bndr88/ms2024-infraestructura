FROM alpine:latest

# Instalar curl y bash
RUN apk add --no-cache curl bash

# Copiar el script
COPY kong-setup.sh /kong-setup.sh

# Dar permisos de ejecución
RUN chmod +x /kong-setup.sh

ENTRYPOINT ["/kong-setup.sh"]
