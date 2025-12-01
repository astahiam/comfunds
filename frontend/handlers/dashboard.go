package handlers

import (
	"hajifund-frontend/models"
	"hajifund-frontend/utils"
	"time"

	"github.com/gofiber/fiber/v2"
)

// Dashboard renders role-specific dashboard (FR-005, FR-007 to FR-010)
func (h *Handler) Dashboard(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	if user == nil {
		return c.Redirect("/login")
	}

	// Determine primary role for dashboard type
	var dashboardType string
	if utils.HasRole(user.Roles, "admin") {
		dashboardType = "admin"
	} else if utils.HasRole(user.Roles, "cooperative_admin") {
		dashboardType = "cooperative_admin"
	} else if utils.HasRole(user.Roles, "business_owner") {
		dashboardType = "business_owner"
	} else if utils.HasRole(user.Roles, "investor") {
		dashboardType = "investor"
	} else {
		dashboardType = "member"
	}

	// Get dashboard data based on user role
	dashboardData := h.getDashboardData(user, dashboardType, c)

	return c.Render("dashboard/index", fiber.Map{
		"Title":         "Dashboard - HajiFund",
		"User":          user,
		"DashboardType": dashboardType,
		"DashboardData": dashboardData,
	}, "base")
}

// getDashboardData returns role-specific dashboard data
func (h *Handler) getDashboardData(user *models.User, dashboardType string, c *fiber.Ctx) map[string]interface{} {
	data := make(map[string]interface{})
	authHeaders := utils.GetAuthHeaders(getTokenFromContext(c))

	switch dashboardType {
	case "admin":
		data = h.getAdminDashboardData(authHeaders)
	case "cooperative_admin":
		data = h.getCooperativeAdminDashboardData(user, authHeaders)
	case "business_owner":
		data = h.getBusinessOwnerDashboardData(authHeaders)
	case "investor":
		data = h.getInvestorDashboardData(authHeaders)
	default:
		data = h.getMemberDashboardData(user, authHeaders)
	}

	return data
}

// getAdminDashboardData returns admin-specific dashboard data
func (h *Handler) getAdminDashboardData(authHeaders map[string]string) map[string]interface{} {
	data := make(map[string]interface{})

	// Get system statistics
	statsResp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/statistics", nil, authHeaders)
	if err == nil && statsResp.Data != nil {
		if statsData, ok := statsResp.Data.(map[string]interface{}); ok {
			data["stats"] = statsData
		}
	}

	// Get pending approvals
	pendingResp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/pending-approvals", nil, authHeaders)
	if err == nil && pendingResp.Data != nil {
		if pendingData, ok := pendingResp.Data.(map[string]interface{}); ok {
			data["pending_approvals"] = pendingData
		}
	}

	// Get recent activities
	activitiesResp, err := utils.MakeAPIRequest("GET", "/api/v1/admin/recent-activities", nil, authHeaders)
	if err == nil && activitiesResp.Data != nil {
		if activitiesData, ok := activitiesResp.Data.(map[string]interface{}); ok {
			data["recent_activities"] = activitiesData
		}
	}

	return data
}

// getCooperativeAdminDashboardData returns cooperative admin dashboard data
func (h *Handler) getCooperativeAdminDashboardData(user *models.User, authHeaders map[string]string) map[string]interface{} {
	data := make(map[string]interface{})

	// Get cooperative statistics
	if user.CooperativeID != nil {
		statsResp, err := utils.MakeAPIRequest("GET", "/api/v1/cooperatives/"+*user.CooperativeID+"/statistics", nil, authHeaders)
		if err == nil && statsResp.Data != nil {
			if statsData, ok := statsResp.Data.(map[string]interface{}); ok {
				data["cooperative_stats"] = statsData
			}
		}

		// Get pending cooperative approvals
		pendingResp, err := utils.MakeAPIRequest("GET", "/api/v1/cooperatives/"+*user.CooperativeID+"/pending-approvals", nil, authHeaders)
		if err == nil && pendingResp.Data != nil {
			if pendingData, ok := pendingResp.Data.(map[string]interface{}); ok {
				data["pending_approvals"] = pendingData
			}
		}
	}

	return data
}

