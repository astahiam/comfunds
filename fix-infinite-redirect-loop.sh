#!/bin/bash

# Fix Infinite Redirect Loop Issue
# This script fixes the infinite redirect loop caused by authentication middleware

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

print_step "Fixing Infinite Redirect Loop Issue"

# 1. Stop services to prevent further issues
print_step "1. Stopping services to prevent further issues..."

systemctl stop hajifund-frontend
systemctl stop hajifund-backend

print_status "Services stopped"

# 2. Fix frontend authentication middleware
print_step "2. Fixing frontend authentication middleware..."

if [ -f "/var/www/hajifund/frontend/main.go" ]; then
    print_info "Backing up current main.go..."
    cp /var/www/hajifund/frontend/main.go /var/www/hajifund/frontend/main.go.backup
    
    print_info "Fixing authentication middleware to prevent infinite loops..."
    
    # Create a fixed version of main.go
    cat > /tmp/main_fixed.go << 'EOF'
package main

import (
	"log"
	"os"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/template/html/v2"
	"hajifund-frontend/handlers"
	"hajifund-frontend/middleware"
	"hajifund-frontend/models"
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

func setupRoutes(app *fiber.App, authHandler, projectHandler, investmentHandler, adminHandler, dashboardHandler *handlers.Handler) {
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
    print_status "Frontend main.go updated to prevent infinite loops"
else
    print_error "Frontend main.go not found"
fi

# 3. Fix authentication middleware
print_step "3. Fixing authentication middleware..."

if [ -f "/var/www/hajifund/frontend/middleware/auth.go" ]; then
    print_info "Backing up current auth middleware..."
    cp /var/www/hajifund/frontend/middleware/auth.go /var/www/hajifund/frontend/middleware/auth.go.backup
    
    print_info "Fixing authentication middleware to prevent infinite loops..."
    
    # Create a fixed version of auth middleware
    cat > /tmp/auth_middleware_fixed.go << 'EOF'
package middleware

import (
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"hajifund-frontend/models"
)

// AuthMiddleware checks for authentication and sets user context
func AuthMiddleware(c *fiber.Ctx) error {
	// Skip authentication for public routes
	if isPublicRoute(c.Path()) {
		return c.Next()
	}

	// Get auth token from cookie
	authToken := c.Cookies("auth_token")
	if authToken == "" {
		// If no token and trying to access protected route, redirect to login
		if isProtectedRoute(c.Path()) {
			return c.Redirect("/login")
		}
		return c.Next()
	}

	// Parse and validate JWT token
	user, err := parseJWTToken(authToken)
	if err != nil {
		// If token is invalid and trying to access protected route, redirect to login
		if isProtectedRoute(c.Path()) {
			return c.Redirect("/login")
		}
		return c.Next()
	}

	// Set user context
	c.Locals("user", user)
	return c.Next()
}

// AdminMiddleware checks for admin role
func AdminMiddleware(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	
	// Check if user has admin role
	hasAdminRole := false
	for _, role := range user.Roles {
		if role == "admin" {
			hasAdminRole = true
			break
		}
	}

	if !hasAdminRole {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Access denied. Admin role required.",
		}, "base")
	}

	return c.Next()
}

// parseJWTToken parses and validates JWT token
func parseJWTToken(tokenString string) (*models.User, error) {
	// Parse token without verification for now
	token, _, err := new(jwt.Parser).ParseUnverified(tokenString, jwt.MapClaims{})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, fiber.NewError(400, "Invalid token claims")
	}

	// Extract user information from claims
	userID, ok := claims["user_id"].(string)
	if !ok {
		return nil, fiber.NewError(400, "Invalid user ID in token")
	}

	email, ok := claims["email"].(string)
	if !ok {
		return nil, fiber.NewError(400, "Invalid email in token")
	}

	name, ok := claims["name"].(string)
	if !ok {
		return nil, fiber.NewError(400, "Invalid name in token")
	}

	// Extract roles
	var roles []string
	if rolesClaim, ok := claims["roles"].([]interface{}); ok {
		for _, role := range rolesClaim {
			if roleStr, ok := role.(string); ok {
				roles = append(roles, roleStr)
			}
		}
	}

	// Extract cooperative ID
	var cooperativeID string
	if coopID, ok := claims["cooperative_id"].(string); ok {
		cooperativeID = coopID
	}

	return &models.User{
		ID:            userID,
		Email:         email,
		Name:          name,
		Roles:         roles,
		CooperativeID: cooperativeID,
	}, nil
}

