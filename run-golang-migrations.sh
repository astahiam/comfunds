#!/bin/bash

# Golang Migrations Runner for PostgreSQL Sharded Databases
# This script runs database migrations on all PostgreSQL shards
# Supports both golang-migrate tool and direct psql execution

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
MIGRATIONS_DIR="${MIGRATIONS_DIR:-./migrations}"
SHARDS=("comfunds00" "comfunds01" "comfunds02" "comfunds03")

# Database connection settings (can be overridden by environment variables)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

# Migration direction (up or down)
DIRECTION="${1:-up}"

# Number of steps to migrate (default: all)
STEPS="${2:-}"

# Check if running in Docker
IN_DOCKER="${IN_DOCKER:-false}"

print_header "Golang Migrations Runner"

print_info "Configuration:"
print_info "  Migrations Directory: $MIGRATIONS_DIR"
print_info "  Database Host: $DB_HOST"
print_info "  Database Port: $DB_PORT"
print_info "  Database User: $DB_USER"
print_info "  SSL Mode: $DB_SSLMODE"
print_info "  Direction: $DIRECTION"
print_info "  Shards: ${SHARDS[*]}"
echo ""

# Validate migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    print_error "Migrations directory not found: $MIGRATIONS_DIR"
    exit 1
fi

# Check if golang-migrate is installed
MIGRATE_CMD=""
if command -v migrate &> /dev/null; then
    MIGRATE_CMD="migrate"
    print_status "golang-migrate tool found"
elif command -v golang-migrate &> /dev/null; then
    MIGRATE_CMD="golang-migrate"
    print_status "golang-migrate tool found"
else
    print_warning "golang-migrate not found, will use psql directly"
    print_info "To install: go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest"
fi

# Function to build database URL
build_db_url() {
    local shard=$1
    if [ -n "$DB_PASSWORD" ]; then
        echo "postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${shard}?sslmode=${DB_SSLMODE}"
    else
        echo "postgresql://${DB_USER}@${DB_HOST}:${DB_PORT}/${shard}?sslmode=${DB_SSLMODE}"
    fi
}

# Function to check database connection
check_db_connection() {
    local shard=$1
    print_info "Checking connection to $shard..."
    
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$shard" -c "SELECT 1;" >/dev/null 2>&1; then
        print_status "Connected to $shard"
        return 0
    else
        print_error "Cannot connect to $shard"
        return 1
    fi
}

# Function to run migrations using golang-migrate
run_migrate_tool() {
    local shard=$1
    local db_url=$(build_db_url "$shard")
    
    print_step "Running migrations for $shard using golang-migrate..."
    
    if [ "$DIRECTION" = "up" ]; then
        if [ -n "$STEPS" ]; then
            migrate -path "$MIGRATIONS_DIR" -database "$db_url" up "$STEPS"
        else
            migrate -path "$MIGRATIONS_DIR" -database "$db_url" up
        fi
    elif [ "$DIRECTION" = "down" ]; then
        if [ -n "$STEPS" ]; then
            migrate -path "$MIGRATIONS_DIR" -database "$db_url" down "$STEPS"
        else
            migrate -path "$MIGRATIONS_DIR" -database "$db_url" down
        fi
    elif [ "$DIRECTION" = "force" ]; then
        if [ -z "$STEPS" ]; then
            print_error "Force migration requires version number"
            return 1
        fi
        migrate -path "$MIGRATIONS_DIR" -database "$db_url" force "$STEPS"
    elif [ "$DIRECTION" = "version" ]; then
        migrate -path "$MIGRATIONS_DIR" -database "$db_url" version
    else
        print_error "Invalid direction: $DIRECTION"
        return 1
    fi
}

