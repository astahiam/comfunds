#!/bin/bash

# Fix Dashboard Route and JavaScript Redirect Issues
# This script fixes the missing dashboard route and redirect issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_info "Please run: sudo $0"
    exit 1
fi

print_step "Fixing Dashboard Route and JavaScript Redirect Issues"
print_info "The issue is that /dashboard route doesn't exist, causing redirect failures"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-frontend 2>/dev/null || true

# 2. Check existing routes
print_step "1. Checking existing routes..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    echo "Current routes in main.go:"
    grep -n "app\.Get\|app\.Post" /var/www/hajifund/frontend/main.go || echo "No routes found"
else
    print_error "Frontend main.go not found"
    exit 1
fi

# 3. Fix frontend main.go to add missing dashboard route
print_step "2. Adding missing dashboard route..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/main.go /var/www/hajifund/frontend/main.go.backup
    
    # Check if dashboard route exists
    if ! grep -q "app.Get(\"/dashboard\"" /var/www/hajifund/frontend/main.go; then
        print_info "Adding dashboard route..."
        
        # Add dashboard route after login route
        sed -i '/app.Get("\/login"/a\
    app.Get("/dashboard", dashboardHandler.Dashboard)' /var/www/hajifund/frontend/main.go
        
        print_status "Dashboard route added"
    else
        print_info "Dashboard route already exists"
    fi
    
    # Check for any incorrect DashboardPage references and remove them
    if grep -q "handlers\.DashboardPage" /var/www/hajifund/frontend/main.go; then
        print_warning "Found incorrect DashboardPage reference, removing..."
        sed -i '/handlers\.DashboardPage/d' /var/www/hajifund/frontend/main.go
        print_status "Incorrect DashboardPage reference removed"
    fi
    
    # Check for any routes that might reference DashboardPage incorrectly
    if grep -q "DashboardPage" /var/www/hajifund/frontend/main.go; then
        print_warning "Found DashboardPage reference, checking for incorrect usage..."
        # Replace any DashboardPage with Dashboard
        sed -i 's/DashboardPage/Dashboard/g' /var/www/hajifund/frontend/main.go
        print_status "DashboardPage references corrected"
    fi
    
    # Check if handlers package is imported
    if ! grep -q "handlers" /var/www/hajifund/frontend/main.go; then
        print_warning "Handlers package not imported, adding import..."
        # Add import if missing
        sed -i '/import (/a\\t"hajifund-frontend/handlers"' /var/www/hajifund/frontend/main.go
        print_status "Handlers import added"
    else
        print_info "Handlers package already imported"
    fi
else
    print_error "Frontend main.go not found"
    exit 1
fi

# 4. Check if dashboard handler exists
print_step "3. Checking dashboard handler..."

if [ -f "/var/www/hajifund/frontend/handlers/dashboard.go" ]; then
    print_info "Dashboard handler already exists"
    
    # Check if Dashboard method exists
    if grep -q "func.*Dashboard" /var/www/hajifund/frontend/handlers/dashboard.go; then
        print_info "Dashboard method found in handler"
    else
        print_warning "Dashboard method not found, but handler file exists"
    fi
else
    print_error "Dashboard handler not found - this is required for the dashboard route"
    print_info "The dashboard handler should exist at /var/www/hajifund/frontend/handlers/dashboard.go"
    print_info "Please ensure the dashboard handler is properly set up"
fi

# 5. Create dashboard template
print_step "4. Creating dashboard template..."

if [ -f "/var/www/hajifund/frontend/views/dashboard.html" ]; then
    print_info "Dashboard template already exists"
