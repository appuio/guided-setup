# Set Shell to bash, otherwise some targets fail with dash/zsh etc.
SHELL := /bin/bash

# Disable built-in rules
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
.SUFFIXES:
.SECONDARY:
.DEFAULT_GOAL := help

# General variables
include Makefile.vars.mk

.PHONY: help
help: ## Show this help
	@grep -E -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: build 
build: docker ## All-in-one build

.PHONY: docker
docker: ## Build docker image
	$(DOCKER_CMD) build -t $(CONTAINER_IMG) .

.PHONY: check
check: ## Run shellcheck on workflow scripts
	./shellcheck.sh -y -q ./workflows/*/*.yml