// isPublicRoute checks if the route is public (no authentication required)
func isPublicRoute(path string) bool {
	publicRoutes := []string{
		"/",
		"/about",
		"/projects",
		"/login",
		"/register",
		"/admin/register",
		"/api/auth/login",
		"/api/auth/register",
		"/api/auth/logout",
	}

	for _, route := range publicRoutes {
		if strings.HasPrefix(path, route) {
			return true
		}
	}

	return false
}

// isProtectedRoute checks if the route requires authentication
func isProtectedRoute(path string) bool {
	protectedRoutes := []string{
		"/dashboard",
		"/profile",
		"/investments",
		"/projects/create",
		"/admin",
		"/api/user",
		"/api/projects",
	}

	for _, route := range protectedRoutes {
		if strings.HasPrefix(path, route) {
			return true
		}
	}

	return false
}
EOF
    
    # Replace the original file
    mv /tmp/auth_middleware_fixed.go /var/www/hajifund/frontend/middleware/auth.go
    print_status "Authentication middleware updated to prevent infinite loops"
else
    print_error "Authentication middleware not found"
fi

# 4. Fix JavaScript to prevent infinite redirects
print_step "4. Fixing JavaScript to prevent infinite redirects..."

if [ -f "/var/www/hajifund/frontend/static/js/app.js" ]; then
    print_info "Backing up current app.js..."
    cp /var/www/hajifund/frontend/static/js/app.js /var/www/hajifund/frontend/static/js/app.js.backup
    
    print_info "Fixing JavaScript to prevent infinite redirects..."
    
    # Create a fixed version of app.js
    cat > /tmp/app_no_loop.js << 'EOF'
// HajiFund Frontend JavaScript - No Infinite Loop Version

// Global variables for authentication state
let isLoggedIn = false;
let currentUser = null;
let redirectInProgress = false; // Prevent infinite redirects

// Utility functions
function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    const toastBody = document.getElementById('toast-body');
    
    if (toast && toastBody) {
        toastBody.textContent = message;
        toast.className = `toast toast-${type}`;
        
        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();
    }
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0
    }).format(amount);
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('id-ID', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// VPS-specific cookie handling
function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) {
        return parts.pop().split(';').shift();
    }
    return null;
}

function setCookie(name, value, days = 7) {
    const expires = new Date();
    expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000));
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;domain=103.103.20.68;SameSite=Lax`;
}

function deleteCookie(name) {
    document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;domain=103.103.20.68`;
}

// Authentication state management
function checkAuthStatus() {
    console.log('🔍 Checking authentication status...');
    console.log('🔍 Document cookies:', document.cookie);
    
    const authToken = getCookie('auth_token');
    console.log('🔍 Auth token from cookie:', authToken);
    
    if (authToken && authToken !== 'null' && authToken !== 'undefined') {
        isLoggedIn = true;
        console.log('✅ User is logged in');
        
        // Try to decode JWT token to get user info
        try {
            const payload = JSON.parse(atob(authToken.split('.')[1]));
            currentUser = {
                id: payload.user_id,
                email: payload.email,
                name: payload.name,
                roles: payload.roles || []
            };
            console.log('✅ User info:', currentUser);
        } catch (error) {
            console.log('❌ Could not decode JWT token:', error);
        }
        
        return true;
    } else {
        isLoggedIn = false;
        currentUser = null;
        console.log('❌ User is not logged in');
        return false;
    }
}

