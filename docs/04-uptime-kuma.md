# 4. Monitoring and phone alerts: Uptime Kuma

**Goal:** a push notification on your phone when a service goes down.

## 4.1 Server
```sh
cd ~/home-lab/stacks/uptime-kuma && docker compose up -d
```
Open `https://status.example.com`. Authelia should let you through if you're logged in.
That's your first proof that SSO works. Then:
1. Pick **SQLite** as the database. The backup hooks handle it.
2. Create Kuma's admin account.
3. Add **HTTP(s)** monitors for `https://auth.example.com` and `https://status.example.com`.
   Add one for each new service as you go.

## 4.2 Alerts with ntfy
1. Install the **ntfy** app on your phone and subscribe to a long random topic,
   e.g. `mylab-7f3k9x`.
2. Kuma → Settings → Notifications → **ntfy**: Server URL `https://ntfy.sh`, Topic
   `mylab-7f3k9x`. The topic is just the name, with no URL and no slashes, otherwise you
   get `topic invalid`. Tick **Default enabled** and **Apply on all existing monitors**,
   then click **Test**.

## If monitors time out
`bootstrap.sh` already contains the fix. If you set up the server some other way:
Kuma runs in a Docker network, and reaching `https://*.example.com` means connecting
to the server's Tailscale IP *from that network*. ufw only allows traffic from
`tailscale0`, so it drops these requests silently. Allow Docker's private range to reach Caddy:
```sh
sudo ufw allow from 172.16.0.0/12 to any port 443 proto tcp comment 'containers -> caddy'
```
Don't allow all ports from that range. 443 is all that's needed.

## Its blind spot
Kuma can't tell you the whole server is down, because it's on that server. The
healthchecks.io ping from the backup job (next step) covers that.

**Next:** [Backups](05-backups.md)
