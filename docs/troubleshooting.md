# Troubleshooting

Every problem below actually happened while building this lab. Search this page for
your error message.

## Server and SSH
| Symptom | Cause | Fix |
|---|---|---|
| Server type "unavailable" | sold out in that location, or a non-EU location | try another EU location, or CAX ↔ CX |
| `Enter passphrase for key` | your SSH key has a passphrase (from `ssh-keygen`) | type it once and store it in the keychain: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` |
| `bash: bootstrap.sh: No such file or directory` | `scp` never ran, or ran on the server | run `scp ... root@<ip>:` **on your computer**, with the trailing colon |
| A file named `root@1.2.3.4` appears locally | `scp` was missing the `:` | delete it, and add the colon |
| `whoami` prints your user, not root | expected | the check is `sudo whoami` |
| `git: command not found` on the server | old bootstrap | `sudo apt-get install -y git` (current `bootstrap.sh` installs it) |
| Locked out after ~6 months | Tailscale key expiry | disable key expiry for the server; to recover, use Hetzner's web console |

## Authelia
| Symptom | Cause | Fix |
|---|---|---|
| `Users.<name>...: non zero value required` | a misspelled field, typically `displayName` | the field is `displayname`, all lowercase |
| `user not found` with `user ''` | Authelia had crashed at startup, or the browser autofilled an empty username | fix `users.yml`, restart, type the username yourself |
| `user not found` for `Name` | usernames were case-sensitive | this repo enables case-insensitive and email login |
| Browser "Sign in" popup on an app behind Authelia (Beszel) | the default forward-auth tried the app's `Authorization` header as Basic auth | this repo restricts forward-auth to `CookieSession` |
| `chown: /config/configuration.yml: Read-only file system` | the config is mounted read-only on purpose | harmless |

## Uptime Kuma
| Symptom | Cause | Fix |
|---|---|---|
| Monitors time out (`timeout of 48000ms exceeded`) | ufw drops traffic from Docker networks to the Tailscale IP | `sudo ufw allow from 172.16.0.0/12 to any port 443 proto tcp` |
| ntfy `topic invalid` | URL or invalid characters in the Topic field | Server URL `https://ntfy.sh`, Topic = just the name |

## restic / B2
| Symptom | Cause | Fix |
|---|---|---|
| `dial tcp ...:80: i/o timeout` | `s3:http://` | use `s3:https://` |
| `stat s3.eu-central-...: no such file or directory` | missing `s3:` prefix, so restic used a local folder | set `RESTIC_REPOSITORY=s3:https://...`, delete the stray local folder, run `restic init` again |
| `Malformed Access Key Id` | keys swapped, quotes or spaces, or the B2 master key | an application key for the bucket; values without quotes. Check lengths: keyID 25 characters, key 31 |
| The `restic-backup` job failed | anything above | `sudo journalctl -u restic-backup -n 40 --no-pager` |

## Pi-hole
| Symptom | Cause | Fix |
|---|---|---|
| `CAP_SYS_TIME is not available` warning | Pi-hole's NTP client | harmless; this repo disables it |
| New password not accepted | password comes from `.env` and is reset at every start | change `PIHOLE_PASSWORD` in `.env`, then `docker compose up -d` |
| All sites stop loading | the server is down and every device uses Pi-hole | turn off **Override DNS servers** in Tailscale until it's back |
| No DNS after a server reboot; Unbound `exited`, `Address already in use` | at boot Docker starts containers in parallel and ignores `depends_on`; Pi-hole grabbed Unbound's fixed IP and then forwarded every query to itself | fixed in this repo: both containers have fixed IPs and dynamic ones come from `.4–.7`. Apply with `docker compose down && docker compose up -d`. The boot check (`bin/boot-check`) alerts you if this ever happens again |
| Monthly maintenance ran, but no ntfy notification arrived | wrong topic in `/etc/homelab/maintenance.env` | check it matches your app, test with `bin/notify test default tada hello`; errors go to `journalctl -u homelab-maintenance` |
| "Back after reboot" notification doesn't arrive right away | the boot check waits 4 minutes after boot | wait; `systemctl list-timers 'homelab-*'` |

## Beszel
| Symptom | Cause | Fix |
|---|---|---|
| System stays red; agent says `no key provided` | `BESZEL_KEY` missing or misnamed in `.env`, or the agent wasn't recreated | fix `.env`, `docker compose up -d`, check logs with `--since 1m` |

## Forgejo
| Symptom | Cause | Fix |
|---|---|---|
| "Forgejo does not provide shell access" | expected | that message means your SSH key works |
| First push rejected | the repo was initialised with a README | create it empty |
