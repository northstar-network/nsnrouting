# nsningress

Traefik ingress for `*.easydeploy.tech` with a Let's Encrypt wildcard certificate via DNS-01 Cloudflare challenge. Supports both production (HTTPS) and local (HTTP) deployments.

## Requirements

- Docker + Docker Compose v2

Production only:
- A Cloudflare API token with the following permissions:
  - `Zone > DNS > Edit` on the `easydeploy.tech` zone
  - `Zone > Zone > Read` on the `easydeploy.tech` zone

## Local (no config needed)

```bash
make start-local              # HTTP only
make start-local-dashboard    # HTTP + dashboard at http://localhost:8080
make stop-local
```

## Production (HTTPS)

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

### Generate the dashboard password hash

```bash
docker run --rm httpd:alpine htpasswd -n admin
```

Copy the output into `.env`, replacing each `$` with `$$`.

## Shared Docker network

Traefik creates the `proxy` Docker network. To expose a service through Traefik from another compose project:

**Production:**
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

**Local:**
```yaml
services:
  myservice:
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.localhost`)"
      - "traefik.http.routers.myservice.entrypoints=web"
      - "traefik.http.services.myservice.loadbalancer.server.port=8080"

networks:
  proxy:
    external: true
```

## Structure

```
nsningress/
├── docker-compose.yml            # base commune
├── docker-compose.prod.yml       # production (HTTPS, Cloudflare, labels dashboard)
├── docker-compose.local.yml      # local (HTTP, port 8080 dashboard)
├── .env                          # secrets (gitignored)
├── .env.example
├── Makefile
├── traefik/
│   ├── traefik.yml               # config prod (HTTPS, certResolver, redirect)
│   ├── traefik.local.yml         # config locale (HTTP seul, dashboard off par défaut)
│   └── dynamic/
│       └── tls.yml               # TLS options (TLS 1.2 min, cipher suites)
└── certs/
    └── acme.json                 # Let's Encrypt ACME storage (gitignored)
```

## Dashboard

| Mode | URL | Auth |
|---|---|---|
| Production | `https://traefik.easydeploy.tech` | Basic auth (`TRAEFIK_DASHBOARD_USERS`) |
| Local | `http://localhost:8080` | Aucune |

Le dashboard local est désactivé par défaut, utilisez `make start-local-dashboard` pour l'activer.
