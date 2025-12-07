# GitHub Actions CI/CD Workflows

This repository includes comprehensive CI/CD pipelines for automated testing, building, and deployment.

## 📋 Workflows Overview

### 1. **CI Pipeline** (`.github/workflows/ci.yml`)
**Purpose:** Continuous Integration - Runs on every push and pull request

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
- ✅ **Lint & Format Check** - Validates code formatting and runs `go vet`
- ✅ **Run Tests** - Executes unit tests and integration tests
- ✅ **Build Docker Images** - Builds backend and frontend Docker images
- ✅ **Security Scan** - Runs security scanners (Gosec, Trivy)
- ✅ **CI Summary** - Provides summary of all checks

**What it does:**
- Checks code formatting with `gofmt`
- Runs `go vet` for static analysis
- Executes unit tests with PostgreSQL service
- Builds Docker images to verify they compile correctly
- Scans for security vulnerabilities
- Generates test coverage reports

### 2. **Deploy to VPS** (`.github/workflows/deploy.yml`)
**Purpose:** Deploy to VPS for development/testing

**Triggers:**
- Push to `main` or `develop` branches
- Manual workflow dispatch

**What it does:**
- Connects to VPS via SSH
- Pulls latest code from specified branch
- Runs deployment script (`deploy-vps-complete.sh`)
- Verifies deployment health
- Shows deployment summary

**Note:** Only deploys on `main` branch or manual dispatch

### 3. **CD Pipeline** (`.github/workflows/cd.yml`)
**Purpose:** Production deployment pipeline

**Triggers:**
- Push to `main` branch
- Manual workflow dispatch with environment selection

**What it does:**
- Production-grade deployment to VPS
- Comprehensive health checks
- Deployment verification
- Detailed deployment summary

## 🔧 Setup Instructions

### 1. Add SSH Key to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to: **Settings → Secrets and variables → Actions**
3. Click **"New repository secret"**
4. Add the following secret:
   - **Name:** `VPS_SSH_KEY`
   - **Value:** Contents of your SSH private key file
   - Click **"Add secret"**

**How to get your SSH key:**
```bash
cat ~/Downloads/ryan-biznet-gio.pem
```
Copy the entire output (including `-----BEGIN` and `-----END` lines) and paste as the secret value.

### 2. Configure Environment Variables (Optional)

You can modify these in the workflow files if needed:
- `VPS_HOST`: 103.103.20.68
- `VPS_USER`: ryankharisma
- `VPS_PATH`: ~/sourcecode

## 🚀 Usage

### Automatic CI on Push/PR

When you push code or create a PR:
1. CI pipeline runs automatically
2. All checks must pass (lint, tests, build)
3. You'll see status checks on your PR

### Manual Deployment

1. Go to **Actions** tab in GitHub
2. Select the workflow you want to run:
   - **Deploy to VPS** - For development/testing
   - **CD Pipeline** - For production deployment
3. Click **"Run workflow"**
4. Select branch and options
5. Click **"Run workflow"**

## 📊 Workflow Status

You can check workflow status:
- In the **Actions** tab
- As status checks on pull requests
- Via GitHub API

## 🔍 Troubleshooting

### CI Pipeline Fails

**Lint fails:**
```bash
# Fix formatting locally
go fmt ./...

# Check formatting
gofmt -s -l .
```

**Tests fail:**
- Check test logs in Actions tab
- Run tests locally: `go test -v ./...`
- Ensure PostgreSQL is running for integration tests

**Build fails:**
- Check Dockerfile syntax
- Verify Docker context paths
- Check for missing dependencies

### Deployment Fails

**SSH Connection Issues:**
1. Verify SSH key secret is correct
2. Test SSH manually:
   ```bash
   ssh -i ~/Downloads/ryan-biznet-gio.pem ryankharisma@103.103.20.68
   ```
3. Check VPS is accessible

**Deployment Script Issues:**
- Check `deploy-vps-complete.sh` exists on VPS
- Verify script has execute permissions
- Check VPS logs: `docker-compose logs`

**Service Health Checks Fail:**
- Services may need more time to start
- Check container logs: `docker-compose logs backend`
- Verify ports are not blocked

## 📝 Workflow Files

- `.github/workflows/ci.yml` - CI pipeline
- `.github/workflows/deploy.yml` - VPS deployment
- `.github/workflows/cd.yml` - Production CD pipeline

## 🔐 Security Notes

- ⚠️ **Never commit SSH keys** to the repository
- ✅ **Always use GitHub Secrets** for sensitive information
- ✅ SSH keys are stored securely in GitHub Secrets
- ✅ SSH connections use strict host key checking
- ✅ Security scans run automatically on every push

## 🎯 Best Practices

1. **Always run CI locally** before pushing:
   ```bash
   go fmt ./...
   go vet ./...
   go test ./...
   ```

2. **Keep workflows updated** with your dependencies

3. **Monitor workflow runs** regularly

4. **Fix failing tests immediately** - Don't let CI break

5. **Use feature branches** - Don't push directly to `main`

6. **Review PRs** before merging to `main`

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Action](https://github.com/docker/build-push-action)
- [Go Setup Action](https://github.com/actions/setup-go)
