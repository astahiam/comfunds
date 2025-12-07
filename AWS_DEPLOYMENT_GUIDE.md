# AWS Free Tier Deployment Guide

Complete guide for deploying the application to AWS EC2 Free Tier.

## Prerequisites

1. **AWS Account** with Free Tier eligibility
2. **EC2 Instance** (t2.micro or t3.micro)
3. **SSH Key Pair** downloaded from AWS
4. **Local PostgreSQL** with your data

## Quick Start

### 1. Launch EC2 Instance

1. Go to AWS EC2 Console
2. Launch Instance:
   - **AMI**: Amazon Linux 2023 or Ubuntu 22.04 LTS
   - **Instance Type**: t2.micro (Free Tier eligible)
   - **Key Pair**: Create/download a key pair
   - **Security Group**: Allow:
     - SSH (22) from your IP
     - HTTP (80) from anywhere (optional)
     - Custom TCP (3000) from anywhere (Frontend)
     - Custom TCP (8080) from anywhere (Backend)
     - Custom TCP (5432) from your IP (PostgreSQL - optional)

### 2. Deploy Application

```bash
# Basic usage
./deploy-complete-aws.sh ec2-user@your-instance.compute-1.amazonaws.com ~/.ssh/aws-key.pem

# Or set environment variables
export AWS_HOST=ec2-user@your-instance.compute-1.amazonaws.com
export AWS_KEY=~/.ssh/aws-key.pem
./deploy-complete-aws.sh
```

### 3. What the Script Does

1. **Exports Local Databases**: Creates SQL dumps of all 4 shards
2. **Prepares Deployment Package**: Packages application code and database dumps
3. **Uploads to AWS**: Transfers everything to EC2 instance
4. **Installs Docker** (if needed): Sets up Docker and Docker Compose
5. **Deploys Application**: Builds images, starts containers, imports databases
6. **Verifies Deployment**: Checks all services are running

## Manual Steps (If Script Fails)

### Step 1: Setup EC2 Instance

```bash
# SSH to instance
ssh -i ~/.ssh/aws-key.pem ec2-user@your-instance.compute-1.amazonaws.com

# Install Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and back in for group changes
exit
```

### Step 2: Copy Files

```bash
# From your local machine
scp -i ~/.ssh/aws-key.pem -r deploy-package-* ec2-user@your-instance:~/app/
```

### Step 3: Deploy

```bash
# On AWS instance
cd ~/app
chmod +x deploy.sh
./deploy.sh
```

## Configuration

### Environment Variables

You can customize the deployment:

```bash
# Local database
export LOCAL_DB_HOST=localhost
export LOCAL_DB_PORT=5432
export LOCAL_DB_USER=postgres
export LOCAL_DB_PASSWORD=your_password

# Remote database
export REMOTE_DB_USER=postgres
export REMOTE_DB_PASSWORD=postgres123

# AWS settings
export AWS_HOST=ec2-user@your-instance.compute-1.amazonaws.com
export AWS_KEY=~/.ssh/aws-key.pem
export AWS_PATH=~/app
```

### Security Group Rules

Make sure your EC2 Security Group allows:

| Type | Protocol | Port Range | Source |
|------|----------|------------|--------|
| SSH | TCP | 22 | Your IP |
| Custom TCP | TCP | 3000 | 0.0.0.0/0 (Frontend) |
| Custom TCP | TCP | 8080 | 0.0.0.0/0 (Backend) |
| Custom TCP | TCP | 5432 | Your IP (PostgreSQL - optional) |

## Troubleshooting

### Cannot Connect via SSH

1. Check Security Group allows SSH from your IP
2. Verify key file permissions: `chmod 400 ~/.ssh/aws-key.pem`
3. Check instance is running

### Docker Build Fails

```bash
# On AWS instance, check logs
cd ~/app
docker-compose logs

# Rebuild manually
docker-compose build --no-cache
```

### Database Import Fails

```bash
# Check PostgreSQL container
docker ps | grep postgres

# Check database exists
docker exec hajifund-postgres psql -U postgres -l

# Import manually
docker exec -i hajifund-postgres psql -U postgres -d comfunds00 < db-dumps/comfunds00_complete.sql
```

### Services Not Accessible

1. Check Security Group rules
2. Check services are running: `docker ps`
3. Check logs: `docker-compose logs`
4. Verify ports: `netstat -tulpn | grep -E '3000|8080'`

## Cost Optimization (Free Tier)

- **EC2**: Use t2.micro (750 hours/month free)
- **EBS Storage**: 30GB free (use gp3, 20GB)
- **Data Transfer**: 1GB/month free outbound
- **No RDS**: Using Docker PostgreSQL (included in EC2)

## Monitoring

```bash
# Check service status
docker ps

# Check logs
docker-compose logs -f

# Check resource usage
docker stats

# Check disk space
df -h
```

## Backup

```bash
# Export databases
docker exec hajifund-postgres pg_dump -U postgres comfunds00 > backup_comfunds00.sql

# Backup entire deployment
tar czf backup-$(date +%Y%m%d).tar.gz ~/app
```

## Updates

To update the application:

```bash
# Pull latest code
cd ~/app
git pull  # if using git

# Or upload new files
scp -i ~/.ssh/aws-key.pem -r new-files ec2-user@instance:~/app/

# Redeploy
./deploy.sh
```

## Cleanup

To remove everything:

```bash
# On AWS instance
cd ~/app
docker-compose down -v
docker system prune -a

# Remove files
rm -rf ~/app
```

## Support

If you encounter issues:

1. Check logs: `docker-compose logs`
2. Verify configuration: `docker-compose config`
3. Check resources: `docker stats`
4. Review Security Groups in AWS Console