function updateUserMenu() {
    console.log('🔄 Updating user menu...');
    
    const loginMenu = document.getElementById('login-menu');
    const userMenu = document.getElementById('user-menu');
    const userProfile = document.getElementById('user-profile');
    const userDropdown = document.getElementById('user-dropdown');
    
    if (isLoggedIn && currentUser) {
        console.log('✅ Showing user menu for:', currentUser.name);
        
        // Show user menu, hide login menu
        if (loginMenu) loginMenu.style.display = 'none';
        if (userMenu) userMenu.style.display = 'block';
        
        // Update user profile info
        if (userProfile) {
            userProfile.textContent = currentUser.name || currentUser.email;
        }
        
        // Update user dropdown
        if (userDropdown) {
            const userName = userDropdown.querySelector('.user-name');
            const userEmail = userDropdown.querySelector('.user-email');
            
            if (userName) userName.textContent = currentUser.name || 'User';
            if (userEmail) userEmail.textContent = currentUser.email;
        }
    } else {
        console.log('❌ Showing login menu');
        
        // Show login menu, hide user menu
        if (loginMenu) loginMenu.style.display = 'block';
        if (userMenu) userMenu.style.display = 'none';
    }
}

function redirectIfNeeded() {
    // Prevent infinite redirects
    if (redirectInProgress) {
        console.log('🔄 Redirect already in progress, skipping...');
        return;
    }
    
    const currentPath = window.location.pathname;
    console.log('🔄 Checking redirect for path:', currentPath);
    
    // If on login/register page and logged in, redirect to dashboard
    if (isLoggedIn && (currentPath === '/login' || currentPath === '/register')) {
        console.log('✅ User is logged in, redirecting from', currentPath, 'to dashboard');
        
        // Set redirect flag to prevent infinite loops
        redirectInProgress = true;
        
        // Show loading message
        showToast('Anda sudah login, mengalihkan ke dashboard...', 'info');
        
        setTimeout(() => {
            if (currentUser && currentUser.roles && currentUser.roles.includes('admin')) {
                window.location.href = '/admin';
            } else {
                window.location.href = '/dashboard';
            }
        }, 1000);
    }
    
    // If on protected page and not logged in, redirect to login
    if (!isLoggedIn && (currentPath === '/dashboard' || currentPath === '/profile' || currentPath === '/investments')) {
        console.log('❌ User is not logged in, redirecting from', currentPath, 'to login');
        redirectInProgress = true;
        window.location.href = '/login';
    }
}

// Authentication functions
async function login(email, password) {
    try {
        console.log('🔄 Attempting login for:', email);
        
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include', // CRITICAL: Include cookies
            body: JSON.stringify({ email, password })
        });

        console.log('🔄 Login response status:', response.status);
        
        const data = await response.json();
        console.log('🔄 Login response data:', data);

        if (data.status === 'success') {
            showToast('Login berhasil!', 'success');
            
            // Update auth state
            checkAuthStatus();
            updateUserMenu();
            
            // Redirect based on user role
            setTimeout(() => {
                if (currentUser && currentUser.roles && currentUser.roles.includes('admin')) {
                    window.location.href = '/admin';
                } else {
                    window.location.href = data.redirect || '/dashboard';
                }
            }, 1000);
        } else {
            showToast(data.message || 'Login gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat login', 'error');
        console.error('Login error:', error);
    }
}

async function register(formData) {
    try {
        console.log('🔄 Attempting registration for:', formData.email);
        
        const response = await fetch('/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include', // CRITICAL: Include cookies
            body: JSON.stringify(formData)
        });

        console.log('🔄 Register response status:', response.status);
        
        const data = await response.json();
        console.log('🔄 Register response data:', data);

        if (data.status === 'success') {
            showToast('Registrasi berhasil!', 'success');
            
            // Update auth state
            checkAuthStatus();
            updateUserMenu();
            
            setTimeout(() => {
                window.location.href = data.redirect || '/dashboard';
            }, 1000);
        } else {
            showToast(data.message || 'Registrasi gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat registrasi', 'error');
        console.error('Register error:', error);
    }
}

async function logout() {
    try {
        console.log('🔄 Attempting logout...');
        
        const response = await fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include' // CRITICAL: Include cookies
        });

        const data = await response.json();
        console.log('🔄 Logout response:', data);

        if (data.status === 'success') {
            showToast('Logout berhasil!', 'success');
        }
        
        // Clear auth state
        isLoggedIn = false;
        currentUser = null;
        updateUserMenu();
        
        setTimeout(() => {
            window.location.href = '/';
        }, 1000);
    } catch (error) {
        console.error('Logout error:', error);
        // Force logout even if API call fails
        isLoggedIn = false;
        currentUser = null;
        updateUserMenu();
        window.location.href = '/';
    }
}

