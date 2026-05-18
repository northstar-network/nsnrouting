# nsningress

Traefik ingress for `*.easydeploy.tech` with a Let's Encrypt wildcard certificate via DNS-01 Cloudflare challenge.

## Requirements

- Docker + Docker Compose v2
- A Cloudflare API token with the following permissions:
  - `Zone > DNS > Edit` on the `easydeploy.tech` zone
  - `Zone > Zone > Read` on the `easydeploy.tech` zone

## Quick start

```bash
# 1. Initialize (creates .env and certs/acme.json with correct permissions)
make setup

# 2. Fill in the variables in .env
#    - CF_DNS_API_TOKEN
#    - TRAEFIK_DASHBOARD_USERS (see below)

# 3. Update the ACME email in traefik/traefik.yml if needed

# 4. Start
make start
```

## Generate the dashboard password hash

```bash
docker run --rm httpd:alpine htpasswd -n admin
```

Copy the output into `.env`, replacing each `$` with `$$`.

## Shared Docker network

Traefik creates the `proxy` Docker network. To expose a service through Traefik from another compose project:

```yaml
services:
  myservice:
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.easydeploy.tech`)"
      - "traefik.http.routers.myservice.entrypoints=websecure"
      - "traefik.http.routers.myservice.tls=true"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"

networks:
  proxy:
    external: true
```

## Structure

```
nsningress/
├── docker-compose.yml
├── .env                    # secrets (gitignored)
├── .env.example
├── Makefile
├── traefik/
│   ├── traefik.yml         # Traefik static config
│   └── dynamic/
│       └── tls.yml         # TLS options (TLS 1.2 min, cipher suites)
└── certs/
    └── acme.json           # Let's Encrypt ACME storage (gitignored)
```

## Dashboard

Available at `https://traefik.easydeploy.tech` (protected by basic auth).