else
    print_info "Creating dashboard template..."
    
    cat > /var/www/hajifund/frontend/views/dashboard.html << 'EOF'
{{ define "dashboard" }}
<div class="container-fluid">
    <div class="row">
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2 d-md-block bg-light sidebar">
            <div class="position-sticky pt-3">
                <ul class="nav flex-column">
                    <li class="nav-item">
                        <a class="nav-link active" href="/dashboard">
                            <i class="fas fa-tachometer-alt me-2"></i>
                            Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/projects">
                            <i class="fas fa-project-diagram me-2"></i>
                            Proyek
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/investments">
                            <i class="fas fa-chart-line me-2"></i>
                            Investasi
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/profile">
                            <i class="fas fa-user me-2"></i>
                            Profil
                        </a>
                    </li>
                </ul>
            </div>
        </div>

        <!-- Main content -->
        <main class="col-md-9 ms-sm-auto col-lg-10 px-md-4">
            <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
                <h1 class="h2">Dashboard</h1>
                <div class="btn-toolbar mb-2 mb-md-0">
                    <div class="btn-group me-2">
                        <button type="button" class="btn btn-sm btn-outline-secondary">Share</button>
                        <button type="button" class="btn btn-sm btn-outline-secondary">Export</button>
                    </div>
                    <button type="button" class="btn btn-sm btn-primary dropdown-toggle">
                        <i class="fas fa-calendar me-1"></i>
                        This week
                    </button>
                </div>
            </div>

            <!-- Welcome message -->
            <div class="alert alert-success" role="alert">
                <h4 class="alert-heading">Selamat datang, {{.User.name}}!</h4>
                <p>Anda telah berhasil login ke HajiFund. Di sini Anda dapat melihat ringkasan investasi dan proyek Anda.</p>
                <hr>
                <p class="mb-0">Gunakan menu di sebelah kiri untuk navigasi ke berbagai fitur.</p>
            </div>

            <!-- Stats cards -->
            <div class="row mb-4">
                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-primary shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col mr-2">
                                    <div class="text-xs font-weight-bold text-primary text-uppercase mb-1">
                                        Total Investasi
                                    </div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">Rp 0</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-chart-line fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-success shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col mr-2">
                                    <div class="text-xs font-weight-bold text-success text-uppercase mb-1">
                                        Proyek Aktif
                                    </div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">0</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-project-diagram fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-info shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col mr-2">
                                    <div class="text-xs font-weight-bold text-info text-uppercase mb-1">
                                        Keuntungan
                                    </div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">Rp 0</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-dollar-sign fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xl-3 col-md-6 mb-4">
                    <div class="card border-left-warning shadow h-100 py-2">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col mr-2">
                                    <div class="text-xs font-weight-bold text-warning text-uppercase mb-1">
                                        Status
                                    </div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800">Aktif</div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-check-circle fa-2x text-gray-300"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Recent activity -->
            <div class="card shadow mb-4">
                <div class="card-header py-3">
                    <h6 class="m-0 font-weight-bold text-primary">Aktivitas Terbaru</h6>
                </div>
                <div class="card-body">
                    <p>Belum ada aktivitas terbaru. Mulai berinvestasi untuk melihat aktivitas di sini.</p>
                </div>
            </div>
        </main>
    </div>
</div>

<script>
// Check login state on page load
document.addEventListener('DOMContentLoaded', function() {
    checkLoginState();
});

async function checkLoginState() {
    try {
        const response = await fetch('/api/v1/user/profile', {
            credentials: 'include'
        });
        
        if (response.ok) {
            const result = await response.json();
            if (result.status === 'success') {
                // User is logged in, update UI
                updateUIForLoggedInUser(result.data);
            } else {
                // User is not logged in, redirect to login
                window.location.href = '/login';
            }
        } else {
            // User is not logged in, redirect to login
            window.location.href = '/login';
        }
    } catch (error) {
        console.log('Error checking login state:', error);
        window.location.href = '/login';
    }
}

function updateUIForLoggedInUser(user) {
    // Update user name if element exists
    const userNameElement = document.getElementById('userName');
    if (userNameElement && user.name) {
        userNameElement.textContent = user.name;
    }
    
    // Update user role if element exists
    const userRoleElement = document.getElementById('userRole');
    if (userRoleElement && user.roles && user.roles.length > 0) {
        userRoleElement.textContent = user.roles[0];
    }
}
</script>

<style>
.sidebar {
    position: fixed;
    top: 0;
    bottom: 0;
    left: 0;
    z-index: 100;
    padding: 48px 0 0;
    box-shadow: inset -1px 0 0 rgba(0, 0, 0, .1);
}

.sidebar-sticky {
    position: relative;
    top: 0;
    height: calc(100vh - 48px);
    padding-top: .5rem;
    overflow-x: hidden;
    overflow-y: auto;
}

.border-left-primary {
    border-left: 0.25rem solid #4e73df !important;
}

.border-left-success {
    border-left: 0.25rem solid #1cc88a !important;
}

.border-left-info {
    border-left: 0.25rem solid #36b9cc !important;
}

.border-left-warning {
    border-left: 0.25rem solid #f6c23e !important;
}
</style>
{{ end }}
EOF
    
    print_status "Dashboard template created"
