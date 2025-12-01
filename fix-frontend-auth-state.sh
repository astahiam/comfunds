#!/bin/bash

# Fix Frontend Authentication State
# This script fixes the frontend JavaScript to properly handle auth_token and update UI

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

print_step "Fixing Frontend Authentication State"

# 1. Fix frontend JavaScript to check auth_token on page load
print_step "1. Fixing frontend JavaScript authentication state..."

if [ -f "/var/www/hajifund/frontend/static/js/app.js" ]; then
    print_info "Updating frontend JavaScript for authentication state..."
    
    # Create a fixed version of app.js with proper auth state handling
    cat > /tmp/app_fixed.js << 'EOF'
// HajiFund Frontend JavaScript

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

// Authentication state management
function checkAuthStatus() {
    const authToken = document.cookie
        .split('; ')
        .find(row => row.startsWith('auth_token='));
    
    if (authToken && authToken.split('=')[1] !== '') {
        isLoggedIn = true;
        console.log('User is logged in');
        
        // Try to decode JWT token to get user info
        try {
            const token = authToken.split('=')[1];
            const payload = JSON.parse(atob(token.split('.')[1]));
            currentUser = {
                id: payload.user_id,
                email: payload.email,
                name: payload.name,
                roles: payload.roles || []
            };
            console.log('User info:', currentUser);
        } catch (error) {
            console.log('Could not decode JWT token:', error);
        }
        
        return true;
    } else {
        isLoggedIn = false;
        currentUser = null;
        console.log('User is not logged in');
        return false;
    }
}

function updateUserMenu() {
    const loginMenu = document.getElementById('login-menu');
    const userMenu = document.getElementById('user-menu');
    const userProfile = document.getElementById('user-profile');
    const userDropdown = document.getElementById('user-dropdown');
    
    if (isLoggedIn && currentUser) {
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
        
        console.log('User menu updated for logged in user');
    } else {
        // Show login menu, hide user menu
        if (loginMenu) loginMenu.style.display = 'block';
        if (userMenu) userMenu.style.display = 'none';
        
        console.log('User menu updated for logged out user');
    }
}

function redirectIfNeeded() {
    const currentPath = window.location.pathname;
    
    // If on login/register page and logged in, redirect to dashboard
    if (isLoggedIn && (currentPath === '/login' || currentPath === '/register')) {
        console.log('User is logged in, redirecting from', currentPath, 'to dashboard');
        
        // Show loading message
        showToast('Anda sudah login, mengalihkan ke dashboard...', 'info');
        
        setTimeout(() => {
            window.location.href = '/dashboard';
        }, 1000);
    }
    
    // If on protected page and not logged in, redirect to login
    if (!isLoggedIn && (currentPath === '/dashboard' || currentPath === '/profile' || currentPath === '/investments')) {
        console.log('User is not logged in, redirecting from', currentPath, 'to login');
        window.location.href = '/login';
    }
}

// Authentication functions
async function login(email, password) {
    try {
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include',
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

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
        const response = await fetch('/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include',
            body: JSON.stringify(formData)
        });

        const data = await response.json();

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
        const response = await fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include'
        });

        const data = await response.json();

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
            credentials: 'include',
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
            credentials: 'include'
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
            credentials: 'include'
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
    console.log('DOM loaded, checking authentication state...');
    
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
    redirectIfNeeded
};
EOF
    
    # Replace the original file
    mv /tmp/app_fixed.js /var/www/hajifund/frontend/static/js/app.js
    print_status "Frontend JavaScript updated with proper authentication state handling"
else
    print_error "Frontend app.js not found"
fi

# 2. Update base template to include proper user menu
print_step "2. Updating base template for user menu..."

if [ -f "/var/www/hajifund/frontend/views/base.html" ]; then
    print_info "Updating base template with proper user menu..."
    
    # Check if base template has proper user menu structure
    if grep -q "user-menu" /var/www/hajifund/frontend/views/base.html; then
        print_status "Base template already has user menu"
    else
        print_warning "Base template might not have proper user menu structure"
        print_info "You may need to update the base template manually to include:"
        print_info "- login-menu (for logged out users)"
        print_info "- user-menu (for logged in users)"
        print_info "- user-dropdown (for user profile)"
    fi
else
    print_error "Base template not found"
fi

# 3. Rebuild and restart frontend
print_step "3. Rebuilding and restarting frontend..."

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

# 4. Test the fix
print_step "4. Testing the fix..."

sleep 3

# Test frontend
print_info "Testing frontend..."
if curl -s http://localhost/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

print_status "Frontend authentication state fix completed!"
print_info "Issues addressed:"
print_info "1. JavaScript now checks auth_token on page load"
print_info "2. User menu updates based on login status"
print_info "3. Automatic redirects for logged in users"
print_info "4. Proper authentication state management"
print_info "5. Frontend rebuilt and restarted"

print_info "Test your application now:"
print_info "1. Visit http://103.103.20.68/"
print_info "2. Check if user menu shows when logged in"
print_info "3. Check if redirects work properly"
print_info "4. Check browser console for authentication logs"
