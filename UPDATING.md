# Updating

## What updates on its own
- **Debian security updates** install daily (unattended-upgrades). They never reboot
  the server; `bin/update-stacks` tells you when a reboot is needed.
- **Nothing else.** Container versions are pinned in `stacks/*/compose.yml`, so nothing
  changes until you decide.

Most pins float on patch releases (`authelia:4.39`, `beszel:0.21`, `forgejo:16`), so a
plain pull picks up bug and security fixes. `uptime-kuma:2` and `caddy:2` also follow
minor releases; both projects keep those backwards compatible. Exact pins
(Vaultwarden, Pi-hole, Unbound, Immich) only change when you edit them.

## Automatic monthly run
`homelab-maintenance.timer` runs `bin/monthly-maintenance` on the **first Sunday of each
month around 04:30** (server time, UTC). It:
1. runs `git pull`, so repo changes you pushed are picked up
2. runs `bin/update-stacks`: a fresh backup, then patch updates for the floating tags
3. checks that nothing is exited, restarting or unhealthy
4. runs `bin/check-updates` and **notifies you** about new minor/major versions. It
   **never applies those**: they need you to read the release notes.
5. reboots if Debian security updates need it. About 4 minutes after **every** boot,
   `bin/boot-check` runs the same health check (including "does Pi-hole actually
   answer?") and alerts you if anything didn't come back

Every run ends with an ntfy notification: **OK**, **needs a decision** (with the list),
or **FAILED** / **containers down** (with what to do). Immich is pinned to an exact
version, so it only ever changes when you bump it.

Install it once on the server:
```sh
cd ~/home-lab && sudo NTFY_URL=https://ntfy.sh/<your-topic> bash maintenance/install.sh
```
Run it now, to test: `sudo systemctl start homelab-maintenance && journalctl -u homelab-maintenance -f`

When a "needs a decision" notification arrives, follow the manual routine below.

## Manual routine (for new minor/major versions, ~15 minutes)

### 1. Mac: see what's new
```sh
cd ~/code/home-lab && bin/check-updates
```
- `ok` / `ok (patch via pull)`: nothing to edit; step 3 picks up the patches.
- `UPDATE AVAILABLE`: a new minor or major version. **Read its release notes first**
  (the link is printed). Look for "breaking changes" and "manual steps".
- Immich's valkey/postgres line: if it lists images, copy those lines from Immich's
  official `docker-compose.yml` into `stacks/immich/compose.yml`.

### 2. Mac: bump what you decided to update
Edit the tag in the stack's `compose.yml`, e.g. `authelia/authelia:4.39` → `4.40`.
For Immich, the version is an exact pin, `IMMICH_VERSION=v3.3.3`, in the **server's**
`stacks/immich/.env` (and in `.env.example` in the repo). Then commit and push:
```sh
git commit -am "Update authelia to 4.40" && git push
```

### 3. Server: apply
```sh
cd ~/home-lab && git pull
bin/update-stacks
```
This takes a fresh backup, pulls images, rebuilds Caddy, restarts each stack, and
removes old images. Updating a single stack: `bin/update-stacks immich`.

### 4. Check
- Kuma: everything green. Beszel: nothing pinned at 100% CPU for long.
- Open the updated apps and log in.
- If it said so: `sudo reboot`, then check Kuma again.

## Per-service notes
- **Immich** changes fastest and has had breaking releases. Update it on its own
  (`bin/update-stacks immich`), never skip a major version, and always read the
  release notes. Its `docker-compose.yml` is the reference for what our copy should be.
- **Authelia**: after an update, `docker compose logs` in `stacks/authelia` may warn
  about deprecated config keys. Fix them before the next major version removes them.
- **Pi-hole**: DNS blips for a few seconds while it restarts.
- **Caddy**: rebuilt from the latest `caddy:2` with the Cloudflare plugin. If the
  build fails, the old container keeps running.

## Rolling back
1. **Image only, no database change:** put the old tag back, push, `git pull`,
   `bin/update-stacks <stack>`.
2. **The app migrated its database** (Immich, Forgejo, Vaultwarden can): the old version
   may refuse the new schema. Restore that stack's state from the backup taken in step 3:
   ```sh
   cd ~/home-lab/stacks/<stack> && docker compose down
   sudo bash -c 'set -a; . /etc/restic/restic.env; set +a; restic snapshots'   # pick the pre-update one
   sudo bash -c 'set -a; . /etc/restic/restic.env; set +a; restic restore <id> --target / --include /srv/state/<stack>'
   ```
   Then put the old tag back and start it. For Immich, restore Postgres from
   `/srv/state/dumps/immich.sql.gz` (see Immich's backup docs).
3. **Everything is broken:** Hetzner server backup (if enabled) → Rebuild from it, or
   follow `backup/RESTORE.md`.
