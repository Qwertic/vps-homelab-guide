# 3. One login: Authelia

**Goal:** one username + password + 2FA code in front of every admin page.

Authelia protects the pages that have no login of their own, or whose login you don't
want exposed: Uptime Kuma, Beszel, the Pi-hole UI. Apps with phone or TV clients
(Vaultwarden, Immich, Jellyfin, Forgejo's git) skip it, because those clients can't get
through a login redirect. They still have their own logins and are only reachable over Tailscale.

## 3.1 Server: secrets and your user
```sh
cd ~/home-lab/stacks/authelia
echo "DOMAIN=example.com" > .env
bash init-secrets.sh
```
Create a password hash. It prompts for the password, so the password stays out of
your shell history. This is a **new password you invent now**: the one you'll type at
`auth.example.com`.
```sh
docker run --rm -it authelia/authelia:4.39 authelia crypto hash generate argon2
```
```sh
cp users.yml.example /srv/state/authelia/data/users.yml
nano /srv/state/authelia/data/users.yml
```
```yaml
users:
  yourname:                # the username. Keep it lowercase
    displayname: Your Name # exactly "displayname", all lowercase. "displayName" fails
    email: you@example.com
    password: '$argon2id$v=19$...'   # the whole Digest line, inside single quotes
    groups: [admins]
```
Indent with **spaces only**: 2 before the username, 4 before its fields.

## 3.2 Start it
```sh
docker compose up -d
docker compose logs --tail 5     # ✅ "Startup complete", with no "fatal"
```
Authelia only reads `users.yml` at startup. After editing it, run `docker compose restart`.

## 3.3 First login and 2FA
1. Open `https://auth.example.com` and log in. Usernames are case-insensitive, and
   your email works too.
2. **Register device → one-time password.** The verification code Authelia "emails"
   is written to a file until you set up SMTP:
   ```sh
   cat /srv/state/authelia/data/notification.txt
   ```
3. Scan the QR code with your authenticator app.

## Notes on the config
- `forward-auth` only accepts **cookie sessions**. The default also tries the
  `Authorization` header as Basic auth, which breaks apps that send their own token
  there (Beszel). The symptom is a browser "Sign in" popup.
- Secrets are injected from files (`*_FILE` env vars), never written into `configuration.yml`.

**Next:** [Uptime Kuma](04-uptime-kuma.md)
