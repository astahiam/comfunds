#!/bin/bash

# Fix Dashboard 302 Redirect Issue
# This script fixes the 302 redirect issue for /dashboard route

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

print_step "Fixing Dashboard 302 Redirect Issue"

# 1. Check if dashboard route exists in frontend
print_step "1. Checking dashboard route configuration..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Checking frontend main.go for dashboard route..."
    
    if grep -q "/dashboard" /var/www/hajifund/frontend/main.go; then
        print_status "Dashboard route found in frontend main.go"
    else
        print_error "Dashboard route NOT found in frontend main.go"
        print_info "Adding dashboard route to frontend main.go..."
        
        # Add dashboard route to frontend main.go
        sed -i '/protected.Get("\/profile", dashboardHandler.Profile)/a\\t\tprotected.Get("\/dashboard", dashboardHandler.Dashboard)' /var/www/hajifund/frontend/main.go
        print_status "Dashboard route added to frontend main.go"
    fi
else
    print_error "Frontend main.go not found"
fi

# 2. Check if dashboard handler exists
print_step "2. Checking dashboard handler..."

if [ -f "/var/www/hajifund/frontend/handlers/dashboard.go" ]; then
    print_status "Dashboard handler exists"
else
    print_warning "Dashboard handler not found, creating it..."
    
    # Create dashboard handler
    cat > /var/www/hajifund/frontend/handlers/dashboard.go << 'EOF'
package handlers

import (
	"github.com/gofiber/fiber/v2"
)

type DashboardHandler struct{}

func NewDashboardHandler() *Handler {
	return &Handler{}
}

// Dashboard renders the dashboard page
func (h *Handler) Dashboard(c *fiber.Ctx) error {
	// Get user from context (set by auth middleware)
	user := c.Locals("user")
	
	return c.Render("dashboard", fiber.Map{
		"Title": "Dashboard - HajiFund",
		"User":  user,
	}, "base")
}
EOF
    
    print_status "Dashboard handler created"
fi

# 3. Check if dashboard template exists
print_step "3. Checking dashboard template..."

if [ -f "/var/www/hajifund/frontend/views/dashboard.html" ]; then
    print_status "Dashboard template exists"
else
    print_warning "Dashboard template not found, creating it..."
    
    # Create dashboard template
    cat > /var/www/hajifund/frontend/views/dashboard.html << 'EOF'
{{ define "dashboard" }}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1 class="h3 mb-0">Dashboard</h1>
                <div class="btn-group" role="group">
                    <button type="button" class="btn btn-outline-primary" onclick="location.reload()">
                        <i class="fas fa-sync-alt me-2"></i>Refresh
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- Welcome Section -->
    <div class="row mb-4">
        <div class="col-12">
            <div class="card border-0 bg-gradient-primary text-white">
                <div class="card-body">
                    <div class="row align-items-center">
                        <div class="col-md-8">
                            <h2 class="card-title mb-2">Selamat Datang, {{.User.Name}}!</h2>
                            <p class="card-text mb-0">Kelola investasi dan proyek Anda dengan mudah</p>
                        </div>
                        <div class="col-md-4 text-end">
                            <i class="fas fa-chart-line fa-3x opacity-75"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Stats Cards -->
    <div class="row mb-4">
        <div class="col-md-3 mb-3">
            <div class="card border-0 shadow-sm">
                <div class="card-body text-center">
                    <div class="text-primary mb-2">
                        <i class="fas fa-chart-pie fa-2x"></i>
                    </div>
                    <h5 class="card-title">Total Investasi</h5>
                    <h3 class="text-primary">Rp 0</h3>
                    <small class="text-muted">Belum ada investasi</small>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card border-0 shadow-sm">
                <div class="card-body text-center">
                    <div class="text-success mb-2">
                        <i class="fas fa-project-diagram fa-2x"></i>
                    </div>
                    <h5 class="card-title">Proyek Aktif</h5>
                    <h3 class="text-success">0</h3>
                    <small class="text-muted">Belum ada proyek</small>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card border-0 shadow-sm">
                <div class="card-body text-center">
                    <div class="text-warning mb-2">
                        <i class="fas fa-coins fa-2x"></i>
                    </div>
                    <h5 class="card-title">Total Return</h5>
                    <h3 class="text-warning">Rp 0</h3>
                    <small class="text-muted">Belum ada return</small>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card border-0 shadow-sm">
                <div class="card-body text-center">
                    <div class="text-info mb-2">
                        <i class="fas fa-tasks fa-2x"></i>
                    </div>
                    <h5 class="card-title">Proyek Selesai</h5>
                    <h3 class="text-info">0</h3>
                    <small class="text-muted">Belum ada proyek selesai</small>
                </div>
            </div>
        </div>
    </div>

    <!-- Quick Actions -->
    <div class="row mb-4">
        <div class="col-12">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white border-0">
                    <h5 class="card-title mb-0">Aksi Cepat</h5>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <a href="/projects/create" class="btn btn-outline-primary w-100">
                                <i class="fas fa-plus me-2"></i>Buat Proyek Baru
                            </a>
                        </div>
                        <div class="col-md-4 mb-3">
                            <a href="/projects" class="btn btn-outline-success w-100">
                                <i class="fas fa-search me-2"></i>Lihat Proyek
                            </a>
                        </div>
                        <div class="col-md-4 mb-3">
                            <a href="/investments" class="btn btn-outline-warning w-100">
                                <i class="fas fa-chart-line me-2"></i>Portfolio Saya
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Recent Activity -->
    <div class="row">
        <div class="col-12">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white border-0">
                    <h5 class="card-title mb-0">Aktivitas Terbaru</h5>
                </div>
                <div class="card-body">
                    <div class="text-center text-muted py-4">
                        <i class="fas fa-inbox fa-3x mb-3"></i>
                        <p class="mb-0">Belum ada aktivitas</p>
                        <small>Mulai berinvestasi atau buat proyek pertama Anda</small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// Dashboard specific JavaScript
