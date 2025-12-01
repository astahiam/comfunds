#!/bin/bash

# Fix Auth Token and JavaScript Issues
# This script fixes auth token not passing and unwanted JavaScript execution

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

print_step "Fixing Auth Token and JavaScript Issues"

# 1. Fix backend cookie settings for auth token
print_step "1. Fixing backend cookie settings for auth token..."

# Check if backend main.go has proper cookie settings
if [ -f "/var/www/hajifund/main.go" ]; then
    print_info "Checking backend cookie configuration..."
    
    # Check if cookie domain is set correctly
    if grep -q "CookieDomain.*103.103.20.68" /var/www/hajifund/main.go; then
        print_status "Cookie domain is set to VPS IP"
    else
        print_warning "Cookie domain might not be set correctly"
        
        # Try to fix cookie domain
        if grep -q "CookieDomain" /var/www/hajifund/main.go; then
            print_info "Updating cookie domain to VPS IP..."
            sed -i 's/CookieDomain:.*/CookieDomain: "103.103.20.68",/g' /var/www/hajifund/main.go
            print_status "Cookie domain updated"
        else
            print_warning "CookieDomain not found in backend code"
        fi
    fi
    
    # Check if cookie path is set correctly
    if grep -q "CookiePath.*/" /var/www/hajifund/main.go; then
        print_status "Cookie path is set correctly"
    else
        print_warning "Cookie path might not be set correctly"
        
        # Try to fix cookie path
        if grep -q "CookiePath" /var/www/hajifund/main.go; then
            print_info "Updating cookie path..."
            sed -i 's/CookiePath:.*/CookiePath: "\/",/g' /var/www/hajifund/main.go
            print_status "Cookie path updated"
        else
            print_warning "CookiePath not found in backend code"
        fi
    fi
    
    # Check if cookie secure is set correctly for HTTP
    if grep -q "CookieSecure.*false" /var/www/hajifund/main.go; then
        print_status "Cookie secure is set to false (correct for HTTP)"
    else
        print_warning "Cookie secure might not be set correctly"
        
        # Try to fix cookie secure
        if grep -q "CookieSecure" /var/www/hajifund/main.go; then
            print_info "Updating cookie secure setting..."
            sed -i 's/CookieSecure:.*/CookieSecure: false,/g' /var/www/hajifund/main.go
            print_status "Cookie secure updated"
        else
            print_warning "CookieSecure not found in backend code"
        fi
    fi
    
    # Check if cookie same site is set correctly
    if grep -q "CookieSameSite.*http.SameSiteLaxMode" /var/www/hajifund/main.go; then
        print_status "Cookie same site is set correctly"
    else
        print_warning "Cookie same site might not be set correctly"
        
        # Try to fix cookie same site
        if grep -q "CookieSameSite" /var/www/hajifund/main.go; then
            print_info "Updating cookie same site setting..."
            sed -i 's/CookieSameSite:.*/CookieSameSite: http.SameSiteLaxMode,/g' /var/www/hajifund/main.go
            print_status "Cookie same site updated"
        else
            print_warning "CookieSameSite not found in backend code"
        fi
    fi
else
    print_error "Backend main.go not found"
fi

# 2. Fix frontend API configuration
print_step "2. Fixing frontend API configuration..."

# Update frontend .env with correct API base URL
cat > /var/www/hajifund/frontend/.env << 'EOF'
PORT=80
API_BASE_URL=http://103.103.20.68:8080
BACKEND_URL=http://103.103.20.68:8080
FRONTEND_URL=http://103.103.20.68
EOF

print_status "Frontend .env updated with correct API base URL"

# 3. Fix frontend login page JavaScript
print_step "3. Fixing frontend login page JavaScript..."

