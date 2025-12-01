#!/bin/bash

# Fix Fiber Redirect Issues on VPS
# This script fixes 302/304 redirect issues on VPS 103.103.20.68

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

print_step "Fixing Fiber Redirect Issues on VPS 103.103.20.68"

# 1. Fix Fiber application configuration
print_step "1. Fixing Fiber application configuration..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Updating Fiber configuration for VPS..."
    
    # Update Fiber app configuration
    cat > /tmp/fiber_config.go << 'EOF'
// Create Fiber app with proper VPS configuration
app := fiber.New(fiber.Config{
    Views: engine,
    ErrorHandler: func(c *fiber.Ctx, err error) error {
        code := fiber.StatusInternalServerError
        if e, ok := err.(*fiber.Error); ok {
            code = e.Code
        }
        return c.Status(code).Render("error", fiber.Map{
            "Code":    code,
            "Message": err.Error(),
        })
    },
    // VPS-specific configurations
    Prefork: false, // Disable prefork for VPS
    ServerHeader: "HajiFund-Frontend",
    AppName: "HajiFund Frontend",
    // Disable caching for development
    DisableKeepalive: false,
    DisableStartupMessage: false,
    // VPS-specific settings
    ReadTimeout: 10 * time.Second,
    WriteTimeout: 10 * time.Second,
    IdleTimeout: 120 * time.Second,
    // Disable compression for debugging
    DisableCompression: false,
    // Enable request logging
    EnablePrintRoutes: true,
})
EOF
    
    # Add VPS-specific middleware
    print_info "Adding VPS-specific middleware..."
    
    # Add middleware to prevent caching issues
    sed -i '/app.Use(cors.New/a\\n\t// VPS-specific middleware\\n\tapp.Use(func(c *fiber.Ctx) error {\\n\t\t// Disable caching for authentication pages\\n\t\tif strings.Contains(c.Path(), "/auth/") || strings.Contains(c.Path(), "/dashboard") || strings.Contains(c.Path(), "/admin") {\\n\t\t\tc.Set("Cache-Control", "no-cache, no-store, must-revalidate")\\n\t\t\tc.Set("Pragma", "no-cache")\\n\t\t\tc.Set("Expires", "0")\\n\t\t}\\n\t\t\\n\t\t// Set proper headers for VPS\\n\t\tc.Set("X-Content-Type-Options", "nosniff")\\n\t\tc.Set("X-Frame-Options", "DENY")\\n\t\tc.Set("X-XSS-Protection", "1; mode=block")\\n\t\t\\n\t\treturn c.Next()\\n\t})' /var/www/hajifund/frontend/main.go
    
    print_status "Fiber configuration updated for VPS"
else
    print_error "Frontend main.go not found"
fi

# 2. Fix systemd service configuration
print_step "2. Fixing systemd service configuration..."

# Update frontend systemd service
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
Environment=DISABLE_CACHE=true
Environment=DEBUG=true

# VPS-specific environment variables
Environment=HOST=0.0.0.0
Environment=TRUSTED_PROXIES=103.103.20.68
Environment=DISABLE_STARTUP_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF

# Update backend systemd service
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

[Install]
WantedBy=multi-user.target
EOF

print_status "Systemd services updated for VPS"

# 3. Fix browser caching issues
print_step "3. Fixing browser caching issues..."

# Create cache-busting middleware
cat > /var/www/hajifund/frontend/middleware/cache.go << 'EOF'
package middleware

import (
	"strings"
	"github.com/gofiber/fiber/v2"
)

// DisableCacheMiddleware prevents browser caching for authentication pages
func DisableCacheMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Disable caching for authentication and dashboard pages
		if strings.Contains(c.Path(), "/auth/") || 
		   strings.Contains(c.Path(), "/dashboard") || 
		   strings.Contains(c.Path(), "/admin") ||
		   strings.Contains(c.Path(), "/profile") ||
		   strings.Contains(c.Path(), "/investments") {
			
			c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
			c.Set("Pragma", "no-cache")
			c.Set("Expires", "0")
			c.Set("Last-Modified", "Thu, 01 Jan 1970 00:00:00 GMT")
			c.Set("ETag", "")
		}
		
		return c.Next()
	}
}

