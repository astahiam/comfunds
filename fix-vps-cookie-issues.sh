#!/bin/bash

# Fix VPS Cookie Issues (Ubuntu vs macOS)
# This script fixes cookie handling differences between macOS local and Ubuntu VPS

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

print_step "Fixing VPS Cookie Issues (Ubuntu vs macOS)"

# 1. Check current cookie configuration
print_step "1. Checking current cookie configuration..."

print_info "macOS vs Ubuntu differences:"
print_info "macOS: localhost cookies work automatically"
print_info "Ubuntu VPS: IP address cookies need special configuration"

# Check if cookies are being set
print_info "Checking if cookies are being set by backend..."
if curl -s -I http://103.103.20.68:8080/api/v1/health | grep -i "set-cookie"; then
    print_status "Backend is setting cookies"
else
    print_warning "Backend might not be setting cookies"
fi

# 2. Fix backend cookie configuration for VPS
print_step "2. Fixing backend cookie configuration for VPS..."

if [ -f "/var/www/hajifund/main.go" ]; then
    print_info "Updating backend cookie settings for Ubuntu VPS..."
    
    # Check current cookie configuration
    print_info "Current backend cookie configuration:"
    grep -n "Cookie" /var/www/hajifund/main.go || print_warning "No cookie configuration found"
    
    # Update cookie domain to VPS IP
    sed -i 's/CookieDomain:.*/CookieDomain: "103.103.20.68",/g' /var/www/hajifund/main.go 2>/dev/null || true
    
    # Update cookie path
    sed -i 's/CookiePath:.*/CookiePath: "\/",/g' /var/www/hajifund/main.go 2>/dev/null || true
    
    # Update cookie secure (false for HTTP)
    sed -i 's/CookieSecure:.*/CookieSecure: false,/g' /var/www/hajifund/main.go 2>/dev/null || true
    
    # Update cookie same site
    sed -i 's/CookieSameSite:.*/CookieSameSite: http.SameSiteLaxMode,/g' /var/www/hajifund/main.go 2>/dev/null || true
    
    print_status "Backend cookie configuration updated for VPS"
else
    print_error "Backend main.go not found"
fi

# 3. Fix frontend cookie handling for VPS
print_step "3. Fixing frontend cookie handling for VPS..."

# Update frontend CORS to allow credentials
if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Updating frontend CORS for VPS cookies..."
    
    # Update CORS origins to include VPS IP
    sed -i 's/AllowOrigins: "http:\/\/localhost:8080"/AllowOrigins: "http:\/\/103.103.20.68:8080,http:\/\/localhost:8080"/g' /var/www/hajifund/frontend/main.go
    
    # Ensure AllowCredentials is set
    if ! grep -q "AllowCredentials" /var/www/hajifund/frontend/main.go; then
        sed -i '/AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",/a\\t\tAllowCredentials: true,' /var/www/hajifund/frontend/main.go
    fi
    
    print_status "Frontend CORS updated for VPS cookies"
else
    print_error "Frontend main.go not found"
fi

# 4. Fix JavaScript cookie handling for VPS
print_step "4. Fixing JavaScript cookie handling for VPS..."

if [ -f "/var/www/hajifund/frontend/static/js/app.js" ]; then
    print_info "Updating JavaScript cookie handling for VPS..."
    
    # Create a fixed version of app.js with proper VPS cookie handling
    cat > /tmp/app_vps_fixed.js << 'EOF'
// HajiFund Frontend JavaScript - VPS Version

// Global variables for authentication state
let isLoggedIn = false;
let currentUser = null;

// Utility functions
function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    const toastBody = document.getElementById('toast-body');
    
    if (toast && toastBody) {
        toastBody.textContent = message;
        toast.className = `toast toast-${type}`;
        
        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();
    }
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

// VPS-specific cookie handling
function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) {
        return parts.pop().split(';').shift();
    }
    return null;
}

function setCookie(name, value, days = 7) {
    const expires = new Date();
    expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000));
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;domain=103.103.20.68;SameSite=Lax`;
}

function deleteCookie(name) {
    document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;domain=103.103.20.68`;
}

// Authentication state management
function checkAuthStatus() {
    console.log('🔍 Checking authentication status...');
    console.log('🔍 Document cookies:', document.cookie);
    
    const authToken = getCookie('auth_token');
    console.log('🔍 Auth token from cookie:', authToken);
    
    if (authToken && authToken !== 'null' && authToken !== 'undefined') {
        isLoggedIn = true;
        console.log('✅ User is logged in');
        
        // Try to decode JWT token to get user info
        try {
            const payload = JSON.parse(atob(authToken.split('.')[1]));
            currentUser = {
                id: payload.user_id,
                email: payload.email,
                name: payload.name,
                roles: payload.roles || []
            };
            console.log('✅ User info:', currentUser);
        } catch (error) {
            console.log('❌ Could not decode JWT token:', error);
        }
        
        return true;
    } else {
        isLoggedIn = false;
        currentUser = null;
        console.log('❌ User is not logged in');
        return false;
    }
}

