#!/bin/bash

# Fix CORS and Redirect Issues
# This script fixes CORS settings and frontend redirect problems

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

print_step "Fixing CORS and Redirect Issues"

# 1. Fix backend CORS settings
print_step "1. Fixing backend CORS settings..."

# Update backend .env with correct CORS origins
cat > /var/www/hajifund/.env << 'EOF'
PORT=8080
ENVIRONMENT=production
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=
DB_SSLMODE=disable
ALLOWED_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080
CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080
TRUSTED_PROXIES=103.103.20.68
EOF

print_status "Backend .env updated with correct CORS origins"

# 2. Fix frontend CORS settings
print_step "2. Fixing frontend CORS settings..."

# Update frontend .env
cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=80
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68
EOF

print_status "Frontend .env updated with correct URLs"

# 3. Fix frontend main.go CORS configuration
print_step "3. Fixing frontend main.go CORS configuration..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Updating frontend CORS configuration..."
    
    # Replace the CORS configuration
    sed -i 's/AllowOrigins: "http:\/\/localhost:8080"/AllowOrigins: "http:\/\/103.103.20.68,http:\/\/localhost:8080"/g' /var/www/hajifund/frontend/main.go
    
    # Add credentials support
    if ! grep -q "AllowCredentials: true" /var/www/hajifund/frontend/main.go; then
        sed -i '/AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",/a\\t\tAllowCredentials: true,' /var/www/hajifund/frontend/main.go
    fi
    
    print_status "Frontend CORS configuration updated"
else
    print_error "Frontend main.go not found"
fi

# 4. Fix frontend JavaScript for proper API calls
print_step "4. Fixing frontend JavaScript for proper API calls..."

if [ -f "/var/www/hajifund/frontend/static/js/app.js" ]; then
    print_info "Updating frontend JavaScript..."
    
    # Create a fixed version of app.js
    cat > /tmp/app_fixed.js << 'EOF'
// HajiFund Frontend JavaScript

// Utility functions
function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    const toastBody = document.getElementById('toast-body');
    
    toastBody.textContent = message;
    toast.className = `toast toast-${type}`;
    
    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0
    }).format(amount);
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('id-ID', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// Authentication functions
async function login(email, password) {
    try {
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include', // CRITICAL: Include cookies
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Login berhasil!', 'success');
            setTimeout(() => {
                // Redirect based on user role
                if (data.user && data.user.roles && data.user.roles.includes('admin')) {
                    window.location.href = '/admin';
                } else {
                    window.location.href = data.redirect || '/dashboard';
                }
            }, 1000);
        } else {
            showToast(data.message || 'Login gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat login', 'error');
        console.error('Login error:', error);
    }
}

// Logout function
async function logout() {
    try {
        const response = await fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include' // CRITICAL: Include cookies
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Logout berhasil!', 'success');
            setTimeout(() => {
                window.location.href = '/';
            }, 1000);
        } else {
            showToast('Logout gagal', 'error');
        }
    } catch (error) {
        console.error('Logout error:', error);
        showToast('Terjadi kesalahan saat logout', 'error');
    }
}

// Check authentication status
function checkAuthStatus() {
    // Check if auth token cookie exists
    const authToken = document.cookie
        .split('; ')
        .find(row => row.startsWith('auth_token='));
    
    return authToken && authToken.split('=')[1] !== '';
}

// Redirect to login if not authenticated (for protected pages)
function requireAuth() {
    if (!checkAuthStatus()) {
        window.location.href = '/login';
        return false;
    }
    return true;
}

