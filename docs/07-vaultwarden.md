# 7. Password manager: Vaultwarden

**Goal:** your own Bitwarden-compatible password manager, with sign-ups closed.

## 7.1 Server
Start with sign-ups open, just long enough to create your own account:
```sh
cd ~/home-lab/stacks/vaultwarden
printf 'DOMAIN=example.com\nSIGNUPS_ALLOWED=true\n' > .env
docker compose up -d
```

## 7.2 Browser
1. Open `https://vault.example.com` → **Create account**.
2. The **master password can't be recovered.** Use a long passphrase and add it to
   your offline copy.
3. **Settings → Security → Two-step login → Authenticator app.** Save the recovery
   code offline too.

## 7.3 Server: close sign-ups
```sh
sed -i 's/SIGNUPS_ALLOWED=true/SIGNUPS_ALLOWED=false/' .env && docker compose up -d
```
✅ Log out and try **Create account** again: it should be refused.

## 7.4 Apps
In any Bitwarden app, on the login screen choose **Self-hosted** and enter server
`https://vault.example.com`. Devices need Tailscale running to sync. When the server
is unreachable, the apps keep a read-only offline copy of your vault.

## 7.5 Check the backup
Add a Kuma monitor for the vault, then:
```sh
sudo systemctl start restic-backup.service && sudo bash -c 'set -a; . /etc/restic/restic.env; set +a; restic ls latest | grep vaultwarden_db'
```
✅ It prints `/srv/state/dumps/sqlite/vaultwarden_db.sqlite3`.

**Next:** [Pi-hole](08-pihole.md)
