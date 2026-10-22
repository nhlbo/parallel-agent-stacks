-include .env
export

# Folder name = Compose project name = Tailscale hostname = remote folder.
PROJECT    := $(notdir $(CURDIR))
DEVBOX     ?= devbox
REMOTE_DIR := ~/code/$(PROJECT)

.DEFAULT_GOAL := help
.PHONY: help runAll down logs psql url sync syncStatus syncStop remoteUp remoteDown remoteLogs

help: ## List commands
	@grep -E '^[a-zA-Z]+:.*## ' Makefile | awk -F':.*## ' '{printf "  make %-11s %s\n", $$1, $$2}'

runAll: ## Start the whole stack for this folder/worktree
	docker compose up -d --build
	@$(MAKE) --no-print-directory url

down: ## Stop the stack
	docker compose down

logs: ## Follow logs (make logs s=app)
	docker compose logs -f $(s)

psql: ## Open psql in this stack's database
	docker compose exec db sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

url: ## Where this stack is reachable on the tailnet
	@echo "http://$(PROJECT):8000   (MagicDNS)"
	@echo "https://$(PROJECT).<your-tailnet>.ts.net   (Tailscale Serve)"

# --- Remote devbox -----------------------------------------------------------

sync: ## Two-way sync this folder to the devbox with Mutagen
	ssh $(DEVBOX) 'mkdir -p $(REMOTE_DIR)'
	mutagen sync create --name=$(PROJECT) \
		--mode=two-way-resolved \
		--ignore-vcs \
		--ignore=__pycache__ --ignore=.venv --ignore=.claude/worktrees \
		. $(DEVBOX):$(REMOTE_DIR)
	mutagen sync flush $(PROJECT)

syncStatus: ## Show the Mutagen sync session
	mutagen sync list $(PROJECT)

syncStop: ## Stop syncing this folder
	mutagen sync terminate $(PROJECT)

remoteUp: ## Run the stack on the devbox instead of the laptop
	mutagen sync flush $(PROJECT)
	ssh $(DEVBOX) 'cd $(REMOTE_DIR) && docker compose up -d --build'
	@$(MAKE) --no-print-directory url

remoteDown: ## Stop the stack on the devbox
	ssh $(DEVBOX) 'cd $(REMOTE_DIR) && docker compose down'

remoteLogs: ## Follow devbox logs (make remoteLogs s=app)
	ssh -t $(DEVBOX) 'cd $(REMOTE_DIR) && docker compose logs -f $(s)'
