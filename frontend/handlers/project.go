package handlers

import (
	"hajifund-frontend/models"
	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
)

// UserProjectsPage renders user's projects page (FR-032, FR-036)
func (h *Handler) UserProjectsPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	if user == nil {
		return c.Redirect("/login")
	}

	// Get user's projects
	projectsResp, err := utils.MakeAPIRequest("GET", "/api/v1/user/projects", nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	var userProjects []models.Project
	if err == nil && projectsResp.Data != nil {
		if data, ok := projectsResp.Data.(map[string]interface{}); ok {
			if projectsData, ok := data["projects"].([]interface{}); ok {
				userProjects = parseProjectsFromAPI(projectsData)
			}
		}
	}

	return c.Render("projects/index", fiber.Map{
		"Title":    "My Projects - HajiFund",
		"User":     user,
		"Projects": userProjects,
	}, "base")
}

// CreateProjectPage renders project creation page (FR-032)
func (h *Handler) CreateProjectPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	// Check if user has business_owner role
	if !utils.HasRole(user.Roles, "business_owner") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Business owner role required to create projects",
		})
	}

	// Get user's businesses
	businessesResp, err := utils.MakeAPIRequest("GET", "/api/v1/user/businesses", nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	var businesses []models.Business
	if err == nil && businessesResp.Data != nil {
		if data, ok := businessesResp.Data.(map[string]interface{}); ok {
			if businessData, ok := data["businesses"].([]interface{}); ok {
				businesses = parseBusinessesFromAPI(businessData)
			}
		}
	}

	return c.Render("projects/create", fiber.Map{
		"Title":      "Create Project - HajiFund",
		"User":       user,
		"Businesses": businesses,
	}, "base")
}

// CreateProject handles project creation (FR-032)
func (h *Handler) CreateProject(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	// Check if user has business_owner role
	if !utils.HasRole(user.Roles, "business_owner") {
		return c.Status(403).JSON(fiber.Map{
			"status":  "error",
			"message": "Business owner role required to create projects",
		})
	}

	var req models.CreateProjectRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	// Make API request to backend
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/projects", req, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create project",
		})
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Project created successfully",
		"redirect": "/projects",
		"data":     resp.Data,
	})
}

// ProjectDetail renders project detail page (FR-036)
func (h *Handler) ProjectDetail(c *fiber.Ctx) error {
	projectID := c.Params("id")
	user := c.Locals("user")

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

	// Get project investments
	investmentsResp, err := utils.MakeAPIRequest("GET", "/api/v1/projects/"+projectID+"/investments", nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	var investments []models.Investment
	if err == nil && investmentsResp.Data != nil {
		if data, ok := investmentsResp.Data.(map[string]interface{}); ok {
			if investmentData, ok := data["investments"].([]interface{}); ok {
				investments = parseInvestmentsFromAPI(investmentData)
			}
		}
	}

	return c.Render("projects/detail", fiber.Map{
		"Title":       project.Title + " - HajiFund",
		"User":        user,
		"Project":     project,
		"Investments": investments,
	}, "base")
}

// PublicProjectsPage renders public projects page for all users (FR-006)
func (h *Handler) PublicProjectsPage(c *fiber.Ctx) error {
	user := c.Locals("user") // May be nil for guest users

	// Get approved public projects
	projectsResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/projects?status=approved", nil, nil)
	var projects []models.Project
	if err == nil && projectsResp.Data != nil {
		if data, ok := projectsResp.Data.(map[string]interface{}); ok {
			if projectsData, ok := data["projects"].([]interface{}); ok {
				projects = parseProjectsFromAPI(projectsData)
			}
		}
	}

	return c.Render("projects/public", fiber.Map{
		"Title":    "Investment Opportunities - HajiFund",
		"User":     user,
		"Projects": projects,
	}, "base")
}

// Helper functions for parsing API responses
func parseProjectsFromAPI(projectsData []interface{}) []models.Project {
	projects := make([]models.Project, len(projectsData))
	for i, proj := range projectsData {
		if projMap, ok := proj.(map[string]interface{}); ok {
			projects[i] = parseProjectFromAPI(projMap)
		}
	}
	return projects
}

func parseProjectFromAPI(projectMap map[string]interface{}) models.Project {
	project := models.Project{
		ID:             getStringValueFromMap(projectMap, "id"),
		Title:          getStringValueFromMap(projectMap, "title"),
		Description:    getStringValueFromMap(projectMap, "description"),
		BusinessID:     getStringValueFromMap(projectMap, "business_id"),
		ProjectType:    getStringValueFromMap(projectMap, "project_type"),
		Status:         getStringValueFromMap(projectMap, "status"),
		ApprovalStatus: getStringValueFromMap(projectMap, "approval_status"),
	}

	// Handle funding amounts
	if fundingGoal, ok := projectMap["funding_goal"].(float64); ok {
		project.FundingGoal = fundingGoal
		project.TargetAmount = fundingGoal
	}
	if currentFunding, ok := projectMap["current_funding"].(float64); ok {
		project.CurrentFunding = currentFunding
		project.RaisedAmount = currentFunding
	}
	if minimumFunding, ok := projectMap["minimum_funding"].(float64); ok {
		project.MinimumFunding = minimumFunding
	}

	// Calculate funding percentage
	if project.FundingGoal > 0 {
		project.FundingPercentage = (project.CurrentFunding / project.FundingGoal) * 100
	}

	// Parse business information if available
	if businessData, ok := projectMap["business"].(map[string]interface{}); ok {
		project.Business = &models.Business{
			ID:          getStringValueFromMap(businessData, "id"),
			Name:        getStringValueFromMap(businessData, "name"),
			Type:        getStringValueFromMap(businessData, "type"),
			Description: getStringValueFromMap(businessData, "description"),
		}
	}

	return project
}

func parseBusinessesFromAPI(businessesData []interface{}) []models.Business {
	businesses := make([]models.Business, len(businessesData))
	for i, biz := range businessesData {
		if bizMap, ok := biz.(map[string]interface{}); ok {
			businesses[i] = models.Business{
				ID:             getStringValueFromMap(bizMap, "id"),
				Name:           getStringValueFromMap(bizMap, "name"),
				Type:           getStringValueFromMap(bizMap, "type"),
				Description:    getStringValueFromMap(bizMap, "description"),
				ApprovalStatus: getStringValueFromMap(bizMap, "approval_status"),
			}
		}
	}
	return businesses
}

func parseInvestmentsFromAPI(investmentsData []interface{}) []models.Investment {
	investments := make([]models.Investment, len(investmentsData))
	for i, inv := range investmentsData {
		if invMap, ok := inv.(map[string]interface{}); ok {
			investment := models.Investment{
				ID:         getStringValueFromMap(invMap, "id"),
				ProjectID:  getStringValueFromMap(invMap, "project_id"),
				InvestorID: getStringValueFromMap(invMap, "investor_id"),
				Status:     getStringValueFromMap(invMap, "status"),
				Currency:   getStringValueFromMap(invMap, "currency"),
			}
			if amount, ok := invMap["amount"].(float64); ok {
				investment.Amount = amount
			}
			if returnAmount, ok := invMap["return_amount"].(float64); ok {
				investment.ReturnAmount = returnAmount
			}
			investments[i] = investment
		}
	}
	return investments
}

func getStringValueFromMap(data map[string]interface{}, key string) string {
	if value, ok := data[key]; ok {
		if str, ok := value.(string); ok {
			return str
		}
	}
	return ""
}