// getBusinessOwnerDashboardData returns business owner dashboard data
func (h *Handler) getBusinessOwnerDashboardData(authHeaders map[string]string) map[string]interface{} {
	data := make(map[string]interface{})

	// Get user's businesses
	businessesResp, err := utils.MakeAPIRequest("GET", "/api/v1/user/businesses", nil, authHeaders)
	if err == nil && businessesResp.Data != nil {
		if businessData, ok := businessesResp.Data.(map[string]interface{}); ok {
			if businesses, ok := businessData["businesses"].([]interface{}); ok {
				data["businesses"] = parseBusinessesFromAPI(businesses)
			}
		}
	}

	// Get user's projects
	projectsResp, err := utils.MakeAPIRequest("GET", "/api/v1/user/projects", nil, authHeaders)
	if err == nil && projectsResp.Data != nil {
		if projectData, ok := projectsResp.Data.(map[string]interface{}); ok {
			if projects, ok := projectData["projects"].([]interface{}); ok {
				data["projects"] = parseProjectsFromAPI(projects)
			}
		}
	}

	// Get project performance metrics
	metricsResp, err := utils.MakeAPIRequest("GET", "/api/v1/user/project-metrics", nil, authHeaders)
	if err == nil && metricsResp.Data != nil {
		if metricsData, ok := metricsResp.Data.(map[string]interface{}); ok {
			data["project_metrics"] = metricsData
		}
	}

	return data
}

// getInvestorDashboardData returns investor dashboard data
func (h *Handler) getInvestorDashboardData(authHeaders map[string]string) map[string]interface{} {
	data := make(map[string]interface{})

	// Get investment portfolio
	portfolioResp, err := utils.MakeAPIRequest("GET", "/api/v1/investments/portfolio", nil, authHeaders)
	if err == nil && portfolioResp.Data != nil {
		if portfolioData, ok := portfolioResp.Data.(map[string]interface{}); ok {
			data["portfolio"] = portfolioData
		}
	}

	// Get recent investments
	investmentsResp, err := utils.MakeAPIRequest("GET", "/api/v1/investments/my-investments?limit=5", nil, authHeaders)
	if err == nil && investmentsResp.Data != nil {
		if investmentData, ok := investmentsResp.Data.(map[string]interface{}); ok {
			if investments, ok := investmentData["investments"].([]interface{}); ok {
				data["recent_investments"] = parseInvestmentsFromAPI(investments)
			}
		}
	}

	// Get profit distributions
	distributionsResp, err := utils.MakeAPIRequest("GET", "/api/v1/investments/profit-distributions?limit=5", nil, authHeaders)
	if err == nil && distributionsResp.Data != nil {
		if distData, ok := distributionsResp.Data.(map[string]interface{}); ok {
			data["profit_distributions"] = distData
		}
	}

	// Get investment opportunities (approved projects)
	opportunitiesResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/projects?status=approved&limit=3", nil, nil)
	if err == nil && opportunitiesResp.Data != nil {
		if opData, ok := opportunitiesResp.Data.(map[string]interface{}); ok {
			if opportunities, ok := opData["projects"].([]interface{}); ok {
				data["investment_opportunities"] = parseProjectsFromAPI(opportunities)
			}
		}
	}

	return data
}