# Function to run migrations using psql directly
run_psql_migrations() {
    local shard=$1
    
    print_step "Running migrations for $shard using psql..."
    
    if [ -n "$DB_PASSWORD" ]; then
        export PGPASSWORD="$DB_PASSWORD"
    fi
    
    # Get migration files based on direction
    if [ "$DIRECTION" = "up" ]; then
        migration_files=$(ls "$MIGRATIONS_DIR"/*.up.sql 2>/dev/null | sort)
    elif [ "$DIRECTION" = "down" ]; then
        migration_files=$(ls "$MIGRATIONS_DIR"/*.down.sql 2>/dev/null | sort -r)
    else
        print_error "psql mode only supports 'up' or 'down' direction"
        return 1
    fi
    
    if [ -z "$migration_files" ]; then
        print_warning "No migration files found in $MIGRATIONS_DIR"
        return 0
    fi
    
    local count=0
    for migration_file in $migration_files; do
        # Limit steps if specified
        if [ -n "$STEPS" ] && [ "$count" -ge "$STEPS" ]; then
            break
        fi
        
        migration_name=$(basename "$migration_file")
        print_info "  Applying $migration_name..."
        
        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$shard" -f "$migration_file" >/dev/null 2>&1; then
            print_status "  ✅ $migration_name applied"
        else
            # Check if error is due to already applied migration
            if [ "$DIRECTION" = "up" ]; then
                print_warning "  ⚠️  $migration_name may have already been applied or failed"
            else
                print_error "  ❌ $migration_name failed"
                return 1
            fi
        fi
        
        count=$((count + 1))
    done
    
    print_status "Completed migrations for $shard"
}

# Function to show migration version
show_version() {
    local shard=$1
    
    if [ -n "$MIGRATE_CMD" ]; then
        local db_url=$(build_db_url "$shard")
        local version=$(migrate -path "$MIGRATIONS_DIR" -database "$db_url" version 2>/dev/null || echo "unknown")
        print_info "  $shard: Version $version"
    else
        print_info "  $shard: Version check requires golang-migrate tool"
    fi
}

# Main execution
main() {
    # Check database connections first
    print_step "Checking database connections..."
    local all_connected=true
    for shard in "${SHARDS[@]}"; do
        if ! check_db_connection "$shard"; then
            all_connected=false
        fi
    done
    
    if [ "$all_connected" = false ]; then
        print_error "Some databases are not accessible. Please check your connection settings."
        exit 1
    fi
    
    echo ""
    
    # Show current versions if checking version
    if [ "$DIRECTION" = "version" ]; then
        print_header "Current Migration Versions"
        for shard in "${SHARDS[@]}"; do
            show_version "$shard"
        done
        echo ""
        exit 0
    fi
    
    # Run migrations on each shard
    print_header "Running Migrations ($DIRECTION)"
    
    local failed_shards=()
    for shard in "${SHARDS[@]}"; do
        echo ""
        print_step "Processing shard: $shard"
        echo "────────────────────────────────────────────"
        
        if [ -n "$MIGRATE_CMD" ]; then
            if run_migrate_tool "$shard"; then
                print_status "✅ Migrations completed for $shard"
            else
                print_error "❌ Migrations failed for $shard"
                failed_shards+=("$shard")
            fi
        else
            if run_psql_migrations "$shard"; then
                print_status "✅ Migrations completed for $shard"
            else
                print_error "❌ Migrations failed for $shard"
                failed_shards+=("$shard")
            fi
        fi
    done
    
    echo ""
    print_header "Migration Summary"
    
    if [ ${#failed_shards[@]} -eq 0 ]; then
        print_status "All migrations completed successfully!"
        
        # Show versions after migration
        if [ -n "$MIGRATE_CMD" ]; then
            echo ""
            print_info "Current migration versions:"
            for shard in "${SHARDS[@]}"; do
                show_version "$shard"
            done
        fi
    else
        print_error "Migrations failed for: ${failed_shards[*]}"
        exit 1
    fi
    
    echo ""
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [direction] [steps]

Run database migrations on all PostgreSQL shards.

Arguments:
  direction    Migration direction: up, down, force, or version (default: up)
  steps       Number of steps to migrate (optional, default: all)

Examples:
  $0                    # Run all up migrations
  $0 up                 # Run all up migrations
  $0 up 1               # Run 1 step up migration
  $0 down               # Run all down migrations
  $0 down 1             # Run 1 step down migration
  $0 force 20240101000000  # Force migration to specific version
  $0 version            # Show current migration versions

Environment Variables:
  DB_HOST              Database host (default: localhost)
  DB_PORT              Database port (default: 5432)
  DB_USER              Database user (default: postgres)
  DB_PASSWORD          Database password (default: empty)
  DB_SSLMODE           SSL mode (default: disable)
  MIGRATIONS_DIR       Migrations directory (default: ./migrations)

Docker Usage:
  # From host machine
  docker-compose exec backend ./run-golang-migrations.sh up
  
  # Or set environment variables
  DB_HOST=postgres DB_USER=postgres DB_PASSWORD=postgres123 ./run-golang-migrations.sh up

EOF
}

# Handle help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Run main function
main