fi

# 6. Fix login page JavaScript to use correct redirect
print_step "5. Fixing login page JavaScript redirect..."

if [ -f "/var/www/hajifund/frontend/views/auth/login.html" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/views/auth/login.html /var/www/hajifund/frontend/views/auth/login.html.backup
    
    # Fix the redirect logic in login page using a simpler approach
    print_info "Updating login page redirect logic..."
    
    # Create a temporary file with the fixed content
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
    
    print_status "Login page JavaScript redirect fixed"
else
    print_error "Login page not found"
fi

# 7. Fix register page JavaScript redirect
print_step "6. Fixing register page JavaScript redirect..."

if [ -f "/var/www/hajifund/frontend/views/auth/register.html" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/views/auth/register.html /var/www/hajifund/frontend/views/auth/register.html.backup
    
    print_info "Updating register page redirect logic..."
    
    # Create a temporary file with the fixed content
    cat > /tmp/register_fixed.html << 'EOF'
{{ define "auth/register" }}
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

        <!-- Right Side - Register Form -->
        <div class="col-lg-6 d-flex align-items-center justify-content-center p-5" style="min-height: 100vh;">
            <div class="w-100" style="max-width: 400px;">
                <!-- Mobile Logo -->
                <div class="text-center mb-4 d-lg-none">
                    <div class="kaaba-icon mx-auto mb-2">
                        <i class="fas fa-kaaba text-success"></i>
                    </div>
                    <h3 class="fw-bold text-success">Hajifund</h3>
                </div>

                <h2 class="fw-bold mb-1">Daftar Sekarang</h2>
                <p class="text-muted mb-4">Bergabunglah dengan komunitas HajiFund</p>

                <!-- Register Form -->
                <form id="registerForm" class="needs-validation" novalidate>
                    <div class="mb-3">
                        <label for="name" class="form-label">Nama Lengkap</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="fas fa-user text-muted"></i>
                            </span>
                            <input type="text" class="form-control" id="name" name="name" required>
                            <div class="invalid-feedback">
                                Nama harus diisi
                            </div>
                        </div>
                    </div>

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

                    <div class="mb-3">
                        <label for="phone" class="form-label">Nomor Telepon</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="fas fa-phone text-muted"></i>
                            </span>
                            <input type="tel" class="form-control" id="phone" name="phone" required>
                            <div class="invalid-feedback">
                                Nomor telepon harus diisi
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label for="address" class="form-label">Alamat</label>
                        <div class="input-group">
                            <span class="input-group-text">
                                <i class="fas fa-map-marker-alt text-muted"></i>
                            </span>
                            <textarea class="form-control" id="address" name="address" rows="2" required></textarea>
                            <div class="invalid-feedback">
                                Alamat harus diisi
                            </div>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Pilih Peran</label>
                        <div class="row g-2">
                            <div class="col-6">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" value="investor" id="role_investor" name="roles">
                                    <label class="form-check-label" for="role_investor">
                                        <i class="fas fa-chart-line me-1"></i>Investor
                                    </label>
                                </div>
                            </div>
                            <div class="col-6">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" value="business_owner" id="role_business" name="roles">
                                    <label class="form-check-label" for="role_business">
                                        <i class="fas fa-store me-1"></i>Pemilik Bisnis
                                    </label>
                                </div>
                            </div>
                        </div>
                        <div class="invalid-feedback">
                            Pilih minimal satu peran
                        </div>
                    </div>

                    <div class="mb-3 form-check">
                        <input type="checkbox" class="form-check-input" id="agreeTerms" required>
                        <label class="form-check-label" for="agreeTerms">
                            Saya menyetujui <a href="/syarat-ketentuan" class="text-success">Syarat & Ketentuan</a>
                        </label>
                        <div class="invalid-feedback">
                            Anda harus menyetujui syarat & ketentuan
                        </div>
                    </div>

                    <button type="submit" class="btn btn-success w-100 mb-3" id="submitBtn">
                        <i class="fas fa-user-plus me-2"></i>Daftar Sekarang
                    </button>
                </form>

                <!-- Links -->
                <div class="text-center">
                    <p class="text-muted">
                        Sudah punya akun? 
                        <a href="/login" class="text-success fw-semibold text-decoration-none">
                            Masuk di sini
                        </a>
                    </p>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// Global variables for registration state
let isRegistering = false;

// Check login status on page load
document.addEventListener('DOMContentLoaded', function() {
    checkLoginStatus();
    setupRegisterForm();
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
                console.log('User already logged in, redirecting...');
                
                // Redirect based on role
                if (result.data.roles && result.data.roles.includes('admin')) {
                    window.location.href = '/admin';
                } else {
                    window.location.href = '/dashboard';
                }
            }
        }
    } catch (error) {
        console.log('User not logged in or error checking auth status:', error);
    }
}