function updateUserMenu() {
    console.log('🔄 Updating user menu...');
    
    const loginMenu = document.getElementById('login-menu');
    const userMenu = document.getElementById('user-menu');
    const userProfile = document.getElementById('user-profile');
    const userDropdown = document.getElementById('user-dropdown');
    
    if (isLoggedIn && currentUser) {
        console.log('✅ Showing user menu for:', currentUser.name);
        
        // Show user menu, hide login menu
        if (loginMenu) loginMenu.style.display = 'none';
        if (userMenu) userMenu.style.display = 'block';
        
        // Update user profile info
        if (userProfile) {
            userProfile.textContent = currentUser.name || currentUser.email;
        }
        
        // Update user dropdown
        if (userDropdown) {
            const userName = userDropdown.querySelector('.user-name');
            const userEmail = userDropdown.querySelector('.user-email');
            
            if (userName) userName.textContent = currentUser.name || 'User';
            if (userEmail) userEmail.textContent = currentUser.email;
        }
    } else {
        console.log('❌ Showing login menu');
        
        // Show login menu, hide user menu
        if (loginMenu) loginMenu.style.display = 'block';
        if (userMenu) userMenu.style.display = 'none';
    }
}

function redirectIfNeeded() {
    const currentPath = window.location.pathname;
    console.log('🔄 Checking redirect for path:', currentPath);
    
    // If on login/register page and logged in, redirect to dashboard
    if (isLoggedIn && (currentPath === '/login' || currentPath === '/register')) {
        console.log('✅ User is logged in, redirecting from', currentPath, 'to dashboard');
        
        // Show loading message
        showToast('Anda sudah login, mengalihkan ke dashboard...', 'info');
        
        setTimeout(() => {
            if (currentUser && currentUser.roles && currentUser.roles.includes('admin')) {
                window.location.href = '/admin';
            } else {
                window.location.href = '/dashboard';
            }
        }, 1000);
    }
    
    // If on protected page and not logged in, redirect to login
    if (!isLoggedIn && (currentPath === '/dashboard' || currentPath === '/profile' || currentPath === '/investments')) {
        console.log('❌ User is not logged in, redirecting from', currentPath, 'to login');
        window.location.href = '/login';
    }
}

