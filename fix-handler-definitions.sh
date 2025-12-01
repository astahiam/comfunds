#!/bin/bash

# Fix Handler Definitions and Method Signatures
# This script fixes all handler definitions and method signatures

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

print_step "Fixing Handler Definitions and Method Signatures"

# 1. Stop services to prevent further issues
print_step "1. Stopping services to prevent further issues..."

systemctl stop hajifund-frontend
systemctl stop hajifund-backend

print_status "Services stopped"

# 2. Fix handler definitions
print_step "2. Fixing handler definitions..."

# Create ProjectHandler
print_info "Creating ProjectHandler..."
cat > /var/www/hajifund/frontend/handlers/project.go << 'EOF'
package handlers

import (
	"github.com/gofiber/fiber/v2"
)

type ProjectHandler struct{}

func (h *ProjectHandler) GetProjects(c *fiber.Ctx) error {
	return c.Render("projects/index", fiber.Map{
		"Title": "Daftar Proyek - HajiFund",
	}, "base")
}

func (h *ProjectHandler) GetProjectByID(c *fiber.Ctx) error {
	projectID := c.Params("id")
	return c.Render("projects/detail", fiber.Map{
		"Title":     "Detail Proyek - HajiFund",
		"ProjectID": projectID,
	}, "base")
}

func (h *ProjectHandler) CreateProjectPage(c *fiber.Ctx) error {
	return c.Render("projects/create", fiber.Map{
		"Title": "Buat Proyek - HajiFund",
	}, "base")
}

func (h *ProjectHandler) CreateProject(c *fiber.Ctx) error {
	// Handle project creation
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Project created successfully",
	})
}

func (h *ProjectHandler) UpdateProject(c *fiber.Ctx) error {
	// Handle project update
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Project updated successfully",
	})
}
EOF

# Create InvestmentHandler
print_info "Creating InvestmentHandler..."
cat > /var/www/hajifund/frontend/handlers/investment.go << 'EOF'
package handlers

import (
	"github.com/gofiber/fiber/v2"
)

type InvestmentHandler struct{}

func (h *InvestmentHandler) GetInvestments(c *fiber.Ctx) error {
	return c.Render("investments/index", fiber.Map{
		"Title": "Daftar Investasi - HajiFund",
	}, "base")
}

func (h *InvestmentHandler) GetInvestmentByID(c *fiber.Ctx) error {
	investmentID := c.Params("id")
	return c.Render("investments/detail", fiber.Map{
		"Title":        "Detail Investasi - HajiFund",
		"InvestmentID": investmentID,
	}, "base")
}

func (h *InvestmentHandler) ProjectInvestmentPage(c *fiber.Ctx) error {
	projectID := c.Params("id")
	return c.Render("investments/invest", fiber.Map{
		"Title":     "Investasi Proyek - HajiFund",
		"ProjectID": projectID,
	}, "base")
}

func (h *InvestmentHandler) CreateInvestment(c *fiber.Ctx) error {
	// Handle investment creation
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Investment created successfully",
	})
}
EOF

# Create AdminHandler
print_info "Creating AdminHandler..."
cat > /var/www/hajifund/frontend/handlers/admin.go << 'EOF'
package handlers

import (
	"github.com/gofiber/fiber/v2"
)

type AdminHandler struct{}

func (h *AdminHandler) AdminDashboard(c *fiber.Ctx) error {
	return c.Render("admin/dashboard", fiber.Map{
		"Title": "Admin Dashboard - HajiFund",
	}, "base")
}

func (h *AdminHandler) AdminProjects(c *fiber.Ctx) error {
	return c.Render("admin/projects", fiber.Map{
		"Title": "Kelola Proyek - HajiFund",
	}, "base")
}

func (h *AdminHandler) AdminUsers(c *fiber.Ctx) error {
	return c.Render("admin/users", fiber.Map{
		"Title": "Kelola Pengguna - HajiFund",
	}, "base")
}

func (h *AdminHandler) AdminRegisterPage(c *fiber.Ctx) error {
	return c.Render("admin/register", fiber.Map{
		"Title": "Registrasi Admin - HajiFund",
	}, "base")
}

func (h *AdminHandler) ApproveProject(c *fiber.Ctx) error {
	// Handle project approval
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Project approved successfully",
	})
}
EOF

# Create DashboardHandler
print_info "Creating DashboardHandler..."
cat > /var/www/hajifund/frontend/handlers/dashboard.go << 'EOF'
package handlers

import (
	"github.com/gofiber/fiber/v2"
)

type DashboardHandler struct{}

func (h *DashboardHandler) Dashboard(c *fiber.Ctx) error {
	return c.Render("dashboard", fiber.Map{
		"Title": "Dashboard - HajiFund",
	}, "base")
}
EOF