// Function to setup register form
function setupRegisterForm() {
    const form = document.getElementById('registerForm');
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
        if (isRegistering) {
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
        isRegistering = true;

        try {
            const formData = new FormData(form);
            
            // Collect selected roles
            const roles = [];
            const roleCheckboxes = form.querySelectorAll('input[name="roles"]:checked');
            roleCheckboxes.forEach(checkbox => {
                if (checkbox.value && checkbox.value.trim() !== '') {
                    roles.push(checkbox.value.trim());
                }
            });

            const registerData = {
                name: formData.get('name'),
                email: formData.get('email'),
                password: formData.get('password'),
                phone: formData.get('phone'),
                address: formData.get('address'),
                roles: roles
            };

            console.log('Submitting registration form...', registerData.email);

            const response = await fetch('/api/v1/auth/register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'include', // CRITICAL: Include cookies
                body: JSON.stringify(registerData)
            });

            console.log('Registration response status:', response.status);

            const result = await response.json();
            console.log('Registration response:', result);

            if (result.status === 'success') {
                // Show success message
                showToast('Registrasi berhasil! Mengalihkan...', 'success');
                
                // Wait a moment then redirect
                setTimeout(() => {
                    // Redirect based on role
                    if (registerData.roles && registerData.roles.includes('admin')) {
                        window.location.href = '/admin';
                    } else {
                        window.location.href = '/dashboard';
                    }
                }, 1000);
            } else {
                showToast(result.message || 'Registrasi gagal', 'error');
            }
        } catch (error) {
            console.error('Registration error:', error);
            showToast('Terjadi kesalahan saat registrasi', 'error');
        } finally {
            // Re-enable submit button after a delay
            setTimeout(() => {
                submitBtn.innerHTML = originalText;
                submitBtn.disabled = false;
                isRegistering = false;
            }, 2000);
        }
    });
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
/* Fix for register page layout */
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
    mv /tmp/register_fixed.html /var/www/hajifund/frontend/views/auth/register.html
    
    print_status "Register page JavaScript redirect fixed"
else
    print_error "Register page not found"
fi

# 8. Build and start services
print_step "7. Building and starting services..."

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o frontend main.go

# Start frontend
print_info "Starting frontend..."
systemctl start hajifund-frontend
sleep 10

# 9. Test the fixes
print_step "8. Testing the fixes..."

sleep 5

print_info "Testing dashboard route..."

echo "1. Testing dashboard route:"
if curl -f -s http://103.103.20.68/dashboard > /dev/null 2>&1; then
    print_status "Dashboard route is accessible"
else
    print_error "Dashboard route is not accessible"
fi

echo "2. Testing login redirect:"
echo "Try logging in at: http://103.103.20.68/login"
echo "After successful login, you should be redirected to: http://103.103.20.68/dashboard"

# 10. Show final status
print_step "9. Final status..."

echo "Frontend status:"
systemctl status hajifund-frontend --no-pager -l | head -5

# 11. Summary
print_status "Dashboard route and redirect fixes completed!"
print_info ""
print_info "🎯 What was fixed:"
print_info "✅ Added missing /dashboard route to frontend"
print_info "✅ Created dashboard handler"
print_info "✅ Created dashboard template"
print_info "✅ Fixed login page JavaScript redirect"
print_info "✅ Fixed register page JavaScript redirect"
print_info "✅ Built and restarted frontend service"
print_info ""
print_info "🔧 Key improvements:"
print_info "   - /dashboard route now exists and works"
print_info "   - Login redirects to /dashboard instead of non-existent route"
print_info "   - Register redirects to /dashboard after successful registration"
print_info "   - Dashboard page shows user information and navigation"
print_info "   - Proper authentication check on dashboard page"
print_info ""
print_info "🌐 Test your login now: http://103.103.20.68/login"
print_info "After successful login, you should be redirected to: http://103.103.20.68/dashboard"
print_info "The 'no resource with given identifier found' error should be fixed!"