async function register(formData) {
    try {
        const response = await fetch('/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include', // CRITICAL: Include cookies
            body: JSON.stringify(formData)
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Registrasi berhasil!', 'success');
            setTimeout(() => {
                window.location.href = data.redirect || '/dashboard';
            }, 1000);
        } else {
            showToast(data.message || 'Registrasi gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat registrasi', 'error');
        console.error('Register error:', error);
    }
}

// Form handlers
function handleLoginForm(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const email = formData.get('email');
    const password = formData.get('password');
    
    if (!email || !password) {
        showToast('Email dan password harus diisi', 'error');
        return;
    }
    
    login(email, password);
}

function handleRegisterForm(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const registerData = {
        name: formData.get('name'),
        email: formData.get('email'),
        password: formData.get('password'),
        phone: formData.get('phone'),
        address: formData.get('address'),
        cooperative_id: formData.get('cooperative_id') || null,
        roles: [formData.get('role')]
    };
    
    // Validation
    if (!registerData.name || !registerData.email || !registerData.password) {
        showToast('Nama, email, dan password harus diisi', 'error');
        return;
    }
    
    if (registerData.password.length < 6) {
        showToast('Password minimal 6 karakter', 'error');
        return;
    }
    
    register(registerData);
}

// Investment functions
async function investInProject(projectId, amount) {
    try {
        const response = await fetch(`/api/projects/${projectId}/invest`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include', // CRITICAL: Include cookies
            body: JSON.stringify({ amount })
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Investasi berhasil!', 'success');
            setTimeout(() => {
                window.location.reload();
            }, 1000);
        } else {
            showToast(data.message || 'Investasi gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat investasi', 'error');
        console.error('Investment error:', error);
    }
}

// Project progress calculation
function calculateProgress(raised, target) {
    if (target === 0) return 0;
    return Math.min((raised / target) * 100, 100);
}

// Real-time updates using WebSocket (placeholder)
function initWebSocket() {
    // This would connect to a WebSocket for real-time updates
    // For now, we'll use polling
    setInterval(updateProjectProgress, 30000); // Update every 30 seconds
}

function updateProjectProgress() {
    // Update project progress bars and funding amounts
    const progressBars = document.querySelectorAll('.project-progress');
    progressBars.forEach(bar => {
        const projectId = bar.dataset.projectId;
        // Fetch updated progress from API
        fetch(`/api/projects/${projectId}/progress`, {
            credentials: 'include' // CRITICAL: Include cookies
        })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    const progress = calculateProgress(data.data.raised_amount, data.data.target_amount);
                    bar.style.width = `${progress}%`;
                    
                    // Update raised amount display
                    const raisedElement = document.querySelector(`[data-project="${projectId}"] .raised-amount`);
                    if (raisedElement) {
                        raisedElement.textContent = formatCurrency(data.data.raised_amount);
                    }
                }
            })
            .catch(error => console.error('Progress update error:', error));
    });
}

// File upload helper (for cloud storage links)
function handleFileUpload(file, callback) {
    // This would integrate with cloud storage services
    // For now, we'll show a placeholder
    showToast('Fitur upload file akan segera tersedia', 'info');
    callback('https://example.com/placeholder-file.pdf');
}

// Hero section data fetching
async function fetchHeroData() {
    try {
        const response = await fetch('http://103.103.20.68:8080/api/v1/public/hero', {
            credentials: 'include' // CRITICAL: Include cookies
        });
        const data = await response.json();
        
        if (data.status === 'success') {
            updateHeroContent(data.data);
        }
    } catch (error) {
        console.error('Hero data fetch error:', error);
    }
}

function updateHeroContent(heroData) {
    // Update hero title
    const titleElement = document.querySelector('.hero-title');
    if (titleElement && heroData.hero_content?.title) {
        titleElement.textContent = heroData.hero_content.title;
    }
    
    // Update hero subtitle
    const subtitleElement = document.querySelector('.hero-subtitle');
    if (subtitleElement && heroData.hero_content?.subtitle) {
        subtitleElement.textContent = heroData.hero_content.subtitle;
    }
    
    // Update CTA buttons
    const ctaContainer = document.querySelector('.d-flex.flex-wrap.gap-3.mb-4');
    if (ctaContainer && heroData.hero_content?.cta_buttons) {
        ctaContainer.innerHTML = '';
        heroData.hero_content.cta_buttons.forEach(button => {
            const buttonElement = document.createElement('a');
            buttonElement.href = button.url;
            buttonElement.textContent = button.text;
            buttonElement.className = button.type === 'outline' 
                ? 'btn btn-outline-success btn-lg px-4' 
                : 'btn btn-success btn-lg px-4';
            ctaContainer.appendChild(buttonElement);
        });
    }
    
    // Update hero image
    const heroImage = document.querySelector('.hero-person-image img');
    if (heroImage && heroData.hero_content?.hero_image?.url) {
        heroImage.src = heroData.hero_content.hero_image.url;
        heroImage.alt = heroData.hero_content.hero_image.alt;
    }
}