// Form handlers
function handleLoginForm(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const email = formData.get('email');
    const password = formData.get('password');
    
    if (!email || !password) {
        showToast('Email dan password harus diisi', 'error');
        return;
    }
    
    login(email, password);
}

function handleRegisterForm(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const registerData = {
        name: formData.get('name'),
        email: formData.get('email'),
        password: formData.get('password'),
        phone: formData.get('phone'),
        address: formData.get('address'),
        cooperative_id: formData.get('cooperative_id') || null,
        roles: [formData.get('role')]
    };
    
    // Validation
    if (!registerData.name || !registerData.email || !registerData.password) {
        showToast('Nama, email, dan password harus diisi', 'error');
        return;
    }
    
    if (registerData.password.length < 6) {
        showToast('Password minimal 6 karakter', 'error');
        return;
    }
    
    register(registerData);
}

// Investment functions
async function investInProject(projectId, amount) {
    try {
        const response = await fetch(`/api/projects/${projectId}/invest`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            credentials: 'include', // CRITICAL: Include cookies
            body: JSON.stringify({ amount })
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Investasi berhasil!', 'success');
            setTimeout(() => {
                window.location.reload();
            }, 1000);
        } else {
            showToast(data.message || 'Investasi gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat investasi', 'error');
        console.error('Investment error:', error);
    }
}

// Project progress calculation
function calculateProgress(raised, target) {
    if (target === 0) return 0;
    return Math.min((raised / target) * 100, 100);
}

// Real-time updates using WebSocket (placeholder)
function initWebSocket() {
    // This would connect to a WebSocket for real-time updates
    // For now, we'll use polling
    setInterval(updateProjectProgress, 30000); // Update every 30 seconds
}

function updateProjectProgress() {
    // Update project progress bars and funding amounts
    const progressBars = document.querySelectorAll('.project-progress');
    progressBars.forEach(bar => {
        const projectId = bar.dataset.projectId;
        // Fetch updated progress from API
        fetch(`/api/projects/${projectId}/progress`, {
            credentials: 'include' // CRITICAL: Include cookies
        })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    const progress = calculateProgress(data.data.raised_amount, data.data.target_amount);
                    bar.style.width = `${progress}%`;
                    
                    // Update raised amount display
                    const raisedElement = document.querySelector(`[data-project="${projectId}"] .raised-amount`);
                    if (raisedElement) {
                        raisedElement.textContent = formatCurrency(data.data.raised_amount);
                    }
                }
            })
            .catch(error => console.error('Progress update error:', error));
    });
}

// File upload helper (for cloud storage links)
function handleFileUpload(file, callback) {
    // This would integrate with cloud storage services
    // For now, we'll show a placeholder
    showToast('Fitur upload file akan segera tersedia', 'info');
    callback('https://example.com/placeholder-file.pdf');
}

// Hero section data fetching
async function fetchHeroData() {
    try {
        const response = await fetch('http://103.103.20.68:8080/api/v1/public/hero', {
            credentials: 'include' // CRITICAL: Include cookies
        });
        const data = await response.json();
        
        if (data.status === 'success') {
            updateHeroContent(data.data);
        }
    } catch (error) {
        console.error('Hero data fetch error:', error);
    }
}

