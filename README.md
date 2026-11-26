# tumble-edge

Shared Caddy edge for websages apps on Fly.io. It holds every public
hostname and certificate, filters abusive and AI-crawler traffic, and
reverse-proxies to private backend apps over Flycast.

```
client --TLS--> Fly proxy --> edge (Caddy :8080, iad + sjc)
                                 | filter, then reverse_proxy
                                 v
                      <backend>.flycast (no public IPs)
```

## Layout

| Path | Purpose |
|------|---------|
| `Caddyfile` | Global options, health check, catch-all 404 |
| `snippets/` | Reusable blocks (`common`, `blockAiBots`) |
| `sites/` | One file per site |
| `fly.toml` | Fly app `websages-edge` |

## Adding a site

1. The backend app has **only** a private Flycast address
   (`fly ips allocate-v6 --private -a <app>`, no public IPs) and
   `force_https = false` in its `[http_service]`.
2. Add `sites/<name>.caddy`:
   ```
   http://host.example.com {
       import common
       reverse_proxy http://<app>.flycast
   }
   ```
3. `fly certs add host.example.com -a websages-edge` and create the DNS records
   it prints. For a host that's still live elsewhere, create only the
   `_acme-challenge` CNAME first.
4. Point A/AAAA at the edge IPs (`fly ips list -a websages-edge`).

## Notes

- TLS is terminated by Fly's proxy; Caddy runs with `auto_https off`.
- Caddy trusts Fly's proxy (`trusted_proxies private_ranges`) and reads
  the real client from `Fly-Client-IP`, then passes it on in
  `X-Forwarded-For`.
- The edge IPs are referenced in DNS for domains we don't own, so never
  release them.
- Bot list: `snippets/ai-bots.caddy`, from
  https://github.com/ai-robots-txt/ai.robots.txt. Matches get a 403.

## Deploy

Pushes to `main` validate and deploy (`FLY_API_TOKEN` repo secret, a
deploy token from `fly tokens create deploy -a websages-edge`). PRs validate only.

First-time setup:

```sh
fly apps create websages-edge --org personal
fly ips allocate-v6 -a websages-edge
fly ips allocate-v4 --shared -a websages-edge
fly deploy
fly machine clone <iad-machine-id> --region sjc -a websages-edge   # second region
```
