# 8. Ad blocking for all devices: Pi-hole

**Goal:** every device on your tailnet uses Pi-hole for DNS, so ads and trackers are
blocked everywhere, including your phone on mobile data.

## 8.1 Server
```sh
cd ~/home-lab/stacks/pihole
cp .env.example .env && nano .env     # TS_IP, TZ, PIHOLE_PASSWORD (save it in Vaultwarden)
docker compose up -d
```
Port 53 is published on the **Tailscale IP only**. A public DNS port turns into an
open resolver that gets abused for attacks.

## 8.2 Your computer: test before switching over
```sh
dig @<server-ts-ip> example.org +short       # ✅ a real IP
dig @<server-ts-ip> doubleclick.net +short   # ✅ 0.0.0.0, which means blocked
```

## 8.3 Tailscale admin → DNS
- **Nameservers → Add nameserver → Custom** → `<server-ts-ip>`
- Turn on **Override DNS servers**
- Leave **MagicDNS** on

The server itself runs Tailscale with `--accept-dns=false` (set in `bootstrap.sh`), so
its own DNS never depends on the Pi-hole it hosts.

✅ The ads are gone on your phone, and `https://dns.example.com` (Authelia, then
Pi-hole's own password) shows queries coming in.

## Things to know
- While Tailscale is on, **all** your devices depend on this server for DNS. If it goes
  down, sites stop loading. Kuma alerts you, and turning off **Override DNS servers**
  restores normal DNS instantly.
- **Changing the password:** edit `PIHOLE_PASSWORD` in `.env`, then `docker compose up -d`.
  Pi-hole re-reads it at every start, so `pihole setpassword` would be overwritten. Avoid `$`
  in the value, because Compose treats it as a variable.
- **Better blocklists:** Lists → add [HaGeZi Multi PRO](https://github.com/hagezi/dns-blocklists)
  → Tools → Update Gravity.

**Next:** [Forgejo](09-forgejo.md)
