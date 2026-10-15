# 2. Domain and HTTPS

**Goal:** `https://<service>.example.com` with real certificates, resolving to the
server's Tailscale IP, so only your devices can open it.

## Why a domain
A cheap domain (~€10/year) gives every service its own name and a valid certificate,
and Authelia's single sign-on depends on all services sharing one parent domain. The
records point at a `100.x` Tailscale address, so nobody outside your tailnet can reach
anything, even if they know the names. Tailscale's free `*.ts.net` names only give one
HTTPS name per machine, which is why this guide uses a domain.

## 2.1 Cloudflare
1. **Register a domain** (Domain Registration → Register). Cloudflare sells at cost.
2. **DNS → Records → Add record:** type **A**, name **`*`**, IPv4 **`<server-ts-ip>`**,
   proxy status **DNS only (grey cloud)**. Cloudflare's proxy can't reach a 100.x address.
3. **My Profile → API Tokens → Create Token →** template **"Edit zone DNS"**, zone =
   your domain only. Save the token in a password manager; Cloudflare shows it once.
   Caddy uses it to prove domain ownership (the DNS-01 challenge), so no port 80 needs to be open.

## 2.2 Server: start Caddy
```sh
cd ~/home-lab/stacks/caddy
cp .env.example .env && chmod 600 .env && nano .env
```
```
TS_IP=<server-ts-ip>
DOMAIN=example.com
ACME_EMAIL=you@example.com
CLOUDFLARE_API_TOKEN=<token>
```
```sh
docker compose up -d --build      # the first build takes a few minutes (it adds the Cloudflare plugin)
docker compose logs -f            # wait for "certificate obtained successfully", then Ctrl-C
```

## 2.3 Check (your computer)
```sh
curl -I https://status.example.com
```
✅ **`HTTP/2 502` means success at this stage:** DNS, the certificate and Caddy all work.
The services behind it just aren't running yet.

If the name doesn't resolve, try `dig +short status.example.com @1.1.1.1`. Some routers
drop DNS answers that point to private IPs.

**Next:** [Authelia](03-authelia.md)
