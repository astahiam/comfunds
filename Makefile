# ComFunds Crowdfunding Platform Makefile

# Variables
BINARY_NAME=comfunds
MAIN_PATH=./main.go
BUILD_DIR=./build
TEST_COVERAGE_DIR=./coverage

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
GOFMT=$(GOCMD) fmt

# Colors for output
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[0;33m
BLUE=\033[0;34m
NC=\033[0m # No Color

.PHONY: all build clean test test-coverage test-race deps fmt lint vet help run dev

# Default target
all: clean deps fmt vet test build

# Build the binary
build:
	@echo "$(BLUE)Building $(BINARY_NAME)...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) -v $(MAIN_PATH)
	@echo "$(GREEN)Build completed: $(BUILD_DIR)/$(BINARY_NAME)$(NC)"

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning...$(NC)"
	@$(GOCLEAN)
	@rm -rf $(BUILD_DIR)
	@rm -rf $(TEST_COVERAGE_DIR)
	@echo "$(GREEN)Clean completed$(NC)"

# Run tests
test:
	@echo "$(BLUE)Running tests...$(NC)"
	@$(GOTEST) -v ./internal/...
	@echo "$(GREEN)Tests completed$(NC)"

# Run tests with coverage
test-coverage:
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	@mkdir -p $(TEST_COVERAGE_DIR)
	@$(GOTEST) -v -coverprofile=$(TEST_COVERAGE_DIR)/coverage.out ./internal/...
	@$(GOCMD) tool cover -html=$(TEST_COVERAGE_DIR)/coverage.out -o $(TEST_COVERAGE_DIR)/coverage.html
	@echo "$(GREEN)Coverage report generated: $(TEST_COVERAGE_DIR)/coverage.html$(NC)"

# Run tests with race detection
test-race:
	@echo "$(BLUE)Running tests with race detection...$(NC)"
	@$(GOTEST) -race -v ./internal/...
	@echo "$(GREEN)Race tests completed$(NC)"

# Run integration tests (requires TEST_INTEGRATION=1)
test-integration:
	@echo "$(BLUE)Running integration tests...$(NC)"
	@TEST_INTEGRATION=1 $(GOTEST) -v ./...
	@echo "$(GREEN)Integration tests completed$(NC)"

# Run all tests (unit + integration)
test-all: test test-integration

# Download dependencies
deps:
	@echo "$(BLUE)Downloading dependencies...$(NC)"
	@$(GOMOD) tidy
	@$(GOMOD) download
	@echo "$(GREEN)Dependencies updated$(NC)"

# Format Go code
fmt:
	@echo "$(BLUE)Formatting code...$(NC)"
	@$(GOFMT) ./...
	@echo "$(GREEN)Code formatted$(NC)"

# Lint code (requires golangci-lint)
lint:
	@echo "$(BLUE)Running linter...$(NC)"
	@golangci-lint run
	@echo "$(GREEN)Linting completed$(NC)"

# Vet code
vet:
	@echo "$(BLUE)Running go vet...$(NC)"
	@$(GOCMD) vet ./...
	@echo "$(GREEN)Vet completed$(NC)"

# Run the application in development mode
dev: build
	@echo "$(BLUE)Starting development server...$(NC)"
	@./$(BUILD_DIR)/$(BINARY_NAME)

# Run the application
run:
	@echo "$(BLUE)Running application...$(NC)"
	@$(GOCMD) run $(MAIN_PATH)

# Setup databases (create sharded databases)
setup-db:
	@echo "$(BLUE)Setting up sharded databases...$(NC)"
	@./scripts/setup_databases.sh
	@echo "$(GREEN)Database setup completed$(NC)"

# Run database migrations (requires migrate tool)
migrate-up:
	@echo "$(BLUE)Running database migrations...$(NC)"
	@migrate -path ./migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):5432/comfunds01?sslmode=$(DB_SSLMODE)" up
	@migrate -path ./migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):5432/comfunds02?sslmode=$(DB_SSLMODE)" up
	@migrate -path ./migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):5432/comfunds03?sslmode=$(DB_SSLMODE)" up
	@migrate -path ./migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):5432/comfunds04?sslmode=$(DB_SSLMODE)" up
	@echo "$(GREEN)Database migrations completed$(NC)"

