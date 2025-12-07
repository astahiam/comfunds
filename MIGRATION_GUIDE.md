# Database Migration Guide

This guide explains how to run database migrations for the ComFunds/HajiFund application using PostgreSQL sharded databases.

## 📋 Overview

The application uses **4 sharded PostgreSQL databases**:
- `comfunds00`
- `comfunds01`
- `comfunds02`
- `comfunds03`

Migrations must be run on **all shards** to keep them in sync.

## 🛠️ Migration Scripts

### 1. `run-golang-migrations.sh` (Recommended)

**Full-featured migration script** with support for:
- golang-migrate tool (if installed)
- Direct psql execution (fallback)
- Up/down/force/version operations
- Environment variable configuration
- Detailed status reporting

**Usage:**
```bash
# Run all up migrations
./run-golang-migrations.sh up

# Run specific number of steps
./run-golang-migrations.sh up 1

# Rollback migrations
./run-golang-migrations.sh down

# Check current version
./run-golang-migrations.sh version

# Force to specific version
./run-golang-migrations.sh force 20240101000000
```

**Environment Variables:**
```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=your_password
export DB_SSLMODE=disable
export MIGRATIONS_DIR=./migrations

./run-golang-migrations.sh up
```

### 2. `run-migrations-docker.sh` (Docker)

**Simplified script for Docker containers** - uses psql directly.

**Usage in Docker:**
```bash
# From host machine
docker-compose exec backend ./run-migrations-docker.sh up

# Or copy and run inside container
docker-compose exec backend bash
./run-migrations-docker.sh up
```

### 3. `run_migrations.sh` (Legacy)

**Original migration script** - uses psql directly, simpler but less features.

**Usage:**
```bash
./run_migrations.sh
```

## 📦 Installing golang-migrate Tool

For best results, install the golang-migrate tool:

```bash
# Install using Go
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Or download binary
curl -L https://github.com/golang-migrate/migrate/releases/download/v4.16.2/migrate.linux-amd64.tar.gz | tar xvz
sudo mv migrate /usr/local/bin/migrate

# Verify installation
migrate -version
```

## 🚀 Quick Start

### Local Development

1. **Set up environment variables:**
   ```bash
   export DB_HOST=localhost
   export DB_PORT=5432
   export DB_USER=postgres
   export DB_PASSWORD=postgres
   ```

2. **Run migrations:**
   ```bash
   ./run-golang-migrations.sh up
   ```

### Docker Environment

1. **Using Docker Compose:**
   ```bash
   # Start services
   docker-compose up -d postgres
   
   # Wait for PostgreSQL to be ready
   sleep 5
   
   # Run migrations from host
   DB_HOST=localhost DB_PORT=5432 DB_USER=postgres DB_PASSWORD=postgres123 \
     ./run-golang-migrations.sh up
   
   # Or run inside backend container
   docker-compose exec backend ./run-migrations-docker.sh up
   ```

2. **Using environment file:**
   ```bash
   # Load from .env file
   export $(cat .env | grep -v '^#' | xargs)
   ./run-golang-migrations.sh up
   ```

## 📁 Migration Files Structure

Migrations are stored in the `migrations/` directory:

```
migrations/
├── 000_create_databases.up.sql
├── 000_create_databases.down.sql
├── 001_create_users_table.up.sql
├── 001_create_users_table.down.sql
├── 003_create_cooperatives_table.up.sql
├── 003_create_cooperatives_table.down.sql
└── ...
```

**Naming Convention:**
- `{number}_{description}.up.sql` - Forward migration
- `{number}_{description}.down.sql` - Rollback migration

## 🔍 Migration Operations

### Up Migrations (Apply)
```bash
# Apply all pending migrations
./run-golang-migrations.sh up

# Apply only 1 migration
./run-golang-migrations.sh up 1

# Apply 3 migrations
./run-golang-migrations.sh up 3
```

