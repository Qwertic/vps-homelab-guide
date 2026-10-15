# Restore runbook

A backup only counts once you've restored from it. Run this drill once before you
upload photos, then again every few months.

## Drill: restore onto a throwaway server
The live server stays untouched. Use only your **offline copy** of the restic
credentials, never values copied from the live server; testing that copy is the point.

1. **Hetzner:** create a CAX11 in the same location, Debian 13, your SSH key,
   **no firewall** (it's throwaway and key-only), no backups. Name it `restore-drill`.
2. **Bootstrap** it like the real server (`hosts/vps/bootstrap.sh`, same `ADMIN_USER`),
   approve it in Tailscale, and SSH in over its Tailscale IP.
3. **Credentials from the offline copy:**
   ```sh
   sudo apt-get install -y restic
   sudo install -d -m 700 /etc/restic
   sudo nano /etc/restic/restic.env   # RESTIC_REPOSITORY, AWS_ACCESS_KEY_ID,
                                      # AWS_SECRET_ACCESS_KEY, RESTIC_PASSWORD_FILE=/etc/restic/password
   sudo nano /etc/restic/password     # the restic password, one line
   ```
4. **Restore everything:**
   ```sh
   sudo bash -c 'set -a; . /etc/restic/restic.env; set +a; restic snapshots && restic restore latest --target /'
   ```
   This brings back `/srv/state`, `/srv/data` and `/home`, which includes the repo and its `.env` files.
5. **Point Caddy at this server's IP:** in `~/home-lab/stacks/caddy/.env`, set
   `TS_IP=` to the output of `tailscale ip -4`.
6. **Start the stacks:**
   ```sh
   for s in caddy authelia uptime-kuma; do (cd ~/home-lab/stacks/$s && docker compose up -d --build); done
   ```
7. **Test from your Mac** without touching real DNS:
   ```sh
   echo "<drill-tailscale-ip> auth.example.com status.example.com" | sudo tee -a /etc/hosts
   ```
   Open https://status.example.com. You should log in with your usual password + 2FA
   and see your monitors. Then **remove that line** from `/etc/hosts` (`sudo nano /etc/hosts`).
8. **Clean up:** delete the `restore-drill` server in Hetzner and remove it from the
   Tailscale admin console.
9. Write down how long it took and anything that surprised you, and fix this runbook.

If an app won't start on a restored database, use the consistent copy from
`/srv/state/dumps/` (SQLite: copy it over the live file with the app stopped).

## Real disaster
Same steps, but on a new VPS that you keep (with the `homelab` firewall), and skip the
`/etc/hosts` trick: update the Cloudflare `*` record to the new Tailscale IP instead.

## What you need offline (paper or a USB stick in a drawer)
This list says *what* to keep. Never write the values into this file; it's in git.
Everything else, including `/srv/state/authelia/secrets`, is inside the restic backup, so
the restic credentials are the only items you can't do without.

- restic repo URL, B2 keys, restic password
- Authelia `storage_encryption_key` (optional extra; it's in the backup too)
- Vaultwarden master password, Tailscale account recovery, Hetzner + Cloudflare logins