# Complete database setup (create databases + run migrations)
setup-db-complete:
	@echo "$(BLUE)Complete database setup (create + migrate)...$(NC)"
	@$(MAKE) setup-db
	@$(MAKE) migrate-up
	@echo "$(GREEN)Complete database setup finished$(NC)"

# Rollback database migrations
migrate-down:
	@echo "$(YELLOW)Rolling back database migrations...$(NC)"
	@migrate -path ./migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):5432/comfunds01?sslmode=$(DB_SSLMODE)" down
	@migrate -path ./migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):5432/comfunds02?sslmode=$(DB_SSLMODE)" down
	@migrate -path ./migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):5432/comfunds03?sslmode=$(DB_SSLMODE)" down
	@migrate -path ./migrations -database "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):5432/comfunds04?sslmode=$(DB_SSLMODE)" down
	@echo "$(GREEN)Database rollback completed$(NC)"

# Create a new migration file
migrate-create:
	@read -p "Enter migration name: " name; \
	migrate create -ext sql -dir ./migrations $$name
	@echo "$(GREEN)Migration files created$(NC)"

# Install development tools
install-tools:
	@echo "$(BLUE)Installing development tools...$(NC)"
	@go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	@go install github.com/golangci-lint/golangci-lint/cmd/golangci-lint@latest
	@echo "$(GREEN)Tools installed$(NC)"

# Docker commands
docker-build:
	@echo "$(BLUE)Building Docker image...$(NC)"
	@docker build -t comfunds:latest .
	@echo "$(GREEN)Docker image built$(NC)"

docker-run:
	@echo "$(BLUE)Running Docker container...$(NC)"
	@docker run -p 8080:8080 --env-file .env comfunds:latest

# Help
help:
	@echo "$(BLUE)ComFunds Crowdfunding Platform - Available Commands:$(NC)"
	@echo ""
	@echo "$(GREEN)Build Commands:$(NC)"
	@echo "  build          - Build the binary"
	@echo "  clean          - Clean build artifacts"
	@echo ""
	@echo "$(GREEN)Test Commands:$(NC)"
	@echo "  test           - Run unit tests"
	@echo "  test-coverage  - Run tests with coverage report"
	@echo "  test-race      - Run tests with race detection"
	@echo "  test-integration - Run integration tests (requires TEST_INTEGRATION=1)"
	@echo "  test-all       - Run all tests (unit + integration)"
	@echo ""
	@echo "$(GREEN)Development Commands:$(NC)"
	@echo "  run            - Run the application directly"
	@echo "  dev            - Build and run in development mode"
	@echo "  deps           - Download and update dependencies"
	@echo "  fmt            - Format Go code"
	@echo "  vet            - Run go vet"
	@echo "  lint           - Run golangci-lint (requires installation)"
	@echo ""
	@echo "$(GREEN)Database Commands:$(NC)"
	@echo "  setup-db       - Create sharded databases"
	@echo "  migrate-up     - Run database migrations"
	@echo "  migrate-down   - Rollback database migrations"
	@echo "  migrate-create - Create a new migration file"
	@echo "  setup-db-complete - Complete setup (create databases + migrations)"
	@echo ""
	@echo "$(GREEN)Docker Commands:$(NC)"
	@echo "  docker-build   - Build Docker image"
	@echo "  docker-run     - Run Docker container"
	@echo ""
	@echo "$(GREEN)Setup Commands:$(NC)"
	@echo "  install-tools  - Install development tools"
	@echo "  all            - Run clean, deps, fmt, vet, test, build"
	@echo ""
	@echo "$(GREEN)Usage Examples:$(NC)"
	@echo "  make all                    # Full build pipeline"
	@echo "  make test-coverage          # Run tests with coverage"
	@echo "  make setup-db-complete      # Complete database setup"
	@echo "  make migrate-create         # Create new migration"
	@echo "  DB_PASSWORD=mypass make migrate-up  # Run migrations with custom DB password"