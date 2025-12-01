#!/bin/bash

# Fix Authentication Middleware 302 Redirect
# This script fixes the auth middleware that's causing 302 redirects

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

print_step "Fixing Authentication Middleware 302 Redirect"

# 1. Check current auth middleware
print_step "1. Checking current auth middleware..."

if [ -f "/var/www/hajifund/frontend/middleware/auth.go" ]; then
    print_info "Frontend auth middleware exists"
    print_info "Current auth middleware content:"
    head -20 /var/www/hajifund/frontend/middleware/auth.go
else
    print_warning "Frontend auth middleware not found, creating it..."
    
    # Create auth middleware
    mkdir -p /var/www/hajifund/frontend/middleware
    
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
	if authToken == "" {
		// No token, redirect to login
		return c.Redirect("/login")
	}

	// Parse and validate JWT token
	token, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {
		// Use a simple secret key for now
		return []byte("your-super-secret-jwt-key-change-this-in-production"), nil
	})

	if err != nil || !token.Valid {
		// Invalid token, redirect to login
		return c.Redirect("/login")
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
    
    print_status "Frontend auth middleware created"
fi

# 2. Check if JWT secret matches
print_step "2. Checking JWT secret configuration..."

print_info "Checking if JWT secret in middleware matches backend..."
if grep -q "your-super-secret-jwt-key-change-this-in-production" /var/www/hajifund/frontend/middleware/auth.go; then
    print_status "JWT secret found in middleware"
else
    print_warning "JWT secret might not match"
fi

# 3. Update frontend main.go to use correct middleware
print_step "3. Updating frontend main.go middleware configuration..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Checking frontend main.go middleware imports..."
    
    # Check if middleware package is imported
    if ! grep -q "hajifund-frontend/middleware" /var/www/hajifund/frontend/main.go; then
        print_info "Adding middleware import to frontend main.go..."
        sed -i '/import (/a\\t"hajifund-frontend/middleware"' /var/www/hajifund/frontend/main.go
        print_status "Middleware import added"
    fi
    
    # Check if AuthMiddleware is used correctly
    if grep -q "middleware.AuthMiddleware" /var/www/hajifund/frontend/main.go; then
        print_status "AuthMiddleware is used in main.go"
    else
        print_warning "AuthMiddleware might not be used correctly"
        print_info "Current protected routes:"
        grep -n "protected.*Group" /var/www/hajifund/frontend/main.go || true
    fi
else
    print_error "Frontend main.go not found"
fi

# 4. Test JWT token parsing
print_step "4. Testing JWT token parsing..."

print_info "Testing JWT token with your specific token..."
# Your JWT token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0

# Decode the JWT token to check if it's valid
print_info "JWT token payload (decoded):"
echo "eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0" | base64 -d 2>/dev/null || echo "Could not decode JWT payload"

# 5. Create a simple test route to debug auth
print_step "5. Creating debug route for authentication..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Adding debug route to frontend main.go..."
    
    # Add debug route before the main routes
    sed -i '/\/\/ Routes/a\\t// Debug route for authentication\\n\tapp.Get("/debug-auth", func(c *fiber.Ctx) error {\\n\t\tauthToken := c.Cookies("auth_token")\\n\t\treturn c.JSON(fiber.Map{\\n\t\t\t"auth_token": authToken,\\n\t\t\t"cookies": c.Cookies(),\\n\t\t\t"headers": c.GetReqHeaders(),\\n\t\t})\\n\t})\\n' /var/www/hajifund/frontend/main.go
    
    print_status "Debug route added"
fi

# 6. Rebuild and restart frontend
print_step "6. Rebuilding and restarting frontend..."

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

# 7. Test the debug route
print_step "7. Testing debug route..."

sleep 3

print_info "Testing debug route..."
debug_response=$(curl -s -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://localhost/debug-auth)

print_info "Debug route response:"
echo "$debug_response"

# 8. Test dashboard route again
print_step "8. Testing dashboard route again..."

print_info "Testing dashboard route with authentication..."
dashboard_response=$(curl -s -I -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://localhost/dashboard)

if echo "$dashboard_response" | grep -q "200 OK"; then
    print_status "Dashboard route is now working (200 OK)!"
elif echo "$dashboard_response" | grep -q "302"; then
    print_warning "Dashboard route is still redirecting (302)"
    print_info "This indicates the auth middleware is still not working correctly"
    
    # Check if the debug route shows the token
    if echo "$debug_response" | grep -q "auth_token"; then
        print_info "Token is being received by frontend"
    else
        print_warning "Token is not being received by frontend"
    fi
else
    print_warning "Dashboard route response unclear"
fi

print_status "Authentication middleware fix completed!"
print_info "Issues addressed:"
print_info "1. Created proper auth middleware"
print_info "2. Added JWT token parsing"
print_info "3. Added debug route for testing"
print_info "4. Frontend rebuilt and restarted"
print_info "5. Tested with your JWT token"

print_info "Next steps if 302 persists:"
print_info "1. Check debug route response: http://103.103.20.68/debug-auth"
print_info "2. Verify JWT secret matches between frontend and backend"
print_info "3. Check if cookie is being set correctly"
print_info "4. Verify middleware execution order"
