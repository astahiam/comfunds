#!/bin/bash

# Fix AuthHandler Missing Methods
# This script fixes the missing methods in AuthHandler

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

print_step "Fixing AuthHandler Missing Methods"

# 1. Stop services to prevent further issues
print_step "1. Stopping services to prevent further issues..."

systemctl stop hajifund-frontend
systemctl stop hajifund-backend

print_status "Services stopped"

# 2. Fix AuthHandler methods
print_step "2. Fixing AuthHandler methods..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    print_info "Backing up current auth.go..."
    cp /var/www/hajifund/frontend/handlers/auth.go /var/www/hajifund/frontend/handlers/auth.go.backup
    
    print_info "Fixing AuthHandler to include all missing methods..."
    
    # Create a fixed version of auth.go
    cat > /tmp/auth_fixed.go << 'EOF'
package handlers

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct{}

// LoginPage renders the login page
func (h *AuthHandler) LoginPage(c *fiber.Ctx) error {
	return c.Render("auth/login", fiber.Map{
		"Title": "Login - HajiFund",
	}, "base")
}

// RegisterPage renders the register page
func (h *AuthHandler) RegisterPage(c *fiber.Ctx) error {
	return c.Render("auth/register", fiber.Map{
		"Title": "Registrasi - HajiFund",
	}, "base")
}

// Login handles user login
func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var loginData struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := c.BodyParser(&loginData); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request data",
		})
	}

	// Forward request to backend
	backendURL := "http://103.103.20.68:8080/api/v1/auth/login"
	
	// Create request body
	requestBody, err := json.Marshal(loginData)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Make request to backend
	resp, err := http.Post(backendURL, "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		log.Printf("Backend request failed: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend service unavailable",
		})
	}
	defer resp.Body.Close()

	// Read response
	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process response",
		})
	}

	// If login successful, set cookie
	if resp.StatusCode == 200 && responseData["status"] == "success" {
		// Extract token from response
		if token, ok := responseData["data"].(map[string]interface{})["token"].(string); ok {
			// Set HTTPOnly cookie
			c.Cookie(&fiber.Cookie{
				Name:     "auth_token",
				Value:    token,
				HTTPOnly: true,
				Secure:   false,
				SameSite: "Lax",
				Path:     "/",
				Domain:   "103.103.20.68",
			})
		}
	}

	// Return response to frontend
	return c.Status(resp.StatusCode).JSON(responseData)
}

// Register handles user registration
func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var registerData struct {
		Name          string   `json:"name"`
		Email         string   `json:"email"`
		Password      string   `json:"password"`
		Phone         string   `json:"phone"`
		Address       string   `json:"address"`
		CooperativeID *string  `json:"cooperative_id"`
		Roles         []string `json:"roles"`
	}

	if err := c.BodyParser(&registerData); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request data",
		})
	}

	// Forward request to backend
	backendURL := "http://103.103.20.68:8080/api/v1/auth/register"
	
	// Create request body
	requestBody, err := json.Marshal(registerData)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Make request to backend
	resp, err := http.Post(backendURL, "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		log.Printf("Backend request failed: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend service unavailable",
		})
	}
	defer resp.Body.Close()

	// Read response
	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process response",
		})
	}

	// If registration successful, set cookie
	if resp.StatusCode == 200 && responseData["status"] == "success" {
		// Extract token from response
		if token, ok := responseData["data"].(map[string]interface{})["token"].(string); ok {
			// Set HTTPOnly cookie
			c.Cookie(&fiber.Cookie{
				Name:     "auth_token",
				Value:    token,
				HTTPOnly: true,
				Secure:   false,
				SameSite: "Lax",
				Path:     "/",
				Domain:   "103.103.20.68",
			})
		}
	}

	// Return response to frontend
	return c.Status(resp.StatusCode).JSON(responseData)
}

// Logout handles user logout
func (h *AuthHandler) Logout(c *fiber.Ctx) error {
	// Forward request to backend
	backendURL := "http://103.103.20.68:8080/api/v1/auth/logout"
	
	// Make request to backend
	req, err := http.NewRequest("POST", backendURL, nil)
	if err != nil {
		log.Printf("Failed to create request: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Add auth token to request
	if token := c.Cookies("auth_token"); token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Backend request failed: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend service unavailable",
		})
	}
	defer resp.Body.Close()

	// Read response
	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process response",
		})
	}

	// Clear cookie
	c.ClearCookie("auth_token")

	// Return response to frontend
	return c.Status(resp.StatusCode).JSON(responseData)
}