### Down Migrations (Rollback)
```bash
# Rollback all migrations
./run-golang-migrations.sh down

# Rollback 1 migration
./run-golang-migrations.sh down 1
```

### Check Version
```bash
# Show current migration version for all shards
./run-golang-migrations.sh version
```

### Force Version
```bash
# Force migration to specific version (use with caution!)
./run-golang-migrations.sh force 20240101000000
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USER` | `postgres` | Database username |
| `DB_PASSWORD` | (empty) | Database password |
| `DB_SSLMODE` | `disable` | SSL mode |
| `MIGRATIONS_DIR` | `./migrations` | Migrations directory |

### Docker Compose Configuration

The scripts automatically read from Docker Compose environment variables:

```yaml
backend:
  environment:
    DB_HOST: postgres
    DB_PORT: 5432
    DB_USER: postgres
    DB_PASSWORD: postgres123
```

## 📝 Creating New Migrations

### Using golang-migrate

```bash
# Create new migration files
migrate create -ext sql -dir ./migrations -seq add_new_column

# This creates:
# migrations/019_add_new_column.up.sql
# migrations/019_add_new_column.down.sql
```

### Manual Creation

1. Create files with sequential numbers:
   ```bash
   touch migrations/019_add_new_feature.up.sql
   touch migrations/019_add_new_feature.down.sql
   ```

2. Write SQL in up file:
   ```sql
   -- migrations/019_add_new_feature.up.sql
   ALTER TABLE users ADD COLUMN new_column VARCHAR(255);
   ```

3. Write rollback in down file:
   ```sql
   -- migrations/019_add_new_feature.down.sql
   ALTER TABLE users DROP COLUMN new_column;
   ```

## ⚠️ Important Notes

1. **Always run migrations on all shards** - The script automatically handles this
2. **Test migrations in development first** - Always test before production
3. **Backup before migrations** - Especially for production deployments
4. **Idempotent migrations** - Use `IF NOT EXISTS` and `IF EXISTS` clauses when possible
5. **Transaction safety** - Each migration file runs in a transaction

## 🐛 Troubleshooting

### Connection Errors

```bash
# Check PostgreSQL is running
pg_isready -h localhost -p 5432

# Test connection manually
psql -h localhost -p 5432 -U postgres -d comfunds00 -c "SELECT 1;"
```

### Migration Already Applied

If you see "already exists" errors, it's usually safe to ignore - the migration script handles this gracefully.

### Version Mismatch

If shards have different versions:
```bash
# Check versions
./run-golang-migrations.sh version

# Force to specific version if needed
./run-golang-migrations.sh force <version>
```

### Permission Issues

```bash
# Grant necessary permissions
psql -h localhost -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE comfunds00 TO postgres;"
```

## 📚 Examples

### Example 1: Fresh Installation

```bash
# 1. Start PostgreSQL
docker-compose up -d postgres

# 2. Wait for it to be ready
sleep 5

# 3. Run all migrations
DB_HOST=localhost DB_USER=postgres DB_PASSWORD=postgres123 \
  ./run-golang-migrations.sh up
```

### Example 2: Update Existing Database

```bash
# 1. Check current version
./run-golang-migrations.sh version

# 2. Run new migrations
./run-golang-migrations.sh up

# 3. Verify
./run-golang-migrations.sh version
```

### Example 3: Rollback Last Migration

```bash
# Rollback 1 step on all shards
./run-golang-migrations.sh down 1
```

## 🔗 Related Files

- `migrations/` - Migration SQL files
- `docker-compose.yml` - Docker configuration
- `env.example` - Environment variable template
- `POSTGRES_CONFIG_GUIDE.md` - PostgreSQL configuration guide

## 📞 Support

If you encounter issues:
1. Check PostgreSQL logs: `docker-compose logs postgres`
2. Verify connection settings
3. Check migration file syntax
4. Review error messages carefully

