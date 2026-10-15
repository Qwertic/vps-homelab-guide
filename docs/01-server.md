# 1. Create the server and lock it down

**Goal:** a Debian server you can reach only over Tailscale, with public SSH closed.

Throughout the guide:
- **Your computer** = the Mac or Linux machine you're typing on.
- **Server** = an SSH session on the VPS (prompt `you@...`).
- Replace `<you>` with the admin username you want on the server.
  Using the same name as on your computer is convenient.

## 1.1 Your computer: Tailscale and an SSH key
- Install Tailscale (macOS: `brew install --cask tailscale` or the App Store) and sign in.
  This creates your tailnet. **Do this first:** once the server is set up, Tailscale is
  the only way in.
- You need an SSH key: `ls ~/.ssh/id_ed25519.pub`. If it's missing, run `ssh-keygen -t ed25519`
  and pick a passphrase. Store the passphrase in the macOS keychain so you aren't asked
  every time:
  ```sh
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
  ```
  ```
  # ~/.ssh/config
  Host *
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
  ```

## 1.2 Fork this repo
Fork it on GitHub (or copy it into your own git host) so you can commit your own changes.
On your computer: `git clone <your fork> ~/code/home-lab`.

## 1.3 Hetzner: create the server
**Cloud Console → your project → Add Server:**

| Setting | Choose | Why |
|---|---|---|
| Location | Falkenstein, Nuremberg or Helsinki | the cheap CX/CAX lines only exist in EU locations |
| Image | **Debian 13** | `bootstrap.sh` targets Debian; on Ubuntu the Docker repo and SSH reload steps fail |
| Type | **CAX21** (ARM, 4 vCPU / 8 GB / 80 GB), or CX33 (x86) | Immich needs the 8 GB; the 2-vCPU/4 GB/40 GB tier is too small |
| Networking | public IPv4 + IPv6 | Tailscale and image pulls need outbound internet |
| SSH keys | add `~/.ssh/id_ed25519.pub` | no root password gets emailed |
| Volumes | none | photos go on a much cheaper Storage Box (step 10) |
| Firewall | create `homelab`: inbound **UDP 41641** from anywhere, plus **TCP 22 from your IP only** for now | 41641 lets Tailscale connect directly; you'll remove 22 at the end of this step |
| Backups | optional (+20%) | one-click rollback while you're learning; restic is the real backup |
| Private network / placement groups | off | only useful with several servers |

"Limited availability" or a sold-out type is common. Try another location or the other CPU architecture.

## 1.4 Run the bootstrap
Your computer:
```sh
scp ~/code/home-lab/hosts/vps/bootstrap.sh root@<public-ip>:
ssh root@<public-ip>
```
Note the **colon** after the IP in `scp`. Without it, scp copies the file to a local file named `root@<ip>`.

Server (as root):
```sh
ADMIN_USER=<you> SSH_PUBKEY="$(cat ~/.ssh/authorized_keys)" bash bootstrap.sh
```
It installs Docker, Tailscale, ufw and git, creates your user with key-only SSH, and
disables root and password logins. When it prints a **Tailscale login link**, open it
and approve the machine. ✅ It ends with `Tailscale IP: 100.x.y.z`. Note that IP; it's
`<server-ts-ip>` from now on.

## 1.5 Tailscale admin console
- Machines → the server → **⋯ → Disable key expiry**. **Don't skip this.** Otherwise the
  server drops off your tailnet after ~180 days and you're locked out.
- Optional: **Edit machine name** → `homelab`, so `ssh homelab` works.

## 1.6 Check before closing anything
Keep the root session open. In a **new** terminal on your computer:
```sh
ssh <you>@<server-ts-ip>
sudo whoami     # ✅ root, without a password prompt
docker ps       # ✅ an empty table (if it says permission denied, log out and back in once)
```

## 1.7 Close public SSH
- Hetzner → Firewalls → `homelab` → delete the **TCP 22** rule (keep UDP 41641).
- Close the root session.
- ✅ `ssh root@<public-ip>` now hangs. `ssh <you>@<server-ts-ip>` still works.

## 1.8 Put the repo on the server
Server:
```sh
git clone <your fork's https URL> ~/home-lab
```
From now on, change things on your computer, commit, push, then run `git pull` on the server.

**Next:** [Domain and HTTPS](02-domain-https.md)
