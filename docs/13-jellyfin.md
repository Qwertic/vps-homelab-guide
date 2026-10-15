# 13. Optional: Jellyfin

Only worth it once you have movies, shows or music. You can add it at any time.

## 13.1 Server
Jellyfin runs as uid 1000. Create its folders first; if Docker created them, they'd be
owned by root and Jellyfin couldn't write to them.
```sh
id -u    # ✅ 1000
install -d /srv/state/jellyfin/config /srv/state/jellyfin/cache
mkdir -p /srv/data/media/movies /srv/data/media/shows /srv/data/media/music
cd ~/home-lab/stacks/jellyfin && echo "DOMAIN=example.com" > .env && docker compose up -d
```

## 13.2 Browser
Open `https://media.example.com`, create the admin user, and add the libraries
`/media/movies`, `/media/shows` and `/media/music`. Turn **Allow remote connections**
on: Tailscale clients count as "remote".

## 13.3 Things to know
- **Adding media:**
  ```sh
  rsync -av --progress ~/Movies/ <server-ts-ip>:/srv/data/media/movies/
  ```
  Use one folder per title: `Movie Name (2010)/Movie Name (2010).mkv`.
- **No video hardware:** converting video on the fly is slow on this server. Set
  the apps to **Maximum / Original** quality, so files play as they are.
- **Backup cost:** if your media can be downloaded again, add `/srv/data/media` to
  `backup/excludes` to save B2 storage. Never exclude photos.
