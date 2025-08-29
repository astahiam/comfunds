# ComFunds Makefile
.PHONY: help build run dev clean test docker-build docker-run docker-dev docker-clean

# Default target
help:
	@echo "ComFunds - Available commands:"
	@echo ""
	@echo "Development:"
	@echo "  dev          - Start development environment"
	@echo "  dev-stop     - Stop development environment"
	@echo "  dev-logs     - Show development logs"
	@echo ""
	@echo "Production:"
	@echo "  build        - Build production images"
	@echo "  run          - Start production environment"
	@echo "  stop         - Stop production environment"
	@echo "  logs         - Show production logs"
	@echo ""
	@echo "Mobile:"
	@echo "  mobile-build - Build mobile app (Android APK)"
	@echo "  mobile-bundle- Build mobile app bundle (Android AAB)"
	@echo ""
	@echo "Utilities:"
	@echo "  clean        - Clean all containers and volumes"
	@echo "  test         - Run tests"
	@echo "  migrate      - Run database migrations"
	@echo "  shell        - Open shell in backend container"

# Development environment
dev:
	@echo "Starting development environment..."
	docker-compose -f docker-compose.dev.yml up -d
	@echo "Development environment started!"
	@echo "Backend API: http://localhost:8081"
	@echo "Frontend Web: http://localhost:3000"
	@echo "Database Admin: http://localhost:8082"
	@echo "Redis: localhost:6380"

dev-stop:
	@echo "Stopping development environment..."
	docker-compose -f docker-compose.dev.yml down

dev-logs:
	docker-compose -f docker-compose.dev.yml logs -f

# Production environment
build:
	@echo "Building production images..."
	docker-compose build
	@echo "Production images built successfully!"

run:
	@echo "Starting production environment..."
	docker-compose up -d
	@echo "Production environment started!"
	@echo "Backend API: http://localhost:8080"
	@echo "Frontend Web: http://localhost:80"

stop:
	@echo "Stopping production environment..."
	docker-compose down

logs:
	docker-compose logs -f

# Mobile builds
mobile-build:
	@echo "Building Android APK..."
	docker build -f mobile/Dockerfile --target android-builder ./mobile
	@echo "Android APK built successfully!"

mobile-bundle:
	@echo "Building Android App Bundle..."
	docker build -f mobile/Dockerfile --target android-bundle ./mobile
	@echo "Android App Bundle built successfully!"

# Utilities
clean:
	@echo "Cleaning all containers and volumes..."
	docker-compose down -v --remove-orphans
	docker-compose -f docker-compose.dev.yml down -v --remove-orphans
	docker system prune -f
	@echo "Cleanup completed!"

test:
	@echo "Running tests..."
	go test ./... -v

migrate:
	@echo "Running database migrations..."
	docker-compose exec backend ./comfunds migrate

shell:
	@echo "Opening shell in backend container..."
	docker-compose exec backend sh

# Database operations
db-reset:
	@echo "Resetting database..."
	docker-compose down -v
	docker-compose up -d postgres
	@echo "Database reset completed!"

# Health checks
health:
	@echo "Checking service health..."
	@echo "Backend API:"
	@curl -f http://localhost:8080/health || echo "Backend API is not responding"
	@echo "Frontend Web:"
	@curl -f http://localhost:80/health || echo "Frontend Web is not responding"

# Development shortcuts
backend-logs:
	docker-compose -f docker-compose.dev.yml logs -f backend-dev

frontend-logs:
	docker-compose -f docker-compose.dev.yml logs -f frontend-dev

db-logs:
	docker-compose -f docker-compose.dev.yml logs -f postgres-dev