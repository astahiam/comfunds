#!/bin/bash

# Complete VPS Deployment Script
# Run this script on your VPS to deploy the application
# Usage: ./deploy-vps-complete.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Configuration
PROJECT_DIR="${PROJECT_DIR:-$HOME/sourcecode}"
GITHUB_REPO="${GITHUB_REPO:-https://github.com/astahiam/comfunds.git}"
BRANCH="${BRANCH:-main}"

# Database configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-postgres123}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

# Options
SKIP_GIT_PULL=false
SKIP_MIGRATIONS=false
SKIP_BUILD=false
FORCE_REBUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-git-pull)
            SKIP_GIT_PULL=true
            shift
            ;;
        --skip-migrations)
            SKIP_MIGRATIONS=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --force-rebuild)
            FORCE_REBUILD=true
            shift
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [options]

Complete VPS Deployment Script

Options:
  --skip-git-pull      Skip pulling latest code from GitHub
  --skip-migrations    Skip running database migrations
  --skip-build         Skip building Docker images
  --force-rebuild      Force rebuild of Docker images
  --help, -h           Show this help message

Environment Variables:
  PROJECT_DIR          Project directory (default: ~/sourcecode)
  GITHUB_REPO          GitHub repository URL
  BRANCH               Git branch to pull (default: main)
  DB_HOST              Database host (default: localhost)
  DB_USER              Database user (default: postgres)
  DB_PASSWORD          Database password

Examples:
  $0                                    # Full deployment
  $0 --skip-git-pull                   # Skip git pull
  $0 --skip-migrations --skip-build     # Only restart services
EOF
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_header "VPS Complete Deployment"

print_info "Configuration:"
print_info "  Project Directory: $PROJECT_DIR"
print_info "  GitHub Repo: $GITHUB_REPO"
print_info "  Branch: $BRANCH"
print_info "  Database: $DB_HOST:$DB_PORT"
print_info "  Database User: $DB_USER"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Some operations may need adjustment."
fi

# Step 1: Check prerequisites
print_step "1. Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    print_info "Install Docker: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
    exit 1
fi
print_status "Docker: $(docker --version)"

# Check Docker Compose
USE_COMPOSE_PLUGIN=false
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    USE_COMPOSE_PLUGIN=true
    print_status "Docker Compose (plugin): $(docker compose version)"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    print_status "Docker Compose (standalone): $(docker-compose --version)"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

# Check Git
if ! command -v git &> /dev/null; then
    print_warning "Git is not installed. Skipping git operations."
    SKIP_GIT_PULL=true
else
    print_status "Git: $(git --version)"
fi

# Check PostgreSQL client (for migrations)
if ! command -v psql &> /dev/null; then
    print_warning "psql is not installed. Migrations may fail."
    print_info "Install: sudo apt-get install postgresql-client"
else
    print_status "PostgreSQL client: Available"
fi

echo ""

# Step 2: Navigate to project directory
print_step "2. Setting up project directory..."

if [ ! -d "$PROJECT_DIR" ]; then
    print_info "Creating project directory: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"
print_status "Current directory: $(pwd)"

