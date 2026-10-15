# 11. Photos: Immich

**Goal:** phone photo backup and a Google Photos-style library, with originals on the
Storage Box and the database plus thumbnails on the fast local SSD.

`stacks/immich/compose.yml` is Immich's official file with three changes:
- no published port (Caddy reaches it)
- thumbnails mounted from `/srv/state`
- joined to the `proxy` network

When upgrading, compare it with the official file (`bin/check-updates` does this for you).

## 11.1 Server
```sh
cd ~/home-lab/stacks/immich
cp .env.example .env
sed -i "s/^DB_PASSWORD=$/DB_PASSWORD=$(openssl rand -hex 24)/" .env
nano .env                 # set TZ
docker compose up -d      # a few GB to download the first time
docker compose ps         # ✅ 4 containers, "healthy" after 1–2 minutes
```

## 11.2 Browser
1. Open `https://photos.example.com`. The **first account becomes the admin**.
2. **Administration → Settings → Storage Template → enable** it **before** uploading.
   Files then land in year/month folders you can browse without Immich. If you've
   already uploaded, run **Jobs → Storage Template Migration**.

## 11.3 Check the backup before uploading
```sh
sudo systemctl start restic-backup.service && sudo bash -c 'set -a; . /etc/restic/restic.env; set +a; restic ls latest | grep immich.sql.gz'
```
✅ It prints `/srv/state/dumps/immich.sql.gz`. Without that database dump, a restore
gives you files but no albums, faces or people.

## 11.4 Upload
| Source | How |
|---|---|
| **Phone** | Immich app → server `https://photos.example.com` → turn on **Backup**. Tailscale must be on. |
| **Folders on a computer** | the CLI, below |
| **Apple Photos / iCloud** | Photos → File → Export → **Export Unmodified Originals**, then the CLI |
| **Google Photos** | Google Takeout, then [immich-go](https://github.com/simulot/immich-go), which keeps dates and albums |

The CLI needs Node.js. Create an API key under Account Settings → API Keys, then:
```sh
npx @immich/cli login https://photos.example.com <api-key>
npx @immich/cli upload --recursive --dry-run ~/Pictures/trip                        # preview first
npx @immich/cli upload --recursive --album-name "Trip 2026" ~/Pictures/trip ~/Desktop/more
```
`--album-name` puts everything into one album; `--album` makes one album per folder.
Duplicates are skipped, so re-running after an interruption is safe. The album is
created at the **end** of the upload.

Afterwards, Immich spends a while making thumbnails and recognising faces
(Administration → Jobs), and the server will be busy. Add a Kuma monitor for photos.

**Next:** [Beszel](12-beszel.md)
