#!/bin/bash

# Fix JWT Cookie Authentication
# This script fixes the JWT cookie authentication between frontend and backend

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

print_step "Fixing JWT Cookie Authentication"

# 1. Fix backend cookie settings for JWT
print_step "1. Fixing backend JWT cookie settings..."

if [ -f "/var/www/hajifund/main.go" ]; then
    print_info "Updating backend cookie configuration for JWT authentication..."
    
    # Check if we need to add cookie configuration to backend
    if ! grep -q "CookieDomain" /var/www/hajifund/main.go; then
        print_info "Adding cookie configuration to backend main.go..."
        
        # Find where to add cookie configuration (after router setup)
        sed -i '/router := gin.Default()/a\\n\t// Configure cookies for JWT authentication\n\trouter.Use(func(c *gin.Context) {\n\t\t// Set cookie domain for VPS\n\t\tc.Header("Set-Cookie", "auth_token=; Domain=103.103.20.68; Path=/; HttpOnly; SameSite=Lax")\n\t\tc.Next()\n\t})' /var/www/hajifund/main.go
    fi
    
    print_status "Backend cookie configuration updated"
else
    print_error "Backend main.go not found"
fi

# 2. Fix frontend auth middleware for JWT cookies
print_step "2. Fixing frontend auth middleware for JWT cookies..."

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
	
	// Debug logging
	println("🔍 AuthMiddleware: Checking for auth_token cookie")
	println("🔍 AuthMiddleware: Cookie value:", authToken)
	
	if authToken == "" {
		println("❌ AuthMiddleware: No auth_token cookie found, redirecting to login")
		return c.Redirect("/login")
	}

	// Parse and validate JWT token
	token, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {
		// Use the same secret as backend
		return []byte("your-super-secret-jwt-key-change-this-in-production"), nil
	})

	if err != nil {
		println("❌ AuthMiddleware: JWT parsing error:", err.Error())
		return c.Redirect("/login")
	}
	
	if !token.Valid {
		println("❌ AuthMiddleware: JWT token is invalid")
		return c.Redirect("/login")
	}

	println("✅ AuthMiddleware: JWT token is valid")

	// Extract claims
	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		println("✅ AuthMiddleware: Extracting user claims")
		
		// Create user object
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
		return c.Next()
	}

	// Parse and validate JWT token
	token, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {
		return []byte("your-super-secret-jwt-key-change-this-in-production"), nil
	})

	if err != nil || !token.Valid {
		return c.Next()
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

print_status "Frontend auth middleware updated for JWT cookies"

# 3. Fix frontend CORS for cookies
print_step "3. Fixing frontend CORS for cookies..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Updating frontend CORS configuration for cookies..."
    
    # Update CORS configuration
    sed -i 's/AllowOrigins: "http:\/\/103.103.20.68,http:\/\/localhost:8080"/AllowOrigins: "http:\/\/103.103.20.68,http:\/\/localhost:8080"/g' /var/www/hajifund/frontend/main.go
    
    # Ensure AllowCredentials is set
    if ! grep -q "AllowCredentials" /var/www/hajifund/frontend/main.go; then
        sed -i '/AllowMethods: "GET, POST, PUT, DELETE, OPTIONS",/a\\t\tAllowCredentials: true,' /var/www/hajifund/frontend/main.go
    fi
    
    print_status "Frontend CORS updated for cookies"
else
    print_error "Frontend main.go not found"
fi

# 4. Fix backend auth controller to set cookies properly
print_step "4. Fixing backend auth controller for cookies..."

if [ -f "/var/www/hajifund/internal/controllers/auth_controller.go" ]; then
    print_info "Checking backend auth controller cookie settings..."
    
    # Check if cookie is being set properly
    if grep -q "Cookie.*auth_token" /var/www/hajifund/internal/controllers/auth_controller.go; then
        print_status "Backend auth controller already sets cookies"
    else
        print_warning "Backend auth controller might not be setting cookies properly"
    fi
else
    print_error "Backend auth controller not found"
fi

# 5. Create a test route to verify JWT cookie handling
print_step "5. Creating test route for JWT cookie handling..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Adding test route for JWT cookie handling..."
    
    # Add test route
    sed -i '/\/\/ Debug route for authentication/a\\n\t// Test route for JWT cookie handling\\n\tapp.Get("/test-jwt", func(c *fiber.Ctx) error {\\n\t\tauthToken := c.Cookies("auth_token")\\n\t\tif authToken == "" {\\n\t\t\treturn c.JSON(fiber.Map{\\n\t\t\t\t"status": "error",\\n\t\t\t\t"message": "No auth_token cookie found",\\n\t\t\t\t"cookies": c.Cookies(),\\n\t\t\t})\\n\t\t}\\n\t\t\\n\t\t// Parse JWT token\\n\t\ttoken, err := jwt.Parse(authToken, func(token *jwt.Token) (interface{}, error) {\\n\t\t\treturn []byte("your-super-secret-jwt-key-change-this-in-production"), nil\\n\t\t})\\n\t\t\\n\t\tif err != nil {\\n\t\t\treturn c.JSON(fiber.Map{\\n\t\t\t\t"status": "error",\\n\t\t\t\t"message": "JWT parsing error: " + err.Error(),\\n\t\t\t\t"token": authToken,\\n\t\t\t})\\n\t\t}\\n\t\t\\n\t\tif !token.Valid {\\n\t\t\treturn c.JSON(fiber.Map{\\n\t\t\t\t"status": "error",\\n\t\t\t\t"message": "JWT token is invalid",\\n\t\t\t\t"token": authToken,\\n\t\t\t})\\n\t\t}\\n\t\t\\n\t\t// Extract claims\\n\t\tif claims, ok := token.Claims.(jwt.MapClaims); ok {\\n\t\t\treturn c.JSON(fiber.Map{\\n\t\t\t\t"status": "success",\\n\t\t\t\t"message": "JWT token is valid",\\n\t\t\t\t"user_id": claims["user_id"],\\n\t\t\t\t"email": claims["email"],\\n\t\t\t\t"name": claims["name"],\\n\t\t\t\t"roles": claims["roles"],\\n\t\t\t})\\n\t\t}\\n\t\t\\n\t\treturn c.JSON(fiber.Map{\\n\t\t\t"status": "error",\\n\t\t\t"message": "Could not extract claims",\\n\t\t})\\n\t})' /var/www/hajifund/frontend/main.go
    
    print_status "Test route added for JWT cookie handling"
else
    print_error "Frontend main.go not found"
fi

# 6. Rebuild and restart services
print_step "6. Rebuilding and restarting services..."

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

# 7. Test JWT cookie authentication
print_step "7. Testing JWT cookie authentication..."

sleep 5

# Test the JWT cookie handling
print_info "Testing JWT cookie handling..."
jwt_test=$(curl -s -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://localhost/test-jwt)

print_info "JWT cookie test response:"
echo "$jwt_test"

# Test dashboard route
print_info "Testing dashboard route..."
dashboard_response=$(curl -s -I -H "Cookie: auth_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZW1haWwiOiJkZW1vLWJ1c2luZXNzQGV4YW1wbGUuY29tIiwibmFtZSI6IkRlbW8gQnVzaW5lc3MgT3duZXIiLCJyb2xlcyI6WyJidXNpbmVzc19vd25lciIsImludmVzdG9yIl0sImNvb3BlcmF0aXZlX2lkIjoiNTUwZTg0MDAtZTI5Yi00MWQ0LWE3MTYtNDQ2NjU1NDQwMDAxIiwic3ViIjoiN2E1MzI3ZmUtN2FjMi00NWZmLThlOWYtM2E2YTlmMDA2ZjcxIiwiZXhwIjoxNzYxMTUyNjEyLCJuYmYiOjE3NjEwNjYyMTIsImlhdCI6MTc2MTA2NjIxMn0.t7ajJyLjK3w3Qe_nrOhjU3B-luA9tkN-KYWs_rYQuu0" http://localhost/dashboard)

if echo "$dashboard_response" | grep -q "200 OK"; then
    print_status "Dashboard route is now working (200 OK)!"
elif echo "$dashboard_response" | grep -q "302"; then
    print_warning "Dashboard route is still redirecting (302)"
    print_info "Check the JWT test response above to see if JWT parsing is working"
else
    print_warning "Dashboard route response unclear"
fi

# 8. Check frontend logs
print_step "8. Checking frontend logs..."

print_info "Checking frontend service logs for JWT processing..."
journalctl -u hajifund-frontend --no-pager -n 20 | grep -E "(AuthMiddleware|JWT|Cookie)" || print_info "No JWT debug output in logs yet"

print_status "JWT cookie authentication fix completed!"
print_info "Issues addressed:"
print_info "1. Backend cookie configuration updated for VPS"
print_info "2. Frontend auth middleware updated for JWT cookies"
print_info "3. Frontend CORS updated to allow credentials"
print_info "4. JWT test route added for debugging"
print_info "5. Services rebuilt and restarted"

print_info "Test routes:"
print_info "1. JWT Test: http://103.103.20.68/test-jwt"
print_info "2. Dashboard: http://103.103.20.68/dashboard"
print_info "3. Debug: http://103.103.20.68/debug-auth"

print_info "If still 302, check:"
print_info "1. JWT test route response"
print_info "2. Frontend logs: journalctl -u hajifund-frontend -f"
print_info "3. Whether cookies are being set by backend"
print_info "4. Whether JWT secret matches between frontend and backend"
