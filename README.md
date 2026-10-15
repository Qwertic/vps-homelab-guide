# VPS homelab guide

A complete self-hosted lab on **one rented server**, reachable **only from your own
devices** through Tailscale. No home hardware and no open ports, and it moves with you
when you move house.

It's written as a step-by-step guide you can follow from zero. Every step says which
machine to run it on and what you should see. Every problem we hit while building it
is in [Troubleshooting](docs/troubleshooting.md).

## What you get
| | Service | What for |
|---|---|---|
| 🔐 | **Authelia** | One login with 2FA in front of every admin page |
| 🔑 | **Vaultwarden** | Password manager (works with the official Bitwarden apps) |
| 📸 | **Immich** | Photo backup from your phone, Google Photos-style |
| 🚫 | **Pi-hole + Unbound** | Ad and tracker blocking on all your devices, with your own DNS resolver |
| 🌍 | **Exit node** *(optional)* | Your own VPN for public Wi-Fi |
| 🌱 | **Forgejo** | Your own git server (this repo can live there) |
| 📈 | **Uptime Kuma + Beszel** | Uptime and resource monitoring, alerts to your phone |
| 🎬 | **Jellyfin** *(optional)* | Media server for movies, shows, music |
| 💾 | **restic → Backblaze B2** | Nightly encrypted off-site backups, with a tested restore |

## How it fits together
```
 your phone / laptop / TV
        │  Tailscale (WireGuard)    the only way in; nothing is publicly exposed
        ▼
 ┌──────────────── Hetzner VPS (Debian, Docker) ────────────────┐
 │  Caddy :443 on the Tailscale IP, real HTTPS via DNS-01       │
 │   ├─ auth.   → Authelia            ├─ photos. → Immich       │
 │   ├─ status. → Uptime Kuma  ┐      ├─ vault.  → Vaultwarden  │
 │   ├─ stats.  → Beszel       ├ SSO  ├─ git.    → Forgejo      │
 │   └─ dns.    → Pi-hole UI   ┘      └─ media.  → Jellyfin     │
 │  Pi-hole :53 → Unbound: DNS for all your tailnet devices     │
 │  /srv/state  app data + databases, on the local SSD          │
 │  /srv/data   photos + media, on a 1 TB Storage Box (SMB)     │
 └────────────────────────────┬─────────────────────────────────┘
                              │ nightly restic (encrypted)
                              ▼
                       Backblaze B2, at a different company
```

## Cost (October 2026, incl. VAT, rough)
| | | €/month |
|---|---|---|
| Server | Hetzner **CAX21** (4 ARM vCPU, 8 GB RAM, 80 GB SSD) | ~12.80 |
| Storage | Hetzner **Storage Box BX11** (1 TB) | ~3.90 |
| Backups | Backblaze B2 (~500 GB) | ~3 |
| Domain | any cheap domain on Cloudflare | ~1 |
| **Total** | | **~€20** |

Prices change; Hetzner raised cloud prices in 2026. Every image in this repo has an
ARM64 build, so the cheaper ARM servers (CAX) work. x86 (CX33) works too.

## The guide
Follow the steps in order. Each one ends in a check, so you know it worked before
moving on.

1. [Create the server and lock it down](docs/01-server.md)
2. [Domain and HTTPS](docs/02-domain-https.md)
3. [One login: Authelia](docs/03-authelia.md)
4. [Monitoring and phone alerts: Uptime Kuma](docs/04-uptime-kuma.md)
5. [Backups: restic to B2](docs/05-backups.md)
6. [Restore drill: prove the backups work](docs/06-restore-drill.md)
7. [Password manager: Vaultwarden](docs/07-vaultwarden.md)
8. [Ad blocking for all devices: Pi-hole](docs/08-pihole.md)
9. [Git server: Forgejo](docs/09-forgejo.md)
10. [Photo storage: Storage Box](docs/10-storage-box.md)
11. [Photos: Immich](docs/11-immich.md)
12. [Server dashboard: Beszel](docs/12-beszel.md)
13. [Optional: Jellyfin](docs/13-jellyfin.md)
14. [Optional: private VPN for public Wi-Fi (exit node)](docs/14-exit-node.md)

Then: [monthly updates](UPDATING.md) · [troubleshooting](docs/troubleshooting.md) ·
[restore runbook](backup/RESTORE.md)

**Before you start, you need:** a Mac or Linux machine with a terminal, an SSH key
(`ssh-keygen -t ed25519`), and accounts at Hetzner, Cloudflare, Tailscale and Backblaze.
All have free tiers except Hetzner. Plan for an evening for steps 1–6 and another for the rest.

## Repo layout
```
hosts/vps/bootstrap.sh          one-time server setup: user, SSH, Docker, Tailscale, firewall
hosts/vps/mount-storagebox.sh   mounts the Storage Box at /srv/data
hosts/vps/exit-node.sh          optional: make the server a Tailscale exit node
stacks/<service>/               one docker compose project per service, with .env.example
backup/                         restic job, database dump hooks, systemd timer, restore runbook
bin/check-updates               (your computer) pinned versions vs latest releases
bin/update-stacks               (server) backup, pull, restart
docs/                           the guide
```

## Rules this setup follows
- **Nothing listens on the public internet.** Ports bind to the server's Tailscale IP
  only. Docker bypasses the ufw firewall, so binding to `0.0.0.0` would quietly expose things.
- **Secrets never go in git.** Each stack has a `.env.example`; the real `.env` stays on the server.
- **Backups leave the provider** and are only trusted after a restore drill.
- **Versions are pinned.** Nothing changes until you update deliberately ([UPDATING.md](UPDATING.md)).

## License
MIT. Use it, fork it, adapt it. Issues and improvements are welcome.
