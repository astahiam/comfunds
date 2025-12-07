# VPS Deployment Quick Start Guide

## 🚀 Quick Deployment (3 Steps)

### Step 1: Copy Deployment Script to VPS (from local machine)

```bash
./copy-deploy-script-to-vps.sh
```

Or manually:
```bash
scp -i ~/Downloads/ryan-biznet-gio.pem deploy-vps-complete.sh ryankharisma@103.103.20.68:~/sourcecode/
```

### Step 2: Connect to VPS

```bash
ssh -i ~/Downloads/ryan-biznet-gio.pem ryankharisma@103.103.20.68
```

### Step 3: Run Deployment Script

```bash
cd ~/sourcecode
./deploy-vps-complete.sh
```

That's it! The script will:
- ✅ Pull latest code from GitHub
- ✅ Build Docker images
- ✅ Start PostgreSQL
- ✅ Run database migrations
- ✅ Start all services
- ✅ Check service health

## 📋 Full Deployment Options

### Option 1: Full Deployment (Default)
```bash
./deploy-vps-complete.sh
```
Runs everything: git pull, build, migrations, start services

### Option 2: Skip Git Pull
```bash
./deploy-vps-complete.sh --skip-git-pull
```
Useful if you've already pulled code manually

### Option 3: Skip Migrations
```bash
./deploy-vps-complete.sh --skip-migrations
```
Useful if migrations are already applied

### Option 4: Skip Build
```bash
./deploy-vps-complete.sh --skip-build
```
Useful for quick restarts without rebuilding

### Option 5: Force Rebuild
```bash
./deploy-vps-complete.sh --force-rebuild
```
Forces complete rebuild of Docker images

### Option 6: Quick Restart (Skip Everything)
```bash
./deploy-vps-complete.sh --skip-git-pull --skip-migrations --skip-build
```
Just restarts services

## 🔧 Environment Variables

You can customize the deployment:

```bash
# Set custom database password
DB_PASSWORD=your_password ./deploy-vps-complete.sh

# Set custom project directory
PROJECT_DIR=/opt/comfunds ./deploy-vps-complete.sh

# Set custom GitHub branch
BRANCH=develop ./deploy-vps-complete.sh
```

## 📊 Check Deployment Status

After deployment, check status:

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f

# Check specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres

# Check service health
curl http://localhost:3000
curl http://localhost:8080/api/v1/health
```

## 🐛 Troubleshooting

### Services Not Starting

```bash
# Check logs
docker-compose logs

# Restart specific service
docker-compose restart backend

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose exec postgres pg_isready -U postgres

# Check database exists
docker-compose exec postgres psql -U postgres -l

# Run migrations manually
DB_HOST=localhost DB_USER=postgres DB_PASSWORD=postgres123 \
  ./run-golang-migrations.sh up
```

### Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :3000
sudo lsof -i :8080
sudo lsof -i :5432

# Stop conflicting services or change ports in docker-compose.yml
```

## 📝 Manual Steps (If Script Fails)

If the automated script fails, you can run steps manually:

```bash
# 1. Pull code
cd ~/sourcecode
git pull origin master

# 2. Stop services
docker-compose down

# 3. Build images
docker-compose build

# 4. Start PostgreSQL
docker-compose up -d postgres
sleep 10

# 5. Run migrations
DB_HOST=localhost DB_USER=postgres DB_PASSWORD=postgres123 \
  ./run-golang-migrations.sh up

# 6. Start all services
docker-compose up -d

# 7. Check status
docker-compose ps
docker-compose logs
```

## 🔗 Related Scripts

- `deploy-vps-complete.sh` - Main deployment script (run on VPS)
- `copy-deploy-script-to-vps.sh` - Copy script to VPS (run locally)
- `export-and-deploy-to-vps.sh` - Export local database (run locally)
- `run-golang-migrations.sh` - Run database migrations
- `pull-from-github.sh` - Pull code from GitHub

## 📞 Quick Reference

**VPS Connection:**
```bash
ssh -i ~/Downloads/ryan-biznet-gio.pem ryankharisma@103.103.20.68
```

**Project Directory:**
```bash
cd ~/sourcecode
```

**Deploy:**
```bash
./deploy-vps-complete.sh
```

**Check Status:**
```bash
docker-compose ps
docker-compose logs -f
```

**Restart:**
```bash
docker-compose restart
```

**Stop:**
```bash
docker-compose stop
```

**Start:**
```bash
docker-compose up -d
```

