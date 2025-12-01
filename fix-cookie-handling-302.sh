#!/bin/bash

# Fix Cookie Handling 302 Redirect
# This script fixes cookie handling between frontend and backend

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

print_step "Fixing Cookie Handling 302 Redirect"

# 1. Check current cookie configuration
print_step "1. Checking current cookie configuration..."

print_info "Checking backend cookie settings..."
if [ -f "/var/www/hajifund/main.go" ]; then
    if grep -q "CookieDomain" /var/www/hajifund/main.go; then
        print_info "Backend cookie domain configuration:"
        grep -n "CookieDomain\|CookiePath\|CookieSecure\|CookieSameSite" /var/www/hajifund/main.go || true
    else
        print_warning "Backend cookie configuration not found"
    fi
else
    print_error "Backend main.go not found"
fi

# 2. Fix backend cookie configuration
print_step "2. Fixing backend cookie configuration..."

if [ -f "/var/www/hajifund/main.go" ]; then
    print_info "Updating backend cookie configuration for VPS..."
    
    # Update cookie domain to VPS IP
    if grep -q "CookieDomain" /var/www/hajifund/main.go; then
        sed -i 's/CookieDomain:.*/CookieDomain: "103.103.20.68",/g' /var/www/hajifund/main.go
    else
        print_warning "CookieDomain not found in backend main.go"
    fi
    
    # Update cookie path
    if grep -q "CookiePath" /var/www/hajifund/main.go; then
        sed -i 's/CookiePath:.*/CookiePath: "\/",/g' /var/www/hajifund/main.go
    else
        print_warning "CookiePath not found in backend main.go"
    fi
    
    # Update cookie secure (false for HTTP)
    if grep -q "CookieSecure" /var/www/hajifund/main.go; then
        sed -i 's/CookieSecure:.*/CookieSecure: false,/g' /var/www/hajifund/main.go
    else
        print_warning "CookieSecure not found in backend main.go"
    fi
    
    # Update cookie same site
    if grep -q "CookieSameSite" /var/www/hajifund/main.go; then
        sed -i 's/CookieSameSite:.*/CookieSameSite: http.SameSiteLaxMode,/g' /var/www/hajifund/main.go
    else
        print_warning "CookieSameSite not found in backend main.go"
    fi
    
    print_status "Backend cookie configuration updated"
else
    print_error "Backend main.go not found"
fi

# 3. Fix frontend cookie handling
print_step "3. Fixing frontend cookie handling..."

if [ -f "/var/www/hajifund/frontend/middleware/auth.go" ]; then
    print_info "Updating frontend auth middleware cookie handling..."
    
    # Update the auth middleware to handle cookies better
    cat > /var/www/hajifund/frontend/middleware/auth.go << 'EOF'
package middleware

import (
	"encoding/json"
	"strings"
	"time"

	"hajifund-frontend/models"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware checks for valid JWT token in cookies
func AuthMiddleware(c *fiber.Ctx) error {
	// Get auth token from cookie
	authToken := c.Cookies("auth_token")
	
	// Debug: Log cookie information
	println("🔍 AuthMiddleware: Checking for auth_token cookie")
	println("🔍 AuthMiddleware: Cookie value:", authToken)
	println("🔍 AuthMiddleware: All cookies:", c.Cookies())
	
	if authToken == "" {
		println("❌ AuthMiddleware: No auth_token cookie found, redirecting to login")
		// No token, redirect to login
		return c.Redirect("/login")
	}

	// Parse and validate JWT token
	token, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {
		// Use a simple secret key for now
		return []byte("your-super-secret-jwt-key-change-this-in-production"), nil
	})

	if err != nil {
		println("❌ AuthMiddleware: JWT parsing error:", err.Error())
		// Invalid token, redirect to login
		return c.Redirect("/login")
	}
	
	if !token.Valid {
		println("❌ AuthMiddleware: JWT token is invalid")
		// Invalid token, redirect to login
		return c.Redirect("/login")
	}

	println("✅ AuthMiddleware: JWT token is valid")

	// Extract claims
	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		println("✅ AuthMiddleware: Extracting user claims")
		
		// Set user data in context
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

		println("✅ AuthMiddleware: User set in context:", user.Name, "Roles:", user.Roles)
		
		// Set user in context
		c.Locals("user", user)
	}

	return c.Next()
}