// getMemberDashboardData returns general member dashboard data
func (h *Handler) getMemberDashboardData(user *models.User, authHeaders map[string]string) map[string]interface{} {
	data := make(map[string]interface{})

	// Get cooperative information
	if user.CooperativeID != nil {
		cooperativesResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/cooperatives", nil, nil)
		if err == nil && cooperativesResp.Data != nil {
			if coopData, ok := cooperativesResp.Data.(map[string]interface{}); ok {
				if cooperatives, ok := coopData["cooperatives"].([]interface{}); ok {
					for _, coop := range cooperatives {
						if coopMap, ok := coop.(map[string]interface{}); ok {
							if coopMap["id"].(string) == *user.CooperativeID {
								data["cooperative"] = models.Cooperative{
									ID:          coopMap["id"].(string),
									Name:        coopMap["name"].(string),
									Description: coopMap["description"].(string),
								}
								break
							}
						}
					}
				}
			}
		}
	}

	// Get available investment opportunities
	projectsResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/projects?status=approved&limit=6", nil, nil)
	if err == nil && projectsResp.Data != nil {
		if projectData, ok := projectsResp.Data.(map[string]interface{}); ok {
			if projects, ok := projectData["projects"].([]interface{}); ok {
				data["available_projects"] = parseProjectsFromAPI(projects)
			}
		}
	}

	return data
}

// Profile renders the user profile page
func (h *Handler) Profile(c *fiber.Ctx) error {
	user := h.getUserFromContext(c)
	if user == nil {
		return c.Redirect("/login")
	}

	refreshedUser := *user
	if resp, err := h.makeAuthenticatedRequest("GET", "/api/v1/auth/profile", nil, c); err == nil && resp != nil {
		if data, ok := resp.Data.(map[string]interface{}); ok {
			hydrateUserFromAPIData(&refreshedUser, data)
		}
	}

	return c.Render("dashboard/profile", fiber.Map{
		"Title": "Profile - HajiFund",
		"User":  &refreshedUser,
	}, "base")
}

// UpdateProfile handles profile updates
func (h *Handler) UpdateProfile(c *fiber.Ctx) error {
	user := h.getUserFromContext(c)
	if user == nil {
		return c.Status(401).JSON(fiber.Map{
			"status":  "error",
			"message": "Unauthorized",
		})
	}

	var req struct {
		Name    string `json:"name"`
		Phone   string `json:"phone"`
		Address string `json:"address"`
	}

	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	resp, err := h.makeAuthenticatedRequest("PUT", "/api/v1/auth/profile", req, c)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update profile",
		})
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Profile updated successfully",
		"data":    resp.Data,
	})
}

func hydrateUserFromAPIData(user *models.User, data map[string]interface{}) {
	if user == nil {
		return
	}

	if id := getStringValue(data["id"]); id != "" {
		user.ID = id
	}
	if email := getStringValue(data["email"]); email != "" {
		user.Email = email
	}
	if name := getStringValue(data["name"]); name != "" {
		user.Name = name
	}
	if phone := getStringValue(data["phone"]); phone != "" {
		user.Phone = phone
	}
	if address := getStringValue(data["address"]); address != "" {
		user.Address = address
	}

	if coopID := getStringValue(data["cooperative_id"]); coopID != "" {
		user.CooperativeID = &coopID
	} else {
		user.CooperativeID = nil
	}

	if roles := data["roles"]; roles != nil {
		user.Roles = extractRolesFromInterface(roles)
	}

	if kycStatus := getStringValue(data["kyc_status"]); kycStatus != "" {
		user.KYCStatus = kycStatus
	}

	user.IsActive = getBoolValue(data["is_active"])

	if createdAt := parseTime(data["created_at"]); !createdAt.IsZero() {
		user.CreatedAt = createdAt
	}
	if updatedAt := parseTime(data["updated_at"]); !updatedAt.IsZero() {
		user.UpdatedAt = updatedAt
	}
}

// Helper function to parse time
func parseTime(timeStr interface{}) time.Time {
	if str, ok := timeStr.(string); ok {
		if t, err := time.Parse(time.RFC3339, str); err == nil {
			return t
		}
	}
	return time.Now()
}
