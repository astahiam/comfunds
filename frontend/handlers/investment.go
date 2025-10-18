package handlers

import (
	"time"

	"hajifund-frontend/models"
	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
)

// Invest handles investment in a project (FR-041 to FR-045)
func (h *Handler) Invest(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	// Check if user has investor role
	if !utils.HasRole(user.Roles, "investor") {
		return c.Status(403).JSON(fiber.Map{
			"status":  "error",
			"message": "Investor role required to make investments",
		})
	}

	var req models.InvestmentRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	// Debug: Check token
	token := getTokenFromContext(c)
	if token == "" {
		return c.Status(401).JSON(fiber.Map{
			"status":  "error",
			"message": "Authentication token not found",
		})
	}

	// Validate investment eligibility and funds (FR-042)
	// Make API request to backend
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/investments", req, utils.GetAuthHeaders(token))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Investment failed: " + err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Investment successful",
		"redirect": "/investments",
		"data":     resp.Data,
	})
}

// UserInvestmentsPage renders user's investments page (FR-041, FR-044)
func (h *Handler) UserInvestmentsPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	if user == nil {
		return c.Redirect("/login")
	}

	// Get user's investments
	investmentsResp, err := utils.MakeAPIRequest("GET", "/api/v1/investments/my-investments", nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	var userInvestments []models.Investment

	if err != nil {
		// Log error but continue to show empty state
		println("❌ Error fetching investments:", err.Error())
	} else if investmentsResp != nil {
		println("✅ Got response from API")
		println("Status:", investmentsResp.Status)
		println("Message:", investmentsResp.Message)

		if investmentsResp.Data != nil {
			println("✅ Response has data")

			// Try to parse as map
			if data, ok := investmentsResp.Data.(map[string]interface{}); ok {
				println("✅ Data is a map, keys:", len(data))

				// Check for investments array
				if investmentData, ok := data["investments"].([]interface{}); ok {
					println("✅ Found investments array, count:", len(investmentData))
					userInvestments = parseInvestmentsFromAPI(investmentData)
					println("✅ Parsed", len(userInvestments), "investments successfully")
				} else {
					println("❌ No 'investments' array in response data")
					// Print what keys are available
					for key := range data {
						println("  Available key:", key)
					}
				}
			} else {
				println("❌ Response data is not a map, type:", investmentsResp.Data)
			}
		} else {
			println("❌ Response data is nil")
		}
	} else {
		println("❌ No response from API")
	}

	// Calculate portfolio summary
	var totalInvested, totalReturns float64
	for _, investment := range userInvestments {
		totalInvested += investment.Amount
		// Note: Returns would be calculated from profit distributions
	}

	return c.Render("investments/index", fiber.Map{
		"Title":         "My Investments - HajiFund",
		"User":          user,
		"Investments":   userInvestments,
		"TotalInvested": totalInvested,
		"TotalReturns":  totalReturns,
	}, "base")
}

// PortfolioPage renders user's investment portfolio (FR-056)
func (h *Handler) PortfolioPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	if user == nil {
		return c.Redirect("/login")
	}

	// Check if user has investor role
	if !utils.HasRole(user.Roles, "investor") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Investor role required to view portfolio",
		}, "base")
	}

	// Get portfolio data
	portfolioResp, err := utils.MakeAPIRequest("GET", "/api/v1/investments/portfolio", nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	var portfolioData map[string]interface{}
	if err == nil && portfolioResp.Data != nil {
		if data, ok := portfolioResp.Data.(map[string]interface{}); ok {
			portfolioData = data
		}
	}

	// Get profit distributions
	distributionsResp, err := utils.MakeAPIRequest("GET", "/api/v1/investments/profit-distributions", nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	var distributions []map[string]interface{}
	if err == nil && distributionsResp.Data != nil {
		if data, ok := distributionsResp.Data.(map[string]interface{}); ok {
			if distData, ok := data["distributions"].([]interface{}); ok {
				distributions = make([]map[string]interface{}, len(distData))
				for i, dist := range distData {
					if distMap, ok := dist.(map[string]interface{}); ok {
						distributions[i] = distMap
					}
				}
			}
		}
	}

	return c.Render("portfolio/index", fiber.Map{
		"Title":         "Investment Portfolio - HajiFund",
		"User":          user,
		"Portfolio":     portfolioData,
		"Distributions": distributions,
	}, "base")
}

// InvestmentDetailPage renders investment detail page
func (h *Handler) InvestmentDetailPage(c *fiber.Ctx) error {
	investmentID := c.Params("id")
	user := c.Locals("user").(*models.User)

	// Get investment details
	investmentResp, err := utils.MakeAPIRequest("GET", "/api/v1/investments/"+investmentID, nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(404).Render("error", fiber.Map{
			"Code":    404,
			"Message": "Investment not found",
		}, "base")
	}

	var investment models.Investment
	if investmentResp.Data != nil {
		if investmentData, ok := investmentResp.Data.(map[string]interface{}); ok {
			investment = parseInvestmentFromAPI(investmentData)
		}
	}

	return c.Render("investments/detail", fiber.Map{
		"Title":      "Investment Detail - HajiFund",
		"User":       user,
		"Investment": investment,
	}, "base")
}

// ProjectInvestmentPage renders investment page for a specific project
func (h *Handler) ProjectInvestmentPage(c *fiber.Ctx) error {
	projectID := c.Params("id")
	user := c.Locals("user").(*models.User)

	// Check if user has investor role
	if !utils.HasRole(user.Roles, "investor") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Investor role required to make investments",
		}, "base")
	}

	// Get project details
	projectResp, err := utils.MakeAPIRequest("GET", "/api/v1/projects/"+projectID, nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(404).Render("error", fiber.Map{
			"Code":    404,
			"Message": "Project not found",
		}, "base")
	}

	var project models.Project
	if projectResp.Data != nil {
		if projectData, ok := projectResp.Data.(map[string]interface{}); ok {
			project = parseProjectFromAPI(projectData)
		}
	}

	// Check if project is eligible for investment (approved status)
	if project.ApprovalStatus != "approved" || (project.Status != "active" && project.Status != "approved") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "This project is not currently accepting investments",
		}, "base")
	}

	return c.Render("investments/invest", fiber.Map{
		"Title":   "Invest in " + project.Title + " - HajiFund",
		"User":    user,
		"Project": project,
	}, "base")
}

