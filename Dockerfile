FROM caddy:2.11.4-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY snippets /etc/caddy/snippets
COPY sites /etc/caddy/sites

# Fail the build on a bad config rather than at boot.
RUN caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
