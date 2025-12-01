#!/bin/bash

# Fix Frontend Internal Server Error
# This script diagnoses and fixes internal server errors in the frontend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

print_step "Diagnosing and Fixing Frontend Internal Server Error"

# 1. Check service status
print_step "1. Checking service status..."

print_info "Checking frontend service status..."
systemctl status hajifund-frontend --no-pager -l

print_info "Checking backend service status..."
systemctl status hajifund-backend --no-pager -l

# 2. Check logs for errors
print_step "2. Checking logs for errors..."

print_info "Checking frontend logs..."
journalctl -u hajifund-frontend --no-pager -l --since "5 minutes ago" | tail -20

print_info "Checking backend logs..."
journalctl -u hajifund-backend --no-pager -l --since "5 minutes ago" | tail -20

# 3. Check if services are running
print_step "3. Checking if services are running..."

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running"
else
    print_error "Frontend service is not running"
    print_info "Starting frontend service..."
    systemctl start hajifund-frontend
fi

if systemctl is-active --quiet hajifund-backend; then
    print_status "Backend service is running"
else
    print_error "Backend service is not running"
    print_info "Starting backend service..."
    systemctl start hajifund-backend
fi

# 4. Check port listeners
print_step "4. Checking port listeners..."

print_info "Checking port 80 (frontend)..."
if netstat -tlnp | grep :80; then
    print_status "Port 80 is listening"
else
    print_warning "Port 80 is not listening"
fi

print_info "Checking port 8080 (backend)..."
if netstat -tlnp | grep :8080; then
    print_status "Port 8080 is listening"
else
    print_warning "Port 8080 is not listening"
fi

# 5. Test direct connections
print_step "5. Testing direct connections..."

print_info "Testing frontend direct connection..."
if curl -s -I http://localhost:80 | head -1; then
    print_status "Frontend responds locally"
else
    print_error "Frontend does not respond locally"
fi

print_info "Testing backend direct connection..."
if curl -s -I http://localhost:8080/api/v1/health | head -1; then
    print_status "Backend responds locally"
else
    print_error "Backend does not respond locally"
fi

# 6. Check file permissions
print_step "6. Checking file permissions..."

print_info "Checking frontend binary permissions..."
if [ -f "/var/www/hajifund/frontend/hajifund-frontend" ]; then
    ls -la /var/www/hajifund/frontend/hajifund-frontend
    if [ -x "/var/www/hajifund/frontend/hajifund-frontend" ]; then
        print_status "Frontend binary is executable"
    else
        print_error "Frontend binary is not executable"
        chmod +x /var/www/hajifund/frontend/hajifund-frontend
        print_status "Made frontend binary executable"
    fi
else
    print_error "Frontend binary not found"
fi

print_info "Checking backend binary permissions..."
if [ -f "/var/www/hajifund/hajifund-backend" ]; then
    ls -la /var/www/hajifund/hajifund-backend
    if [ -x "/var/www/hajifund/hajifund-backend" ]; then
        print_status "Backend binary is executable"
    else
        print_error "Backend binary is not executable"
        chmod +x /var/www/hajifund/hajifund-backend
        print_status "Made backend binary executable"
    fi
else
    print_error "Backend binary not found"
fi

# 7. Check Go modules
print_step "7. Checking Go modules..."

print_info "Checking frontend Go modules..."
cd /var/www/hajifund/frontend
if [ -f "go.mod" ]; then
    print_status "Frontend go.mod exists"
    go mod tidy
    print_status "Frontend modules tidied"
else
    print_error "Frontend go.mod not found"
    go mod init hajifund-frontend
    go mod tidy
    print_status "Created frontend go.mod"
fi

print_info "Checking backend Go modules..."
cd /var/www/hajifund
if [ -f "go.mod" ]; then
    print_status "Backend go.mod exists"
    go mod tidy
    print_status "Backend modules tidied"
else
    print_error "Backend go.mod not found"
    go mod init hajifund-backend
    go mod tidy
    print_status "Created backend go.mod"
fi

# 8. Rebuild applications
print_step "8. Rebuilding applications..."

print_info "Stopping services..."
systemctl stop hajifund-frontend
systemctl stop hajifund-backend

print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o hajifund-frontend main.go
chown www-data:www-data hajifund-frontend
chmod +x hajifund-frontend
setcap 'cap_net_bind_service=+ep' hajifund-frontend
print_status "Frontend built successfully"

print_info "Building backend..."
cd /var/www/hajifund
go build -o hajifund-backend main.go
chown www-data:www-data hajifund-backend
chmod +x hajifund-backend
print_status "Backend built successfully"

# 9. Check for missing templates
print_step "9. Checking for missing templates..."

print_info "Checking base template..."
if [ -f "/var/www/hajifund/frontend/views/base.html" ]; then
    print_status "Base template exists"
else
    print_error "Base template missing"
    print_info "Creating base template..."
    mkdir -p /var/www/hajifund/frontend/views
    cat > /var/www/hajifund/frontend/views/base.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{.Title}} - HajiFund</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-light bg-light">
        <div class="container">
            <a class="navbar-brand" href="/">HajiFund</a>
            <div class="navbar-nav ms-auto">
                <a class="nav-link" href="/login">Login</a>
                <a class="nav-link" href="/register">Daftar</a>
            </div>
        </div>
    </nav>
    
    <main>
        {{template "content" .}}
    </main>
    
    <footer class="bg-dark text-white text-center py-3">
        <p>&copy; 2024 HajiFund. All rights reserved.</p>
    </footer>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOF
    print_status "Base template created"
fi

# 10. Start services
print_step "10. Starting services..."

print_info "Starting backend service..."
systemctl start hajifund-backend
sleep 3

print_info "Starting frontend service..."
systemctl start hajifund-frontend
sleep 3

# 11. Test services
print_step "11. Testing services..."

print_info "Testing backend health..."
if curl -s http://localhost:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is healthy"
else
    print_warning "Backend health check failed"
fi

print_info "Testing frontend..."
if curl -s http://localhost:80 | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend test failed"
fi

# 12. Check final status
print_step "12. Checking final status..."

print_info "Final service status:"
systemctl status hajifund-frontend --no-pager -l | head -10
systemctl status hajifund-backend --no-pager -l | head -10

print_info "Final port status:"
netstat -tlnp | grep -E ":(80|8080)"

print_info "Testing external access..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "Frontend is accessible externally"
else
    print_warning "Frontend external access failed"
fi

print_status "Frontend Internal Server Error diagnosis completed!"
print_info "Issues checked:"
print_info "1. Service status and logs"
print_info "2. Port listeners"
print_info "3. File permissions"
print_info "4. Go modules"
print_info "5. Application rebuild"
print_info "6. Missing templates"
print_info "7. Service restart"

print_info "If issues persist, check:"
print_info "1. Frontend logs: journalctl -u hajifund-frontend -f"
print_info "2. Backend logs: journalctl -u hajifund-backend -f"
print_info "3. System logs: journalctl -f"
print_info "4. Network connectivity: curl -v http://103.103.20.68/"
print_info "5. Firewall rules: ufw status"
