package handlers

import (
	"hajifund-frontend/models"
	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
)

// NewBusinessHandler creates a new business handler
func NewBusinessHandler() *Handler {
	return &Handler{}
}

// BusinessPage renders the business management page
func (h *Handler) BusinessPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	// Get user's businesses
	businessesResp, err := utils.MakeAPIRequest("GET", "/api/v1/user/businesses", nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	var businesses []models.Business
	if err == nil && businessesResp.Data != nil {
		if data, ok := businessesResp.Data.(map[string]interface{}); ok {
			if businessData, ok := data["businesses"].([]interface{}); ok {
				businesses = make([]models.Business, len(businessData))
				for i, business := range businessData {
					if businessMap, ok := business.(map[string]interface{}); ok {
						businesses[i] = models.Business{
							ID:             businessMap["id"].(string),
							Name:           businessMap["name"].(string),
							Description:    businessMap["description"].(string),
							Type:           businessMap["type"].(string),
							Address:        businessMap["address"].(string),
							OwnerID:        businessMap["owner_id"].(string),
							CooperativeID:  businessMap["cooperative_id"].(string),
							Status:         businessMap["status"].(string),
							ApprovalStatus: businessMap["approval_status"].(string),
						}
					}
				}
			}
		}
	}

	return c.Render("business/index", fiber.Map{
		"Title":      "My Businesses - HajiFund",
		"User":       user,
		"Businesses": businesses,
	}, "base")
}

// CreateBusinessPage renders the business creation page
func (h *Handler) CreateBusinessPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	// Check if user has business_owner role
	if !utils.HasRole(user.Roles, "business_owner") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Business owner role required to create businesses",
		})
	}

	// Get available cooperatives from public endpoint
	cooperativesResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/cooperatives", nil, nil)
	var cooperatives []models.Cooperative
	if err == nil && cooperativesResp.Data != nil {
		if data, ok := cooperativesResp.Data.(map[string]interface{}); ok {
			if coopData, ok := data["cooperatives"].([]interface{}); ok {
				cooperatives = make([]models.Cooperative, len(coopData))
				for i, coop := range coopData {
					if coopMap, ok := coop.(map[string]interface{}); ok {
						cooperatives[i] = models.Cooperative{
							ID:          coopMap["id"].(string),
							Name:        coopMap["name"].(string),
							Description: getStringValue(coopMap["description"]),
						}
					}
				}
			}
		}
	}

	return c.Render("business/create", fiber.Map{
		"Title":        "Create Business - HajiFund",
		"User":         user,
		"Cooperatives": cooperatives,
	}, "base")
}

// CreateBusiness handles business creation
func (h *Handler) CreateBusiness(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	// Check if user has business_owner role
	if !utils.HasRole(user.Roles, "business_owner") {
		return c.Status(403).JSON(fiber.Map{
			"status":  "error",
			"message": "Business owner role required to create businesses",
		})
	}

	var req models.CreateBusinessRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	// Make API request to backend
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/businesses", req, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Business created successfully",
		"redirect": "/business",
		"data":     resp.Data,
	})
}

// BusinessDetail renders business detail page
func (h *Handler) BusinessDetail(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	businessID := c.Params("id")

	// Get business details
	businessResp, err := utils.MakeAPIRequest("GET", "/api/v1/businesses/"+businessID, nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(404).Render("error", fiber.Map{
			"Code":    404,
			"Message": "Business not found",
		})
	}

	var business models.Business
	if data, ok := businessResp.Data.(map[string]interface{}); ok {
		business = models.Business{
			ID:             data["id"].(string),
			Name:           data["name"].(string),
			Description:    data["description"].(string),
			Type:           data["type"].(string),
			Address:        data["address"].(string),
			OwnerID:        data["owner_id"].(string),
			CooperativeID:  data["cooperative_id"].(string),
			Status:         data["status"].(string),
			ApprovalStatus: data["approval_status"].(string),
		}
	}

	// Check if user owns this business
	if business.OwnerID != user.ID {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Access denied to this business",
		})
	}

	return c.Render("business/detail", fiber.Map{
		"Title":    "Business Details - HajiFund",
		"User":     user,
		"Business": business,
	}, "base")
}

// UpdateBusiness handles business updates
func (h *Handler) UpdateBusiness(c *fiber.Ctx) error {
	businessID := c.Params("id")

	var req models.CreateBusinessRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	// Make API request to backend
	resp, err := utils.MakeAPIRequest("PUT", "/api/v1/businesses/"+businessID, req, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update business",
		})
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Business updated successfully",
		"redirect": "/business/" + businessID,
		"data":     resp.Data,
	})
}

// SubmitBusinessForApproval handles business approval submission
func (h *Handler) SubmitBusinessForApproval(c *fiber.Ctx) error {
	businessID := c.Params("id")

	// Make API request to backend
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/businesses/"+businessID+"/submit-approval", nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to submit business for approval",
		})
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Business submitted for approval successfully",
		"redirect": "/business/" + businessID,
		"data":     resp.Data,
	})
}

// Helper functions
func getTokenFromContext(c *fiber.Ctx) string {
	return c.Cookies("auth_token")
}