# Step 3: Pull latest code from GitHub
if [ "$SKIP_GIT_PULL" = false ]; then
    print_step "3. Pulling latest code from GitHub..."
    
    if [ -d ".git" ]; then
        print_info "Git repository found. Pulling latest changes..."
        
        # Check current branch
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
        
        if [ -z "$CURRENT_BRANCH" ]; then
            print_warning "No branch checked out. Checking out $BRANCH..."
            git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
        elif [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
            print_info "Switching from '$CURRENT_BRANCH' to '$BRANCH'..."
            git checkout "$BRANCH"
        fi
        
        # Fetch and pull
        git fetch origin
        if git pull origin "$BRANCH"; then
            print_status "Code pulled successfully"
            LATEST_COMMIT=$(git log -1 --oneline)
            print_info "Latest commit: $LATEST_COMMIT"
        else
            print_error "Failed to pull code"
            print_warning "Continuing with existing code..."
        fi
    else
        print_info "Not a git repository. Cloning..."
        if git clone -b "$BRANCH" "$GITHUB_REPO" .; then
            print_status "Repository cloned successfully"
        else
            print_error "Failed to clone repository"
            print_warning "Continuing with existing files..."
        fi
    fi
else
    print_info "Skipping git pull (--skip-git-pull)"
fi

echo ""

# Step 4: Check Docker Compose file
print_step "4. Checking Docker Compose configuration..."

if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found in $PROJECT_DIR"
    print_info "Make sure you're in the correct directory"
    exit 1
fi
print_status "Docker Compose file found"

# Step 5: Stop existing services
print_step "5. Stopping existing services..."

if $COMPOSE_CMD ps 2>/dev/null | grep -q "Up"; then
    print_info "Stopping running containers..."
    $COMPOSE_CMD stop
    print_status "Services stopped"
else
    print_info "No running services found"
fi

echo ""

# Step 6: Build Docker images
if [ "$SKIP_BUILD" = false ]; then
    print_step "6. Building Docker images..."
    
    # Try docker-compose build first, with fallback to individual builds
    BUILD_SUCCESS=false
    
    if [ "$FORCE_REBUILD" = true ]; then
        print_info "Force rebuilding images..."
        if timeout 300 $COMPOSE_CMD build --no-cache 2>&1; then
            BUILD_SUCCESS=true
        else
            BUILD_EXIT_CODE=$?
            if [ $BUILD_EXIT_CODE -eq 124 ]; then
                print_warning "Build timed out (5 minutes)"
            elif [ $BUILD_EXIT_CODE -eq 139 ]; then
                print_warning "Segmentation fault detected in docker-compose"
            else
                print_warning "$COMPOSE_CMD build failed with exit code $BUILD_EXIT_CODE"
            fi
        fi
    else
        if timeout 300 $COMPOSE_CMD build 2>&1; then
            BUILD_SUCCESS=true
        else
            BUILD_EXIT_CODE=$?
            if [ $BUILD_EXIT_CODE -eq 124 ]; then
                print_warning "Build timed out (5 minutes)"
            elif [ $BUILD_EXIT_CODE -eq 139 ]; then
                print_warning "Segmentation fault detected in docker-compose"
            else
                print_warning "$COMPOSE_CMD build failed with exit code $BUILD_EXIT_CODE"
            fi
        fi
    fi
    
    # Fallback: Build images individually if docker-compose fails
    if [ "$BUILD_SUCCESS" = false ]; then
        print_warning "docker-compose build failed, trying individual builds..."
        print_info "This is a workaround for docker-compose segmentation fault"
        
        # Build backend
        if [ -f "Dockerfile.backend" ]; then
            print_info "Building backend image individually..."
            if docker build -f Dockerfile.backend -t hajifund-backend . 2>&1; then
                print_status "Backend image built"
            else
                print_error "Backend build failed"
                exit 1
            fi
        fi
        
        # Build frontend
        if [ -f "frontend/Dockerfile.frontend" ]; then
            print_info "Building frontend image individually..."
            if docker build -f frontend/Dockerfile.frontend -t hajifund-frontend ./frontend 2>&1; then
                print_status "Frontend image built"
            else
                print_warning "Frontend build failed, trying alternative Dockerfile..."
                if [ -f "frontend/Dockerfile" ]; then
                    docker build -f frontend/Dockerfile -t hajifund-frontend ./frontend 2>&1 && \
                        print_status "Frontend image built" || \
                        print_error "Frontend build failed"
                fi
            fi
        elif [ -f "frontend/Dockerfile" ]; then
            print_info "Building frontend image individually..."
            if docker build -f frontend/Dockerfile -t hajifund-frontend ./frontend 2>&1; then
                print_status "Frontend image built"
            else
                print_error "Frontend build failed"
                exit 1
            fi
        fi
        
        print_status "Images built individually (workaround method)"
    else
        print_status "Docker images built successfully"
    fi
else
    print_info "Skipping build (--skip-build)"
fi

echo ""

# Step 7: Start PostgreSQL first
print_step "7. Starting PostgreSQL..."

$COMPOSE_CMD up -d postgres
print_status "PostgreSQL starting..."

# Wait for PostgreSQL to be ready
print_info "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if $COMPOSE_CMD exec -T postgres pg_isready -U "$DB_USER" >/dev/null 2>&1; then
        print_status "PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "PostgreSQL failed to start"
        $COMPOSE_CMD logs postgres
        exit 1
    fi
    sleep 2
done

echo ""

# Step 8: Run database migrations
if [ "$SKIP_MIGRATIONS" = false ]; then
    print_step "8. Running database migrations..."
    
    # Wait a bit more for PostgreSQL to be fully ready
    print_info "Waiting for PostgreSQL to be fully ready..."
    sleep 5
    
    # Check if databases exist, create them if not
    print_info "Checking/creating databases..."
    export PGPASSWORD="$DB_PASSWORD"
    for shard in comfunds00 comfunds01 comfunds02 comfunds03; do
        if $COMPOSE_CMD exec -T postgres psql -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$shard"; then
            print_info "Database $shard exists"
        else
            print_info "Creating database $shard..."
            $COMPOSE_CMD exec -T postgres psql -U "$DB_USER" -c "CREATE DATABASE $shard;" || print_warning "Failed to create $shard (may already exist)"
        fi
    done
    
    # Check if migration script exists
    if [ -f "run-golang-migrations.sh" ]; then
        print_info "Running migrations using run-golang-migrations.sh..."
        chmod +x run-golang-migrations.sh 2>/dev/null || true
        
        # Use docker exec to run migrations inside postgres container
        if $COMPOSE_CMD exec -T postgres psql -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
            print_info "PostgreSQL is accessible, running migrations..."
            # Run migrations using docker exec
            export PGPASSWORD="$DB_PASSWORD"
            for shard in comfunds00 comfunds01 comfunds02 comfunds03; do
                print_info "Running migrations for $shard..."
                if [ -d "migrations" ]; then
                    for migration in migrations/*.up.sql; do
                        [ -f "$migration" ] || continue
                        migration_name=$(basename "$migration")
                        print_info "  Applying $migration_name..."
                        $COMPOSE_CMD exec -T postgres psql -U "$DB_USER" -d "$shard" -f "/docker-entrypoint-initdb.d/../migrations/$migration_name" 2>/dev/null || \
                        cat "$migration" | $COMPOSE_CMD exec -T postgres psql -U "$DB_USER" -d "$shard" 2>&1 | grep -v "already exists" || true
                    done
                fi
            done
            print_status "Migrations completed"
        else
            print_warning "Cannot connect to PostgreSQL, migrations will be skipped"
            print_info "Databases will be initialized by Docker init scripts on first start"
        fi
    elif [ -d "migrations" ]; then
        print_info "Running migrations directly via Docker..."
        export PGPASSWORD="$DB_PASSWORD"
        for shard in comfunds00 comfunds01 comfunds02 comfunds03; do
            print_info "Migrating $shard..."
            for migration in migrations/*.up.sql; do
                [ -f "$migration" ] || continue
                migration_name=$(basename "$migration")
                cat "$migration" | $COMPOSE_CMD exec -T postgres psql -U "$DB_USER" -d "$shard" 2>&1 | grep -v "already exists" || true
            done
        done
        print_status "Migrations completed"
    else
        print_warning "No migration files found, skipping migrations"
        print_info "Databases will be initialized by Docker init scripts"
    fi
else
    print_info "Skipping migrations (--skip-migrations)"
fi

echo ""

# Step 9: Start all services
print_step "9. Starting all services..."

$COMPOSE_CMD up -d
print_status "Services starting..."

# Wait a bit for services to start
sleep 5

echo ""

# Step 10: Check service status
print_step "10. Checking service status..."

echo ""
print_info "Container Status:"
$COMPOSE_CMD ps

echo ""
print_info "Service Health Checks:"

# Check PostgreSQL
if $COMPOSE_CMD exec -T postgres pg_isready -U "$DB_USER" >/dev/null 2>&1; then
    print_status "PostgreSQL: Healthy"
else
    print_error "PostgreSQL: Unhealthy"
fi

# Check Backend
if curl -f http://localhost:8080/api/v1/health >/dev/null 2>&1; then
    print_status "Backend API: Healthy"
else
    print_warning "Backend API: Not responding (may still be starting)"
fi

# Check Frontend
if curl -f http://localhost:3000 >/dev/null 2>&1; then
    print_status "Frontend: Healthy"
else
    print_warning "Frontend: Not responding (may still be starting)"
fi

echo ""

# Step 11: Show logs
print_step "11. Recent logs (last 20 lines per service):"

echo ""
print_info "PostgreSQL logs:"
$COMPOSE_CMD logs --tail=20 postgres | tail -20 || true

echo ""
print_info "Backend logs:"
$COMPOSE_CMD logs --tail=20 backend | tail -20 || true

echo ""
print_info "Frontend logs:"
$COMPOSE_CMD logs --tail=20 frontend | tail -20 || true

echo ""

# Final summary
print_header "Deployment Summary"

print_status "Deployment completed!"
echo ""
print_info "Services are running. Check status with:"
echo "  $COMPOSE_CMD ps"
echo ""
print_info "View logs with:"
echo "  $COMPOSE_CMD logs -f"
echo ""
print_info "Access services:"
echo "  Frontend: http://103.103.20.68:3000"
echo "  Backend API: http://103.103.20.68:8080"
echo "  PostgreSQL: localhost:5432"
echo ""
print_info "Useful commands:"
echo "  $COMPOSE_CMD restart          # Restart all services"
echo "  $COMPOSE_CMD stop             # Stop all services"
echo "  $COMPOSE_CMD logs -f backend  # Follow backend logs"
echo "  $COMPOSE_CMD exec backend sh  # Access backend container"
echo ""

print_status "🚀 Deployment complete!"