// Authentication functions
async function login(email, password) {
    try {
        console.log('🔄 Attempting login for:', email);
        
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include', // CRITICAL: Include cookies
            body: JSON.stringify({ email, password })
        });

        console.log('🔄 Login response status:', response.status);
        
        const data = await response.json();
        console.log('🔄 Login response data:', data);

        if (data.status === 'success') {
            showToast('Login berhasil!', 'success');
            
            // Update auth state
            checkAuthStatus();
            updateUserMenu();
            
            // Redirect based on user role
            setTimeout(() => {
                if (currentUser && currentUser.roles && currentUser.roles.includes('admin')) {
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

async function register(formData) {
    try {
        console.log('🔄 Attempting registration for:', formData.email);
        
        const response = await fetch('/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include', // CRITICAL: Include cookies
            body: JSON.stringify(formData)
        });

        console.log('🔄 Register response status:', response.status);
        
        const data = await response.json();
        console.log('🔄 Register response data:', data);

        if (data.status === 'success') {
            showToast('Registrasi berhasil!', 'success');
            
            // Update auth state
            checkAuthStatus();
            updateUserMenu();
            
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

async function logout() {
    try {
        console.log('🔄 Attempting logout...');
        
        const response = await fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include' // CRITICAL: Include cookies
        });

        const data = await response.json();
        console.log('🔄 Logout response:', data);

        if (data.status === 'success') {
            showToast('Logout berhasil!', 'success');
        }
        
        // Clear auth state
        isLoggedIn = false;
        currentUser = null;
        updateUserMenu();
        
        setTimeout(() => {
            window.location.href = '/';
        }, 1000);
    } catch (error) {
        console.error('Logout error:', error);
        // Force logout even if API call fails
        isLoggedIn = false;
        currentUser = null;
        updateUserMenu();
        window.location.href = '/';
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
    console.log('🚀 DOM loaded, checking authentication state...');
    console.log('🌐 Current URL:', window.location.href);
    console.log('🍪 Document cookies:', document.cookie);
    
    // Check authentication status first
    checkAuthStatus();
    updateUserMenu();
    redirectIfNeeded();
    
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
    
    // Handle logout buttons
    const logoutButtons = document.querySelectorAll('.logout-btn');
    logoutButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            logout();
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
    handleFileUpload,
    checkAuthStatus,
    updateUserMenu,
    redirectIfNeeded,
    getCookie,
    setCookie,
    deleteCookie
};
EOF
    
    # Replace the original file
    mv /tmp/app_vps_fixed.js /var/www/hajifund/frontend/static/js/app.js
    print_status "JavaScript updated with VPS-specific cookie handling"
else
    print_error "Frontend app.js not found"
fi

# 5. Fix systemd service environment for VPS
print_step "5. Fixing systemd service environment for VPS..."

# Update frontend systemd service with VPS-specific settings
cat > /etc/systemd/system/hajifund-frontend.service << 'EOF'
[Unit]
Description=HajiFund Frontend Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund/frontend
ExecStart=/var/www/hajifund/frontend/hajifund-frontend
Restart=always
RestartSec=5
Environment=GIN_MODE=release
Environment=PORT=80
Environment=API_BASE_URL=http://103.103.20.68:8080
Environment=FRONTEND_URL=http://103.103.20.68
Environment=HOST=0.0.0.0
Environment=TRUSTED_PROXIES=103.103.20.68
Environment=DISABLE_CACHE=true
Environment=DEBUG=true

# VPS-specific cookie settings
Environment=COOKIE_DOMAIN=103.103.20.68
Environment=COOKIE_PATH=/
Environment=COOKIE_SECURE=false
Environment=COOKIE_SAME_SITE=Lax

[Install]
WantedBy=multi-user.target
EOF

# Update backend systemd service with VPS-specific settings
cat > /etc/systemd/system/hajifund-backend.service << 'EOF'
[Unit]
Description=HajiFund Backend Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/hajifund
ExecStart=/var/www/hajifund/hajifund-backend
Restart=always
RestartSec=5
Environment=GIN_MODE=release
Environment=PORT=8080
Environment=HOST=0.0.0.0
Environment=TRUSTED_PROXIES=103.103.20.68
Environment=ALLOWED_ORIGINS=http://103.103.20.68,http://localhost:8080
Environment=CORS_ORIGINS=http://103.103.20.68,http://localhost:8080

# VPS-specific cookie settings
Environment=COOKIE_DOMAIN=103.103.20.68
Environment=COOKIE_PATH=/
Environment=COOKIE_SECURE=false
Environment=COOKIE_SAME_SITE=Lax

[Install]
WantedBy=multi-user.target
EOF

print_status "Systemd services updated with VPS-specific cookie settings"

# 6. Rebuild and restart services
print_step "6. Rebuilding and restarting services..."

# Stop services
systemctl stop hajifund-backend
systemctl stop hajifund-frontend

# Reload systemd
systemctl daemon-reload

# Build applications
print_info "Building applications..."
cd /var/www/hajifund
go build -o hajifund-backend main.go
chown www-data:www-data hajifund-backend
chmod +x hajifund-backend

cd /var/www/hajifund/frontend
go build -o hajifund-frontend main.go
chown www-data:www-data hajifund-frontend
chmod +x hajifund-frontend
setcap 'cap_net_bind_service=+ep' hajifund-frontend

# Start services
print_info "Starting services..."
systemctl start hajifund-backend
systemctl start hajifund-frontend
print_status "Services restarted with VPS-specific settings"

# 7. Test cookie handling
print_step "7. Testing cookie handling..."

sleep 5

# Test cookie setting
print_info "Testing cookie setting..."
cookie_test=$(curl -s -I -X POST -H "Content-Type: application/json" -d '{"email":"admin@hajifund.com","password":"admin123"}' http://103.103.20.68:8080/api/v1/auth/login)

if echo "$cookie_test" | grep -i "set-cookie"; then
    print_status "Backend is setting cookies"
    echo "$cookie_test" | grep -i "set-cookie"
else
    print_warning "Backend might not be setting cookies"
fi

# Test frontend
print_info "Testing frontend..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

print_status "VPS cookie issues fix completed!"
print_info "Issues addressed:"
print_info "1. Backend cookie domain set to VPS IP"
print_info "2. Frontend CORS updated for VPS cookies"
print_info "3. JavaScript updated with VPS-specific cookie handling"
print_info "4. Systemd services updated with VPS environment"
print_info "5. Services rebuilt and restarted"

print_info "Key differences fixed:"
print_info "macOS: localhost cookies work automatically"
print_info "Ubuntu VPS: IP address cookies need special configuration"
print_info "VPS: Cookie domain must be set to VPS IP"
print_info "VPS: CORS must allow credentials"
print_info "VPS: JavaScript must use credentials: 'include'"

print_info "Test your application now:"
print_info "1. Open browser developer tools"
print_info "2. Check Application tab > Cookies"
print_info "3. Check Console for authentication logs"
print_info "4. Verify auth_token cookie is set"
print_info "5. Test login/logout functionality"