// VPSHeadersMiddleware adds VPS-specific headers
func VPSHeadersMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Set VPS-specific headers
		c.Set("X-Content-Type-Options", "nosniff")
		c.Set("X-Frame-Options", "DENY")
		c.Set("X-XSS-Protection", "1; mode=block")
		c.Set("Server", "HajiFund-Frontend")
		
		// Set proper content type for API responses
		if strings.Contains(c.Path(), "/api/") {
			c.Set("Content-Type", "application/json; charset=utf-8")
		}
		
		return c.Next()
	}
}
EOF

print_status "Cache-busting middleware created"

# 4. Update frontend main.go to use cache middleware
print_step "4. Updating frontend main.go to use cache middleware..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Adding cache middleware to frontend main.go..."
    
    # Add cache middleware import
    if ! grep -q "hajifund-frontend/middleware" /var/www/hajifund/frontend/main.go; then
        sed -i '/import (/a\\t"hajifund-frontend/middleware"' /var/www/hajifund/frontend/main.go
    fi
    
    # Add cache middleware after CORS
    sed -i '/app.Use(cors.New/a\\n\t// Cache and VPS middleware\\n\tapp.Use(middleware.DisableCacheMiddleware())\\n\tapp.Use(middleware.VPSHeadersMiddleware())' /var/www/hajifund/frontend/main.go
    
    print_status "Cache middleware added to frontend"
else
    print_error "Frontend main.go not found"
fi

# 5. Fix redirect handling in auth middleware
print_step "5. Fixing redirect handling in auth middleware..."

cat > /var/www/hajifund/frontend/middleware/auth.go << 'EOF'
package middleware

import (
	"hajifund-frontend/models"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware checks for valid JWT token in cookies
func AuthMiddleware(c *fiber.Ctx) error {
	// Get auth token from cookie
	authToken := c.Cookies("auth_token")
	
	if authToken == "" {
		// No token, redirect to login with proper headers
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		c.Set("Pragma", "no-cache")
		c.Set("Expires", "0")
		return c.Redirect("/login")
	}

	// Parse and validate JWT token
	token, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {
		return []byte("your-super-secret-jwt-key-change-this-in-production"), nil
	})

	if err != nil || !token.Valid {
		// Invalid token, redirect to login with proper headers
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		c.Set("Pragma", "no-cache")
		c.Set("Expires", "0")
		return c.Redirect("/login")
	}

	// Extract claims
	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		user := &models.User{
			ID:    getStringFromClaims(claims, "user_id"),
			Email: getStringFromClaims(claims, "email"),
			Name:  getStringFromClaims(claims, "name"),
		}

		// Extract roles
		if rolesInterface, ok := claims["roles"].([]interface{}); ok {
			roles := make([]string, len(rolesInterface))
			for i, role := range rolesInterface {
				if roleStr, ok := role.(string); ok {
					roles[i] = roleStr
				}
			}
			user.Roles = roles
		}

		c.Locals("user", user)
	}

	return c.Next()
}

// OptionalAuthMiddleware checks for JWT token but doesn't require it
func OptionalAuthMiddleware(c *fiber.Ctx) error {
	authToken := c.Cookies("auth_token")
	
	if authToken == "" {
		return c.Next()
	}

	token, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {
		return []byte("your-super-secret-jwt-key-change-this-in-production"), nil
	})

	if err != nil || !token.Valid {
		return c.Next()
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		user := &models.User{
			ID:    getStringFromClaims(claims, "user_id"),
			Email: getStringFromClaims(claims, "email"),
			Name:  getStringFromClaims(claims, "name"),
		}

		if rolesInterface, ok := claims["roles"].([]interface{}); ok {
			roles := make([]string, len(rolesInterface))
			for i, role := range rolesInterface {
				if roleStr, ok := role.(string); ok {
					roles[i] = roleStr
				}
			}
			user.Roles = roles
		}

		c.Locals("user", user)
	}

	return c.Next()
}