// GetUserProfile gets user profile information
func (h *AuthHandler) GetUserProfile(c *fiber.Ctx) error {
	// Forward request to backend
	backendURL := "http://103.103.20.68:8080/api/v1/user/profile"
	
	// Make request to backend
	req, err := http.NewRequest("GET", backendURL, nil)
	if err != nil {
		log.Printf("Failed to create request: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Add auth token to request
	if token := c.Cookies("auth_token"); token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Backend request failed: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend service unavailable",
		})
	}
	defer resp.Body.Close()

	// Read response
	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process response",
		})
	}

	// Return response to frontend
	return c.Status(resp.StatusCode).JSON(responseData)
}
EOF
    
    # Replace the original file
    mv /tmp/auth_fixed.go /var/www/hajifund/frontend/handlers/auth.go
    print_status "AuthHandler updated with all missing methods"
else
    print_error "AuthHandler not found"
fi

# 3. Fix imports in auth.go
print_step "3. Fixing imports in auth.go..."

if [ -f "/var/www/hajifund/frontend/handlers/auth.go" ]; then
    print_info "Fixing imports in auth.go..."
    
    # Create a properly formatted auth.go with correct imports
    cat > /tmp/auth_imports_fixed.go << 'EOF'
package handlers

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"

	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct{}

// LoginPage renders the login page
func (h *AuthHandler) LoginPage(c *fiber.Ctx) error {
	return c.Render("auth/login", fiber.Map{
		"Title": "Login - HajiFund",
	}, "base")
}

// RegisterPage renders the register page
func (h *AuthHandler) RegisterPage(c *fiber.Ctx) error {
	return c.Render("auth/register", fiber.Map{
		"Title": "Registrasi - HajiFund",
	}, "base")
}

// Login handles user login
func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var loginData struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := c.BodyParser(&loginData); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request data",
		})
	}

	// Forward request to backend
	backendURL := "http://103.103.20.68:8080/api/v1/auth/login"
	
	// Create request body
	requestBody, err := json.Marshal(loginData)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Make request to backend
	resp, err := http.Post(backendURL, "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		log.Printf("Backend request failed: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend service unavailable",
		})
	}
	defer resp.Body.Close()

	// Read response
	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process response",
		})
	}

	// If login successful, set cookie
	if resp.StatusCode == 200 && responseData["status"] == "success" {
		// Extract token from response
		if token, ok := responseData["data"].(map[string]interface{})["token"].(string); ok {
			// Set HTTPOnly cookie
			c.Cookie(&fiber.Cookie{
				Name:     "auth_token",
				Value:    token,
				HTTPOnly: true,
				Secure:   false,
				SameSite: "Lax",
				Path:     "/",
				Domain:   "103.103.20.68",
			})
		}
	}

	// Return response to frontend
	return c.Status(resp.StatusCode).JSON(responseData)
}

// Register handles user registration
func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var registerData struct {
		Name          string   `json:"name"`
		Email         string   `json:"email"`
		Password      string   `json:"password"`
		Phone         string   `json:"phone"`
		Address       string   `json:"address"`
		CooperativeID *string  `json:"cooperative_id"`
		Roles         []string `json:"roles"`
	}

	if err := c.BodyParser(&registerData); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request data",
		})
	}

	// Forward request to backend
	backendURL := "http://103.103.20.68:8080/api/v1/auth/register"
	
	// Create request body
	requestBody, err := json.Marshal(registerData)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Make request to backend
	resp, err := http.Post(backendURL, "application/json", bytes.NewBuffer(requestBody))
	if err != nil {
		log.Printf("Backend request failed: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend service unavailable",
		})
	}
	defer resp.Body.Close()

	// Read response
	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process response",
		})
	}

	// If registration successful, set cookie
	if resp.StatusCode == 200 && responseData["status"] == "success" {
		// Extract token from response
		if token, ok := responseData["data"].(map[string]interface{})["token"].(string); ok {
			// Set HTTPOnly cookie
			c.Cookie(&fiber.Cookie{
				Name:     "auth_token",
				Value:    token,
				HTTPOnly: true,
				Secure:   false,
				SameSite: "Lax",
				Path:     "/",
				Domain:   "103.103.20.68",
			})
		}
	}

	// Return response to frontend
	return c.Status(resp.StatusCode).JSON(responseData)
}

// Logout handles user logout
func (h *AuthHandler) Logout(c *fiber.Ctx) error {
	// Forward request to backend
	backendURL := "http://103.103.20.68:8080/api/v1/auth/logout"
	
	// Make request to backend
	req, err := http.NewRequest("POST", backendURL, nil)
	if err != nil {
		log.Printf("Failed to create request: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Add auth token to request
	if token := c.Cookies("auth_token"); token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Backend request failed: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend service unavailable",
		})
	}
	defer resp.Body.Close()

	// Read response
	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process response",
		})
	}

	// Clear cookie
	c.ClearCookie("auth_token")

	// Return response to frontend
	return c.Status(resp.StatusCode).JSON(responseData)
}

