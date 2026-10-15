#!/usr/bin/env bash
# Consistent copies of every SQLite DB under /srv/state (Authelia, Vaultwarden,
# Uptime Kuma, Forgejo, Jellyfin, Beszel). Copying the live files can capture a
# half-written database; sqlite's .backup can't.
set -euo pipefail
out=/srv/state/dumps/sqlite
install -d -m 700 "$out"
find /srv/state -path /srv/state/dumps -prune -o -type f \
  \( -name '*.db' -o -name '*.sqlite' -o -name '*.sqlite3' \) -print |
while read -r db; do
  if head -c 16 "$db" | grep -q 'SQLite format 3'; then
    sqlite3 "$db" ".backup '$out/$(echo "${db#/srv/state/}" | tr / _)'"
  fi
done
