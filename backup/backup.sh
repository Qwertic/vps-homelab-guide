#!/usr/bin/env bash
# Nightly offsite backup of /srv/state (app state), /srv/data (photos, media) and
# /home (the repo checkout with each stack's .env: tokens and passwords).
# Installed as /usr/local/bin/homelab-backup and run by restic-backup.timer.
set -euo pipefail
set -a; source /etc/restic/restic.env; set +a

ping() { if [[ -n "${HC_PING_URL:-}" ]]; then curl -fsS -m 10 --retry 3 "${HC_PING_URL}$1" >/dev/null || true; fi; }
trap 'ping /fail' ERR
ping /start

# Pre-backup hooks, e.g. dumping Immich's Postgres into /srv/state/dumps.
# Raw database files copied while running are not a safe backup.
for hook in /etc/restic/pre.d/*.sh; do
  if [[ -e "$hook" ]]; then bash "$hook"; fi
done

restic backup /srv/state /srv/data /home --exclude-caches --exclude-file=/etc/restic/excludes
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune

# Sundays: verify a random 5% of the stored data actually reads back.
if [[ "$(date +%u)" == 7 ]]; then
  restic check --read-data-subset=5%
fi

ping ""