if [ -f "/var/www/hajifund/frontend/views/auth/login.html" ]; then
    print_info "Updating login page JavaScript..."
    
    # Create a fixed version of the login page
    cat > /tmp/login_fixed.html << 'EOF'
{{ define "auth/login" }}
<div class="container-fluid">
    <div class="row min-vh-100">
        <!-- Left Side - Branding -->
        <div class="col-lg-6 d-none d-lg-block bg-gradient-primary d-flex align-items-center justify-content-center" style="position: sticky; top: 0; height: 100vh;">
            <div class="text-center text-white">
                <div class="mb-4">
                    <div class="kaaba-icon mx-auto mb-3" style="width: 80px; height: 80px;">
                        <i class="fas fa-kaaba text-white" style="font-size: 2.5rem;"></i>
                    </div>
                    <h1 class="display-4 fw-bold mb-3">Hajifund</h1>
                    <p class="lead mb-4">Solusi Terbaik Crowdfunding Berbasis Syariah</p>
                    <div class="d-flex justify-content-center gap-4">
                        <div class="text-center">
                            <div class="h3 mb-1">1.2K+</div>
                            <small>Investor Aktif</small>
                        </div>
                        <div class="text-center">
                            <div class="h3 mb-1">350+</div>
                            <small>UMKM Terdanai</small>
                        </div>
                        <div class="text-center">
                            <div class="h3 mb-1">Rp 2.5M+</div>
                            <small>Total Pendanaan</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Side - Login Form -->
        <div class="col-lg-6 d-flex align-items-center justify-content-center p-5" style="min-height: 100vh;">
            <div class="w-100" style="max-width: 400px;">
                <!-- Mobile Logo -->
                <div class="text-center mb-4 d-lg-none">
                    <div class="kaaba-icon mx-auto mb-2">
                        <i class="fas fa-kaaba text-success"></i>
                    </div>
                    <h3 class="fw-bold text-success">Hajifund</h3>
                </div>

                <h2 class="fw-bold mb-1">Selamat Datang</h2>
                <p class="text-muted mb-4">Masuk ke akun Anda untuk melanjutkan</p>

                <!-- Login Form -->
                <form id="loginForm" class="needs-validation" novalidate>
                    <div class="mb-3">
                        <label for="email" class="form-label">Email</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="fas fa-envelope text-muted"></i>
                            </span>
                            <input type="email" class="form-control" id="email" name="email" required>
                            <div class="invalid-feedback">
                                Email tidak valid
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label for="password" class="form-label">Password</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="fas fa-lock text-muted"></i>
                            </span>
                            <input type="password" class="form-control" id="password" name="password" required>
                            <button class="btn btn-outline-secondary" type="button" id="togglePassword">
                                <i class="fas fa-eye"></i>
                            </button>
                            <div class="invalid-feedback">
                                Password harus diisi
                            </div>
                        </div>
                    </div>

                    <div class="mb-3 form-check">
                        <input type="checkbox" class="form-check-input" id="rememberMe">
                        <label class="form-check-label" for="rememberMe">
                            Ingat saya
                        </label>
                    </div>

                    <button type="submit" class="btn btn-success w-100 mb-3" id="submitBtn">
                        <i class="fas fa-sign-in-alt me-2"></i>Masuk
                    </button>
                </form>

                <!-- Demo Accounts -->
                <div class="card border-0 bg-light mb-4">
                    <div class="card-body p-3">
                        <h6 class="card-title text-muted mb-2">Demo Accounts:</h6>
                        <div class="row g-2">
                            <div class="col-6">
                                <button class="btn btn-outline-primary btn-sm w-100" onclick="fillDemoUser()">
                                    <i class="fas fa-user me-1"></i>Member
                                </button>
                            </div>
                            <div class="col-6">
                                <button class="btn btn-outline-warning btn-sm w-100" onclick="fillDemoAdmin()">
                                    <i class="fas fa-crown me-1"></i>Admin
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Links -->
                <div class="text-center">
                    <p class="text-muted">
                        Belum punya akun? 
                        <a href="/register" class="text-success fw-semibold text-decoration-none">
                            Daftar sekarang
                        </a>
                    </p>
                    <a href="#" class="text-muted text-decoration-none small">
                        <i class="fas fa-key me-1"></i>Lupa password?
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// Global variables for login state
let isLoggedIn = false;
let currentUser = null;

// Check login status on page load
document.addEventListener('DOMContentLoaded', function() {
    checkLoginStatus();
    setupLoginForm();
});

// Function to check if user is already logged in
async function checkLoginStatus() {
    try {
        const response = await fetch('/api/v1/user/profile', {
            credentials: 'include'
        });
        
        if (response.ok) {
            const result = await response.json();
            if (result.status === 'success') {
                // User is already logged in, redirect to dashboard
                currentUser = result.data;
                isLoggedIn = true;
                
                console.log('User already logged in:', currentUser);
                
                // Redirect based on role
                if (currentUser.roles && currentUser.roles.includes('admin')) {
                    window.location.href = '/admin';
                } else {
                    window.location.href = '/dashboard';
                }
            }
        }
    } catch (error) {
        console.log('User not logged in or error checking auth status:', error);
        isLoggedIn = false;
    }
}

