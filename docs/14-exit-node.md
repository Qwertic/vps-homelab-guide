# 14. Optional: a private VPN for public Wi-Fi (Tailscale exit node)

**Goal:** on a hotel or café network, one switch in the Tailscale app sends **all**
your traffic through the server: encrypted to the server, then out from there, with
Pi-hole blocking ads along the way. It's like a commercial VPN, but your own.

## Server
```sh
cd ~/home-lab && sudo bash hosts/vps/exit-node.sh
ping -6 -c1 google.com     # ✅ IPv6 still works after enabling forwarding
```
The script turns on IP forwarding and adds a ufw rule that allows routing from the
tailnet to the internet. ufw blocks forwarded traffic by default, which is why
enabling the exit node in Tailscale alone isn't enough. Then it advertises the
server as an exit node.

## Tailscale admin
Machines → the server → **⋯ → Edit route settings → ✅ Use as exit node**.

## Use it
In the Tailscale app: **Exit node → the server**. Then open `https://ifconfig.me`.
✅ It shows the server's public IP, not yours.

Turn it off when you don't need it: everyday browsing is faster directly. Traffic
counts toward the server's included 20 TB a month, which is plenty for this.
