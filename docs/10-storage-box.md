# 10. Photo storage: Storage Box

**Goal:** 1 TB at `/srv/data` for about €4 a month. A cloud volume of the same size
would cost more than the server.

## 10.1 Hetzner: create it
**Storage Boxes → Create → BX11** in the **same location** as the server. Set a
password (save it in Vaultwarden), then in the box's settings:
- turn **SMB/Samba support: on**
- leave **External reachability: off**. The server reaches the box over Hetzner's network.

Note the username (`u123456`).

## 10.2 Server: mount it
```sh
cd ~/home-lab && git pull
read -rsp 'Storage Box password: ' SB_PASS; echo
sudo SB_USER=u123456 SB_PASS="$SB_PASS" bash hosts/vps/mount-storagebox.sh
```
`read -rsp` keeps the password off the screen and out of your shell history. The
mount is encrypted (`seal`), and it waits for the network at boot (`_netdev`, automount).

✅ It prints `//u123456.your-storagebox.de/backup  1.0T … /srv/data`. Then:
```sh
touch /srv/data/test && ls /srv/data && rm /srv/data/test   # ✅ immich/ media/ test
```

## 10.3 Reboot test
Now is a good time to prove everything comes back on its own:
```sh
sudo reboot
# about 1 min later, ssh back in:
df -h /srv/data && docker ps --format '{{.Names}}: {{.Status}}'
```
✅ The box is mounted and every container is `Up`. Kuma probably sent you a short
down → up alert, which proves your alerts work.

The Storage Box is at Hetzner, the same company as your server, so it is **not** your
off-site copy. B2 is.

**Next:** [Immich](11-immich.md)