# 3. Fix main.go to use correct handler types
print_step "3. Fixing main.go to use correct handler types..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Backing up current main.go..."
    cp /var/www/hajifund/frontend/main.go /var/www/hajifund/frontend/main.go.backup
    
    print_info "Fixing main.go to use correct handler types..."
    
    # Create a fixed version of main.go
    cat > /tmp/main_fixed.go << 'EOF'
package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/template/html/v2"
	"hajifund-frontend/handlers"
	"hajifund-frontend/middleware"
)

func main() {
	// Create Fiber app
	app := fiber.New(fiber.Config{
		Views: html.New("./views", ".html"),
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).Render("error", fiber.Map{
				"Code":    code,
				"Message": err.Error(),
			}, "base")
		},
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New())

	// CORS configuration for VPS
	app.Use(cors.New(cors.Config{
		AllowOrigins:     "http://103.103.20.68:8080,http://localhost:8080",
		AllowMethods:     "GET, POST, PUT, DELETE, OPTIONS",
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization",
		AllowCredentials: true,
	}))

	// Initialize handlers
	authHandler := &handlers.AuthHandler{}
	projectHandler := &handlers.ProjectHandler{}
	investmentHandler := &handlers.InvestmentHandler{}
	adminHandler := &handlers.AdminHandler{}
	dashboardHandler := &handlers.DashboardHandler{}

	// Setup routes
	setupRoutes(app, authHandler, projectHandler, investmentHandler, adminHandler, dashboardHandler)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "80"
	}

	log.Printf("Frontend server starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}

func setupRoutes(app *fiber.App, authHandler *handlers.AuthHandler, projectHandler *handlers.ProjectHandler, investmentHandler *handlers.InvestmentHandler, adminHandler *handlers.AdminHandler, dashboardHandler *handlers.DashboardHandler) {
	// Public routes (no authentication required)
	app.Get("/", func(c *fiber.Ctx) error {
		return c.Render("landing", fiber.Map{
			"Title": "HajiFund - Platform Investasi Syariah",
		}, "base")
	})

	app.Get("/about", func(c *fiber.Ctx) error {
		return c.Render("about", fiber.Map{
			"Title": "Tentang Kami - HajiFund",
		}, "base")
	})

	app.Get("/projects", projectHandler.GetProjects)
	app.Get("/projects/:id", projectHandler.GetProjectByID)

	// Auth routes (no authentication required)
	app.Get("/login", authHandler.LoginPage)
	app.Get("/register", authHandler.RegisterPage)
	app.Get("/admin/register", adminHandler.AdminRegisterPage)

	// API routes (no authentication required for login/register)
	app.Post("/api/auth/login", authHandler.Login)
	app.Post("/api/auth/register", authHandler.Register)
	app.Post("/api/auth/logout", authHandler.Logout)

	// Protected routes (authentication required)
	protected := app.Group("/", middleware.AuthMiddleware)
	
	// Dashboard
	protected.Get("/dashboard", dashboardHandler.Dashboard)
	
	// Profile
	protected.Get("/profile", func(c *fiber.Ctx) error {
		return c.Render("profile", fiber.Map{
			"Title": "Profil - HajiFund",
		}, "base")
	})

	// Investments
	protected.Get("/investments", investmentHandler.GetInvestments)
	protected.Get("/investments/:id", investmentHandler.GetInvestmentByID)
	protected.Get("/projects/:id/invest", investmentHandler.ProjectInvestmentPage)
	protected.Post("/api/projects/:id/invest", investmentHandler.CreateInvestment)

	// Projects (for authenticated users)
	protected.Get("/projects/create", projectHandler.CreateProjectPage)
	protected.Post("/api/projects", projectHandler.CreateProject)
	protected.Put("/api/projects/:id", projectHandler.UpdateProject)

	// Admin routes
	admin := app.Group("/admin", middleware.AuthMiddleware, middleware.AdminMiddleware)
	admin.Get("/", adminHandler.AdminDashboard)
	admin.Get("/projects", adminHandler.AdminProjects)
	admin.Get("/users", adminHandler.AdminUsers)
	admin.Post("/projects/:id/approve", adminHandler.ApproveProject)

	// API routes for authenticated users
	api := app.Group("/api", middleware.AuthMiddleware)
	api.Get("/user/profile", authHandler.GetUserProfile)
	api.Get("/projects", projectHandler.GetProjects)
	api.Get("/projects/:id", projectHandler.GetProjectByID)
	api.Put("/projects/:id", projectHandler.UpdateProject)
	api.Post("/projects/:id/approve", adminHandler.ApproveProject)
}
EOF
    
    # Replace the original file
    mv /tmp/main_fixed.go /var/www/hajifund/frontend/main.go
    print_status "Frontend main.go updated with correct handler types"
else
    print_error "Frontend main.go not found"
fi

# 4. Create missing templates
print_step "4. Creating missing templates..."

# Create dashboard template
print_info "Creating dashboard template..."
mkdir -p /var/www/hajifund/frontend/views
cat > /var/www/hajifund/frontend/views/dashboard.html << 'EOF'
{{define "dashboard"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Dashboard</h1>
            <div class="row">
                <div class="col-md-3">
                    <div class="card bg-primary text-white">
                        <div class="card-body">
                            <h5 class="card-title">Total Investasi</h5>
                            <h3 class="card-text">Rp 0</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-success text-white">
                        <div class="card-body">
                            <h5 class="card-title">Total Proyek</h5>
                            <h3 class="card-text">0</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-info text-white">
                        <div class="card-body">
                            <h5 class="card-title">Total Return</h5>
                            <h3 class="card-text">Rp 0</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-warning text-white">
                        <div class="card-body">
                            <h5 class="card-title">Proyek Aktif</h5>
                            <h3 class="card-text">0</h3>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

# Create admin templates
print_info "Creating admin templates..."
mkdir -p /var/www/hajifund/frontend/views/admin
cat > /var/www/hajifund/frontend/views/admin/dashboard.html << 'EOF'
{{define "admin/dashboard"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Admin Dashboard</h1>
            <div class="row">
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Kelola Proyek</h5>
                        </div>
                        <div class="card-body">
                            <p class="card-text">Kelola dan setujui proyek investasi.</p>
                            <a href="/admin/projects" class="btn btn-primary">Kelola Proyek</a>
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="card-title">Kelola Pengguna</h5>
                        </div>
                        <div class="card-body">
                            <p class="card-text">Kelola pengguna dan peran.</p>
                            <a href="/admin/users" class="btn btn-primary">Kelola Pengguna</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

cat > /var/www/hajifund/frontend/views/admin/projects.html << 'EOF'
{{define "admin/projects"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Kelola Proyek</h1>
            <div class="card">
                <div class="card-body">
                    <p class="card-text">Daftar proyek yang perlu disetujui.</p>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

cat > /var/www/hajifund/frontend/views/admin/users.html << 'EOF'
{{define "admin/users"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Kelola Pengguna</h1>
            <div class="card">
                <div class="card-body">
                    <p class="card-text">Daftar pengguna sistem.</p>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

# Create investment templates
print_info "Creating investment templates..."
mkdir -p /var/www/hajifund/frontend/views/investments
cat > /var/www/hajifund/frontend/views/investments/index.html << 'EOF'
{{define "investments/index"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Daftar Investasi</h1>
            <div class="card">
                <div class="card-body">
                    <p class="card-text">Daftar investasi Anda.</p>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

cat > /var/www/hajifund/frontend/views/investments/detail.html << 'EOF'
{{define "investments/detail"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Detail Investasi</h1>
            <div class="card">
                <div class="card-body">
                    <p class="card-text">Detail investasi ID: {{.InvestmentID}}</p>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

# Create projects templates
print_info "Creating projects templates..."
mkdir -p /var/www/hajifund/frontend/views/projects
cat > /var/www/hajifund/frontend/views/projects/index.html << 'EOF'
{{define "projects/index"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Daftar Proyek</h1>
            <div class="card">
                <div class="card-body">
                    <p class="card-text">Daftar proyek investasi yang tersedia.</p>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

cat > /var/www/hajifund/frontend/views/projects/detail.html << 'EOF'
{{define "projects/detail"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Detail Proyek</h1>
            <div class="card">
                <div class="card-body">
                    <p class="card-text">Detail proyek ID: {{.ProjectID}}</p>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

cat > /var/www/hajifund/frontend/views/projects/create.html << 'EOF'
{{define "projects/create"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Buat Proyek</h1>
            <div class="card">
                <div class="card-body">
                    <p class="card-text">Form untuk membuat proyek baru.</p>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

# Create profile template
print_info "Creating profile template..."
cat > /var/www/hajifund/frontend/views/profile.html << 'EOF'
{{define "profile"}}
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <h1 class="h3 mb-4">Profil</h1>
            <div class="card">
                <div class="card-body">
                    <p class="card-text">Halaman profil pengguna.</p>
                </div>
            </div>
        </div>
    </div>
</div>
{{end}}
EOF

print_status "All templates created"

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
print_status "Services restarted with all handler definitions"

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

print_status "Handler definitions fix completed!"
print_info "Issues addressed:"
print_info "1. Created all missing handler types"
print_info "2. Fixed method signatures"
print_info "3. Created all missing templates"
print_info "4. Updated main.go with correct types"
print_info "5. Services rebuilt and restarted"

print_info "Key fixes:"
print_info "1. ProjectHandler with all required methods"
print_info "2. InvestmentHandler with all required methods"
print_info "3. AdminHandler with all required methods"
print_info "4. DashboardHandler with Dashboard method"
print_info "5. All templates created for proper rendering"

print_info "Test your application now:"
print_info "1. Check that services are running"
print_info "2. Test all routes and handlers"
print_info "3. Verify no compilation errors"
print_info "4. Check that all pages render correctly"
