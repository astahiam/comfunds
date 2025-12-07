# PostgreSQL Username and Password Configuration Guide

This guide shows where and how to configure PostgreSQL username and password in the HajiFund/ComFunds codebase.

## 📍 Configuration Locations

### 1. **Docker Compose Files** (Primary Configuration)

#### Main Docker Compose (`docker-compose.yml`)
**Location:** `docker-compose.yml`

**PostgreSQL Service Configuration:**
```yaml
postgres:
  environment:
    POSTGRES_USER: postgres          # ← Username here
    POSTGRES_PASSWORD: postgres123   # ← Password here
```

**Backend Service Database Connection:**
```yaml
backend:
  environment:
    DB_USER: postgres                # ← Username here
    DB_PASSWORD: postgres123          # ← Password here
    
    # Shard configurations
    SHARD_0_USER: postgres            # ← Username for shard 0
    SHARD_0_PASSWORD: postgres123     # ← Password for shard 0
    SHARD_1_USER: postgres            # ← Username for shard 1
    SHARD_1_PASSWORD: postgres123     # ← Password for shard 1
    # ... same for shards 2 and 3
```

#### Prepare Docker Compose (`prepare-docker/docker-compose.yml`)
**Location:** `prepare-docker/docker-compose.yml`

Similar structure but with different default password:
```yaml
postgres:
  environment:
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres      # ← Different default password
```

### 2. **Environment Files** (.env)

#### Main Environment File (`env.example`)
**Location:** `env.example`

```bash
# Main database connection
DB_USER=postgres                      # ← Username
DB_PASSWORD=postgres123               # ← Password

# Shard configurations
SHARD_0_USER=postgres                 # ← Shard 0 username
SHARD_0_PASSWORD=postgres123           # ← Shard 0 password
SHARD_1_USER=postgres                 # ← Shard 1 username
SHARD_1_PASSWORD=postgres123          # ← Shard 1 password
# ... same for shards 2 and 3
```

#### Backend Environment (`prepare-docker/backend.env`)
**Location:** `prepare-docker/backend.env`

```bash
DB_USER=postgres                      # ← Username
DB_PASSWORD=postgres                  # ← Password

SHARD_0_USER=postgres                 # ← Shard 0 username
SHARD_0_PASSWORD=postgres             # ← Shard 0 password
# ... same for all shards
```

### 3. **Application Code** (Go)

#### Main Application (`main.go`)
**Location:** `main.go` (lines 39-40)

```go
shardConfig := database.ShardConfig{
    Host:     getEnv("DB_HOST", "localhost"),
    Port:     5432,
    Username: getEnv("DB_USER", "postgres"),      // ← Reads from env var DB_USER
    Password: getEnv("DB_PASSWORD", ""),          // ← Reads from env var DB_PASSWORD
    SSLMode:  getEnv("DB_SSLMODE", "disable"),
}
```

The application reads from environment variables:
- `DB_USER` (default: "postgres")
- `DB_PASSWORD` (default: "")

### 4. **Database Initialization Script**

#### Init Script (`docker/postgres/init-multiple-databases.sh`)
**Location:** `docker/postgres/init-multiple-databases.sh`

This script uses the `$POSTGRES_USER` environment variable set by Docker:
```bash
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"
```

## 🔧 How to Change PostgreSQL Username/Password

### Option 1: Update Docker Compose (Recommended for Docker deployments)

1. **Edit `docker-compose.yml`:**
   ```yaml
   postgres:
     environment:
       POSTGRES_USER: your_new_username      # Change this
       POSTGRES_PASSWORD: your_new_password  # Change this
   
   backend:
     environment:
       DB_USER: your_new_username            # Change this
       DB_PASSWORD: your_new_password         # Change this
       
       # Update all shard configurations
       SHARD_0_USER: your_new_username
       SHARD_0_PASSWORD: your_new_password
       # ... repeat for shards 1, 2, 3
   ```

2. **Restart services:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Option 2: Use Environment Variables

1. **Create/Edit `.env` file** (copy from `env.example`):
   ```bash
   cp env.example .env
   ```

2. **Update values in `.env`:**
   ```bash
   DB_USER=your_new_username
   DB_PASSWORD=your_new_password
   
   SHARD_0_USER=your_new_username
   SHARD_0_PASSWORD=your_new_password
   # ... repeat for all shards
   ```

3. **Update docker-compose.yml to use env file:**
   ```yaml
   backend:
     env_file:
       - .env
   ```

### Option 3: Set Environment Variables Directly

```bash
export DB_USER=your_new_username
export DB_PASSWORD=your_new_password
export SHARD_0_USER=your_new_username
export SHARD_0_PASSWORD=your_new_password
# ... etc
```

## 📋 Current Default Values

| Location | Username | Password |
|----------|----------|----------|
| `docker-compose.yml` | `postgres` | `postgres123` |
| `prepare-docker/docker-compose.yml` | `postgres` | `postgres` |
| `env.example` | `postgres` | `postgres123` |
| `prepare-docker/backend.env` | `postgres` | `postgres` |

## ⚠️ Important Notes

1. **Consistency**: Make sure the username and password match across:
   - PostgreSQL service environment variables
   - Backend service environment variables
   - All shard configurations (SHARD_0, SHARD_1, SHARD_2, SHARD_3)

2. **Security**: 
   - Never commit `.env` files with real passwords to git
   - Use strong passwords in production
   - Consider using Docker secrets or environment variable injection

3. **Database Initialization**:
   - The `init-multiple-databases.sh` script uses `$POSTGRES_USER` from Docker environment
   - All shard databases are created with permissions granted to this user

4. **Application Connection**:
   - The Go application reads `DB_USER` and `DB_PASSWORD` from environment variables
   - Default fallback is `postgres` for username and empty string for password

## 🔍 Quick Reference: Files to Update

When changing PostgreSQL credentials, update these files:

1. ✅ `docker-compose.yml` - PostgreSQL and backend service configs
2. ✅ `prepare-docker/docker-compose.yml` - If using prepare-docker setup
3. ✅ `env.example` or `.env` - Environment variable defaults
4. ✅ `prepare-docker/backend.env` - Backend environment config
5. ✅ `prepare-docker/frontend.env` - If frontend connects to DB (unlikely)

## 🚀 Example: Changing Password for Production

```bash
# 1. Edit docker-compose.yml
POSTGRES_PASSWORD: secure_production_password_123
DB_PASSWORD: secure_production_password_123
SHARD_0_PASSWORD: secure_production_password_123
# ... etc

# 2. Create .env file (don't commit this!)
cat > .env << EOF
DB_USER=postgres
DB_PASSWORD=secure_production_password_123
SHARD_0_USER=postgres
SHARD_0_PASSWORD=secure_production_password_123
# ... etc
EOF

# 3. Restart services
docker-compose down
docker-compose up -d
```

