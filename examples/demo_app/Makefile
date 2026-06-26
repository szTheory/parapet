DOCKER_COMPOSE := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi)
AUTO_ENV := .docker/auto.env
AUTO_COMPOSE := $(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.auto-port.yml
AUTO_ENV_SHELL := set -a; [ ! -f .env ] || . ./.env; . ./$(AUTO_ENV); set +a;

.PHONY: up up-auto up-db-port up-response up-recovery up-escalation up-history urls down reset rebuild scenario gallery gallery-shot

# Zero-infra component gallery preview — no Docker, no Postgres, free loopback port.
gallery:
	@scripts/gallery_preview.sh

gallery-shot:
	@scripts/gallery_preview.sh --shot

up:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example. Edit COMPOSE_PROJECT_NAME or WEB_PORT if you run multiple demo stacks."; fi
	@rm -f "$(AUTO_ENV)"
	$(DOCKER_COMPOSE) up -d --build
	@DOCKER_COMPOSE="$(DOCKER_COMPOSE)" scripts/print_docker_urls.sh

up-auto:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example. Edit COMPOSE_PROJECT_NAME if you run multiple demo stacks."; fi
	@scripts/prepare_auto_env.sh
	@$(AUTO_ENV_SHELL) $(AUTO_COMPOSE) up -d --build
	@$(AUTO_ENV_SHELL) DOCKER_COMPOSE="$(AUTO_COMPOSE)" scripts/print_docker_urls.sh

up-db-port:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example. Edit DB_PORT if 5432 is already in use."; fi
	@rm -f "$(AUTO_ENV)"
	$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.db-port.yml up -d --build
	@DOCKER_COMPOSE="$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.db-port.yml" scripts/print_docker_urls.sh

scenario:
	@if [ -z "$(SCENARIO)" ]; then echo "Usage: make scenario SCENARIO=response|recovery|escalation|history|all"; exit 1; fi
	$(MAKE) reset
	PARAPET_DEMO_SCENARIO="$(SCENARIO)" $(MAKE) up-auto

up-response:
	$(MAKE) scenario SCENARIO=response

up-recovery:
	$(MAKE) scenario SCENARIO=recovery

up-escalation:
	$(MAKE) scenario SCENARIO=escalation

up-history:
	$(MAKE) scenario SCENARIO=history

urls:
	@if [ -f "$(AUTO_ENV)" ]; then \
		$(AUTO_ENV_SHELL) DOCKER_COMPOSE="$(AUTO_COMPOSE)" scripts/print_docker_urls.sh; \
	else \
		DOCKER_COMPOSE="$(DOCKER_COMPOSE)" scripts/print_docker_urls.sh; \
	fi

down:
	@if [ -f "$(AUTO_ENV)" ]; then \
		$(AUTO_ENV_SHELL) $(AUTO_COMPOSE) down; \
	else \
		$(DOCKER_COMPOSE) down; \
	fi

reset:
	@if [ -f "$(AUTO_ENV)" ]; then \
		$(AUTO_ENV_SHELL) $(AUTO_COMPOSE) down -v; \
		rm -f "$(AUTO_ENV)"; \
	else \
		$(DOCKER_COMPOSE) down -v; \
	fi

rebuild:
	$(DOCKER_COMPOSE) build --no-cache