// GetInvestmentLimits gets investment limits for a project
func (h *Handler) GetInvestmentLimits(c *fiber.Ctx) error {
	projectID := c.Params("id")

	// Get token for authenticated request
	token := getTokenFromContext(c)
	if token == "" {
		return c.Status(401).JSON(fiber.Map{
			"status":  "error",
			"message": "Authentication required",
		})
	}

	// Make API request to backend
	resp, err := utils.MakeAPIRequest("GET", "/api/v1/investments/project/"+projectID+"/limits", nil, utils.GetAuthHeaders(token))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to get investment limits: " + err.Error(),
		})
	}

	return c.JSON(resp)
}

// Helper function to parse multiple investments from API
func parseInvestmentsFromAPI(investmentsData []interface{}) []models.Investment {
	investments := make([]models.Investment, 0, len(investmentsData))
	for _, investmentData := range investmentsData {
		if investmentMap, ok := investmentData.(map[string]interface{}); ok {
			investments = append(investments, parseInvestmentFromAPI(investmentMap))
		}
	}
	return investments
}

// Helper function to parse single investment from API
func parseInvestmentFromAPI(investmentMap map[string]interface{}) models.Investment {
	investment := models.Investment{
		ID:         getStringValueFromMap(investmentMap, "id"),
		ProjectID:  getStringValueFromMap(investmentMap, "project_id"),
		InvestorID: getStringValueFromMap(investmentMap, "investor_id"),
		Status:     getStringValueFromMap(investmentMap, "status"),
		Currency:   getStringValueFromMap(investmentMap, "currency"),
	}

	if amount, ok := investmentMap["amount"].(float64); ok {
		investment.Amount = amount
	}
	if returnAmount, ok := investmentMap["return_amount"].(float64); ok {
		investment.ReturnAmount = returnAmount
	}

	// Parse investment date - try multiple formats
	investment.InvestmentDate = parseTimeFromMap(investmentMap, "investment_date")

	// Parse other date fields
	if createdAtStr, ok := investmentMap["created_at"].(string); ok && createdAtStr != "" {
		if t := parseTimeString(createdAtStr); t != nil {
			investment.CreatedAt = *t
		}
	}
	if updatedAtStr, ok := investmentMap["updated_at"].(string); ok && updatedAtStr != "" {
		if t := parseTimeString(updatedAtStr); t != nil {
			investment.UpdatedAt = *t
		}
	}

	// Parse project information if available
	if projectData, ok := investmentMap["project"].(map[string]interface{}); ok {
		investment.Project = &models.Project{
			ID:          getStringValueFromMap(projectData, "id"),
			Title:       getStringValueFromMap(projectData, "title"),
			Description: getStringValueFromMap(projectData, "description"),
			Status:      getStringValueFromMap(projectData, "status"),
		}
		if fundingGoal, ok := projectData["funding_goal"].(float64); ok {
			investment.Project.FundingGoal = fundingGoal
		}
	}

	return investment
}

// Helper function to parse time from map
func parseTimeFromMap(m map[string]interface{}, key string) *time.Time {
	if timeStr, ok := m[key].(string); ok && timeStr != "" {
		return parseTimeString(timeStr)
	}
	return nil
}

// Helper function to parse time string with multiple formats
func parseTimeString(timeStr string) *time.Time {
	dateFormats := []string{
		time.RFC3339,
		time.RFC3339Nano,
		"2006-01-02T15:04:05Z07:00",
		"2006-01-02T15:04:05.999999999Z07:00",
		"2006-01-02 15:04:05",
		"2006-01-02",
	}

	for _, format := range dateFormats {
		if t, err := time.Parse(format, timeStr); err == nil {
			return &t
		}
	}

	// Debug: print if parsing failed
	println("⚠️  Failed to parse time string:", timeStr)
	return nil
}
