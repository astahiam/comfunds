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

	// Get pending businesses by querying database directly
	// Since admin needs to see ALL pending businesses across cooperatives
	var pendingBusinesses []models.Business

	// For now, create mock pending businesses to demonstrate admin functionality
	pendingBusinesses = []models.Business{
		{
			ID:             "mock-business-1",
			Name:           "Toko Kelontong Berkah",
			Type:           "retail",
			Description:    "Toko kelontong yang melayani kebutuhan sehari-hari masyarakat",
			ApprovalStatus: "pending",
			OwnerID:        "owner-123",
			CooperativeID:  "550e8400-e29b-41d4-a716-446655440001",
		},
		{
			ID:             "mock-business-2",
			Name:           "Warung Makan Sederhana",
			Type:           "services",
			Description:    "Warung makan dengan menu masakan rumahan yang lezat",
			ApprovalStatus: "pending",
			OwnerID:        "owner-456",
			CooperativeID:  "550e8400-e29b-41d4-a716-446655440002",
		},
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

func (h *Handler) CooperativesPage(c *fiber.Ctx) error {
	return c.Render("admin/cooperatives", fiber.Map{
		"Title": "Cooperatives - HajiFund Admin",
	})
}

func (h *Handler) ProjectsPage(c *fiber.Ctx) error {
	return c.Render("admin/projects", fiber.Map{
		"Title": "Projects - HajiFund Admin",
	})
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
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Project approved",
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
