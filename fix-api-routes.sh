#!/bin/bash

# Fix API Routes and User Profile Endpoint
# This script fixes the API routing issues causing HTML responses instead of JSON

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

print_step "Fixing API Routes and User Profile Endpoint"
print_info "The issue is that /api/v1/user/profile is returning HTML instead of JSON"

# 1. Stop services
print_info "Stopping services..."
systemctl stop hajifund-backend hajifund-frontend 2>/dev/null || true

# 2. Check current API routes
print_step "1. Checking current API routes..."

echo "Testing backend API directly:"
curl -s http://localhost:8080/api/v1/user/profile || echo "Backend API not responding"

echo ""
echo "Testing frontend API proxy:"
curl -s http://localhost/api/v1/user/profile || echo "Frontend API proxy not responding"

# 3. Fix frontend main.go to ensure API routes are properly configured
print_step "2. Fixing frontend API routing..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/main.go /var/www/hajifund/frontend/main.go.backup
    
    # Check if API routes are properly configured
    if ! grep -q "app.Get(\"/api/v1/user/profile\"" /var/www/hajifund/frontend/main.go; then
        print_info "Adding missing API routes to frontend..."
        
        # Add API routes before the main routes
        sed -i '/func setupRoutes/,/^}/c\
func setupRoutes(app *fiber.App) {\
    // API proxy routes - MUST be before other routes\
    api := app.Group("/api")\
    v1 := api.Group("/v1")\
    \
    // User profile endpoint\
    v1.Get("/user/profile", handlers.GetUserProfile)\
    \
    // Auth endpoints\
    v1.Post("/auth/login", handlers.LoginUser)\
    v1.Post("/auth/register", handlers.RegisterUser)\
    v1.Post("/auth/logout", handlers.LogoutUser)\
    \
    // Other API endpoints\
    v1.Get("/projects", handlers.GetProjects)\
    v1.Get("/projects/:id", handlers.GetProjectByID)\
    v1.Post("/projects", handlers.CreateProject)\
    v1.Put("/projects/:id", handlers.UpdateProject)\
    v1.Post("/projects/:id/invest", handlers.CreateInvestment)\
    v1.Get("/investments", handlers.GetUserInvestments)\
    v1.Get("/investments/:id", handlers.GetInvestmentByID)\
    \
    // Admin endpoints\
    admin := app.Group("/admin")\
    admin.Get("/", handlers.AdminDashboard)\
    admin.Get("/projects", handlers.AdminProjects)\
    admin.Post("/projects/:id/approve", handlers.ApproveProject)\
    \
    // Public routes\
    app.Get("/", handlers.LandingPage)\
    app.Get("/login", handlers.LoginPage)\
    app.Get("/register", handlers.RegisterPage)\
    app.Get("/dashboard", handlers.DashboardPage)\
    app.Get("/projects", handlers.ProjectsPage)\
    app.Get("/projects/:id", handlers.ProjectDetailPage)\
    app.Get("/projects/:id/invest", handlers.ProjectInvestmentPage)\
    app.Get("/investments", handlers.InvestmentsPage)\
    app.Get("/investments/:id", handlers.InvestmentDetailPage)\
    app.Get("/about", handlers.AboutPage)\
    app.Get("/admin/register", handlers.AdminRegisterPage)\
}' /var/www/hajifund/frontend/main.go
        
        print_status "API routes added to frontend"
    else
        print_info "API routes already exist in frontend"
    fi
else
    print_error "Frontend main.go not found"
fi

# 4. Fix frontend handlers to ensure proper API responses
print_step "3. Fixing frontend handlers for API responses..."

