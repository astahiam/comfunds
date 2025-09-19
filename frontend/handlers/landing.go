package handlers

import (
	"hajifund-frontend/models"
	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
)

// LandingPage renders the main landing page
func LandingPage(c *fiber.Ctx) error {
	// Get hero data
	heroResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/hero", nil, nil)
	var heroData map[string]interface{}
	if err == nil && heroResp.Data != nil {
		if data, ok := heroResp.Data.(map[string]interface{}); ok {
			heroData = data
		}
	}

	// Get approved projects for investment opportunities
	projectsResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/projects?status=approved&limit=6", nil, nil)
	var featuredProjects []models.Project
	if err == nil && projectsResp.Data != nil {
		if data, ok := projectsResp.Data.(map[string]interface{}); ok {
			if projectsData, ok := data["projects"].([]interface{}); ok {
				featuredProjects = make([]models.Project, len(projectsData))
				for i, project := range projectsData {
					if projectMap, ok := project.(map[string]interface{}); ok {
						// Parse project data with comprehensive fields
						project := models.Project{
							ID:             getStringValue(projectMap["id"]),
							Title:          getStringValue(projectMap["title"]),
							Description:    getStringValue(projectMap["description"]),
							BusinessID:     getStringValue(projectMap["business_id"]),
							ProjectType:    getStringValue(projectMap["project_type"]),
							Status:         getStringValue(projectMap["status"]),
							ApprovalStatus: getStringValue(projectMap["approval_status"]),
						}

						// Handle funding amounts
						if fundingGoal, ok := projectMap["funding_goal"]; ok {
							if goal, ok := fundingGoal.(float64); ok {
								project.FundingGoal = goal
								project.TargetAmount = goal // backward compatibility
							}
						}

						if currentFunding, ok := projectMap["current_funding"]; ok {
							if current, ok := currentFunding.(float64); ok {
								project.CurrentFunding = current
								project.RaisedAmount = current // backward compatibility
							}
						}

						// Calculate funding percentage
						if project.FundingGoal > 0 {
							project.FundingPercentage = (project.CurrentFunding / project.FundingGoal) * 100
						}

						// Parse business information if available
						if businessData, ok := projectMap["business"].(map[string]interface{}); ok {
							project.Business = &models.Business{
								ID:          getStringValue(businessData["id"]),
								Name:        getStringValue(businessData["name"]),
								Type:        getStringValue(businessData["type"]),
								Description: getStringValue(businessData["description"]),
							}
						}

						featuredProjects[i] = project
					}
				}
			}
		}
	}

	// Get active cooperatives
	cooperativesResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/cooperatives?limit=4", nil, nil)
	var activeCooperatives []models.Cooperative
	if err == nil && cooperativesResp.Data != nil {
		if data, ok := cooperativesResp.Data.(map[string]interface{}); ok {
			if coopData, ok := data["cooperatives"].([]interface{}); ok {
				activeCooperatives = make([]models.Cooperative, len(coopData))
				for i, coop := range coopData {
					if coopMap, ok := coop.(map[string]interface{}); ok {
						activeCooperatives[i] = models.Cooperative{
							ID:          coopMap["id"].(string),
							Name:        coopMap["name"].(string),
							Description: coopMap["description"].(string),
						}
					}
				}
			}
		}
	}

	return c.Render("landing", fiber.Map{
		"Title":              "HajiFund - Islamic Crowdfunding Platform",
		"HeroData":           heroData,
		"FeaturedProjects":   featuredProjects,
		"ActiveCooperatives": activeCooperatives,
	}, "base")
}
