.PHONY: setup start stop restart logs ps

setup:
	@test -f .env || (cp .env.example .env && echo ">> .env created from .env.example — fill in the values before starting")
	@mkdir -p certs
	@touch certs/acme.json
	@chmod 600 certs/acme.json
	@echo ">> Setup done"

start: setup
	docker compose up -d

stop:
	docker compose down

restart:
	docker compose restart traefik

logs:
	docker compose logs -f traefik

ps:
	docker compose ps
