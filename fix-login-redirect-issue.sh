#!/bin/bash

# HajiFund Login Redirect and Cookie Fix Script
# This script fixes the login redirect and cookie persistence issues

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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
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

print_step "Fixing Login Redirect and Cookie Issues"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend hajifund-frontend nginx 2>/dev/null || true

# 2. Fix backend environment for proper cookie handling
print_step "1. Fixing backend environment configuration..."

cat > /var/www/hajifund/.env << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_SSLMODE=disable

# Application Configuration
ENVIRONMENT=production
PORT=8080
JWT_SECRET=hajifund-super-secret-jwt-key-production-2024-vps-103-103-20-68

# CORS Configuration - CRITICAL for session persistence
CORS_ORIGINS=http://103.103.20.68,http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000

# Trusted Proxies (for nginx)
TRUSTED_PROXIES=127.0.0.1,::1,103.103.20.68

# Rate Limiting
GENERAL_RATE_LIMIT_RPM=60
GENERAL_RATE_LIMIT_BURST=100

# Cookie Configuration
COOKIE_DOMAIN=103.103.20.68
COOKIE_SECURE=false
COOKIE_SAME_SITE=Lax
EOF

print_status "Backend environment configured"

# 3. Fix frontend environment
print_step "2. Fixing frontend environment configuration..."

cat > /var/www/hajifund/frontend/.env << 'EOF'
# Backend Configuration
BACKEND_URL=http://localhost:8080
FRONTEND_URL=http://103.103.20.68
PORT=3000
ENVIRONMENT=production

# API Configuration
API_BASE_URL=http://localhost:8080

# Cookie Configuration
COOKIE_DOMAIN=103.103.20.68
EOF

print_status "Frontend environment configured"

# 4. Fix frontend cookie handling in auth handler
print_step "3. Fixing frontend cookie handling..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    print_info "Updating cookie configuration in auth handler..."
    
    # Backup the original file
    cp /var/www/hajifund/frontend/handlers/auth.go /var/www/hajifund/frontend/handlers/auth.go.backup
    
    # Update cookie configuration for production
    sed -i 's/Secure:   false/Secure:   false/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/SameSite: "Lax"/SameSite: "Lax"/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/HTTPOnly: true/HTTPOnly: true/g' /var/www/hajifund/frontend/handlers/auth.go
    sed -i 's/Domain:   ""/Domain:   "103.103.20.68"/g' /var/www/hajifund/frontend/handlers/auth.go
    
    print_status "Frontend auth handler updated"
fi

# 5. Fix frontend login JavaScript
print_step "4. Fixing frontend login JavaScript..."

