package handlers

import (
	"hajifund-frontend/models"
	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
)

// AdminDashboard renders the admin dashboard with pending approvals (FR-007)
func (h *Handler) AdminDashboard(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	// Fetch pending businesses from backend API (no mock)
	var pendingBusinesses []models.Business
	if resp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/businesses/pending", nil, authHeaders); err == nil && resp.Data != nil {
		if data, ok := resp.Data.(map[string]interface{}); ok {
			if list, ok := data["businesses"].([]interface{}); ok {
				pendingBusinesses = make([]models.Business, 0, len(list))
				for _, item := range list {
					if m, ok := item.(map[string]interface{}); ok {
						pendingBusinesses = append(pendingBusinesses, models.Business{
							ID:             getStringValue(m["id"]),
							Name:           getStringValue(m["name"]),
							Type:           getStringValue(m["type"]),
							Description:    getStringValue(m["description"]),
							ApprovalStatus: getStringValue(m["approval_status"]),
							OwnerID:        getStringValue(m["owner_id"]),
							CooperativeID:  getStringValue(m["cooperative_id"]),
						})
					}
				}
			}
		}
	}

	// Get system statistics
	statsResp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/statistics", nil, authHeaders)
	var systemStats map[string]interface{}
	if err == nil && statsResp.Data != nil {
		if stats, ok := statsResp.Data.(map[string]interface{}); ok {
			systemStats = stats
		}
	}

	return c.Render("admin/dashboard", fiber.Map{
		"Title":             "Admin Dashboard - HajiFund",
		"User":              user,
		"PendingBusinesses": pendingBusinesses,
		"SystemStats":       systemStats,
	}, "base")
}

// UsersPage renders the admin users management page (FR-007)
func (h *Handler) UsersPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	// Get all users
	usersResp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/users", nil, authHeaders)
	var users []models.User
	if err == nil && usersResp.Data != nil {
		if data, ok := usersResp.Data.(map[string]interface{}); ok {
			if userData, ok := data["users"].([]interface{}); ok {
				users = parseUsersFromAPI(userData)
			}
		}
	}

	// Get users by role for statistics
	roleStats := make(map[string]int)
	for _, userItem := range users {
		for _, role := range userItem.Roles {
			roleStats[role]++
		}
	}

	return c.Render("admin/users", fiber.Map{
		"Title":     "User Management - HajiFund Admin",
		"User":      user,
		"Users":     users,
		"RoleStats": roleStats,
	}, "base")
}

// BusinessesPage renders the admin businesses management page
func (h *Handler) BusinessesPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	// Get all businesses for admin review
	var allBusinesses []models.Business
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	// Try to get real businesses from backend API
	businessesResp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/businesses", nil, authHeaders)
	if err == nil && businessesResp.Data != nil {
		if data, ok := businessesResp.Data.(map[string]interface{}); ok {
			if businessesData, ok := data["businesses"].([]interface{}); ok {
				allBusinesses = make([]models.Business, len(businessesData))
				for i, business := range businessesData {
					if businessMap, ok := business.(map[string]interface{}); ok {
						allBusinesses[i] = models.Business{
							ID:             getStringValue(businessMap["id"]),
							Name:           getStringValue(businessMap["name"]),
							Type:           getStringValue(businessMap["type"]),
							Description:    getStringValue(businessMap["description"]),
							ApprovalStatus: getStringValue(businessMap["approval_status"]),
							OwnerID:        getStringValue(businessMap["owner_id"]),
							CooperativeID:  getStringValue(businessMap["cooperative_id"]),
						}
					}
				}
			}
		}
	}

	// Compute counts
	pendingCount := 0
	approvedCount := 0
	rejectedCount := 0
	for _, b := range allBusinesses {
		switch b.ApprovalStatus {
		case "pending":
			pendingCount++
		case "approved":
			approvedCount++
		case "rejected":
			rejectedCount++
		}
	}

	return c.Render("admin/businesses", fiber.Map{
		"Title":         "Business Management - HajiFund Admin",
		"User":          user,
		"Businesses":    allBusinesses,
		"PendingCount":  pendingCount,
		"ApprovedCount": approvedCount,
		"RejectedCount": rejectedCount,
	}, "base")
}

