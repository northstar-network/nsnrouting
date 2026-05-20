.PHONY: setup setup-local start start-local start-local-dashboard stop stop-local restart logs ps

COMPOSE_PROD  = docker compose -f docker-compose.yml -f docker-compose.prod.yml
COMPOSE_LOCAL = docker compose -f docker-compose.yml -f docker-compose.local.yml

setup:
	@test -f .env || (cp .env.example .env && echo ">> .env created from .env.example — fill in the values before starting")
	@mkdir -p certs
	@touch certs/acme.json
	@chmod 600 certs/acme.json
	@echo ">> Setup done"

setup-local:
	@echo ">> Local setup done (no certs needed)"

start: setup
	$(COMPOSE_PROD) up -d

start-local: setup-local
	$(COMPOSE_LOCAL) up -d

start-local-dashboard: setup-local
	TRAEFIK_DASHBOARD=true $(COMPOSE_LOCAL) up -d

stop:
	$(COMPOSE_PROD) down

stop-local:
	$(COMPOSE_LOCAL) down

restart:
	docker restart traefik

logs:
	docker logs -f traefik

ps:
	docker compose ps
