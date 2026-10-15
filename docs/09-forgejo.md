# 9. Git server: Forgejo

**Goal:** your own git server, which can also hold your copy of this repo.

## 9.1 Server
```sh
cd ~/home-lab/stacks/forgejo
printf 'TS_IP=<server-ts-ip>\nDOMAIN=example.com\n' > .env
docker compose up -d
```
Open `https://git.example.com`. On the install page, leave the database (SQLite) and
server settings as they are. Under **Administrator account settings**, create your
admin, then click **Install**.

## 9.2 Your computer: SSH for git (port 2222)
```
# ~/.ssh/config
Host git.example.com
  Port 2222
  User git
```
Add your public key under Forgejo → Settings → **SSH / GPG Keys**, then test:
```sh
ssh -T git.example.com
```
✅ It replies "Hi there, …! You've successfully authenticated… but Forgejo does not
provide shell access". That message is the success: Forgejo only accepts git over SSH.

## 9.3 Optional: host your lab repo here
1. In Forgejo, create a **private** repo. Leave "Initialize repository" **unticked**,
   or the first push is rejected.
2. Your computer:
   ```sh
   git remote add forgejo ssh://git@git.example.com:2222/<you>/home-lab.git && git push forgejo main
   ```
3. Keep an **off-site copy** too: Forgejo → repo Settings → **Mirror settings → Push
   mirror** to a private GitHub or Codeberg repo, using a token with write access to
   that repo only. Then your rebuild instructions survive even if the lab is gone.

To make the server pull from Forgejo, create a read-only token under Forgejo →
Settings → Applications, then:
```sh
cd ~/home-lab && git remote set-url origin https://git.example.com/<you>/home-lab.git
git config --global credential.helper store   # stores the token in ~/.git-credentials (backed up, encrypted)
git pull                                      # username + token as the password, asked once
```

**Next:** [Storage Box](10-storage-box.md)
