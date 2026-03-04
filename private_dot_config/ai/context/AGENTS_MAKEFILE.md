# Makefile Standards and Best Practices

# APPLIES-TO: make

Standards for writing maintainable, portable Makefiles.

## Table of Contents

- [Core Principles](#core-principles)
- [Basic Structure](#basic-structure)
- [Variables](#variables)
- [Targets and Rules](#targets-and-rules)
- [Common Patterns](#common-patterns)
- [Language-Specific Makefiles](#language-specific-makefiles)
- [Best Practices](#best-practices)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

## Core Principles

1. **Self-Documenting**: Help target shows available commands
2. **Portable**: Works on Linux, macOS, and WSL
3. **Idempotent**: Safe to run multiple times
4. **Fast**: Use .PHONY for non-file targets
5. **Clear**: One logical operation per target

## Basic Structure

### Minimal Template

```makefile
# Makefile
.DEFAULT_GOAL := help
.PHONY: help

# Variables
PROJECT_NAME := myapp
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Targets
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build the application
	go build -o bin/$(PROJECT_NAME) ./cmd/$(PROJECT_NAME)

.PHONY: test
test: ## Run tests
	go test -v ./...

.PHONY: clean
clean: ## Clean build artifacts
	rm -rf bin/
```

### Self-Documenting Help

```makefile
# ✅ Good - auto-generated help from comments
.DEFAULT_GOAL := help
.PHONY: help

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the application
	@echo "Building..."

test: ## Run all tests
	@echo "Testing..."

# Output when running 'make' or 'make help':
#   build          Build the application
#   test           Run all tests

# ❌ Bad - manual help (gets outdated)
help:
	@echo "build  - Build the application"
	@echo "test   - Run tests"
```

## Variables

### Standard Variables

```makefile
# ✅ Good - organized variables
# Project metadata
PROJECT_NAME := myapp
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Directories
BUILD_DIR := ./bin
SRC_DIR := ./cmd
TEST_DIR := ./test

# Go configuration (following AGENTS_GO.md)
GO := go
GOFLAGS := -mod=vendor
LDFLAGS := -X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME)

# Tool versions
GOLANGCI_LINT_VERSION := v1.55.2
```

### Shell Command Variables

```makefile
# ✅ Good - use := for shell commands (evaluated once)
GIT_COMMIT := $(shell git rev-parse --short HEAD)
BUILD_TIME := $(shell date -u +%Y-%m-%d)

# ❌ Bad - use = (evaluated every time, slower)
GIT_COMMIT = $(shell git rev-parse --short HEAD)
```

### Conditional Variables

```makefile
# ✅ Good - detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    OS := linux
    OPEN := xdg-open
endif
ifeq ($(UNAME_S),Darwin)
    OS := darwin
    OPEN := open
endif

# Use in targets
open-coverage: test
	$(OPEN) coverage.html
```

## Targets and Rules

### .PHONY Targets

```makefile
# ✅ Good - mark non-file targets as .PHONY
.PHONY: build test clean install deploy

build:
	go build -o bin/app

test:
	go test ./...

clean:
	rm -rf bin/

# ❌ Bad - missing .PHONY (make checks for file named 'test')
test:
	go test ./...
```

### Target Dependencies

```makefile
# ✅ Good - clear dependencies
.PHONY: all build test lint

all: lint test build ## Run all checks and build

build: clean ## Build application
	go build -o bin/app

test: ## Run tests
	go test ./...

lint: ## Run linter
	golangci-lint run

clean: ## Clean build artifacts
	rm -rf bin/

# ❌ Bad - unclear dependencies
build:
	rm -rf bin/
	go test ./...
	golangci-lint run
	go build -o bin/app
```

### Pattern Rules

```makefile
# ✅ Good - pattern rules for similar targets
.PHONY: test-unit test-integration test-e2e

test-%: ## Run specific test suite
	go test -tags=$* ./...

# Usage:
# make test-unit
# make test-integration
# make test-e2e
```

### Silent Commands

```makefile
# ✅ Good - use @ to suppress command output
.PHONY: info

info: ## Show build information
	@echo "Version: $(VERSION)"
	@echo "Commit:  $(GIT_COMMIT)"
	@echo "Built:   $(BUILD_TIME)"

# ❌ Bad - shows commands (noisy)
info:
	echo "Version: $(VERSION)"
	echo "Commit:  $(GIT_COMMIT)"
```

## Common Patterns

### Standard Targets

```makefile
# Standard Makefile targets (GNU conventions)
.PHONY: all build install test clean distclean

all: build ## Build everything (default)

build: ## Build the application
	go build -o bin/app

install: build ## Install the application
	cp bin/app /usr/local/bin/

test: ## Run tests
	go test ./...

clean: ## Remove build artifacts
	rm -rf bin/

distclean: clean ## Remove all generated files
	rm -rf vendor/
	go clean -modcache
```

### Development Workflow

```makefile
.PHONY: dev run watch fmt lint

dev: fmt lint test ## Run development checks

run: build ## Build and run application
	./bin/app

watch: ## Watch for changes and rebuild
	find . -name '*.go' | entr -r make run

fmt: ## Format code
	gofmt -s -w .
	goimports -w .

lint: ## Run linter
	golangci-lint run
```

### Docker Integration

```makefile
# Docker variables
DOCKER_IMAGE := $(PROJECT_NAME):$(VERSION)
DOCKER_REGISTRY := docker.io/username

.PHONY: docker-build docker-push docker-run

docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE) .
	docker tag $(DOCKER_IMAGE) $(PROJECT_NAME):latest

docker-push: docker-build ## Push Docker image
	docker tag $(DOCKER_IMAGE) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE)
	docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE)
	docker push $(DOCKER_REGISTRY)/$(PROJECT_NAME):latest

docker-run: docker-build ## Run Docker container
	docker run --rm -p 8080:8080 $(DOCKER_IMAGE)
```

### Tool Installation

```makefile
# Tools directory
TOOLS_DIR := $(shell pwd)/.tools
TOOLS_BIN := $(TOOLS_DIR)/bin
export PATH := $(TOOLS_BIN):$(PATH)

# Tool versions
GOLANGCI_LINT_VERSION := v1.55.2
BUF_VERSION := v1.28.1

.PHONY: tools install-golangci-lint install-buf

tools: install-golangci-lint install-buf ## Install all tools

install-golangci-lint: ## Install golangci-lint
	@mkdir -p $(TOOLS_BIN)
	@if [ ! -f $(TOOLS_BIN)/golangci-lint ] || [ "$$($(TOOLS_BIN)/golangci-lint version --format short 2>/dev/null)" != "$(GOLANGCI_LINT_VERSION)" ]; then \
		echo "Installing golangci-lint $(GOLANGCI_LINT_VERSION)..."; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(TOOLS_BIN) $(GOLANGCI_LINT_VERSION); \
	fi

install-buf: ## Install buf
	@mkdir -p $(TOOLS_BIN)
	@if [ ! -f $(TOOLS_BIN)/buf ]; then \
		echo "Installing buf $(BUF_VERSION)..."; \
		GOBIN=$(TOOLS_BIN) go install github.com/bufbuild/buf/cmd/buf@$(BUF_VERSION); \
	fi
```

### Testing Targets

```makefile
.PHONY: test test-unit test-integration test-coverage test-race

test: test-unit test-integration ## Run all tests

test-unit: ## Run unit tests
	go test -short ./...

test-integration: ## Run integration tests
	go test -run Integration ./...

test-coverage: ## Run tests with coverage
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

test-race: ## Run tests with race detector
	go test -race ./...

test-bench: ## Run benchmarks
	go test -bench=. -benchmem ./...
```

### Release Targets

```makefile
.PHONY: release tag version

version: ## Show current version
	@echo $(VERSION)

tag: ## Create git tag for release
	@if [ -z "$(TAG)" ]; then \
		echo "Usage: make tag TAG=v1.0.0"; \
		exit 1; \
	fi
	git tag -a $(TAG) -m "Release $(TAG)"
	git push origin $(TAG)

release: test lint ## Build release binaries
	@mkdir -p dist
	GOOS=linux GOARCH=amd64 go build -o dist/$(PROJECT_NAME)-linux-amd64
	GOOS=darwin GOARCH=amd64 go build -o dist/$(PROJECT_NAME)-darwin-amd64
	GOOS=darwin GOARCH=arm64 go build -o dist/$(PROJECT_NAME)-darwin-arm64
	GOOS=windows GOARCH=amd64 go build -o dist/$(PROJECT_NAME)-windows-amd64.exe
	@echo "Release binaries in dist/"
```

## Language-Specific Makefiles

### Go (Following AGENTS_GO.md)

```makefile
# Makefile for Go projects
.DEFAULT_GOAL := help
.PHONY: help

# Project
PROJECT_NAME := myapp
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Go
GO := go
GOFLAGS := -mod=vendor
LDFLAGS := -X main.Version=$(VERSION) -X main.BuildTime=$(shell date -u +%Y-%m-%d)
MAIN_PACKAGE := ./cmd/$(PROJECT_NAME)

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build application
	$(GO) build $(GOFLAGS) -ldflags="$(LDFLAGS)" -o bin/$(PROJECT_NAME) $(MAIN_PACKAGE)

.PHONY: test
test: ## Run tests
	$(GO) test -v ./...

.PHONY: test-coverage
test-coverage: ## Run tests with coverage
	$(GO) test -coverprofile=coverage.out ./...
	$(GO) tool cover -html=coverage.out -o coverage.html

.PHONY: lint
lint: ## Run linter
	golangci-lint run

.PHONY: fmt
fmt: ## Format code
	gofmt -s -w .
	goimports -w .

.PHONY: mod
mod: ## Tidy and vendor dependencies
	$(GO) mod tidy
	$(GO) mod vendor

.PHONY: proto
proto: ## Generate protobuf code
	buf generate

.PHONY: run
run: build ## Build and run
	./bin/$(PROJECT_NAME)

.PHONY: clean
clean: ## Clean build artifacts
	rm -rf bin/ coverage.out coverage.html
```

### Python (Following AGENTS_PYTHON.md)

```makefile
# Makefile for Python projects
.DEFAULT_GOAL := help
.PHONY: help

# Project
PROJECT_NAME := myapp
PYTHON := python3
UV := uv

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: venv
venv: ## Create virtual environment
	$(UV) venv

.PHONY: install
install: ## Install dependencies
	$(UV) pip install -e ".[dev]"

.PHONY: test
test: ## Run tests
	pytest tests/

.PHONY: test-coverage
test-coverage: ## Run tests with coverage
	pytest --cov=$(PROJECT_NAME) --cov-report=html tests/
	@echo "Coverage report: htmlcov/index.html"

.PHONY: lint
lint: ## Run linters
	ruff check .
	mypy $(PROJECT_NAME)

.PHONY: fmt
fmt: ## Format code
	ruff format .

.PHONY: type-check
type-check: ## Run type checker
	mypy --strict $(PROJECT_NAME)

.PHONY: run
run: ## Run application
	$(PYTHON) -m $(PROJECT_NAME)

.PHONY: clean
clean: ## Clean generated files
	rm -rf build/ dist/ *.egg-info .pytest_cache .mypy_cache .ruff_cache htmlcov/ .coverage
	find . -type d -name __pycache__ -exec rm -rf {} +
```

### TypeScript/Vue (Following AGENTS_TYPESCRIPT_VUE.md)

```makefile
# Makefile for TypeScript/Vue projects
.DEFAULT_GOAL := help
.PHONY: help

# Project
PROJECT_NAME := myapp
NPM := npm

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: install
install: ## Install dependencies
	$(NPM) install

.PHONY: dev
dev: ## Run development server
	$(NPM) run dev

.PHONY: build
build: ## Build for production
	$(NPM) run build

.PHONY: preview
preview: build ## Preview production build
	$(NPM) run preview

.PHONY: test
test: ## Run tests
	$(NPM) run test

.PHONY: test-ui
test-ui: ## Run tests with UI
	$(NPM) run test:ui

.PHONY: lint
lint: ## Run linter
	$(NPM) run lint

.PHONY: type-check
type-check: ## Run type checker
	$(NPM) run type-check

.PHONY: fmt
fmt: ## Format code
	$(NPM) run format

.PHONY: clean
clean: ## Clean build artifacts
	rm -rf dist/ node_modules/ .nuxt/ .output/
```

### PowerShell (Following AGENTS_POWERSHELL.md)

```makefile
# Makefile for PowerShell projects
.DEFAULT_GOAL := help
.PHONY: help

# Project
PROJECT_NAME := MyModule

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: test
test: ## Run Pester tests
	pwsh -Command "Invoke-Pester -Path ./Tests -Output Detailed"

.PHONY: test-coverage
test-coverage: ## Run tests with coverage
	pwsh -Command "Invoke-Pester -Path ./Tests -CodeCoverage ./$(PROJECT_NAME)/*.ps1 -Output Detailed"

.PHONY: analyze
analyze: ## Run PSScriptAnalyzer
	pwsh -Command "Invoke-ScriptAnalyzer -Path ./$(PROJECT_NAME) -Recurse"

.PHONY: fmt
fmt: ## Format code
	pwsh -Command "Get-ChildItem -Path ./$(PROJECT_NAME) -Filter *.ps1 -Recurse | ForEach-Object { Invoke-Formatter -ScriptDefinition (Get-Content $$_.FullName -Raw) | Set-Content $$_.FullName }"

.PHONY: install
install: ## Install module locally
	pwsh -Command "Install-Module -Name ./$(PROJECT_NAME) -Force"

.PHONY: clean
clean: ## Clean build artifacts
	rm -rf ./Output/
```

## Best Practices

### Do's

```makefile
# ✅ Use .PHONY for non-file targets
.PHONY: build test clean

# ✅ Use := for variables (evaluated once)
VERSION := $(shell git describe --tags)

# ✅ Use @ to suppress command echo
info:
	@echo "Building version $(VERSION)"

# ✅ Check for required tools
build:
	@command -v go >/dev/null 2>&1 || { echo "go not found"; exit 1; }
	go build

# ✅ Use multi-line for readability
docker-build:
	docker build \
		--build-arg VERSION=$(VERSION) \
		--tag $(IMAGE) \
		.

# ✅ Document targets with ##
build: ## Build the application
	go build
```

### Don'ts

```makefile
# ❌ Missing .PHONY
test:
	go test ./...

# ❌ Using = instead of := for shell commands
VERSION = $(shell git describe --tags)  # Evaluated every time!

# ❌ Hardcoded values
build:
	go build -o myapp

# ❌ No documentation
build:
	go build

# ❌ Too many operations in one target
deploy:
	go test ./...
	go build
	docker build -t app .
	docker push app
	kubectl apply -f k8s/
```

### Error Handling

```makefile
# ✅ Good - check prerequisites
.PHONY: build
build:
	@command -v go >/dev/null 2>&1 || { echo "Error: go not found"; exit 1; }
	@[ -f go.mod ] || { echo "Error: go.mod not found"; exit 1; }
	go build -o bin/app

# ✅ Good - stop on error
.PHONY: ci
ci:
	@echo "Running CI pipeline..."
	$(MAKE) lint || exit 1
	$(MAKE) test || exit 1
	$(MAKE) build || exit 1
	@echo "CI pipeline complete"

# ✅ Good - optional commands
.PHONY: clean
clean:
	rm -rf bin/ || true
	rm -f coverage.out || true
```

## AI Assistant Guidelines

### When Creating Makefiles

1. **Start with template**: Use appropriate language template
2. **Add help target**: Self-documenting help
3. **Use .PHONY**: Mark all non-file targets
4. **Organize variables**: Project, tools, directories
5. **Standard targets**: build, test, clean, install
6. **Document targets**: Use ## comments
7. **Keep it simple**: One logical operation per target

### Example AI Prompt

```
Create a Makefile following .ai/context/AGENTS_MAKEFILE.md:

For: Go microservice (from AGENTS_GO.md)
Requirements:
- Build binary with version info
- Run tests with coverage
- Lint with golangci-lint
- Generate protobuf with buf
- Docker build and push
- Self-documenting help
- Tool installation targets
```

### When Reviewing Makefiles

Check for:

- [ ] .DEFAULT_GOAL set to help
- [ ] help target with auto-generated list
- [ ] All non-file targets marked .PHONY
- [ ] Variables use := not =
- [ ] Targets documented with ##
- [ ] Commands use @ to reduce noise
- [ ] Standard targets present (build, test, clean)
- [ ] Error checking for required tools
- [ ] Portable (works on Linux and macOS)

### LazyVim Integration

```vim
# Keybindings from EDITORS.md
<leader>ff         " Find Makefile
<leader>sg         " Search in Makefile

# Run make targets
:!make build
:!make test

# Or use toggleterm
<C-\>              " Toggle terminal
make build         " Run make command
```

## Best Practices Summary

✅ **Do:**

- Use .PHONY for non-file targets
- Use := for variables (evaluated once)
- Add self-documenting help
- Document targets with ##
- Use @ to suppress command echo
- Check for required tools
- Keep targets focused (one operation)
- Use pattern rules for similar targets
- Organize variables at the top
- Support both development and CI workflows

❌ **Don't:**

- Skip .PHONY declarations
- Use = for shell command variables
- Hardcode values
- Create overly complex targets
- Forget error checking
- Mix multiple languages in one Makefile
- Skip documentation
- Ignore portability (Linux/macOS/WSL)

## Tools

- **make**: Standard make utility

  ```bash
  # Run default target
  make

  # Run specific target
  make build

  # Show what would be executed
  make -n build

  # Run with specific variable
  make build VERSION=1.0.0
  ```

- **remake**: Make with better debugging

  ```bash
  # Install
  brew install remake

  # Debug Makefile
  remake -x build
  ```

## References

- [GNU Make Manual](https://www.gnu.org/software/make/manual/)
- [Make Best Practices](https://suva.sh/posts/well-documented-makefiles/)
- [Makefile Tutorial](https://makefiletutorial.com/)

## Version History

- 2024-01-25: Initial version
