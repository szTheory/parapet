DOCKER_COMPOSE := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; else echo "docker-compose"; fi)

.PHONY: up down rebuild

up:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example. Please review ports to avoid conflicts."; fi
	$(DOCKER_COMPOSE) up

down:
	$(DOCKER_COMPOSE) down

rebuild:
	$(DOCKER_COMPOSE) build --no-cache
