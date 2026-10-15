#!/usr/bin/env bash
# Install the backup job on the VPS. Run as root from this directory.
set -euo pipefail
apt-get -y install restic sqlite3
install -d -m 700 /etc/restic /etc/restic/pre.d
[[ -e /etc/restic/restic.env ]] || install -m 600 restic.env.example /etc/restic/restic.env
[[ -e /etc/restic/password ]] || { openssl rand -base64 32 > /etc/restic/password; chmod 600 /etc/restic/password; }
install -m 644 excludes /etc/restic/excludes
install -m 755 pre.d/*.sh /etc/restic/pre.d/
install -m 755 backup.sh /usr/local/bin/homelab-backup
install -m 644 restic-backup.service restic-backup.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now restic-backup.timer
cat <<'MSG'
Next:
  1. Fill in /etc/restic/restic.env
  2. Copy /etc/restic/password to offline storage
  3. set -a; . /etc/restic/restic.env; set +a; restic init
  4. systemctl start restic-backup.service && journalctl -u restic-backup -f
MSG
