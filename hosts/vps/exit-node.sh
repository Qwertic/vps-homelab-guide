#!/usr/bin/env bash
# Make the server a Tailscale exit node: on untrusted Wi-Fi, flip one switch in the
# Tailscale app and all your traffic leaves through the server, past Pi-hole.
#
#   sudo bash hosts/vps/exit-node.sh
#
# Then approve it once: Tailscale admin → Machines → the server → ⋯ →
# Edit route settings → "Use as exit node".
set -euo pipefail

cat > /etc/sysctl.d/99-tailscale-exit-node.conf <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p /etc/sysctl.d/99-tailscale-exit-node.conf

# ufw drops forwarded (routed) traffic by default. Allow tailnet → internet only.
wan=$(ip route show default | awk '{print $5; exit}')
ufw route allow in on tailscale0 out on "$wan" comment 'tailscale exit node'

tailscale set --advertise-exit-node

echo "Now approve it: Tailscale admin → Machines → $(hostname) → Edit route settings → Use as exit node"