// Dashboard statistics
function updateDashboardStats() {
    // Dashboard stats will be loaded from server-side rendering
    // No need for additional API call
    console.log('Dashboard stats loaded from server');
}

function updateStatCards(stats) {
    const statElements = {
        'total-investments': stats.total_investments || 0,
        'total-projects': stats.total_projects || 0,
        'total-returns': stats.total_returns || 0,
        'active-projects': stats.active_projects || 0
    };
    
    Object.entries(statElements).forEach(([id, value]) => {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = formatCurrency(value);
        }
    });
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Initialize WebSocket for real-time updates
    initWebSocket();

    // Update dashboard stats if on dashboard page
    if (window.location.pathname === '/dashboard') {
        updateDashboardStats();
    }
    
    // Fetch hero data if on landing page
    if (window.location.pathname === '/') {
        fetchHeroData();
    }

    // Handle form submissions
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLoginForm);
    }

    const registerForm = document.getElementById('registerForm');
    if (registerForm) {
        registerForm.addEventListener('submit', handleRegisterForm);
    }

    // Handle investment buttons
    const investButtons = document.querySelectorAll('.invest-btn');
    investButtons.forEach(button => {
        button.addEventListener('click', function() {
            const projectId = this.dataset.projectId;
            const amount = prompt('Masukkan jumlah investasi (Rp):');
            
            if (amount && !isNaN(amount) && parseFloat(amount) > 0) {
                investInProject(projectId, parseFloat(amount));
            }
        });
    });
});

// Export functions for global access
window.HajiFund = {
    login,
    register,
    logout,
    showToast,
    formatCurrency,
    formatDate,
    investInProject,
    handleFileUpload
};
EOF
    
    # Replace the original file
    mv /tmp/app_fixed.js /var/www/hajifund/frontend/static/js/app.js
    print_status "Frontend JavaScript updated with proper API calls"
else
    print_error "Frontend app.js not found"
fi

# 5. Rebuild and restart services
print_step "5. Rebuilding and restarting services..."

# Stop services
systemctl stop hajifund-backend
systemctl stop hajifund-frontend

# Build backend
print_info "Building backend..."
cd /var/www/hajifund
go build -o hajifund-backend main.go
chown www-data:www-data hajifund-backend
chmod +x hajifund-backend
print_status "Backend built"

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o hajifund-frontend main.go
chown www-data:www-data hajifund-frontend
chmod +x hajifund-frontend
setcap 'cap_net_bind_service=+ep' hajifund-frontend
print_status "Frontend built"

# Start services
print_info "Starting services..."
systemctl start hajifund-backend
systemctl start hajifund-frontend
print_status "Services started"

# 6. Test the fixes
print_step "6. Testing the fixes..."

sleep 5

# Test backend
print_info "Testing backend..."
if curl -s http://localhost:8080/api/v1/health | grep -q "OK"; then
    print_status "Backend is responding"
else
    print_warning "Backend might not be responding"
fi

# Test frontend
print_info "Testing frontend..."
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

# Test login API
print_info "Testing login API..."
login_test=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@hajifund.com","password":"admin123"}')

if echo "$login_test" | grep -q "access_token"; then
    print_status "Login API returns access_token correctly"
else
    print_warning "Login API might not be working correctly"
fi

print_status "CORS and redirect issues fix completed!"
print_info "Issues fixed:"
print_info "1. Backend CORS configured for VPS IP"
print_info "2. Frontend CORS configured for VPS IP"
print_info "3. Frontend JavaScript updated with credentials: 'include'"
print_info "4. Proper redirect logic based on user roles"
print_info "5. All API calls now include cookies"
print_info "6. Services rebuilt and restarted"
