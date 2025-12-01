package main

import (
	"hajifund-frontend/handlers"
	"hajifund-frontend/middleware"
	"log"
	"os"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/template/html/v2"
	"github.com/joho/godotenv"
)

// Helper function for string replacement
func replaceString(s, old, new string) string {
	return strings.ReplaceAll(s, old, new)
}

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Initialize HTML template engine
	engine := html.New("./views", ".html")
	engine.Reload(true) // Enable auto-reload in development

	// Add template functions
	engine.AddFunc("hasRole", func(roles []string, role string) bool {
		for _, r := range roles {
			if r == role {
				return true
			}
		}
		return false
	})

	// Deduplicate roles array
	engine.AddFunc("uniqueRoles", func(roles []string) []string {
		seen := make(map[string]bool)
		result := []string{}
		for _, role := range roles {
			if !seen[role] {
				seen[role] = true
				result = append(result, role)
			}
		}
		return result
	})

	// Add math functions for templates
	engine.AddFunc("add", func(a, b int) int {
		return a + b
	})

	engine.AddFunc("sub", func(a, b int) int {
		return a - b
	})

	engine.AddFunc("mul", func(a, b float64) float64 {
		return a * b
	})

	engine.AddFunc("div", func(a, b float64) float64 {
		if b == 0 {
			return 0
		}
		return a / b
	})

	// Add Indonesian date formatting function
	engine.AddFunc("formatDateID", func(t interface{}, layout string) string {
		if t == nil {
			return ""
		}

		// Type assertion to time.Time
		var timeVal interface{}
		timeVal = t

		switch v := timeVal.(type) {
		case interface{ IsZero() bool }:
			if v.IsZero() {
				return ""
			}
		}

		// Format the date
		formatted := ""
		if layout == "date" {
			// Format: "11 Oktober 2025"
			formatted = t.(interface{ Format(string) string }).Format("02 January 2006")
		} else if layout == "datetime" {
			// Format: "11 Oktober 2025 13:22"
			formatted = t.(interface{ Format(string) string }).Format("02 January 2006 15:04")
		} else {
			// Custom format
			formatted = t.(interface{ Format(string) string }).Format(layout)
		}

		// Replace English month names with Indonesian
		monthMap := map[string]string{
			"January":   "Januari",
			"February":  "Februari",
			"March":     "Maret",
			"April":     "April",
			"May":       "Mei",
			"June":      "Juni",
			"July":      "Juli",
			"August":    "Agustus",
			"September": "September",
			"October":   "Oktober",
			"November":  "November",
			"December":  "Desember",
		}

		for eng, ind := range monthMap {
			if len(formatted) > 0 {
				formatted = replaceString(formatted, eng, ind)
			}
		}

		return formatted
	})

	// Create Fiber app
	app := fiber.New(fiber.Config{
		Views:     engine,
		BodyLimit: 10 * 1024 * 1024, // 10MB limit for file uploads
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
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins:     "http://localhost:8080",
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization",
		AllowMethods:     "GET, POST, PUT, DELETE, OPTIONS",
		AllowCredentials: true, // Allow cookies to be sent
	}))

	// Static files
	app.Static("/static", "./static")

	// Initialize handlers
	authHandler := handlers.NewAuthHandler()
	dashboardHandler := handlers.NewDashboardHandler()
	adminHandler := handlers.NewAdminHandler()
	cooperativeHandler := handlers.NewCooperativeHandler()
	projectHandler := handlers.NewProjectHandler()
	investmentHandler := handlers.NewInvestmentHandler()
	businessHandler := handlers.NewBusinessHandler()
	uploadHandler := handlers.NewUploadHandler()

	// Test route
	app.Get("/test", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "success",
			"message": "HajiFund Frontend is running!",
		})
	})

	// Routes
	setupRoutes(app, authHandler, dashboardHandler, adminHandler, cooperativeHandler, projectHandler, investmentHandler, businessHandler, uploadHandler)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	log.Printf("🚀 HajiFund Frontend starting on port %s", port)
	log.Fatal(app.Listen(":" + port))
}