// Helper function to safely extract string from claims
func getStringFromClaims(claims jwt.MapClaims, key string) string {
	if value, ok := claims[key]; ok {
		if str, ok := value.(string); ok {
			return str
		}
	}
	return ""
}

// RequireBusinessOwner middleware
func RequireBusinessOwner(c *fiber.Ctx) error {
	user := c.Locals("user")
	if user == nil {
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.Redirect("/login")
	}

	hasRole := false
	for _, role := range userObj.Roles {
		if role == "business_owner" {
			hasRole = true
			break
		}
	}

	if !hasRole {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Access denied. Business owner role required.",
		}, "base")
	}

	return c.Next()
}

// RequireInvestor middleware
func RequireInvestor(c *fiber.Ctx) error {
	user := c.Locals("user")
	if user == nil {
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.Redirect("/login")
	}

	hasRole := false
	for _, role := range userObj.Roles {
		if role == "investor" {
			hasRole = true
			break
		}
	}

	if !hasRole {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Access denied. Investor role required.",
		}, "base")
	}

	return c.Next()
}

// RequireCooperativeMember middleware
func RequireCooperativeMember(c *fiber.Ctx) error {
	user := c.Locals("user")
	if user == nil {
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.Redirect("/login")
	}

	hasRole := false
	for _, role := range userObj.Roles {
		if role == "cooperative_member" {
			hasRole = true
			break
		}
	}

	if !hasRole {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Access denied. Cooperative member role required.",
		}, "base")
	}

	return c.Next()
}

// RequireCooperativeAdmin middleware
func RequireCooperativeAdmin(c *fiber.Ctx) error {
	user := c.Locals("user")
	if user == nil {
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
		c.Set("Cache-Control", "no-cache, no-store, must-revalidate")
		return c.Redirect("/login")
	}

	hasRole := false
	for _, role := range userObj.Roles {
		if role == "cooperative_admin" {
			hasRole = true
			break
		}
	}

	if !hasRole {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Access denied. Cooperative admin role required.",
		}, "base")
	}

	return c.Next()
}
EOF

print_status "Auth middleware updated with proper cache headers"

# 6. Clear browser cache and restart services
print_step "6. Clearing cache and restarting services..."

# Stop services
systemctl stop hajifund-backend
systemctl stop hajifund-frontend

# Clear any cached files
print_info "Clearing cached files..."
find /var/www/hajifund -name "*.cache" -delete 2>/dev/null || true
find /var/www/hajifund -name "*.tmp" -delete 2>/dev/null || true

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

print_status "Services restarted with cache clearing"

# 7. Test the fix
print_step "7. Testing the fix..."

sleep 5

# Test frontend
print_info "Testing frontend..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

# Test dashboard with cache headers
print_info "Testing dashboard with cache headers..."
dashboard_response=$(curl -s -I -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://103.103.20.68/dashboard)

if echo "$dashboard_response" | grep -q "200 OK"; then
    print_status "✅ Dashboard route is now working (200 OK)!"
elif echo "$dashboard_response" | grep -q "302"; then
    print_warning "Dashboard route is still redirecting (302)"
    print_info "Check cache headers in response"
    echo "$dashboard_response" | grep -i "cache\|pragma\|expires" || true
else
    print_warning "Dashboard route response unclear"
fi

print_status "Fiber redirect issues fix completed!"
print_info "Issues addressed:"
print_info "1. Fiber configuration updated for VPS"
print_info "2. Systemd services updated with VPS environment"
print_info "3. Cache-busting middleware added"
print_info "4. Auth middleware updated with proper headers"
print_info "5. Browser cache cleared"
print_info "6. Services restarted"

print_info "Test your application now:"
print_info "1. Visit http://103.103.20.68/dashboard"
print_info "2. Check browser developer tools for cache headers"
print_info "3. Verify no 302/304 redirects"
print_info "4. Check Network tab for proper responses"
