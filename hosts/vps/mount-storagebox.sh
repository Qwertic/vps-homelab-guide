#!/usr/bin/env bash
# Mount a Hetzner Storage Box at /srv/data over SMB3.
# Enable SMB support for the box in the Hetzner console first.
#
#   SB_USER=u123456 SB_PASS='...' bash mount-storagebox.sh
#
# It's at Hetzner, same as the VPS, so it is NOT your offsite copy. restic → B2 is.
set -euo pipefail
: "${SB_USER:?set SB_USER (e.g. u123456)}"
: "${SB_PASS:?set SB_PASS}"

apt-get -y install cifs-utils
install -m 600 /dev/null /etc/storagebox.cred
printf 'username=%s\npassword=%s\n' "$SB_USER" "$SB_PASS" > /etc/storagebox.cred

if [[ -n "$(ls -A /srv/data)" ]]; then
  echo "/srv/data is not empty; move its contents onto the box first." >&2
  exit 1
fi

line="//${SB_USER}.your-storagebox.de/backup /srv/data cifs credentials=/etc/storagebox.cred,uid=1000,gid=1000,file_mode=0660,dir_mode=0770,iocharset=utf8,seal,_netdev,nofail,x-systemd.automount 0 0"
grep -q ' /srv/data cifs ' /etc/fstab || echo "$line" >> /etc/fstab
systemctl daemon-reload
mount /srv/data
install -d -o 1000 -g 1000 /srv/data/immich /srv/data/media
df -h /srv/data
