# 6. Restore drill: prove the backups work

**Goal:** rebuild the lab on a throwaway server using **only your offline copy**. It
takes about 20 minutes and costs a few cents. Do it before you put photos or passwords
on the server.

The exact steps are in the runbook: **[backup/RESTORE.md](../backup/RESTORE.md)**. In short:
1. Create a small throwaway server: CAX11, Debian 13, **no firewall**. It's key-only
   and deleted afterwards.
2. Bootstrap it and approve it in Tailscale.
3. Type the restic credentials **from your offline copy**. Don't copy them from the
   live server: checking your notes is the point. If you get `wrong password` or
   `Malformed Access Key`, your notes are wrong. Better to find out now.
4. Restore: `restic restore latest --target /`. This brings back `/srv`, `/home`, the repo
   and the `.env` files.
5. Set `TS_IP` in `stacks/caddy/.env` to the **drill** server's Tailscale IP.
6. Start caddy, authelia and uptime-kuma.
7. On your computer, temporarily point the names at the drill server in `/etc/hosts`,
   then flush the DNS cache:
   ```sh
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
   ```
   Log in with a private browser window while watching
   `docker compose logs -f` in `stacks/authelia` on the drill server.
   ✅ **Pass:** your login appears in the drill server's log, your password and 2FA work,
   and Kuma shows your monitors.
8. Undo the `/etc/hosts` change, delete the server, and remove it from Tailscale.

Afterwards you can decide whether to keep Hetzner's server backups (one-click
rollback after a bad update) or drop them (−20% cost).

**Next:** [Vaultwarden](07-vaultwarden.md)
