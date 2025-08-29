package main

import (
	"log"
	"os"
	"time"

	"comfunds/internal/auth"
	"comfunds/internal/config"
	"comfunds/internal/controllers"
	"comfunds/internal/database"
	"comfunds/internal/repositories"
	"comfunds/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Load configuration
	cfg := config.Load()

	// Set Gin mode
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize sharded database manager
	shardConfig := database.ShardConfig{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     5432,
		Username: getEnv("DB_USER", "postgres"),
		Password: getEnv("DB_PASSWORD", ""),
		SSLMode:  getEnv("DB_SSLMODE", "disable"),
	}

	shardMgr, err := database.NewShardManager(shardConfig)
	if err != nil {
		log.Fatal("Failed to initialize shard manager:", err)
	}
	defer shardMgr.Close()

	// Initialize JWT manager
	jwtManager := auth.NewJWTManager(cfg.JWTSecret, 24*time.Hour) // 24 hours for access token

	// Initialize repositories
	userRepo := repositories.NewUserRepositorySharded(shardMgr)
	cooperativeRepo := repositories.NewCooperativeRepository(shardMgr)

	// Initialize audit repository and service
	auditRepo := repositories.NewAuditRepository(shardMgr)
	auditService := services.NewAuditService(auditRepo)

	// Initialize specialized services for cooperative management
	investmentPolicyService := services.NewInvestmentPolicyService(auditService)
	projectApprovalService := services.NewProjectApprovalService(auditService)
	fundMonitoringService := services.NewFundMonitoringService(auditService)
	memberRegistryService := services.NewMemberRegistryService(userRepo, cooperativeRepo, auditService)
	businessManagementService := services.NewBusinessManagementService(auditService)
	investmentFundingService := services.NewInvestmentFundingService(auditService)
	fundManagementService := services.NewFundManagementService(auditService)
	profitSharingService := services.NewProfitSharingService(auditService)

	// Initialize services
	userService := services.NewUserServiceAuth(userRepo, cooperativeRepo, jwtManager)
	userServiceWithAudit := services.NewUserServiceWithAudit(userService, auditService, userRepo)
	cooperativeService := services.NewCooperativeService(cooperativeRepo, userRepo, auditService, investmentPolicyService, projectApprovalService, fundMonitoringService, memberRegistryService)

	// Initialize controllers
	authController := controllers.NewAuthController(userService)
	roleController := controllers.NewRoleController(userService)
	projectController := controllers.NewProjectController()
	userControllerWithAudit := controllers.NewUserControllerWithAudit(userServiceWithAudit)
	cooperativeController := controllers.NewCooperativeController(cooperativeService)
	businessController := controllers.NewBusinessController(businessManagementService)
	investmentFundingController := controllers.NewInvestmentFundingController(investmentFundingService)
	fundManagementController := controllers.NewFundManagementController(fundManagementService)
	profitSharingController := controllers.NewProfitSharingController(profitSharingService)

	// Initialize permission middleware
	permissionMiddleware := auth.NewPermissionMiddleware()

	// Setup router
	router := gin.Default()

	// CORS middleware
	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// API routes
	v1 := router.Group("/api/v1")
	{
		// Health check
		v1.GET("/health", func(c *gin.Context) {
			// Check shard health
			shardHealth := shardMgr.HealthCheck()

			c.JSON(200, gin.H{
				"status":       "OK",
				"message":      "ComFunds API is running",
				"version":      "2.0.0",
				"timestamp":    time.Now(),
				"shard_health": shardHealth,
			})
		})

		// Authentication routes (no auth required)
		authRoutes := v1.Group("/auth")
		{
			authRoutes.POST("/register", authController.RegisterUser)
			authRoutes.POST("/login", authController.LoginUser)
			authRoutes.POST("/refresh", authController.RefreshToken)
		}

		// Public routes (no authentication required) - FR-006: Guest Users
		public := v1.Group("/public")
		public.Use(auth.OptionalAuth(jwtManager))
		{
			// FR-006: Guest users can view public project information only
			public.GET("/projects", projectController.GetPublicProjects)
		}

		// Role information (public)
		v1.GET("/roles/info", roleController.GetRoleInfo)

		// Protected routes (require authentication)
		protected := v1.Group("/")
		protected.Use(auth.AuthMiddleware(jwtManager))
		{
			// Profile routes
			profile := protected.Group("/auth")
			{
				profile.GET("/profile", authController.GetProfile)
				profile.PUT("/profile", authController.UpdateProfile)
			}

			// User role management
			user := protected.Group("/user")
			{
				user.GET("/roles", roleController.GetUserRoles)
				user.PUT("/roles", roleController.UpdateUserRoles)

				// FR-008: Business Owners can manage their projects
				user.GET("/projects", permissionMiddleware.RequirePermission(auth.PermissionManageOwnProjects), projectController.GetUserProjects)
			}

			// FR-007: Cooperative Members can view cooperative projects
			cooperative := protected.Group("/cooperative")
			cooperative.Use(permissionMiddleware.RequireCooperativeAccess())
			{
				cooperative.GET("/projects", projectController.GetCooperativeProjects)
			}

			// FR-008: Business Owners can create and manage projects
			projects := protected.Group("/projects")
			{
				projects.POST("", permissionMiddleware.RequirePermission(auth.PermissionCreateProject), projectController.CreateProject)
			}

			// FR-041 to FR-045: Investment & Funding System
			investments := protected.Group("/investments")
			{
				// Investment creation and validation
				investments.POST("", investmentFundingController.CreateInvestment)                                  // FR-041: Create investment
				investments.GET("/validate/:project_id", investmentFundingController.ValidateInvestmentEligibility) // FR-042: Validate eligibility
				investments.GET("/:id", investmentFundingController.GetInvestment)                                  // Get investment details
				investments.PUT("/:id", investmentFundingController.UpdateInvestment)                               // Update investment
				investments.DELETE("/:id", investmentFundingController.CancelInvestment)                            // Cancel investment

				// Project investments and funding progress
				investments.GET("/project/:project_id", investmentFundingController.GetProjectInvestments)                   // FR-044: Multiple investors
				investments.GET("/project/:project_id/progress", investmentFundingController.GetProjectFundingProgress)      // Funding progress
				investments.GET("/project/:project_id/analytics", investmentFundingController.GetProjectInvestmentAnalytics) // Analytics

				// Investment limits (FR-045)
				investments.GET("/project/:project_id/limits", investmentFundingController.GetProjectInvestmentLimits)                                           // Get limits
				investments.POST("/project/:project_id/limits", permissionMiddleware.RequireAdminRole(), investmentFundingController.SetProjectInvestmentLimits) // Set limits

				// Investor portfolio
				investments.GET("/portfolio", investmentFundingController.GetInvestorPortfolio)        // Portfolio summary
				investments.GET("/my-investments", investmentFundingController.GetInvestorInvestments) // My investments
			}

			// Investment approval routes (admin/cooperative admin)
			investmentAdmin := protected.Group("/admin/investments")
			investmentAdmin.Use(permissionMiddleware.RequireAdminRole())
			{
				investmentAdmin.POST("/approve", investmentFundingController.ApproveInvestment)                   // Approve investment
				investmentAdmin.POST("/reject", investmentFundingController.RejectInvestment)                     // Reject investment
				investmentAdmin.GET("/summary/:cooperative_id", investmentFundingController.GetInvestmentSummary) // Investment summary
			}

			// FR-046 to FR-049: Fund Management System
			funds := protected.Group("/funds")
			{
				// Fund disbursement management
				funds.POST("/disbursements", fundManagementController.CreateFundDisbursement)                      // FR-046: Create disbursement
				funds.GET("/disbursements/:id", fundManagementController.GetFundDisbursement)                      // Get disbursement details
				funds.GET("/projects/:project_id/disbursements", fundManagementController.GetProjectDisbursements) // Get project disbursements
				funds.POST("/disbursements/:id/approve", fundManagementController.ApproveFundDisbursement)         // Approve disbursement
				funds.POST("/disbursements/:id/reject", fundManagementController.RejectFundDisbursement)           // Reject disbursement
				funds.POST("/disbursements/:id/process", fundManagementController.ProcessFundDisbursement)         // Process disbursement

				// Fund usage tracking (FR-047)
				funds.POST("/usage", fundManagementController.CreateFundUsage)                                   // Create fund usage
				funds.GET("/usage/:id", fundManagementController.GetFundUsage)                                   // Get fund usage details
				funds.GET("/disbursement-usage/:disbursement_id", fundManagementController.GetDisbursementUsage) // Get disbursement usage
				funds.POST("/usage/:id/verify", fundManagementController.VerifyFundUsage)                        // Verify fund usage

				// Fund balance and audit trail (FR-048)
				funds.GET("/cooperatives/:cooperative_id/balance", fundManagementController.GetCooperativeFundBalance) // Get cooperative balance
				funds.GET("/projects/:project_id/balance", fundManagementController.GetProjectFundBalance)             // Get project balance
				funds.GET("/projects/:project_id/audit-trail", fundManagementController.GetFundAuditTrail)             // Get fund audit trail

				// Fund refunds (FR-049)
				funds.POST("/refunds", fundManagementController.CreateFundRefund)                      // Create fund refund
				funds.GET("/refunds/:id", fundManagementController.GetFundRefund)                      // Get refund details
				funds.GET("/projects/:project_id/refunds", fundManagementController.GetProjectRefunds) // Get project refunds
				funds.POST("/refunds/:id/process", fundManagementController.ProcessFundRefund)         // Process refund
				funds.POST("/refunds/:id/complete", fundManagementController.CompleteFundRefund)       // Complete refund
			}

			// Fund management admin routes
			fundAdmin := protected.Group("/admin/funds")
			fundAdmin.Use(permissionMiddleware.RequireAdminRole())
			{
				fundAdmin.GET("/summary/:cooperative_id", fundManagementController.GetFundManagementSummary)       // Fund management summary
				fundAdmin.GET("/projects/:project_id/analytics", fundManagementController.GetProjectFundAnalytics) // Project fund analytics
			}

			// Admin routes (cooperative administrators)
			admin := protected.Group("/admin")
			admin.Use(permissionMiddleware.RequireAdminRole())
			{
				admin.GET("/users/role/:role", roleController.GetUsersByRole)

				// FR-011 to FR-014: User CRUD Operations with Audit Trail
				admin.GET("/users", userControllerWithAudit.GetUsers)
				admin.GET("/users/:id", userControllerWithAudit.GetUser)
				admin.PUT("/users/:id", userControllerWithAudit.UpdateUser)
				admin.DELETE("/users/:id", userControllerWithAudit.SoftDeleteUser)
				admin.GET("/users/:id/audit", userControllerWithAudit.GetUserAuditTrail)

				// FR-027: Business approval management
				admin.GET("/businesses/pending", businessController.GetPendingBusinessApprovals)
				admin.POST("/businesses/approve", businessController.ApproveBusiness)
				admin.POST("/businesses/reject", businessController.RejectBusiness)
			}

			// FR-015 to FR-023: Cooperative Management
			cooperatives := protected.Group("/cooperatives")
			{
				// Public cooperative operations (require authentication)
				cooperatives.GET("", cooperativeController.GetCooperatives)
				cooperatives.GET("/:id", cooperativeController.GetCooperative)
				cooperatives.GET("/:id/members", cooperativeController.GetCooperativeMembers)

				// Admin-only cooperative operations
				cooperatives.POST("", permissionMiddleware.RequireAdminRole(), cooperativeController.CreateCooperative)
				cooperatives.PUT("/:id", permissionMiddleware.RequireAdminRole(), cooperativeController.UpdateCooperative)
				cooperatives.DELETE("/:id", permissionMiddleware.RequireAdminRole(), cooperativeController.DeleteCooperative)

				// FR-020: Project approval/rejection
				cooperatives.POST("/:id/projects/:project_id/approve", permissionMiddleware.RequireAdminRole(), cooperativeController.ApproveProject)
			}

			// FR-024 to FR-031: Business Management
			businesses := protected.Group("/businesses")
			{
				// Business CRUD operations
				businesses.POST("", businessController.CreateBusiness)                                // FR-024: Business owners only
				businesses.GET("/:id", businessController.GetBusiness)                                // FR-028: View business details
				businesses.PUT("/:id", businessController.UpdateBusiness)                             // FR-028: Update business (owner only)
				businesses.POST("/:id/submit-approval", businessController.SubmitBusinessForApproval) // FR-027: Submit for approval

				// Performance metrics and reports
				businesses.POST("/:id/metrics", businessController.RecordPerformanceMetrics) // FR-030: Record metrics
				businesses.POST("/:id/reports", businessController.GenerateFinancialReport)  // FR-031: Generate reports
				businesses.GET("/:id/analytics", businessController.GetBusinessAnalytics)    // FR-030: Analytics
			}

			// User's business management (FR-029: Multiple business management)
			userRoutes := protected.Group("/user")
			{
				userRoutes.GET("/businesses", businessController.GetOwnerBusinesses) // FR-029: Get owned businesses
			}

			// FR-050 to FR-057: Profit-Sharing & Returns System
			profitSharing := protected.Group("/profit-sharing")
			{
				// Profit calculation (FR-050 to FR-053)
				profitSharing.POST("/calculations", profitSharingController.CreateProfitCalculation)                          // Create profit calculation
				profitSharing.GET("/calculations/:id", profitSharingController.GetProfitCalculation)                          // Get calculation details
				profitSharing.GET("/projects/:project_id/calculations", profitSharingController.GetProjectProfitCalculations) // Get project calculations
				profitSharing.POST("/calculations/verify", profitSharingController.VerifyProfitCalculation)                   // Verify calculation (admin/cooperative)

				// Profit distribution (FR-054 to FR-056)
				profitSharing.POST("/distributions", profitSharingController.CreateProfitDistribution)                          // Create distribution
				profitSharing.POST("/distributions/process", profitSharingController.ProcessProfitDistribution)                 // Process distribution
				profitSharing.GET("/distributions/:id", profitSharingController.GetProfitDistribution)                          // Get distribution details
				profitSharing.GET("/projects/:project_id/distributions", profitSharingController.GetProjectProfitDistributions) // Get project distributions

				// Tax documentation (FR-057)
				profitSharing.POST("/tax-documents", profitSharingController.CreateTaxDocumentation)                                   // Create tax document
				profitSharing.GET("/tax-documents/:id", profitSharingController.GetTaxDocumentation)                                   // Get tax document
				profitSharing.GET("/distribution-tax-documents/:distribution_id", profitSharingController.GetDistributionTaxDocuments) // Get distribution tax docs

				// ComFunds Fee Management
				profitSharing.POST("/fees", profitSharingController.CreateComFundsFee)              // Create fee structure
				profitSharing.PUT("/fees/:id", profitSharingController.UpdateComFundsFee)           // Update fee structure
				profitSharing.POST("/fees/:id/enable", profitSharingController.EnableComFundsFee)   // Enable fee
				profitSharing.POST("/fees/:id/disable", profitSharingController.DisableComFundsFee) // Disable fee
				profitSharing.GET("/fees/:id", profitSharingController.GetComFundsFee)              // Get fee details
				profitSharing.GET("/fees/active", profitSharingController.GetActiveComFundsFees)    // Get active fees

				// Project fee calculation
				profitSharing.POST("/project-fees/calculate", profitSharingController.CalculateProjectFee)         // Calculate project fee
				profitSharing.POST("/project-fees/collect", profitSharingController.CollectProjectFee)             // Collect project fee
				profitSharing.POST("/project-fees/:id/waive", profitSharingController.WaiveProjectFee)             // Waive project fee
				profitSharing.GET("/project-fees/:id", profitSharingController.GetProjectFeeCalculation)           // Get fee calculation
				profitSharing.GET("/projects/:project_id/fees", profitSharingController.GetProjectFeeCalculations) // Get project fees
			}

			// Profit sharing admin routes
			profitSharingAdmin := protected.Group("/admin/profit-sharing")
			profitSharingAdmin.Use(permissionMiddleware.RequireAdminRole())
			{
				profitSharingAdmin.GET("/summary/:cooperative_id", profitSharingController.GetProfitSharingSummary)          // Profit sharing summary
				profitSharingAdmin.GET("/projects/:project_id/analytics", profitSharingController.GetProjectProfitAnalytics) // Project profit analytics
				profitSharingAdmin.GET("/fees/analytics", profitSharingController.GetComFundsFeeAnalytics)                   // Fee analytics
			}
		}
	}

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = cfg.Port
	}

	log.Printf("ComFunds Crowdfunding Platform starting on port %s", port)
	log.Printf("Sharded database initialized with %d shards", 4)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

// Helper function to get environment variables with default values
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
