package handlers

import (
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

	// Validate investment eligibility and funds (FR-042)
	// Make API request to backend
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/investments", req, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Investment failed",
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
	if err == nil && investmentsResp.Data != nil {
		if data, ok := investmentsResp.Data.(map[string]interface{}); ok {
			if investmentData, ok := data["investments"].([]interface{}); ok {
				userInvestments = parseInvestmentsFromAPI(investmentData)
			}
		}
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
		})
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
		})
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
		})
	}

	// Get project details
	projectResp, err := utils.MakeAPIRequest("GET", "/api/v1/projects/"+projectID, nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(404).Render("error", fiber.Map{
			"Code":    404,
			"Message": "Project not found",
		})
	}

	var project models.Project
	if projectResp.Data != nil {
		if projectData, ok := projectResp.Data.(map[string]interface{}); ok {
			project = parseProjectFromAPI(projectData)
		}
	}

	// Check if project is eligible for investment (approved status)
	if project.ApprovalStatus != "approved" || project.Status != "active" {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "This project is not currently accepting investments",
		})
	}

	return c.Render("investments/invest", fiber.Map{
		"Title":   "Invest in " + project.Title + " - HajiFund",
		"User":    user,
		"Project": project,
	}, "base")
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
