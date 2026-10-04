#!/usr/bin/env sh
# Respaldo diario de la base y las fotos. Programar con cron (ver DESPLIEGUE.md).
set -eu
DESTINO=/opt/garlic/backups
FECHA=$(date +%F)
mkdir -p "$DESTINO"
cd /opt/garlic/deploy
docker compose exec -T db pg_dump -U garlic -Fc garlic > "$DESTINO/garlic-$FECHA.dump"
docker run --rm -v garlic_evidencias:/datos:ro -v "$DESTINO":/respaldo alpine \
  tar czf "/respaldo/evidencias-$FECHA.tgz" -C /datos .
# conservar 14 dias
find "$DESTINO" -type f -mtime +14 -delete