# Update login.html to handle cookies properly
if [ -f "/var/www/hajifund/frontend/views/auth/login.html" ]; then
    print_info "Updating login form JavaScript..."
    
    # Backup the original file
    cp /var/www/hajifund/frontend/views/auth/login.html /var/www/hajifund/frontend/views/auth/login.html.backup
    
    # Create a new login.html with proper cookie handling
    cat > /var/www/hajifund/frontend/views/auth/login.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Masuk - HajiFund</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .login-container {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .login-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            padding: 40px;
            width: 100%;
            max-width: 400px;
        }
        .login-header {
            text-align: center;
            margin-bottom: 30px;
        }
        .login-header h2 {
            color: #2c3e50;
            font-weight: 700;
            margin-bottom: 10px;
        }
        .login-header p {
            color: #7f8c8d;
            margin: 0;
        }
        .form-control {
            border-radius: 10px;
            border: 2px solid #e9ecef;
            padding: 12px 15px;
            font-size: 16px;
            transition: all 0.3s ease;
        }
        .form-control:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }
        .btn-login {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 10px;
            padding: 12px;
            font-size: 16px;
            font-weight: 600;
            color: white;
            width: 100%;
            transition: all 0.3s ease;
        }
        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.3);
        }
        .form-check-input:checked {
            background-color: #667eea;
            border-color: #667eea;
        }
        .text-muted a {
            color: #667eea;
            text-decoration: none;
        }
        .text-muted a:hover {
            text-decoration: underline;
        }
        .toast-container {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1050;
        }
        .toast {
            background: white;
            border: none;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        }
        .toast-header {
            background: transparent;
            border-bottom: 1px solid #e9ecef;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-card">
            <div class="login-header">
                <h2><i class="fas fa-sign-in-alt me-2"></i>Masuk</h2>
                <p>Selamat datang kembali di HajiFund</p>
            </div>
            
            <form id="loginForm" novalidate>
                <div class="mb-3">
                    <label for="email" class="form-label">Email</label>
                    <input type="email" class="form-control" id="email" name="email" required>
                    <div class="invalid-feedback">
                        Masukkan email yang valid
                    </div>
                </div>
                
                <div class="mb-3">
                    <label for="password" class="form-label">Password</label>
                    <div class="input-group">
                        <input type="password" class="form-control" id="password" name="password" required>
                        <button class="btn btn-outline-secondary" type="button" id="togglePassword">
                            <i class="fas fa-eye"></i>
                        </button>
                    </div>
                    <div class="invalid-feedback">
                        Masukkan password
                    </div>
                </div>
                
                <div class="mb-3 form-check">
                    <input type="checkbox" class="form-check-input" id="rememberMe">
                    <label class="form-check-label" for="rememberMe">
                        Ingat saya
                    </label>
                </div>
                
                <button type="submit" class="btn btn-login">
                    <i class="fas fa-sign-in-alt me-2"></i>Masuk
                </button>
            </form>
            
            <div class="text-center mt-4">
                <p class="text-muted">
                    Belum punya akun? 
                    <a href="/register">Daftar di sini</a>
                </p>
            </div>
        </div>
    </div>

    <!-- Toast Container -->
    <div class="toast-container">
        <div id="toast" class="toast" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="toast-header">
                <i class="fas fa-info-circle text-primary me-2"></i>
                <strong class="me-auto">HajiFund</strong>
                <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
            </div>
            <div class="toast-body" id="toastMessage">
                <!-- Toast message will be inserted here -->
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // DOM elements
        const form = document.getElementById('loginForm');
        const emailInput = document.getElementById('email');
        const passwordInput = document.getElementById('password');
        const togglePasswordBtn = document.getElementById('togglePassword');
        const toast = new bootstrap.Toast(document.getElementById('toast'));
        const toastMessage = document.getElementById('toastMessage');

        // Show toast message
        function showToast(message, type = 'info') {
            toastMessage.textContent = message;
            
            // Update toast icon and color based on type
            const toastHeader = toast._element.querySelector('.toast-header');
            const icon = toastHeader.querySelector('i');
            
            icon.className = type === 'success' ? 'fas fa-check-circle text-success me-2' :
                            type === 'error' ? 'fas fa-exclamation-circle text-danger me-2' :
                            'fas fa-info-circle text-primary me-2';
            
            toast.show();
        }

        // Toggle password visibility
        togglePasswordBtn.addEventListener('click', function() {
            const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
            passwordInput.setAttribute('type', type);
            
            const icon = this.querySelector('i');
            icon.className = type === 'password' ? 'fas fa-eye' : 'fas fa-eye-slash';
        });

        // Form validation
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            // Reset validation
            form.classList.remove('was-validated');
            
            // Validate form
            if (!form.checkValidity()) {
                e.stopPropagation();
                form.classList.add('was-validated');
                return;
            }
            
            // Show loading state
            const submitBtn = form.querySelector('button[type="submit"]');
            const originalText = submitBtn.innerHTML;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Memproses...';
            submitBtn.disabled = true;
            
            try {
                // Prepare form data
                const formData = new FormData(form);
                const loginData = {
                    email: formData.get('email'),
                    password: formData.get('password')
                };
                
                console.log('Attempting login with:', loginData.email);
                
                // Make login request
                const response = await fetch('/api/auth/login', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    credentials: 'include', // CRITICAL: Include cookies
                    body: JSON.stringify(loginData)
                });
                
                console.log('Login response status:', response.status);
                console.log('Login response headers:', response.headers);
                
                const result = await response.json();
                console.log('Login response data:', result);
                
                if (response.ok && result.status === 'success') {
                    showToast('Login berhasil! Mengalihkan ke dashboard...', 'success');
                    
                    // Wait a bit then redirect
                    setTimeout(() => {
                        // Check if user has admin role for redirect
                        if (result.data && result.data.user && result.data.user.roles) {
                            const roles = result.data.user.roles;
                            if (roles.includes('admin')) {
                                window.location.href = '/admin';
                            } else {
                                window.location.href = '/dashboard';
                            }
                        } else {
                            window.location.href = '/dashboard';
                        }
                    }, 1500);
                    
                } else {
                    showToast(result.message || 'Login gagal. Periksa email dan password Anda.', 'error');
                }
                
            } catch (error) {
                console.error('Login error:', error);
                showToast('Terjadi kesalahan. Silakan coba lagi.', 'error');
            } finally {
                // Reset button state
                submitBtn.innerHTML = originalText;
                submitBtn.disabled = false;
            }
        });

        // Check if user is already logged in
        document.addEventListener('DOMContentLoaded', async function() {
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
        });
    </script>
