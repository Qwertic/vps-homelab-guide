# Caddy with the Cloudflare DNS plugin, for DNS-01 certificates on Tailscale-only hostnames.
# Using a different DNS provider? Swap the module: https://github.com/caddy-dns
FROM caddy:2-builder AS builder
RUN xcaddy build --with github.com/caddy-dns/cloudflare

FROM caddy:2
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