func setupRoutes(app *fiber.App, authHandler, dashboardHandler, adminHandler, cooperativeHandler, projectHandler, investmentHandler, businessHandler, uploadHandler *handlers.Handler) {
	// Admin registration route (public, no auth required) - using unique path to avoid conflicts
	app.Get("/admin-registration", func(c *fiber.Ctx) error {
		println("🔍 Admin registration route called")
		return c.JSON(fiber.Map{"message": "Admin registration route is working!"})
	})

	// Admin registration route
	app.Get("/admin/register", adminHandler.AdminRegisterPage)

	// Public routes with optional authentication
	app.Get("/", middleware.OptionalAuthMiddleware, handlers.LandingPage)
	app.Get("/tentang-kami", middleware.OptionalAuthMiddleware, handlers.AboutPage)
	app.Get("/info-pembiayaan", middleware.OptionalAuthMiddleware, handlers.InfoPembiayaanPage)
	app.Get("/ajukan-pembiayaan", middleware.OptionalAuthMiddleware, handlers.AjukanPembiayaanPage)
	app.Get("/kisah-sukses", middleware.OptionalAuthMiddleware, handlers.KisahSuksesPage)
	app.Get("/syarat-ketentuan", middleware.OptionalAuthMiddleware, handlers.SyaratKetentuanPage)
	app.Get("/kebijakan-privasi", middleware.OptionalAuthMiddleware, handlers.KebijakanPrivasiPage)
	app.Get("/login", middleware.OptionalAuthMiddleware, authHandler.LoginPage)
	app.Get("/register", middleware.OptionalAuthMiddleware, authHandler.RegisterPage)
	app.Post("/api/auth/login", authHandler.Login)
	app.Post("/api/auth/register", authHandler.Register)
	app.Post("/api/auth/logout", authHandler.Logout)

	// Public project routes (FR-006: Guest users can view public projects)
	app.Get("/projects/public", middleware.OptionalAuthMiddleware, projectHandler.PublicProjectsPage)

	// Protected routes (require authentication)
	protected := app.Group("/", middleware.AuthMiddleware)
	{
		// Dashboard routes
		protected.Get("/dashboard", dashboardHandler.Dashboard)
		protected.Get("/profile", dashboardHandler.Profile)
		protected.Put("/api/profile", dashboardHandler.UpdateProfile)

		// Project routes (FR-032 to FR-040)
		protected.Get("/projects", projectHandler.UserProjectsPage)
		protected.Get("/projects/create", middleware.RequireBusinessOwner, projectHandler.CreateProjectPage)
		protected.Post("/api/projects", middleware.RequireBusinessOwner, projectHandler.CreateProject)
		protected.Get("/projects/:id", projectHandler.ProjectDetail)
		protected.Put("/api/projects/:id", projectHandler.UpdateProject)

		// Investment routes (FR-041 to FR-049, FR-054 to FR-057)
		protected.Get("/investments", middleware.RequireInvestor, investmentHandler.UserInvestmentsPage)
		protected.Get("/investments/:id", middleware.RequireInvestor, investmentHandler.InvestmentDetailPage)
		protected.Get("/portfolio", middleware.RequireInvestor, investmentHandler.PortfolioPage)
		protected.Get("/projects/:id/invest", middleware.RequireInvestor, investmentHandler.ProjectInvestmentPage)
		protected.Post("/api/investments", middleware.RequireInvestor, investmentHandler.Invest)
		protected.Get("/api/investments/project/:id/limits", middleware.RequireInvestor, investmentHandler.GetInvestmentLimits)

		// Business routes (FR-024 to FR-031)
		protected.Get("/business", middleware.RequireCooperativeMember, businessHandler.BusinessPage)
		protected.Get("/business/create", middleware.RequireBusinessOwner, businessHandler.CreateBusinessPage)
		protected.Post("/api/businesses", middleware.RequireBusinessOwner, businessHandler.CreateBusiness)
		protected.Get("/business/:id", businessHandler.BusinessDetail)
		protected.Get("/business/:id/edit", middleware.RequireBusinessOwner, businessHandler.EditBusinessPage)
		protected.Put("/api/businesses/:id", middleware.RequireBusinessOwner, businessHandler.UpdateBusiness)
		protected.Post("/api/businesses/:id/submit-approval", middleware.RequireBusinessOwner, businessHandler.SubmitBusinessForApproval)

		// Upload routes
		protected.Post("/api/upload/business-document", uploadHandler.UploadBusinessDocument)
		protected.Delete("/api/upload/business-document", uploadHandler.DeleteBusinessDocument)
	}

	// Admin routes (require admin role) - using /admin prefix
	admin := app.Group("/admin", middleware.AuthMiddleware)
	{
		admin.Get("/", adminHandler.AdminDashboard)
		admin.Get("/users", adminHandler.UsersPage)
		admin.Get("/businesses", adminHandler.BusinessesPage)
		admin.Get("/businesses/:id", adminHandler.BusinessDetailPage)
		admin.Get("/cooperatives", adminHandler.CooperativesPage)
		admin.Get("/projects", adminHandler.ProjectsPage)
		admin.Get("/investments", adminHandler.InvestmentsPage)
		admin.Post("/api/cooperatives/:id/approve", adminHandler.ApproveCooperative)
		admin.Post("/api/projects/:id/approve", adminHandler.ApproveProject)
		admin.Post("/api/projects/:id/reject", adminHandler.RejectProject)
		admin.Put("/api/projects/:id/update-approval", projectHandler.UpdateProjectApproval)
		admin.Post("/api/businesses/:id/approve", adminHandler.ApproveBusiness)
		admin.Post("/api/businesses/:id/reject", adminHandler.RejectBusiness)
		admin.Post("/api/investments/:id/approve", adminHandler.ApproveInvestment)

		// Admin user management routes (FR-007)
		admin.Get("/api/users/:id", adminHandler.GetUser)
		admin.Put("/api/users/:id", adminHandler.UpdateUser)
		admin.Put("/api/users/:id/roles", adminHandler.UpdateUserRoles)
	}

	// Cooperative admin routes (require cooperative admin role)
	coopAdmin := app.Group("/cooperative", middleware.AuthMiddleware, middleware.RequireCooperativeAdmin)
	{
		coopAdmin.Get("/", cooperativeHandler.CooperativeDashboard)
		coopAdmin.Get("/members", cooperativeHandler.MembersPage)
		coopAdmin.Get("/projects", cooperativeHandler.CooperativeProjectsPage)
		coopAdmin.Get("/businesses", cooperativeHandler.CooperativeBusinessesPage)
		coopAdmin.Post("/api/members/:id/approve", cooperativeHandler.ApproveMember)
		coopAdmin.Post("/api/projects/:id/approve", cooperativeHandler.CooperativeApproveProject)
		coopAdmin.Post("/api/businesses/:id/approve", cooperativeHandler.CooperativeApproveBusiness)
		coopAdmin.Post("/api/investments/:id/disburse", cooperativeHandler.DisburseInvestment)
	}
}
