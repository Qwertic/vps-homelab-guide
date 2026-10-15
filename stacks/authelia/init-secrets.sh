#!/usr/bin/env bash
# Generate Authelia's secrets once on the VPS. Copy them to your offline
# break-glass storage: losing storage_encryption_key makes the DB unreadable.
set -euo pipefail
dir=/srv/state/authelia/secrets
install -d -m 700 "$dir"
for name in jwt_secret session_secret storage_encryption_key; do
  [[ -s "$dir/$name" ]] || openssl rand -hex 64 > "$dir/$name"
done
chmod 600 "$dir"/*
install -d /srv/state/authelia/data
echo "Secrets in $dir. Now create /srv/state/authelia/data/users.yml from users.yml.example."