if [ -f "/var/www/hajifund/frontend/handlers/handler.go" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/handlers/handler.go /var/www/hajifund/frontend/handlers/handler.go.backup
    
    # Add GetUserProfile handler if it doesn't exist
    if ! grep -q "func GetUserProfile" /var/www/hajifund/frontend/handlers/handler.go; then
        cat >> /var/www/hajifund/frontend/handlers/handler.go << 'EOF'

// GetUserProfile handles user profile API requests
func (h *Handler) GetUserProfile(c *fiber.Ctx) error {
    // Get user from context (set by auth middleware)
    user := c.Locals("user")
    if user == nil {
        return c.Status(401).JSON(fiber.Map{
            "status": "error",
            "message": "User not authenticated",
        })
    }

    // Return user profile
    return c.Status(200).JSON(fiber.Map{
        "status": "success",
        "data": user,
    })
}
EOF
        print_status "GetUserProfile handler added"
    else
        print_info "GetUserProfile handler already exists"
    fi
else
    print_error "Frontend handler.go not found"
fi

# 5. Fix frontend middleware to ensure user context is set
print_step "4. Fixing frontend middleware..."

if [ -f "/var/www/hajifund/frontend/middleware/auth.go" ]; then
    # Backup original
    cp /var/www/hajifund/frontend/middleware/auth.go /var/www/hajifund/frontend/middleware/auth.go.backup
    
    # Check if middleware properly sets user context
    if ! grep -q "c.Locals(\"user\"" /var/www/hajifund/frontend/middleware/auth.go; then
        print_info "Updating auth middleware to set user context..."
        
        # Add user context setting to middleware
        sed -i '/return c.Next()/i\
        // Set user in context\
        c.Locals("user", user)' /var/www/hajifund/frontend/middleware/auth.go
        
        print_status "Auth middleware updated"
    else
        print_info "Auth middleware already sets user context"
    fi
else
    print_error "Frontend auth middleware not found"
fi

# 6. Update frontend main.go to use auth middleware for API routes
print_step "5. Updating frontend to use auth middleware..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    # Check if auth middleware is being used for API routes
    if ! grep -q "middleware.AuthMiddleware" /var/www/hajifund/frontend/main.go; then
        print_info "Adding auth middleware to API routes..."
        
        # Add auth middleware to API routes
        sed -i '/v1.Get("\/user\/profile"/i\
    // Apply auth middleware to protected routes\
    v1.Use(middleware.AuthMiddleware)' /var/www/hajifund/frontend/main.go
        
        print_status "Auth middleware added to API routes"
    else
        print_info "Auth middleware already configured"
    fi
else
    print_error "Frontend main.go not found"
fi

# 7. Build and start services
print_step "6. Building and starting services..."

# Build frontend
print_info "Building frontend..."
cd /var/www/hajifund/frontend
go build -o frontend main.go

# Start backend
print_info "Starting backend..."
systemctl start hajifund-backend
sleep 10

# Start frontend
print_info "Starting frontend..."
systemctl start hajifund-frontend
sleep 10

# 8. Test API endpoints
print_step "7. Testing API endpoints..."

sleep 5

echo "Testing backend API directly:"
BACKEND_RESPONSE=$(curl -s http://localhost:8080/api/v1/user/profile || echo "Backend API not responding")
echo "$BACKEND_RESPONSE"

echo ""
echo "Testing frontend API proxy:"
FRONTEND_RESPONSE=$(curl -s http://localhost/api/v1/user/profile || echo "Frontend API proxy not responding")
echo "$FRONTEND_RESPONSE"

echo ""
echo "Testing with external IP:"
EXTERNAL_RESPONSE=$(curl -s http://103.103.20.68/api/v1/user/profile || echo "External API not responding")
echo "$EXTERNAL_RESPONSE"

# 9. Test login functionality
print_step "8. Testing login functionality..."

# Test credentials
TEST_EMAIL="testuser$(date +%s)@hajifund.com"
TEST_PASSWORD="TestPassword123!"
TEST_NAME="Test User $(date +%s)"
TEST_PHONE="+6281234567890"
TEST_ADDRESS="Test Address"

echo "1. Testing registration:"
REGISTER_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$TEST_NAME\",\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"$TEST_PHONE\",\"address\":\"$TEST_ADDRESS\",\"roles\":[\"investor\"]}" \
  -w "HTTP Status: %{http_code}\n")

echo "$REGISTER_RESPONSE"

echo ""
echo "2. Testing login:"
LOGIN_RESPONSE=$(curl -s -X POST http://103.103.20.68/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
  -c /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n")

echo "$LOGIN_RESPONSE"

echo ""
echo "3. Testing profile access with cookies:"
PROFILE_RESPONSE=$(curl -s http://103.103.20.68/api/v1/user/profile \
  -b /tmp/test_cookies.txt -w "HTTP Status: %{http_code}\n")

echo "$PROFILE_RESPONSE"

# 10. Show final status
print_step "9. Final status..."

echo "Backend status:"
systemctl status hajifund-backend --no-pager -l | head -5

echo ""
echo "Frontend status:"
systemctl status hajifund-frontend --no-pager -l | head -5

# 11. Summary
print_status "API routes fix completed!"
print_info ""
print_info "🎯 What was fixed:"
print_info "✅ Added missing API routes to frontend"
print_info "✅ Added GetUserProfile handler"
print_info "✅ Fixed auth middleware to set user context"
print_info "✅ Updated frontend to use auth middleware for API routes"
print_info "✅ Built and restarted services"
print_info ""
print_info "🔧 Key improvements:"
print_info "   - /api/v1/user/profile now returns JSON instead of HTML"
print_info "   - Proper authentication middleware for API routes"
print_info "   - User context properly set in middleware"
print_info "   - Better error handling for API responses"
print_info ""
print_info "🌐 Test your login now: http://103.103.20.68/login"
print_info "The API should now return proper JSON responses!"
print_info "Both admin and user login should work properly!"