// Function to setup login form
function setupLoginForm() {
    const form = document.getElementById('loginForm');
    const togglePassword = document.getElementById('togglePassword');
    const passwordInput = document.getElementById('password');
    const submitBtn = document.getElementById('submitBtn');

    // Toggle password visibility
    togglePassword.addEventListener('click', function() {
        const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
        passwordInput.setAttribute('type', type);
        
        const icon = this.querySelector('i');
        icon.classList.toggle('fa-eye');
        icon.classList.toggle('fa-eye-slash');
    });

    // Form submission with proper redirect handling
    form.addEventListener('submit', async function(e) {
        e.preventDefault();
        
        // Prevent double submission
        if (submitBtn.disabled) {
            console.log('Form already submitting, ignoring duplicate submission');
            return;
        }
        
        // Reset validation
        form.classList.remove('was-validated');
        
        // Validate form
        if (!form.checkValidity()) {
            e.stopPropagation();
            form.classList.add('was-validated');
            return;
        }

        // Disable submit button and show loading state
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Memproses...';
        submitBtn.disabled = true;

        try {
            const formData = new FormData(form);
            const loginData = {
                email: formData.get('email'),
                password: formData.get('password')
            };

            console.log('Submitting login form...', loginData.email);

            const response = await fetch('/api/v1/auth/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'include', // CRITICAL: Include cookies
                body: JSON.stringify(loginData)
            });

            console.log('Login response status:', response.status);

            const result = await response.json();
            console.log('Login response:', result);

            if (result.status === 'success') {
                // Show success message
                showToast('Login berhasil! Mengalihkan...', 'success');
                
                // Set login state
                isLoggedIn = true;
                currentUser = result.data.user;
                
                // Wait a moment then redirect
                setTimeout(() => {
                    // Redirect based on role
                    if (currentUser && currentUser.roles && currentUser.roles.includes('admin')) {
                        window.location.href = '/admin';
                    } else {
                        window.location.href = '/dashboard';
                    }
                }, 1000);
            } else {
                showToast(result.message || 'Login gagal', 'error');
            }
        } catch (error) {
            console.error('Login error:', error);
            showToast('Terjadi kesalahan saat login', 'error');
        } finally {
            // Re-enable submit button after a delay
            setTimeout(() => {
                submitBtn.innerHTML = originalText;
                submitBtn.disabled = false;
            }, 2000);
        }
    });

    // Demo account functions
    window.fillDemoUser = function() {
        document.getElementById('email').value = 'demo-business@example.com';
        document.getElementById('password').value = 'Password123!';
    };

    window.fillDemoAdmin = function() {
        document.getElementById('email').value = 'admin@hajifund.com';
        document.getElementById('password').value = 'admin123';
    };
}

// Function to show toast messages
function showToast(message, type = 'info') {
    // Create toast element if it doesn't exist
    let toast = document.getElementById('toast');
    if (!toast) {
        toast = document.createElement('div');
        toast.id = 'toast';
        toast.className = 'toast';
        toast.setAttribute('role', 'alert');
        toast.setAttribute('aria-live', 'assertive');
        toast.setAttribute('aria-atomic', 'true');
        
        toast.innerHTML = `
            <div class="toast-header">
                <i class="fas fa-info-circle text-primary me-2"></i>
                <strong class="me-auto">HajiFund</strong>
                <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
            </div>
            <div class="toast-body" id="toastMessage">
                <!-- Toast message will be inserted here -->
            </div>
        `;
        
        document.body.appendChild(toast);
    }
    
    const toastMessage = document.getElementById('toastMessage');
    toastMessage.textContent = message;
    
    // Update toast icon and color based on type
    const toastHeader = toast.querySelector('.toast-header');
    const icon = toastHeader.querySelector('i');
    
    icon.className = type === 'success' ? 'fas fa-check-circle text-success me-2' :
                    type === 'error' ? 'fas fa-exclamation-circle text-danger me-2' :
                    'fas fa-info-circle text-primary me-2';
    
    // Show toast
    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();
}
</script>

<style>
/* Fix for login page layout */
.container-fluid {
    padding: 0;
}

/* Ensure the left sidebar stays in viewport while allowing right side to scroll */
@media (min-width: 992px) {
    .bg-gradient-primary {
        position: sticky;
        top: 0;
        max-height: 100vh;
        overflow: hidden;
    }
    
    /* Allow the right side to scroll naturally */
    .row.min-vh-100 {
        display: flex;
        flex-wrap: nowrap;
    }
}

/* Ensure form content doesn't get cut off on smaller screens */
@media (max-width: 991px) {
    .col-lg-6.d-flex {
        min-height: auto !important;
        padding: 2rem 1rem !important;
    }
}

/* Override any conflicting vh-100 styles */
.row.min-vh-100 {
    min-height: 100vh;
    height: auto !important;
}

/* Prevent button from being clicked multiple times */
#submitBtn:disabled {
    opacity: 0.7;
    cursor: not-allowed;
}
</style>
{{ end }}
EOF
    
    # Replace the original file
    mv /tmp/login_fixed.html /var/www/hajifund/frontend/views/auth/login.html
    print_status "Login page JavaScript fixed"
else
    print_error "Login page not found"
fi

# 4. Remove unwanted JavaScript functions
print_step "4. Removing unwanted JavaScript functions..."

# Check if there are any updateProjectProgress functions in the codebase
print_info "Searching for updateProjectProgress function..."
if find /var/www/hajifund/frontend -name "*.html" -exec grep -l "updateProjectProgress" {} \; 2>/dev/null; then
    print_warning "Found updateProjectProgress function in HTML files"
    
    # Remove or comment out the function
    find /var/www/hajifund/frontend -name "*.html" -exec sed -i 's/updateProjectProgress/\/\/ updateProjectProgress/g' {} \;
    print_status "updateProjectProgress function disabled"
else
    print_status "No updateProjectProgress function found"
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
if curl -s http://localhost:8080/api/v1/health | grep -q "ok"; then
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

if echo "$login_test" | grep -q "auth_token"; then
    print_status "Login API returns auth_token correctly"
else
    print_warning "Login API might not be working correctly"
fi

print_status "Auth token and JavaScript issues fix completed!"
print_info "Issues fixed:"
print_info "1. Auth token should now pass to frontend"
print_info "2. updateProjectProgress function should not run after login"
print_info "3. Cookie settings updated for proper session handling"
print_info "4. Frontend API configuration updated"
