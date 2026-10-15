# 12. Server dashboard: Beszel

**Goal:** CPU, memory, disk (including the Storage Box) and per-container usage, with
alerts before you run out of disk space. With Immich running, the 80 GB disk and
8 GB of RAM are the limits you'll hit first.

## 12.1 Server
```sh
mkdir -p /srv/state/beszel/data /srv/state/beszel/socket /srv/data/.beszel
cd ~/home-lab/stacks/beszel
cp .env.example .env
docker compose up -d
```
The agent complains about a missing key until step 12.3. That's expected.

## 12.2 Browser
Open `https://stats.example.com`. Log in to Authelia, then create Beszel's admin account.

## 12.3 Add this server
1. **Add System:** name `homelab`, Host/IP **`/beszel_socket/beszel.sock`**. The hub and
   agent talk through a shared socket file, not the network.
2. Copy the **public key** and **token** from the dialog into `.env`:
   ```
   BESZEL_KEY=ssh-ed25519 AAAA...
   BESZEL_TOKEN=...
   ```
   One line each, no quotes. Then `docker compose up -d`, and click **Add system**.
3. ✅ `homelab` turns green within about 30 seconds.

If it stays red, check what the agent actually receives:
```sh
docker compose config | grep -E '^\s+(KEY|TOKEN):' | cut -c1-40
docker compose logs --since 1m beszel-agent
```
`no key provided` means the `.env` line is missing, misnamed or not saved. Note that
`logs --tail` also shows old errors, so use `--since`.

## 12.4 Alerts
Settings → Notifications → `https://ntfy.sh/<topic>`. On `homelab`, click the bell and
enable **Disk > 80%**, **Memory > 90%** and **Status**.

**Next:** [Jellyfin (optional)](13-jellyfin.md) · [Monthly updates](../UPDATING.md)