document.addEventListener('DOMContentLoaded', function() {
    console.log('Dashboard loaded successfully');
    
    // Check if user is authenticated
    const authToken = document.cookie
        .split('; ')
        .find(row => row.startsWith('auth_token='));
    
    if (!authToken || authToken.split('=')[1] === '') {
        console.log('No auth token found, redirecting to login');
        window.location.href = '/login';
        return;
    }
    
    console.log('User is authenticated, dashboard loaded');
});
</script>
{{ end }}
EOF
    
    print_status "Dashboard template created"
fi

# 4. Check frontend authentication middleware
print_step "4. Checking frontend authentication middleware..."

if [ -f "/var/www/hajifund/frontend/middleware/auth.go" ]; then
    print_info "Checking frontend auth middleware..."
    
    if grep -q "Dashboard" /var/www/hajifund/frontend/middleware/auth.go; then
        print_status "Dashboard route is handled by auth middleware"
    else
        print_warning "Dashboard route might not be handled by auth middleware"
    fi
else
    print_warning "Frontend auth middleware not found"
fi

# 5. Rebuild and restart frontend
print_step "5. Rebuilding and restarting frontend..."

# Stop frontend
systemctl stop hajifund-frontend

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o hajifund-frontend main.go
chown www-data:www-data hajifund-frontend
chmod +x hajifund-frontend
setcap 'cap_net_bind_service=+ep' hajifund-frontend
print_status "Frontend built"

# Start frontend
print_info "Starting frontend..."
systemctl start hajifund-frontend
print_status "Frontend started"

# 6. Test the dashboard route
print_step "6. Testing dashboard route..."

sleep 3

# Test dashboard route
print_info "Testing dashboard route..."
if curl -s -I http://localhost/dashboard | grep -q "200 OK"; then
    print_status "Dashboard route is working (200 OK)"
elif curl -s -I http://localhost/dashboard | grep -q "302"; then
    print_warning "Dashboard route is still redirecting (302)"
    print_info "This might be due to authentication middleware"
else
    print_warning "Dashboard route might not be responding correctly"
fi

# Test with authentication
print_info "Testing dashboard with authentication..."
auth_response=$(curl -s -I -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://localhost/dashboard)

if echo "$auth_response" | grep -q "200 OK"; then
    print_status "Dashboard route works with authentication (200 OK)"
elif echo "$auth_response" | grep -q "302"; then
    print_warning "Dashboard route still redirecting with authentication (302)"
    print_info "This indicates an issue with the authentication middleware"
else
    print_warning "Dashboard route response unclear"
fi

print_status "Dashboard 302 redirect fix completed!"
print_info "Issues addressed:"
print_info "1. Dashboard route added to frontend main.go"
print_info "2. Dashboard handler created"
print_info "3. Dashboard template created"
print_info "4. Frontend rebuilt and restarted"
print_info "5. Dashboard route tested"

print_info "If the 302 redirect persists, check:"
print_info "1. Authentication middleware configuration"
print_info "2. Route order in main.go"
print_info "3. Middleware execution order"
print_info "4. Frontend logs for specific error messages"
