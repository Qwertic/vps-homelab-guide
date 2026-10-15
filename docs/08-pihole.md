# 8. Ad blocking for all devices: Pi-hole

**Goal:** every device on your tailnet uses Pi-hole for DNS, so ads and trackers are
blocked everywhere, including your phone on mobile data.

The stack runs two containers:
- **Pi-hole** blocks, and answers your lab names (`*.example.com` → the server's Tailscale
  IP) itself, so the lab keeps working even if Cloudflare's DNS is down.
- **Unbound** is Pi-hole's only upstream. It resolves names from the root servers
  itself, so no single company (Google, Cloudflare, Quad9) sees every lookup, and it
  validates DNSSEC.

## 8.1 Server
```sh
cd ~/home-lab/stacks/pihole
cp .env.example .env && nano .env     # TS_IP, DOMAIN, TZ, PIHOLE_PASSWORD (save it in Vaultwarden)
docker compose up -d
```
Port 53 is published on the **Tailscale IP only**. A public DNS port turns into an
open resolver that gets abused for attacks.

## 8.2 Your computer: test before switching over
```sh
dig @<server-ts-ip> example.org +short                            # ✅ a real IP (resolved by Unbound)
dig @<server-ts-ip> photos.example.com +short                     # ✅ the server's Tailscale IP, answered locally
dig @<server-ts-ip> doubleclick.net +short                        # ✅ 0.0.0.0, which means blocked
dig @<server-ts-ip> dnssec-failed.org | grep -o 'status: [A-Z]*'  # ✅ SERVFAIL: bad DNSSEC signatures are rejected
```

## 8.3 Tailscale admin → DNS
- **Nameservers → Add nameserver → Custom** → `<server-ts-ip>`
- Turn on **Override DNS servers**
- Leave **MagicDNS** on

The server itself runs Tailscale with `--accept-dns=false` (set in `bootstrap.sh`), so
its own DNS never depends on the Pi-hole it hosts.

✅ The ads are gone on your phone, and `https://dns.example.com` (Authelia, then
Pi-hole's own password) shows queries coming in.

If normal names return `SERVFAIL`, Unbound can't reach the root servers (some networks
block outgoing DNS). Add a fallback upstream and check `docker compose logs unbound`:
```sh
sed -i 's/#53"$/#53;9.9.9.9"/' compose.yml && docker compose up -d
```

## Things to know
- While Tailscale is on, **all** your devices depend on this server for DNS. If it goes
  down, sites stop loading. Kuma alerts you, and turning off **Override DNS servers**
  restores normal DNS instantly.
- **Changing the password:** edit `PIHOLE_PASSWORD` in `.env`, then `docker compose up -d`.
  Pi-hole re-reads it at every start, so `pihole setpassword` would be overwritten. Avoid `$`
  in the value, because Compose treats it as a variable.
- **Better blocklists:** Lists → Address →
  `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt`
  ([HaGeZi Multi PRO](https://github.com/hagezi/dns-blocklists)) → **Add blocklist** →
  Tools → **Update Gravity**. Use the list file's address, not the project page: the page
  "loads" ~2,000 junk entries instead of ~200,000 domains. Check with:
  ```sh
  docker compose exec pihole pihole-FTL sqlite3 /etc/pihole/gravity.db "select enabled, number, address from adlist"
  ```
- **YouTube ads can't be blocked by DNS:** they come from the same servers as the videos.
  Use an ad blocker in the browser or app on each device instead.

**Optional:** [use the server as a VPN on public Wi-Fi](14-exit-node.md)

**Next:** [Forgejo](09-forgejo.md)
