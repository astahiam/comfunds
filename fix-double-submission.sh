#!/bin/bash

# HajiFund Double Submission Fix Script
# This script fixes the double submission issue on the login page

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    echo -e "${BLUE}🔄 $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_info "Please run: sudo $0"
    exit 1
fi

print_step "Fixing Double Submission Issue on Login Page"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-frontend nginx 2>/dev/null || true

# 2. Fix the login page to prevent double submission
print_step "1. Fixing login page double submission issue..."

# Backup original file
cp /var/www/hajifund/frontend/views/auth/login.html /var/www/hajifund/frontend/views/auth/login.html.backup

# Create the fixed login page
cat > /var/www/hajifund/frontend/views/auth/login.html << 'EOF'
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
// Form validation and submission with double-submission prevention
document.addEventListener('DOMContentLoaded', function() {
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

    // Form submission with double-submission prevention
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

            const response = await fetch('/api/auth/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'include', // Include cookies for session
                body: JSON.stringify(loginData)
            });

            console.log('Login response status:', response.status);

            const result = await response.json();
            console.log('Login response:', result);

            if (result.status === 'success') {
                // Show success message
                showToast('Login berhasil! Mengalihkan...', 'success');
                
                // Redirect after short delay
                setTimeout(() => {
                    if (result.data && result.data.user && result.data.user.roles) {
                        const roles = result.data.user.roles;
                        if (roles.includes('admin')) {
                            window.location.href = '/admin';
                        } else {
                            window.location.href = '/dashboard';
                        }
                    } else {
                        window.location.href = result.redirect || '/dashboard';
                    }
                }, 1000);
            } else {
                showToast(result.message || 'Login gagal', 'error');
            }
        } catch (error) {
            console.error('Login error:', error);
            showToast('Terjadi kesalahan saat login', 'error');
        } finally {
            // Re-enable submit button after a delay to prevent rapid clicking
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

    // Check if user is already logged in
    async function checkAuthStatus() {
        try {
            const response = await fetch('/api/user/profile', {
                credentials: 'include'
            });
            
            if (response.ok) {
                const result = await response.json();
                if (result.status === 'success') {
                    // User is already logged in, redirect to dashboard
                    if (result.data && result.data.roles && result.data.roles.includes('admin')) {
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

    // Check auth status on page load
    checkAuthStatus();
});
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

print_status "Login page updated with double-submission prevention"

# 3. Start services
print_step "2. Starting services..."

print_info "Starting frontend..."
systemctl start hajifund-frontend
sleep 10

print_info "Starting nginx..."
systemctl start nginx
sleep 5

# 4. Test the fix
print_step "3. Testing the fix..."

sleep 5

print_info "Testing login page accessibility..."
if curl -f -s http://localhost:3000/login > /dev/null 2>&1; then
    print_status "Login page is accessible"
else
    print_error "Login page is not accessible"
fi

print_info "Testing through nginx..."
if curl -f -s http://103.103.20.68/login > /dev/null 2>&1; then
    print_status "Login page accessible through nginx"
else
    print_error "Login page not accessible through nginx"
fi

# 5. Show final status
print_step "4. Final status..."

echo "Frontend status:"
systemctl status hajifund-frontend --no-pager -l | head -5

echo ""
echo "Nginx status:"
systemctl status nginx --no-pager -l | head -5

print_status "Double submission fix completed!"
print_info ""
print_info "🎉 What was fixed:"
print_info "✅ Added double-submission prevention to login form"
print_info "✅ Submit button is disabled during form submission"
print_info "✅ Added loading state with spinner"
print_info "✅ Added 2-second delay before re-enabling button"
print_info "✅ Added console logging for debugging"
print_info "✅ Maintained original login page design"
print_info ""
print_info "🔧 Key improvements:"
print_info "   - Prevents multiple login requests"
print_info "   - Shows loading state during submission"
print_info "   - Re-enables button after 2 seconds"
print_info "   - Includes proper error handling"
print_info ""
print_info "🌐 Test your login now: http://103.103.20.68/login"
print_info "The double submission issue should now be fixed!"
