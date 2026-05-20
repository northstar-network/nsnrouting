# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo does

Traefik v3 ingress controller for `*.easydeploy.tech`, with wildcard Let's Encrypt via Cloudflare DNS-01 challenge. It creates the shared `proxy` Docker network that all other compose projects on the host attach to.

## Commands

```bash
# Production (HTTPS, Cloudflare, requires .env)
make start        # setup + docker compose up -d (prod)
make stop         # docker compose down (prod)

# Local (HTTP only, no config needed)
make start-local            # docker compose up -d (local, dashboard off)
make start-local-dashboard  # idem + dashboard sur http://localhost:8080
make stop-local             # docker compose down (local)

# Common
make restart      # docker restart traefik
make logs         # docker logs -f traefik
make ps           # docker compose ps
```

## Architecture

Three-file Compose split:

| File | Role |
|---|---|
| `docker-compose.yml` | Base — image, Docker socket mount, `proxy` network |
| `docker-compose.prod.yml` | Prod additions — ports 80/443, `CF_DNS_API_TOKEN`, `acme.json`, dashboard labels |
| `docker-compose.local.yml` | Local additions — ports 80/8080, no env vars, no cert storage |

Two Traefik static configs:

| File | Role |
|---|---|
| `traefik/traefik.yml` | Prod — HTTPS entrypoint, Cloudflare certResolver, HTTP→HTTPS redirect |
| `traefik/traefik.local.yml` | Local — HTTP only, dashboard désactivé par défaut |

Le dashboard local est toggleable via `TRAEFIK_API_DASHBOARD` / `TRAEFIK_API_INSECURE` (variables nativement lues par Traefik), injectées par `docker-compose.local.yml` depuis `TRAEFIK_DASHBOARD=true`.

`traefik/dynamic/tls.yml` sets TLS 1.2 minimum and cipher suites (prod only, ignored in local).

## Exposing a service through Traefik (prod)

In any other compose project on the same host:

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

For local, use `entrypoints=web` and omit the `tls` labels.

## First-time prod setup

1. `make setup` — creates `.env` from `.env.example` and `certs/acme.json` with `chmod 600`
2. Fill `.env`: `CF_DNS_API_TOKEN` and `TRAEFIK_DASHBOARD_USERS`
   - Generate password hash: `docker run --rm httpd:alpine htpasswd -n admin` (replace each `$` with `$$` in `.env`)
3. `make start`

`.env` and `certs/acme.json` are gitignored.
