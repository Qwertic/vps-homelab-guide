# 5. Backups: restic to Backblaze B2

**Goal:** a nightly encrypted backup at a **different company** than your server,
with a check that alerts you if it ever stops.

What gets backed up:
- `/srv/state`: app config and databases
- `/srv/data`: photos and media
- `/home`: the repo checkout, including each stack's `.env` (your tokens and passwords)

Before each run, hooks in `backup/pre.d/` write consistent database copies to
`/srv/state/dumps/`. Copying a database file while it's being written can capture it
half-finished. The dump hooks are:
- `sqlite3 .backup` for every SQLite database
- `pg_dumpall` for Immich

## 5.1 Backblaze B2 (browser)
1. Sign up and pick an **EU region** at signup (it can't be changed later).
2. **Create a bucket:** private, encryption off (restic already encrypts). Note its
   **Endpoint**, e.g. `s3.eu-central-003.backblazeb2.com`.
3. **Application Keys → Add a New Application Key** for **that bucket only**, read and
   write. Save the **keyID** (25 characters, starts with `00`) and the **applicationKey**
   (31 characters, starts with `K00`). The **master key doesn't work** with S3 tools.
4. Optional, recommended: a [healthchecks.io](https://healthchecks.io) check with a
   1-day period and 2-hour grace, sending alerts to your ntfy topic. Copy its ping URL.

## 5.2 Server: install the job
```sh
cd ~/home-lab/backup && sudo bash install.sh
sudo nano /etc/restic/restic.env
```
```
RESTIC_REPOSITORY=s3:https://s3.eu-central-003.backblazeb2.com/<bucket>/homelab
AWS_ACCESS_KEY_ID=<keyID>
AWS_SECRET_ACCESS_KEY=<applicationKey>
RESTIC_PASSWORD_FILE=/etc/restic/password
HC_PING_URL=<healthchecks ping URL, or empty>
```
Pay attention to the prefix: **`s3:https://`**.
- With `http://`, the connection times out.
- Without `s3:` entirely, restic quietly creates a **local folder** with that name and
  says "created repository". Nothing goes to B2.

## 5.3 Your offline copy
This is the one thing you must not skip. Write these down **off the server**: on paper,
or in a password manager that doesn't run on this server:
- the repository URL
- the keyID and applicationKey
- the restic password: `sudo cat /etc/restic/password`

Without them the backup can't be opened. Everything else (including Authelia's
secrets) is inside the backup. Don't rely on Vaultwarden for these: it runs on the
server you'd be trying to restore.

## 5.4 Create the repository and run the first backup
```sh
sudo bash -c 'set -a; . /etc/restic/restic.env; set +a; restic init'
```
✅ The message must say `at s3:https://...`, and files appear in the bucket in B2's web UI.
```sh
sudo systemctl start restic-backup.service && echo BACKUP-OK
sudo bash -c 'set -a; . /etc/restic/restic.env; set +a; restic snapshots; restic ls latest | grep -E "dumps/sqlite|stacks/caddy/.env"'
systemctl list-timers restic-backup.timer
```
✅ What to look for:
- a snapshot, plus the database dumps and your Caddy `.env` in the listing
- the next run scheduled around 03:30

The job keeps 7 daily, 4 weekly and 12 monthly snapshots, and on Sundays it reads
back 5% of the data to check its integrity.

**Next:** [Restore drill](06-restore-drill.md)
