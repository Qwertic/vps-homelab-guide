#!/usr/bin/env bash
# One-time setup for a fresh Debian 12/13 Hetzner VPS:
# admin user, SSH hardening, Docker, Tailscale, firewall, auto security updates.
#
# Run as root from the Hetzner console or first SSH session:
#   ADMIN_USER=me SSH_PUBKEY="ssh-ed25519 AAAA..." [TS_AUTHKEY=tskey-...] bash bootstrap.sh
#
# Before you close the root session, open a second one as ADMIN_USER over Tailscale
# and confirm it works.
set -euo pipefail

: "${ADMIN_USER:?set ADMIN_USER}"
: "${SSH_PUBKEY:?set SSH_PUBKEY}"

export DEBIAN_FRONTEND=noninteractive

echo "==> Packages"
apt-get update
apt-get -y upgrade
apt-get -y install ca-certificates curl gnupg ufw unattended-upgrades git bind9-dnsutils

echo "==> Admin user"
if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
fi
install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
echo "$SSH_PUBKEY" > "/home/$ADMIN_USER/.ssh/authorized_keys"
chown "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh/authorized_keys"
chmod 600 "/home/$ADMIN_USER/.ssh/authorized_keys"
# Key-only access, so there is no password to type for sudo.
echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$ADMIN_USER"
chmod 440 "/etc/sudoers.d/90-$ADMIN_USER"

echo "==> SSH hardening"
cat > /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
sshd -t
systemctl reload ssh

echo "==> Automatic security updates"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo "==> Docker"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "$ADMIN_USER"
docker network inspect proxy >/dev/null 2>&1 || docker network create proxy

# Containers publish ports on the Tailscale IP only. This lets Docker bind that IP
# at boot even if tailscaled hasn't brought the interface up yet.
echo "net.ipv4.ip_nonlocal_bind = 1" > /etc/sysctl.d/90-nonlocal-bind.conf
sysctl --system >/dev/null

echo "==> Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh
if [[ -n "${TS_AUTHKEY:-}" ]]; then
  tailscale up --accept-dns=false --authkey "$TS_AUTHKEY"
else
  tailscale up --accept-dns=false   # prints a login URL; blocks until you approve the machine
fi
echo "Tailscale IP: $(tailscale ip -4)"

echo "==> Firewall"
# Docker-published ports bypass ufw, which is why compose files bind to the
# Tailscale IP. ufw covers host services such as sshd.
ufw default deny incoming
ufw default allow outgoing
ufw allow in on tailscale0
ufw allow 41641/udp comment 'tailscale direct connections'
# Containers (e.g. Uptime Kuma) reaching services by their public names hit Caddy
# on the Tailscale IP from a Docker bridge, not from tailscale0.
ufw allow from 172.16.0.0/12 to any port 443 proto tcp comment 'containers -> caddy'
ufw --force enable

echo "==> Directories"
install -d -o "$ADMIN_USER" -g "$ADMIN_USER" /srv/state /srv/data

cat <<EOF

Done. Next:
  1. In a NEW terminal: ssh $ADMIN_USER@$(tailscale ip -4)   (must work before you log out)
  2. Add a Hetzner Cloud Firewall: allow inbound 41641/udp only.
  3. Clone this repo to /home/$ADMIN_USER/home-lab and follow README.md.
EOF