// GetUserProfile gets user profile information
func (h *AuthHandler) GetUserProfile(c *fiber.Ctx) error {
	// Forward request to backend
	backendURL := "http://103.103.20.68:8080/api/v1/user/profile"
	
	// Make request to backend
	req, err := http.NewRequest("GET", backendURL, nil)
	if err != nil {
		log.Printf("Failed to create request: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Add auth token to request
	if token := c.Cookies("auth_token"); token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Backend request failed: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend service unavailable",
		})
	}
	defer resp.Body.Close()

	// Read response
	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		log.Printf("Failed to decode response: %v", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to process response",
		})
	}

	// Return response to frontend
	return c.Status(resp.StatusCode).JSON(responseData)
}
EOF
    
    # Replace the original file
    mv /tmp/auth_imports_fixed.go /var/www/hajifund/frontend/handlers/auth.go
    print_status "AuthHandler imports fixed"
else
    print_error "AuthHandler not found"
fi

# 4. Create missing auth templates
print_step "4. Creating missing auth templates..."

# Create auth templates directory
mkdir -p /var/www/hajifund/frontend/views/auth

# Create login template
print_info "Creating login template..."
cat > /var/www/hajifund/frontend/views/auth/login.html << 'EOF'
{{define "auth/login"}}
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-6">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Login</h3>
                </div>
                <div class="card-body">
                    <form id="loginForm">
                        <div class="mb-3">
                            <label for="email" class="form-label">Email</label>
                            <input type="email" class="form-control" id="email" name="email" required>
                        </div>
                        <div class="mb-3">
                            <label for="password" class="form-label">Password</label>
                            <input type="password" class="form-control" id="password" name="password" required>
                        </div>
                        <button type="submit" class="btn btn-primary w-100">Login</button>
                    </form>
                    <div class="mt-3 text-center">
                        <a href="/register">Belum punya akun? Daftar di sini</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

# Create register template
print_info "Creating register template..."
cat > /var/www/hajifund/frontend/views/auth/register.html << 'EOF'
{{define "auth/register"}}
<div class="container">
    <div class="row justify-content-center">
        <div class="col-md-6">
            <div class="card">
                <div class="card-header">
                    <h3 class="card-title">Registrasi</h3>
                </div>
                <div class="card-body">
                    <form id="registerForm">
                        <div class="mb-3">
                            <label for="name" class="form-label">Nama Lengkap</label>
                            <input type="text" class="form-control" id="name" name="name" required>
                        </div>
                        <div class="mb-3">
                            <label for="email" class="form-label">Email</label>
                            <input type="email" class="form-control" id="email" name="email" required>
                        </div>
                        <div class="mb-3">
                            <label for="password" class="form-label">Password</label>
                            <input type="password" class="form-control" id="password" name="password" required>
                        </div>
                        <div class="mb-3">
                            <label for="phone" class="form-label">Telepon</label>
                            <input type="tel" class="form-control" id="phone" name="phone">
                        </div>
                        <div class="mb-3">
                            <label for="address" class="form-label">Alamat</label>
                            <textarea class="form-control" id="address" name="address" rows="3"></textarea>
                        </div>
                        <div class="mb-3">
                            <label for="role" class="form-label">Peran</label>
                            <select class="form-control" id="role" name="role" required>
                                <option value="">Pilih Peran</option>
                                <option value="investor">Investor</option>
                                <option value="business_owner">Pemilik Bisnis</option>
                            </select>
                        </div>
                        <button type="submit" class="btn btn-primary w-100">Daftar</button>
                    </form>
                    <div class="mt-3 text-center">
                        <a href="/login">Sudah punya akun? Login di sini</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

print_status "Auth templates created"

# 5. Rebuild and restart services
print_step "5. Rebuilding and restarting services..."

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
print_status "Services restarted with all AuthHandler methods"

# 6. Test the fixes
print_step "6. Testing the fixes..."

sleep 5

# Test frontend
print_info "Testing frontend..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

# Test backend
print_info "Testing backend..."
if curl -s http://103.103.20.68:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is responding"
else
    print_warning "Backend might not be responding"
fi

print_status "AuthHandler methods fix completed!"
print_info "Issues addressed:"
print_info "1. Added LoginPage method"
print_info "2. Added RegisterPage method"
print_info "3. Added Login method"
print_info "4. Added Register method"
print_info "5. Added Logout method"
print_info "6. Added GetUserProfile method"
print_info "7. Created auth templates"
print_info "8. Services rebuilt and restarted"

print_info "Key fixes:"
print_info "1. All AuthHandler methods implemented"
print_info "2. Proper backend forwarding"
print_info "3. Cookie handling for authentication"
print_info "4. Error handling and logging"
print_info "5. Complete auth flow"

print_info "Test your application now:"
print_info "1. Check that services are running"
print_info "2. Test login/register functionality"
print_info "3. Verify no compilation errors"
print_info "4. Check that auth pages render correctly"