// OptionalAuthMiddleware checks for JWT token but doesn't require it
func OptionalAuthMiddleware(c *fiber.Ctx) error {
	// Get auth token from cookie
	authToken := c.Cookies("auth_token")
	
	if authToken == "" {
		// No token, continue without user
		return c.Next()
	}

	// Parse and validate JWT token
	token, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {
		// Use a simple secret key for now
		return []byte("your-super-secret-jwt-key-change-this-in-production"), nil
	})

	if err != nil || !token.Valid {
		// Invalid token, continue without user
		return c.Next()
	}

	// Extract claims
	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		// Set user data in context
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

		// Set user in context
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
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
		return c.Redirect("/login")
	}

	// Check if user has business_owner role
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
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
		return c.Redirect("/login")
	}

	// Check if user has investor role
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
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
		return c.Redirect("/login")
	}

	// Check if user has cooperative_member role
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
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
		return c.Redirect("/login")
	}

	// Check if user has cooperative_admin role
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
    
    print_status "Frontend auth middleware updated with debug logging"
else
    print_error "Frontend auth middleware not found"
fi

# 4. Update frontend CORS to allow credentials
print_step "4. Updating frontend CORS to allow credentials..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Updating frontend CORS configuration..."
    
    # Update CORS to allow credentials
    sed -i 's/AllowOrigins: "http:\/\/103.103.20.68,http:\/\/localhost:8080"/AllowOrigins: "http:\/\/103.103.20.68,http:\/\/localhost:8080"/g' /var/www/hajifund/frontend/main.go
    
    # Add AllowCredentials if not present
    if ! grep -q "AllowCredentials" /var/www/hajifund/frontend/main.go; then
        sed -i '/AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",/a\\t\tAllowCredentials: true,' /var/www/hajifund/frontend/main.go
    fi
    
    print_status "Frontend CORS updated to allow credentials"
else
    print_error "Frontend main.go not found"
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

# 6. Test cookie handling
print_step "6. Testing cookie handling..."

sleep 5

# Test debug route
print_info "Testing debug route..."
debug_response=$(curl -s -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://localhost/debug-auth)

print_info "Debug route response:"
echo "$debug_response"

# Test dashboard route
print_info "Testing dashboard route..."
dashboard_response=$(curl -s -I -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://localhost/dashboard)

if echo "$dashboard_response" | grep -q "200 OK"; then
    print_status "Dashboard route is now working (200 OK)!"
elif echo "$dashboard_response" | grep -q "302"; then
    print_warning "Dashboard route is still redirecting (302)"
    print_info "Check the debug route response above to see if cookies are being received"
else
    print_warning "Dashboard route response unclear"
fi

# 7. Check frontend logs
print_step "7. Checking frontend logs..."

print_info "Checking frontend service logs for debug output..."
journalctl -u hajifund-frontend --no-pager -n 20 | grep -E "(AuthMiddleware|Cookie|JWT)" || print_info "No debug output in logs yet"

print_status "Cookie handling fix completed!"
print_info "Issues addressed:"
print_info "1. Backend cookie configuration updated for VPS IP"
print_info "2. Frontend auth middleware updated with debug logging"
print_info "3. Frontend CORS updated to allow credentials"
print_info "4. Services rebuilt and restarted"
print_info "5. Cookie handling tested"

print_info "Next steps:"
print_info "1. Check debug route: http://103.103.20.68/debug-auth"
print_info "2. Check frontend logs: journalctl -u hajifund-frontend -f"
print_info "3. Test dashboard: http://103.103.20.68/dashboard"
print_info "4. If still 302, check if cookies are being set by backend"
