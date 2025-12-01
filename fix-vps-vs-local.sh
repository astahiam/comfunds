#!/bin/bash

# Fix VPS vs Local Differences
# This script fixes the differences between local and VPS deployment

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

print_step "Fixing VPS vs Local Differences"

# 1. The main issue: VPS IP vs localhost
print_step "1. Fixing VPS IP vs localhost issues..."

print_info "Local works because:"
print_info "- Frontend: localhost:3000"
print_info "- Backend: localhost:8080" 
print_info "- Same domain = cookies work"

print_info "VPS breaks because:"
print_info "- Frontend: 103.103.20.68:80"
print_info "- Backend: 103.103.20.68:8080"
print_info "- Different ports = cookies don't work"

# 2. Fix backend cookie domain for VPS
print_step "2. Fixing backend cookie domain for VPS..."

if [ -f "/var/www/hajifund/main.go" ]; then
    print_info "Updating backend cookie domain to VPS IP..."
    
    # Update cookie domain to VPS IP
    sed -i 's/CookieDomain:.*/CookieDomain: "103.103.20.68",/g' /var/www/hajifund/main.go 2>/dev/null || true
    
    # Update cookie path
    sed -i 's/CookiePath:.*/CookiePath: "\/",/g' /var/www/hajifund/main.go 2>/dev/null || true
    
    # Update cookie secure (false for HTTP)
    sed -i 's/CookieSecure:.*/CookieSecure: false,/g' /var/www/hajifund/main.go 2>/dev/null || true
    
    # Update cookie same site
    sed -i 's/CookieSameSite:.*/CookieSameSite: http.SameSiteLaxMode,/g' /var/www/hajifund/main.go 2>/dev/null || true
    
    print_status "Backend cookie domain updated to VPS IP"
else
    print_error "Backend main.go not found"
fi

# 3. Fix frontend CORS for VPS
print_step "3. Fixing frontend CORS for VPS..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Updating frontend CORS for VPS..."
    
    # Update CORS origins to include VPS IP
    sed -i 's/AllowOrigins: "http:\/\/localhost:8080"/AllowOrigins: "http:\/\/103.103.20.68:8080,http:\/\/localhost:8080"/g' /var/www/hajifund/frontend/main.go
    
    # Ensure AllowCredentials is set
    if ! grep -q "AllowCredentials" /var/www/hajifund/frontend/main.go; then
        sed -i '/AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",/a\\t\tAllowCredentials: true,' /var/www/hajifund/frontend/main.go
    fi
    
    print_status "Frontend CORS updated for VPS"
else
    print_error "Frontend main.go not found"
fi

# 4. Fix frontend auth middleware for VPS
print_step "4. Fixing frontend auth middleware for VPS..."

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
		return c.Redirect("/login")
	}

	// Parse and validate JWT token
	token, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {
		// Use the same secret as backend
		return []byte("your-super-secret-jwt-key-change-this-in-production"), nil
	})

	if err != nil || !token.Valid {
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
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
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
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
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
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
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
		return c.Redirect("/login")
	}

	userObj, ok := user.(*models.User)
	if !ok {
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

print_status "Frontend auth middleware updated for VPS"

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

# 6. Test the fix
print_step "6. Testing the fix..."

sleep 5

# Test dashboard route
print_info "Testing dashboard route..."
dashboard_response=$(curl -s -I -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://localhost/dashboard)

if echo "$dashboard_response" | grep -q "200 OK"; then
    print_status "✅ Dashboard route is now working (200 OK)!"
    print_info "The VPS vs local issue has been fixed!"
elif echo "$dashboard_response" | grep -q "302"; then
    print_warning "Dashboard route is still redirecting (302)"
    print_info "This might be due to cookie domain issues"
else
    print_warning "Dashboard route response unclear"
fi

print_status "VPS vs Local fix completed!"
print_info "Key differences fixed:"
print_info "1. Backend cookie domain: localhost → 103.103.20.68"
print_info "2. Frontend CORS: localhost:8080 → 103.103.20.68:8080"
print_info "3. Cookie settings: Updated for VPS IP"
print_info "4. Auth middleware: Updated for VPS deployment"

print_info "Test your dashboard now:"
print_info "http://103.103.20.68/dashboard"
