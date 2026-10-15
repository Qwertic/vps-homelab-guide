# 15. Tailscale access policy

**Goal:** decide exactly who can reach what. By default, every device on your tailnet
can reach every other device on every port, **including the server reaching your
laptop**. This policy changes that:

| Who | Can reach the server on |
|---|---|
| You (tailnet admin) | everything: SSH, HTTPS, DNS, git SSH |
| People you share it with (e.g. family using Immich) | HTTPS only |
| The server itself | none of your devices |

The policy lives in [`hosts/tailscale/policy.hujson`](../hosts/tailscale/policy.hujson),
so changes are reviewed like code.

## Safety net first
If you lock yourself out, Hetzner still gives you a way in: server → **Rescue → Reset
root password**, then the **>_ Console** button opens a browser terminal.

## 15.1 Apply the policy
Tailscale admin → **Access controls → JSON editor**:
1. Replace the contents with `policy.hujson`.
2. Replace `YOUR-LOGIN@example.com` with your login exactly as shown under **Users**.
   GitHub sign-ins look like `YourName@github`.
3. **Save.** The built-in tests check that you can still reach ports 22, 443, 53 and 2222.
   If a test fails, nothing is applied.

## 15.2 Tag the server
Machines → the server → **⋯ → Edit ACL tags → `tag:homelab`**. The server now belongs
to the tag rather than your user. Tagged machines also never have their key expire.

## 15.3 Check
```sh
ssh <server-ts-ip> 'echo ssh-ok'                          # ✅ ssh-ok
curl -sI https://status.example.com | head -1             # ✅ HTTP/2 302 (the redirect to Authelia)
dig @<server-ts-ip> example.org +short                    # ✅ an IP
ssh -T git.example.com 2>&1 | head -1                     # ✅ "Hi there, …"
```
Also check your phone: ads are still blocked, and the exit node still works.

If SSH fails after tagging, remove the tag; access comes back immediately.

## Sharing Immich with someone
Machines → the server → **Share** → send the invite. They join from their own Tailscale
account and get HTTPS only (`autogroup:shared`). Create an Immich account for them.
Shared albums work across accounts.