function updateHeroContent(heroData) {
    // Update hero title
    const titleElement = document.querySelector('.hero-title');
    if (titleElement && heroData.hero_content?.title) {
        titleElement.textContent = heroData.hero_content.title;
    }
    
    // Update hero subtitle
    const subtitleElement = document.querySelector('.hero-subtitle');
    if (subtitleElement && heroData.hero_content?.subtitle) {
        subtitleElement.textContent = heroData.hero_content.subtitle;
    }
    
    // Update CTA buttons
    const ctaContainer = document.querySelector('.d-flex.flex-wrap.gap-3.mb-4');
    if (ctaContainer && heroData.hero_content?.cta_buttons) {
        ctaContainer.innerHTML = '';
        heroData.hero_content.cta_buttons.forEach(button => {
            const buttonElement = document.createElement('a');
            buttonElement.href = button.url;
            buttonElement.textContent = button.text;
            buttonElement.className = button.type === 'outline' 
                ? 'btn btn-outline-success btn-lg px-4' 
                : 'btn btn-success btn-lg px-4';
            ctaContainer.appendChild(buttonElement);
        });
    }
    
    // Update hero image
    const heroImage = document.querySelector('.hero-person-image img');
    if (heroImage && heroData.hero_content?.hero_image?.url) {
        heroImage.src = heroData.hero_content.hero_image.url;
        heroImage.alt = heroData.hero_content.hero_image.alt;
    }
}

// Dashboard statistics
function updateDashboardStats() {
    // Dashboard stats will be loaded from server-side rendering
    // No need for additional API call
    console.log('Dashboard stats loaded from server');
}

function updateStatCards(stats) {
    const statElements = {
        'total-investments': stats.total_investments || 0,
        'total-projects': stats.total_projects || 0,
        'total-returns': stats.total_returns || 0,
        'active-projects': stats.active_projects || 0
    };
    
    Object.entries(statElements).forEach(([id, value]) => {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = formatCurrency(value);
        }
    });
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 DOM loaded, checking authentication state...');
    console.log('🌐 Current URL:', window.location.href);
    console.log('🍪 Document cookies:', document.cookie);
    
    // Check authentication status first
    checkAuthStatus();
    updateUserMenu();
    
    // Only redirect if not already in progress
    if (!redirectInProgress) {
        redirectIfNeeded();
    }
    
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Initialize WebSocket for real-time updates
    initWebSocket();

    // Update dashboard stats if on dashboard page
    if (window.location.pathname === '/dashboard') {
        updateDashboardStats();
    }
    
    // Fetch hero data if on landing page
    if (window.location.pathname === '/') {
        fetchHeroData();
    }

    // Handle form submissions
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLoginForm);
    }

    const registerForm = document.getElementById('registerForm');
    if (registerForm) {
        registerForm.addEventListener('submit', handleRegisterForm);
    }

    // Handle investment buttons
    const investButtons = document.querySelectorAll('.invest-btn');
    investButtons.forEach(button => {
        button.addEventListener('click', function() {
            const projectId = this.dataset.projectId;
            const amount = prompt('Masukkan jumlah investasi (Rp):');
            
            if (amount && !isNaN(amount) && parseFloat(amount) > 0) {
                investInProject(projectId, parseFloat(amount));
            }
        });
    });
    
    // Handle logout buttons
    const logoutButtons = document.querySelectorAll('.logout-btn');
    logoutButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            logout();
        });
    });
});

// Export functions for global access
window.HajiFund = {
    login,
    register,
    logout,
    showToast,
    formatCurrency,
    formatDate,
    investInProject,
    handleFileUpload,
    checkAuthStatus,
    updateUserMenu,
    redirectIfNeeded,
    getCookie,
    setCookie,
    deleteCookie
};
EOF
    
    # Replace the original file
    mv /tmp/app_no_loop.js /var/www/hajifund/frontend/static/js/app.js
    print_status "JavaScript updated to prevent infinite redirects"
else
    print_error "Frontend app.js not found"
fi

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
print_status "Services restarted with infinite loop fixes"

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

print_status "Infinite redirect loop fix completed!"
print_info "Issues addressed:"
print_info "1. Authentication middleware updated to prevent infinite loops"
print_info "2. JavaScript updated with redirect protection"
print_info "3. Route handling improved"
print_info "4. Services rebuilt and restarted"

print_info "Key fixes:"
print_info "1. Added redirectInProgress flag to prevent infinite loops"
print_info "2. Improved route checking in middleware"
print_info "3. Better error handling for authentication"
print_info "4. Cleaner redirect logic"

print_info "Test your application now:"
print_info "1. Open browser developer tools"
print_info "2. Check Console for authentication logs"
print_info "3. Verify no infinite redirects"
print_info "4. Test login/logout functionality"
print_info "5. Check that dashboard loads properly"
