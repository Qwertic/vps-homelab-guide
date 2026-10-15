#!/usr/bin/env bash
# Install the monthly maintenance timer. Run from the repo on the server:
#   sudo NTFY_URL=https://ntfy.sh/<your-topic> bash maintenance/install.sh
set -euo pipefail
: "${NTFY_URL:?set NTFY_URL, e.g. https://ntfy.sh/your-topic}"
user=${SUDO_USER:?run with sudo as your admin user}
repo=$(cd "$(dirname "$0")/.." && pwd)

install -d -m 755 /etc/homelab
printf 'NTFY_URL=%s\n' "$NTFY_URL" > /etc/homelab/maintenance.env
chmod 644 /etc/homelab/maintenance.env

cat > /etc/systemd/system/homelab-maintenance.service <<UNIT
[Unit]
Description=Homelab monthly maintenance (backup, patch updates, version report)
Wants=network-online.target
After=network-online.target docker.service

[Service]
Type=oneshot
User=$user
ExecStart=$repo/bin/monthly-maintenance
UNIT

cat > /etc/systemd/system/homelab-maintenance.timer <<'UNIT'
[Unit]
Description=Homelab monthly maintenance, first Sunday of the month

[Timer]
OnCalendar=Sun *-*-01..07 04:30:00
RandomizedDelaySec=15m
Persistent=true

[Install]
WantedBy=timers.target
UNIT

cat > /etc/systemd/system/homelab-boot-check.service <<UNIT
[Unit]
Description=Homelab health check after boot (alerts via ntfy)

[Service]
Type=oneshot
User=$user
ExecStart=$repo/bin/boot-check
UNIT

cat > /etc/systemd/system/homelab-boot-check.timer <<'UNIT'
[Unit]
Description=Run the homelab health check 4 minutes after every boot

[Timer]
OnBootSec=4min

[Install]
WantedBy=timers.target
UNIT

# dig, for the DNS check in bin/healthcheck
command -v dig >/dev/null || apt-get -y install bind9-dnsutils

systemctl daemon-reload
systemctl enable --now homelab-maintenance.timer homelab-boot-check.timer
systemctl list-timers 'homelab-*' --no-pager
