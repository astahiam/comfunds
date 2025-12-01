#!/bin/bash

# Fix Dashboard Route for Direct Golang Deployment
# This script fixes the dashboard route issue with correct directory structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

print_step "Fixing Dashboard Route for Direct Golang Deployment"

# 1. Check if dashboard route exists in main.go
print_step "1. Checking dashboard route in main.go..."

if [ -f "/var/www/hajifund/main.go" ]; then
    print_info "Main.go found, checking for dashboard route..."
    
    # Check if dashboard route exists
    if grep -q "app.Get(\"/dashboard\"" /var/www/hajifund/main.go; then
        print_info "Dashboard route already exists"
    else
        print_info "Adding dashboard route..."
        
        # Add dashboard route after login route
        sed -i '/app.Get("\/login"/a\
    app.Get("/dashboard", dashboardHandler.Dashboard)' /var/www/hajifund/main.go
        
        print_status "Dashboard route added"
    fi
    
    # Check for any incorrect DashboardPage references and remove them
    if grep -q "handlers\.DashboardPage" /var/www/hajifund/main.go; then
        print_warning "Found incorrect DashboardPage reference, removing..."
        sed -i '/handlers\.DashboardPage/d' /var/www/hajifund/main.go
        print_status "Incorrect DashboardPage reference removed"
    fi
    
    # Check for any routes that might reference DashboardPage incorrectly
    if grep -q "DashboardPage" /var/www/hajifund/main.go; then
        print_warning "Found DashboardPage reference, checking for incorrect usage..."
        # Replace any DashboardPage with Dashboard
        sed -i 's/DashboardPage/Dashboard/g' /var/www/hajifund/main.go
        print_status "DashboardPage references corrected"
    fi
    
    # Check if handlers package is imported
    if ! grep -q "handlers" /var/www/hajifund/main.go; then
        print_warning "Handlers package not imported, adding import..."
        # Add import if missing
        sed -i '/import (/a\\t"hajifund-frontend/handlers"' /var/www/hajifund/main.go
        print_status "Handlers import added"
    else
        print_info "Handlers package already imported"
    fi
else
    print_error "Main.go not found"
    exit 1
fi

# 2. Check if dashboard handler exists
print_step "2. Checking dashboard handler..."

if [ -f "/var/www/hajifund/handlers/dashboard.go" ]; then
    print_info "Dashboard handler already exists"
    
    # Check if Dashboard method exists
    if grep -q "func.*Dashboard" /var/www/hajifund/handlers/dashboard.go; then
        print_info "Dashboard method found in handler"
    else
        print_warning "Dashboard method not found, but handler file exists"
    fi
else
    print_error "Dashboard handler not found - this is required for the dashboard route"
    print_info "The dashboard handler should exist at /var/www/hajifund/handlers/dashboard.go"
    print_info "Please ensure the dashboard handler is properly set up"
fi

# 3. Create dashboard template if it doesn't exist
print_step "3. Creating dashboard template..."

if [ -f "/var/www/hajifund/views/dashboard.html" ]; then
    print_info "Dashboard template already exists"
else
    print_info "Creating dashboard template..."
    
    cat > /var/www/hajifund/views/dashboard.html << 'EOF'
{{ define "dashboard" }}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1 class="h3 mb-0">Dashboard</h1>
                <div class="text-muted">
                    <i class="fas fa-calendar-alt me-2"></i>
                    <span id="currentDate"></span>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-8">
            <div class="card mb-4">
                <div class="card-header">
                    <h5 class="card-title mb-0">
                        <i class="fas fa-chart-line me-2"></i>
                        Selamat Datang di HajiFund
                    </h5>
                </div>
                <div class="card-body">
                    <p class="card-text">
                        Selamat datang di dashboard HajiFund. Dari sini Anda dapat mengelola investasi, 
                        melihat portofolio, dan mengakses berbagai fitur platform.
                    </p>
                    <div class="row">
                        <div class="col-md-6">
                            <div class="d-flex align-items-center">
                                <div class="flex-shrink-0">
                                    <i class="fas fa-wallet text-success fa-2x"></i>
                                </div>
                                <div class="flex-grow-1 ms-3">
                                    <h6 class="mb-0">Portofolio</h6>
                                    <small class="text-muted">Kelola investasi Anda</small>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="d-flex align-items-center">
                                <div class="flex-shrink-0">
                                    <i class="fas fa-chart-pie text-primary fa-2x"></i>
                                </div>
                                <div class="flex-grow-1 ms-3">
                                    <h6 class="mb-0">Analisis</h6>
                                    <small class="text-muted">Lihat performa investasi</small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-lg-4">
            <div class="card mb-4">
                <div class="card-header">
                    <h5 class="card-title mb-0">
                        <i class="fas fa-bell me-2"></i>
                        Notifikasi
                    </h5>
                </div>
                <div class="card-body">
                    <div class="list-group list-group-flush">
                        <div class="list-group-item border-0 px-0">
                            <div class="d-flex align-items-center">
                                <i class="fas fa-info-circle text-info me-3"></i>
                                <div>
                                    <h6 class="mb-1">Selamat Datang!</h6>
                                    <p class="mb-0 text-muted small">Akun Anda telah berhasil dibuat.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// Set current date
document.addEventListener('DOMContentLoaded', function() {
    const now = new Date();
    const options = { 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric',
        weekday: 'long'
    };
    document.getElementById('currentDate').textContent = now.toLocaleDateString('id-ID', options);
});
</script>
{{ end }}
EOF
    
    print_status "Dashboard template created"
fi

# 4. Build and restart services
print_step "4. Building and restarting services..."

# Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend
systemctl stop hajifund-frontend

# Build backend
print_info "Building backend..."
cd /var/www/hajifund
go build -o hajifund-backend main.go

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o hajifund-frontend main.go

# Start services
print_info "Starting services..."
systemctl start hajifund-backend
systemctl start hajifund-frontend

# Check service status
print_info "Checking service status..."
if systemctl is-active --quiet hajifund-backend; then
    print_status "Backend service is running"
else
    print_error "Backend service failed to start"
    systemctl status hajifund-backend
fi

if systemctl is-active --quiet hajifund-frontend; then
    print_status "Frontend service is running"
else
    print_error "Frontend service failed to start"
    systemctl status hajifund-frontend
fi

# 5. Test dashboard route
print_step "5. Testing dashboard route..."

print_info "Testing dashboard route..."
if curl -s http://103.103.20.68/dashboard | grep -q "Dashboard"; then
    print_status "Dashboard route is working"
else
    print_warning "Dashboard route might not be working correctly"
fi

print_status "Dashboard route fix completed!"
print_info "You can now access the dashboard at: http://103.103.20.68/dashboard"
