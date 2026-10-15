#!/usr/bin/env bash
# Immich's Postgres holds albums, faces and metadata. Without it the photo files
# restore as an unsorted pile. Command from https://docs.immich.app/administration/backup-and-restore
set -euo pipefail
docker ps --format '{{.Names}}' | grep -qx immich_postgres || exit 0
install -d -m 700 /srv/state/dumps
docker exec immich_postgres pg_dumpall --clean --if-exists --username=postgres \
  | gzip > /srv/state/dumps/immich.sql.gz.tmp
mv /srv/state/dumps/immich.sql.gz.tmp /srv/state/dumps/immich.sql.gz