// BusinessDetailPage renders the admin business detail page
func (h *Handler) BusinessDetailPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	businessID := c.Params("id")
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	// Get business details from backend API
	var business models.Business
	businessResp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/businesses/"+businessID, nil, authHeaders)
	if err != nil || businessResp.Data == nil {
		return c.Status(404).Render("errors/404", fiber.Map{
			"Title": "Business Not Found - HajiFund Admin",
			"User":  user,
		}, "base")
	}

	if data, ok := businessResp.Data.(map[string]interface{}); ok {
		business = models.Business{
			ID:                 getStringValue(data["id"]),
			Name:               getStringValue(data["name"]),
			Type:               getStringValue(data["type"]),
			Description:        getStringValue(data["description"]),
			ApprovalStatus:     getStringValue(data["approval_status"]),
			OwnerID:            getStringValue(data["owner_id"]),
			CooperativeID:      getStringValue(data["cooperative_id"]),
			RegistrationNumber: getStringValue(data["registration_number"]),
			LegalStructure:     getStringValue(data["legal_structure"]),
			Industry:           getStringValue(data["industry"]),
			Address:            getStringValue(data["address"]),
			Phone:              getStringValue(data["phone"]),
			Email:              getStringValue(data["email"]),
			Website:            getStringValue(data["website"]),
			EstablishedDate:    getStringValue(data["established_date"]),
			EmployeeCount:      getIntValue(data["employee_count"]),
			AnnualRevenue:      getFloatValue(data["annual_revenue"]),
			Currency:           getStringValue(data["currency"]),
			BankAccount:        getStringValue(data["bank_account"]),
			BusinessLicense:    getStringValue(data["business_license"]),
		}
	}

	return c.Render("admin/business-detail", fiber.Map{
		"Title":    "Business Details - HajiFund Admin",
		"User":     user,
		"Business": business,
	}, "base")
}

func (h *Handler) CooperativesPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	// Get cooperatives data
	cooperatives := []models.Cooperative{
		{
			ID:          "550e8400-e29b-41d4-a716-446655440001",
			Name:        "Koperasi Haji",
			Description: "Koperasi untuk jamaah haji dan umroh",
		},
		{
			ID:          "550e8400-e29b-41d4-a716-446655440002",
			Name:        "Koperasi SIDANA",
			Description: "Koperasi Simpan Pinjam Dana Amanah",
		},
	}

	return c.Render("admin/cooperatives", fiber.Map{
		"Title":        "Cooperative Management - HajiFund Admin",
		"User":         user,
		"Cooperatives": cooperatives,
	}, "base")
}

func (h *Handler) ProjectsPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	// Fetch projects (admin sees all projects)
	projectsResp, err := utils.MakeAPIRequest("GET", "/api/v1/projects", nil, authHeaders)
	var projects []models.Project
	if err == nil && projectsResp.Data != nil {
		if data, ok := projectsResp.Data.(map[string]interface{}); ok {
			if projData, ok := data["projects"].([]interface{}); ok {
				projects = make([]models.Project, len(projData))
				for i, proj := range projData {
					if pm, ok := proj.(map[string]interface{}); ok {
						// Map all available fields
						projects[i] = models.Project{
							ID:             getStringValue(pm["id"]),
							Title:          getStringValue(pm["title"]),
							Description:    getStringValue(pm["description"]),
							BusinessID:     getStringValue(pm["business_id"]),
							ProjectType:    getStringValue(pm["project_type"]),
							Category:       getStringValue(pm["category"]),
							Status:         getStringValue(pm["status"]),
							ApprovalStatus: getStringValue(pm["approval_status"]),
							TargetAmount:   getFloatValue(pm["target_amount"]),
							RaisedAmount:   getFloatValue(pm["raised_amount"]),
							FundingGoal:    getFloatValue(pm["funding_goal"]),
							CurrentFunding: getFloatValue(pm["current_funding"]),
						}

						// Handle legacy field mapping
						if projects[i].TargetAmount == 0 && projects[i].FundingGoal > 0 {
							projects[i].TargetAmount = projects[i].FundingGoal
						}
						if projects[i].RaisedAmount == 0 && projects[i].CurrentFunding > 0 {
							projects[i].RaisedAmount = projects[i].CurrentFunding
						}
					}
				}
			}
		}
	}

	return c.Render("admin/projects", fiber.Map{
		"Title":    "Projects - HajiFund Admin",
		"User":     user,
		"Projects": projects,
	}, "base")
}

func (h *Handler) InvestmentsPage(c *fiber.Ctx) error {
	return c.Render("admin/investments", fiber.Map{
		"Title": "Investments - HajiFund Admin",
	})
}

func (h *Handler) ApproveCooperative(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Cooperative approved",
	})
}

func (h *Handler) ApproveProject(c *fiber.Ctx) error {
	projectID := c.Params("id")
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	// Debug logging
	println("🔍 ApproveProject called for project ID:", projectID)
	println("🔑 Auth headers:", authHeaders)

	// Read the request body to forward sharia_compliant and other data
	body := c.Body()
	println("📦 Request body:", string(body))

	// Make API request to approve project
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/admin/projects/"+projectID+"/approve", body, authHeaders)
	if err != nil {
		println("❌ Error from backend API:", err.Error())
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to approve project: " + err.Error(),
		})
	}

	println("✅ Project approved successfully:", resp)

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Project approved successfully",
		"data":    resp.Data,
	})
}

