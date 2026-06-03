.PHONY: up down rebuild

up:
	@if [ ! -f .env ]; then cp .env.example .env; echo "Created .env from .env.example. Please review ports to avoid conflicts."; fi
	docker-compose up

down:
	docker-compose down

rebuild:
	docker-compose build --no-cache
