DOCKER_COMPOSE := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi)
AUTO_ENV := .docker/auto.env
AUTO_COMPOSE := $(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.auto-port.yml
PROXY_COMPOSE := $(AUTO_COMPOSE) -f docker-compose.proxy.yml
AUTO_ENV_SHELL := set -a; [ ! -f .env ] || . ./.env; . ./$(AUTO_ENV); set +a;

.PHONY: up up-auto up-fixed up-monitoring up-proxy up-proxy-monitoring up-db-port up-response up-recovery up-escalation up-history urls down reset rebuild scenario gallery gallery-shot

# Zero-infra component gallery preview — no Docker, no Postgres, free loopback port.
gallery:
	@scripts/gallery_preview.sh

gallery-shot:
	@scripts/gallery_preview.sh --shot

# Default launch — conflict-free auto-port so several demo stacks (and your other
# local projects) never collide. Lean by default (web + db only); add Grafana +
# Prometheus with `make up-monitoring`. Use `make up-fixed` for classic 4000/3000/9090.
up:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example."; fi
	@scripts/prepare_auto_env.sh
	@$(AUTO_ENV_SHELL) $(AUTO_COMPOSE) up -d --build \
		|| ( echo "↻ A port was taken since allocation — reselecting free ports and retrying once…"; \
		     scripts/prepare_auto_env.sh; $(AUTO_ENV_SHELL) $(AUTO_COMPOSE) up -d --build )
	@$(AUTO_ENV_SHELL) DOCKER_COMPOSE="$(AUTO_COMPOSE)" scripts/print_docker_urls.sh

# Same as `up`, plus the Grafana + Prometheus observability stack (opt-in profile).
up-monitoring:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example."; fi
	@scripts/prepare_auto_env.sh
	@$(AUTO_ENV_SHELL) $(AUTO_COMPOSE) --profile monitoring up -d --build
	@$(AUTO_ENV_SHELL) DOCKER_COMPOSE="$(AUTO_COMPOSE) --profile monitoring" scripts/print_docker_urls.sh

# Reach the demo at http://parapet.localhost via the shared dev-proxy (no ports
# to remember). Requires the one-time proxy setup — see dev-proxy/README.md.
up-proxy:
	@docker network inspect dev-proxy-net >/dev/null 2>&1 || { \
		echo "✗ Shared proxy network 'dev-proxy-net' not found. One-time setup:"; \
		echo "    docker network create dev-proxy-net"; \
		echo "    (cd dev-proxy && docker compose up -d)"; \
		echo "  See dev-proxy/README.md."; exit 1; }
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example."; fi
	@scripts/prepare_auto_env.sh
	@$(AUTO_ENV_SHELL) $(PROXY_COMPOSE) up -d --build
	@echo ""
	@echo "Parapet demo is proxied at:"
	@echo "  Operator UI: http://parapet.localhost/parapet"
	@echo "  (host-port URLs from the auto-port mapping also still work)"

# Same as up-proxy, plus Grafana at http://grafana.parapet.localhost.
up-proxy-monitoring:
	@docker network inspect dev-proxy-net >/dev/null 2>&1 || { \
		echo "✗ Shared proxy network 'dev-proxy-net' not found. One-time setup:"; \
		echo "    docker network create dev-proxy-net"; \
		echo "    (cd dev-proxy && docker compose up -d)"; \
		echo "  See dev-proxy/README.md."; exit 1; }
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example."; fi
	@scripts/prepare_auto_env.sh
	@$(AUTO_ENV_SHELL) $(PROXY_COMPOSE) --profile monitoring up -d --build
	@echo ""
	@echo "Parapet demo is proxied at:"
	@echo "  Operator UI: http://parapet.localhost/parapet"
	@echo "  Grafana:     http://grafana.parapet.localhost"

# Back-compat alias — `up` is already auto-port.
up-auto: up

# Classic fixed-port launch (web 4000 / grafana 3000 / prometheus 9090, full stack).
# Collides if another stack already holds those ports — prefer `make up`.
up-fixed:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example. Edit COMPOSE_PROJECT_NAME or WEB_PORT if you run multiple demo stacks."; fi
	@rm -f "$(AUTO_ENV)"
	$(DOCKER_COMPOSE) --profile monitoring up -d --build
	@DOCKER_COMPOSE="$(DOCKER_COMPOSE) --profile monitoring" scripts/print_docker_urls.sh

up-db-port:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example. Edit DB_PORT if 5432 is already in use."; fi
	@rm -f "$(AUTO_ENV)"
	$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.db-port.yml up -d --build
	@DOCKER_COMPOSE="$(DOCKER_COMPOSE) -f docker-compose.yml -f docker-compose.db-port.yml" scripts/print_docker_urls.sh

scenario:
	@if [ -z "$(SCENARIO)" ]; then echo "Usage: make scenario SCENARIO=response|recovery|escalation|history|all"; exit 1; fi
	$(MAKE) reset
	PARAPET_DEMO_SCENARIO="$(SCENARIO)" $(MAKE) up-monitoring

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