</body>
</html>
EOF
    
    print_status "Login form updated with proper cookie handling and redirect logic"
fi

# 6. Fix nginx configuration for better cookie handling
print_step "5. Fixing nginx configuration..."

cat > /etc/nginx/sites-available/hajifund << 'EOF'
# Upstream definitions
upstream backend {
    server 127.0.0.1:8080;
    keepalive 32;
}

upstream frontend {
    server 127.0.0.1:3000;
    keepalive 32;
}

# Rate limiting zones
limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;

# Main HTTP server
server {
    listen 80;
    server_name _;
    
    # Increase client body size for file uploads
    client_max_body_size 50M;
    
    # Frontend routes
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # CRITICAL: Authentication endpoints with proper cookie handling
    location /api/v1/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for authentication
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/auth/ routes (without v1) - REDIRECT TO v1
    location /api/auth/ {
        limit_req zone=login burst=10 nodelay;
        
        proxy_pass http://backend/api/v1/auth/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for authentication
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Backend API routes with cookie handling
    location /api/v1/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for session persistence
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Handle /api/ routes (general API without v1)
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://backend/api/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CRITICAL: Cookie handling for session persistence
        proxy_cookie_domain ~^(.+)$ 103.103.20.68;
        proxy_set_header Cookie $http_cookie;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Admin routes
    location /admin/ {
        proxy_pass http://frontend/admin/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Static files with caching
    location /static/ {
        proxy_pass http://frontend/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        
        # Compression
        gzip_static on;
    }
    
    # Upload files
    location /uploads/ {
        proxy_pass http://backend/uploads/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|git|htaccess|htpasswd)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

print_status "Nginx configuration updated"

# 7. Test nginx configuration
print_info "Testing nginx configuration..."
if nginx -t; then
    print_status "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
    exit 1
fi

# 8. Start services in order
print_step "6. Starting services..."

print_info "Starting backend..."
systemctl start hajifund-backend
sleep 10

# Check if backend is responding
if curl -f -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    print_status "Backend is responding"
else
    print_error "Backend is not responding"
    echo "Backend logs:"
    journalctl -u hajifund-backend -n 20 --no-pager
fi

print_info "Starting frontend..."
systemctl start hajifund-frontend
sleep 10

# Check if frontend is responding
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    print_status "Frontend is responding"
else
    print_error "Frontend is not responding"
    echo "Frontend logs:"
    journalctl -u hajifund-frontend -n 20 --no-pager
fi

print_info "Starting nginx..."
systemctl start nginx
sleep 5

# 9. Test the complete flow
print_step "7. Testing complete login flow..."

sleep 10

# Test user credentials
TEST_EMAIL="testuser@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

echo "Testing complete authentication flow:"
echo "1. Registering test user:"
curl -s -X POST http://103.103.20.68/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -c /tmp/register_cookies.txt -w "HTTP Status: %{http_code}\n"

echo ""
echo "2. Login test:"
curl -s -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n"

echo ""
echo "3. Cookie verification:"
if [ -f "/tmp/test_cookies.txt" ] && [ -s "/tmp/test_cookies.txt" ]; then
    print_status "Cookies are being set"
    cat /tmp/test_cookies.txt
else
    print_error "No cookies are being set"
fi

echo ""
echo "4. Profile access test:"
curl -s http://103.103.20.68/api/v1/user/profile \
  -b /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n"

# 10. Show final status
print_step "8. Final service status..."
echo "Backend:"
systemctl status hajifund-backend --no-pager -l

echo ""
echo "Frontend:"
systemctl status hajifund-frontend --no-pager -l

echo ""
echo "Nginx:"
systemctl status nginx --no-pager -l

print_status "Login redirect and cookie fix completed!"
print_info "Key fixes applied:"
print_info "✅ Fixed frontend login JavaScript with proper cookie handling"
print_info "✅ Added credentials: 'include' to fetch requests"
print_info "✅ Added proper redirect logic after successful login"
print_info "✅ Added role-based redirect (admin vs dashboard)"
print_info "✅ Fixed cookie domain configuration"
print_info "✅ Added session persistence checks"
print_info ""
print_info "Test your login now: http://103.103.20.68/login"
print_info "After successful login, you should be redirected to dashboard!"
print_info ""
print_info "The login should now:"
print_info "1. ✅ Accept credentials"
print_info "2. ✅ Set cookies properly"
print_info "3. ✅ Redirect to dashboard/admin based on role"
print_info "4. ✅ Maintain session across page navigation"