func (h *Handler) RejectProject(c *fiber.Ctx) error {
	projectID := c.Params("id")
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	var req struct {
		Reason string `json:"reason"`
	}
	if err := c.BodyParser(&req); err != nil {
		println("❌ Error parsing request body:", err.Error())
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
	}

	// Debug logging
	println("🔍 RejectProject called for project ID:", projectID)
	println("📝 Rejection reason:", req.Reason)

	// Make API request to reject project
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/admin/projects/"+projectID+"/reject", map[string]interface{}{
		"reason": req.Reason,
	}, authHeaders)
	if err != nil {
		println("❌ Error from backend API:", err.Error())
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to reject project: " + err.Error(),
		})
	}

	println("✅ Project rejected successfully:", resp)

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Project rejected successfully",
		"data":    resp.Data,
	})
}

// ApproveBusiness handles business approval by admin (FR-007)
func (h *Handler) ApproveBusiness(c *fiber.Ctx) error {
	businessID := c.Params("id")
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	// Make API request to approve business
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/admin/businesses/approve", map[string]string{
		"business_id": businessID,
	}, authHeaders)

	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to approve business",
		})
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Business approved successfully",
		"data":    resp.Data,
	})
}

// RejectBusiness handles business rejection by admin (FR-007)
func (h *Handler) RejectBusiness(c *fiber.Ctx) error {
	businessID := c.Params("id")
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	var req struct {
		Reason string `json:"reason"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	// Make API request to reject business
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/admin/businesses/reject", map[string]interface{}{
		"business_id": businessID,
		"reason":      req.Reason,
	}, authHeaders)

	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to reject business",
		})
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Business rejected successfully",
		"data":    resp.Data,
	})
}

func (h *Handler) ApproveInvestment(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Investment approved",
	})
}

// Helper functions for parsing API responses
func parseUsersFromAPI(usersData []interface{}) []models.User {
	users := make([]models.User, len(usersData))
	for i, user := range usersData {
		if userMap, ok := user.(map[string]interface{}); ok {
			users[i] = models.User{
				ID:        getStringValue(userMap["id"]),
				Email:     getStringValue(userMap["email"]),
				Name:      getStringValue(userMap["name"]),
				Phone:     getStringValue(userMap["phone"]),
				Address:   getStringValue(userMap["address"]),
				KYCStatus: getStringValue(userMap["kyc_status"]),
				IsActive:  getBoolValue(userMap["is_active"]),
				Roles:     extractRolesFromInterface(userMap["roles"]),
			}

			// Handle cooperative ID (pointer)
			if coopID := getStringValue(userMap["cooperative_id"]); coopID != "" {
				users[i].CooperativeID = &coopID
			}
		}
	}
	return users
}

// Helper function to get int value from interface{}
func getIntValue(val interface{}) int {
	if val == nil {
		return 0
	}
	if intVal, ok := val.(int); ok {
		return intVal
	}
	if floatVal, ok := val.(float64); ok {
		return int(floatVal)
	}
	return 0
}

// Helper function to get float value from interface{}
func getFloatValue(val interface{}) float64 {
	if val == nil {
		return 0.0
	}
	if floatVal, ok := val.(float64); ok {
		return floatVal
	}
	if intVal, ok := val.(int); ok {
		return float64(intVal)
	}
	return 0.0
}

// GetUser handles getting a specific user by ID (FR-007)
func (h *Handler) GetUser(c *fiber.Ctx) error {
	userID := c.Params("id")
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	resp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/users/"+userID, nil, authHeaders)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{
			"status":  "error",
			"message": "User not found",
		})
	}

	return c.JSON(resp)
}

// UpdateUser handles updating a user's information (FR-007)
func (h *Handler) UpdateUser(c *fiber.Ctx) error {
	userID := c.Params("id")
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	var req models.UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	resp, err := utils.MakeAPIRequest("PUT", "/api/v1/admin/users/"+userID, req, authHeaders)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update user",
		})
	}

	return c.JSON(resp)
}

// UpdateUserRoles handles updating a user's roles (FR-007)
func (h *Handler) UpdateUserRoles(c *fiber.Ctx) error {
	userID := c.Params("id")
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	var req struct {
		Roles []string `json:"roles"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	resp, err := utils.MakeAPIRequest("PUT", "/api/v1/user/roles", map[string]interface{}{
		"user_id": userID,
		"roles":   req.Roles,
	}, authHeaders)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update user roles",
		})
	}

	return c.JSON(resp)
}

// AdminRegisterPage renders the admin registration page
func (h *Handler) AdminRegisterPage(c *fiber.Ctx) error {
	println("🔍 AdminRegisterPage handler called")
	return c.Render("admin/register", fiber.Map{
		"Title": "Admin Registration - HajiFund",
	})
}

// AdminLoginPage renders the admin login page
func (h *Handler) AdminLoginPage(c *fiber.Ctx) error {
	return c.Render("admin/login", fiber.Map{
		"Title": "Admin Login - HajiFund",
	})
}

// TestAdminRoute is a simple test route
func (h *Handler) TestAdminRoute(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Admin route is working!",
		"path":    c.Path(),
	})
}
