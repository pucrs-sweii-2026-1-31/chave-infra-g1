.PHONY: setup up down logs reset provision tf-init tf-plan tf-apply config ps verify verify-topology check-repos

COMPOSE = docker compose

-include .env

SHELL_PORT ?= 3000
MS_AUTH_PORT ?= 3001
MFE_AUTH_PORT ?= 4001
MINISTACK_PORT ?= 4566

SHELL_URL ?= http://localhost:$(SHELL_PORT)
AUTH_API_URL ?= http://localhost:$(MS_AUTH_PORT)
MFE_AUTH_URL ?= http://localhost:$(MFE_AUTH_PORT)
MINISTACK_URL ?= http://localhost:$(MINISTACK_PORT)

setup: .env check-repos
	$(COMPOSE) up -d --build
	@echo "[make] Stack started."
	@echo "[make] Shell:     $(SHELL_URL)"
	@echo "[make] Auth MFE:  $(MFE_AUTH_URL)"
	@echo "[make] Auth API:  $(AUTH_API_URL)"
	@echo "[make] Swagger:   $(AUTH_API_URL)/docs"
	@echo "[make] Ministack: $(MINISTACK_URL)"

up: .env check-repos
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

reset: .env check-repos
	$(COMPOSE) down -v --remove-orphans
	$(COMPOSE) up -d --build

provision: .env
	$(COMPOSE) up -d ministack
	$(COMPOSE) --profile provision run --rm infra-provisioner

tf-init: .env
	$(COMPOSE) up -d ministack
	$(COMPOSE) --profile provision run --rm --entrypoint terraform infra-provisioner init

tf-plan: .env
	$(COMPOSE) up -d ministack
	$(COMPOSE) --profile provision run --rm --entrypoint terraform infra-provisioner plan

tf-apply: provision

config: .env
	$(COMPOSE) config

ps:
	$(COMPOSE) ps

verify: .env
	@./scripts/verify-stack.sh endpoints

verify-topology:
	@./scripts/verify-stack.sh topology

check-repos:
	@missing=0; \
	for dockerfile in ../chave-ms-auth/Dockerfile ../chave-mfe-auth/Dockerfile ../chave-shell/Dockerfile; do \
		if [ ! -f "$$dockerfile" ]; then \
			echo "[make] Missing required sibling Dockerfile: $$dockerfile"; \
			missing=1; \
		elif grep -q "npm ci" "$$dockerfile"; then \
			lockfile="$$(dirname "$$dockerfile")/package-lock.json"; \
			if [ ! -f "$$lockfile" ]; then \
				echo "[make] Missing npm lockfile required by '$$dockerfile': $$lockfile"; \
				missing=1; \
			fi; \
		fi; \
	done; \
	if [ "$$missing" = "1" ]; then \
		echo "[make] Clone, restore, or regenerate the sibling application repositories next to chave-infra."; \
		exit 1; \
	fi

.env:
	@if [ ! -f .env ]; then \
		echo "[make] .env not found; copying .env.example."; \
		cp .env.example .env; \
	fi
