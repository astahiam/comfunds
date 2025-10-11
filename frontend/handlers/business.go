package handlers

import (
	"fmt"
	"hajifund-frontend/models"
	"hajifund-frontend/utils"
	"time"

	"github.com/gofiber/fiber/v2"
)

// NewBusinessHandler creates a new business handler
func NewBusinessHandler() *Handler {
	return &Handler{}
}

// Helper functions
func getTokenFromContext(c *fiber.Ctx) string {
	return c.Cookies("auth_token")
}

func getBusinessStringValue(value interface{}) string {
	if value == nil {
		return ""
	}
	if str, ok := value.(string); ok {
		return str
	}
	return ""
}

func getBusinessStringPointer(value interface{}) *string {
	if value == nil {
		return nil
	}
	if str, ok := value.(string); ok {
		return &str
	}
	return nil
}

func getBusinessTimePointer(value interface{}) *time.Time {
	if value == nil {
		return nil
	}
	if str, ok := value.(string); ok && str != "" {
		if t, err := time.Parse(time.RFC3339, str); err == nil {
			return &t
		}
	}
	return nil
}

func getBusinessTimeValue(value interface{}) time.Time {
	if value == nil {
		return time.Time{}
	}
	
	if str, ok := value.(string); ok && str != "" {
		// Try multiple date formats
		formats := []string{
			time.RFC3339,
			time.RFC3339Nano,
			"2006-01-02T15:04:05.999999999Z07:00",
			"2006-01-02T15:04:05.999999999Z",
			"2006-01-02T15:04:05Z07:00",
			"2006-01-02T15:04:05Z",
			"2006-01-02 15:04:05.999999999",
			"2006-01-02 15:04:05",
			"2006-01-02",
		}

		for _, format := range formats {
			if t, err := time.Parse(format, str); err == nil {
				// Convert to WIB (UTC+7) timezone
				wib := time.FixedZone("WIB", 7*60*60)
				return t.In(wib)
			}
		}
	}
	return time.Time{}
}

func getBusinessIntValue(value interface{}) int {
	if value == nil {
		return 0
	}
	if intVal, ok := value.(int); ok {
		return intVal
	}
	if floatVal, ok := value.(float64); ok {
		return int(floatVal)
	}
	return 0
}

func getBusinessFloatValue(value interface{}) float64 {
	if value == nil {
		return 0
	}
	if floatVal, ok := value.(float64); ok {
		return floatVal
	}
	if intVal, ok := value.(int); ok {
		return float64(intVal)
	}
	return 0
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
							ID:               getBusinessStringValue(businessMap["id"]),
							Name:             getBusinessStringValue(businessMap["name"]),
							Description:      getBusinessStringValue(businessMap["description"]),
							Type:             getBusinessStringValue(businessMap["type"]),
							Address:          getBusinessStringValue(businessMap["address"]),
							OwnerID:          getBusinessStringValue(businessMap["owner_id"]),
							CooperativeID:    getBusinessStringValue(businessMap["cooperative_id"]),
							Status:           getBusinessStringValue(businessMap["status"]),
							ApprovalStatus:   getBusinessStringValue(businessMap["approval_status"]),
							ApprovedBy:       getBusinessStringPointer(businessMap["approved_by"]),
							ApprovedAt:       getBusinessTimePointer(businessMap["approved_at"]),
							RejectedBy:       getBusinessStringPointer(businessMap["rejected_by"]),
							RejectedAt:       getBusinessTimePointer(businessMap["rejected_at"]),
							RejectionReason:  getBusinessStringValue(businessMap["rejection_reason"]),
							ReviewerComments: getBusinessStringValue(businessMap["reviewer_comments"]),
							CreatedAt:        getBusinessTimeValue(businessMap["created_at"]),
							UpdatedAt:        getBusinessTimeValue(businessMap["updated_at"]),
							// Risk Assessment Documents
							BusinessPlanURL:        getBusinessStringValue(businessMap["business_plan_url"]),
							SWOTAnalysisURL:        getBusinessStringValue(businessMap["swot_analysis_url"]),
							FinancialStatementsURL: getBusinessStringValue(businessMap["financial_statements_url"]),
							MarketResearchURL:      getBusinessStringValue(businessMap["market_research_url"]),
							RiskAssessmentURL:      getBusinessStringValue(businessMap["risk_assessment_url"]),
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
		}, "base")
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
							Description: getBusinessStringValue(coopMap["description"]),
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
	if err != nil || businessResp.Status != "success" {
		return c.Status(404).Render("error", fiber.Map{
			"Code":    404,
			"Message": "Business not found",
		}, "base")
	}

	var business models.Business
	if data, ok := businessResp.Data.(map[string]interface{}); ok {
		business = models.Business{
			ID:                 getBusinessStringValue(data["id"]),
			Name:               getBusinessStringValue(data["name"]),
			Description:        getBusinessStringValue(data["description"]),
			Type:               getBusinessStringValue(data["type"]),
			Address:            getBusinessStringValue(data["address"]),
			OwnerID:            getBusinessStringValue(data["owner_id"]),
			CooperativeID:      getBusinessStringValue(data["cooperative_id"]),
			Status:             getBusinessStringValue(data["status"]),
			ApprovalStatus:     getBusinessStringValue(data["approval_status"]),
			RegistrationNumber: getBusinessStringValue(data["registration_number"]),
			LegalStructure:     getBusinessStringValue(data["legal_structure"]),
			Industry:           getBusinessStringValue(data["industry"]),
			Phone:              getBusinessStringValue(data["phone"]),
			Email:              getBusinessStringValue(data["email"]),
			Website:            getBusinessStringValue(data["website"]),
			EstablishedDate:    getBusinessStringValue(data["established_date"]),
			EmployeeCount:      getBusinessIntValue(data["employee_count"]),
			AnnualRevenue:      getBusinessFloatValue(data["annual_revenue"]),
			Currency:           getBusinessStringValue(data["currency"]),
			BankAccount:        getBusinessStringValue(data["bank_account"]),
			BusinessLicense:    getBusinessStringValue(data["business_license"]),
			CreatedAt:          getBusinessTimeValue(data["created_at"]),
			UpdatedAt:          getBusinessTimeValue(data["updated_at"]),
			// Risk Assessment Documents
			BusinessPlanURL:        getBusinessStringValue(data["business_plan_url"]),
			SWOTAnalysisURL:        getBusinessStringValue(data["swot_analysis_url"]),
			FinancialStatementsURL: getBusinessStringValue(data["financial_statements_url"]),
			MarketResearchURL:      getBusinessStringValue(data["market_research_url"]),
			RiskAssessmentURL:      getBusinessStringValue(data["risk_assessment_url"]),
			// Approval/Rejection fields
			ApprovedBy:       getBusinessStringPointer(data["approved_by"]),
			ApprovedAt:       getBusinessTimePointer(data["approved_at"]),
			RejectedBy:       getBusinessStringPointer(data["rejected_by"]),
			RejectedAt:       getBusinessTimePointer(data["rejected_at"]),
			RejectionReason:  getBusinessStringValue(data["rejection_reason"]),
			ReviewerComments: getBusinessStringValue(data["reviewer_comments"]),
		}
	}

	// Check if user has access to this business
	hasAccess := false

	// Business owner can always access their own business
	if business.OwnerID == user.ID {
		hasAccess = true
	}

	// Cooperative members can view businesses in their cooperative
	if !hasAccess && user.CooperativeID != nil && business.CooperativeID == *user.CooperativeID {
		// Check if user has member, business_owner, investor, or admin role
		for _, role := range user.Roles {
			if role == "member" || role == "business_owner" || role == "investor" || role == "admin" {
				hasAccess = true
				break
			}
		}
	}

	// Admins can view all businesses
	if !hasAccess {
		for _, role := range user.Roles {
			if role == "admin" {
				hasAccess = true
				break
			}
		}
	}

	if !hasAccess {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Access denied to this business",
		}, "base")
	}

	return c.Render("business/detail", fiber.Map{
		"Title":    "Business Details - HajiFund",
		"User":     user,
		"Business": business,
	}, "base")
}

// EditBusinessPage renders the business edit page
func (h *Handler) EditBusinessPage(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	businessID := c.Params("id")

	// Fetch business details
	businessResp, err := utils.MakeAPIRequest("GET", "/api/v1/businesses/"+businessID, nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil || businessResp.Status != "success" {
		return c.Status(404).Render("error", fiber.Map{
			"Code":    404,
			"Message": "Business not found",
		}, "base")
	}

	var business models.Business
	if data, ok := businessResp.Data.(map[string]interface{}); ok {
		business = models.Business{
			ID:                 getBusinessStringValue(data["id"]),
			Name:               getBusinessStringValue(data["name"]),
			Description:        getBusinessStringValue(data["description"]),
			Type:               getBusinessStringValue(data["type"]),
			Address:            getBusinessStringValue(data["address"]),
			OwnerID:            getBusinessStringValue(data["owner_id"]),
			CooperativeID:      getBusinessStringValue(data["cooperative_id"]),
			Status:             getBusinessStringValue(data["status"]),
			ApprovalStatus:     getBusinessStringValue(data["approval_status"]),
			RegistrationNumber: getBusinessStringValue(data["registration_number"]),
			LegalStructure:     getBusinessStringValue(data["legal_structure"]),
			Industry:           getBusinessStringValue(data["industry"]),
			Phone:              getBusinessStringValue(data["phone"]),
			Email:              getBusinessStringValue(data["email"]),
			Website:            getBusinessStringValue(data["website"]),
			EstablishedDate:    getBusinessStringValue(data["established_date"]),
			EmployeeCount:      getBusinessIntValue(data["employee_count"]),
			AnnualRevenue:      getBusinessFloatValue(data["annual_revenue"]),
			Currency:           getBusinessStringValue(data["currency"]),
			BankAccount:        getBusinessStringValue(data["bank_account"]),
			BusinessLicense:    getBusinessStringValue(data["business_license"]),
			ApprovedBy:         getBusinessStringPointer(data["approved_by"]),
			ApprovedAt:         getBusinessTimePointer(data["approved_at"]),
			RejectedBy:         getBusinessStringPointer(data["rejected_by"]),
			RejectedAt:         getBusinessTimePointer(data["rejected_at"]),
			RejectionReason:    getBusinessStringValue(data["rejection_reason"]),
			ReviewerComments:   getBusinessStringValue(data["reviewer_comments"]),
			// Risk Assessment Documents
			BusinessPlanURL:        getBusinessStringValue(data["business_plan_url"]),
			SWOTAnalysisURL:        getBusinessStringValue(data["swot_analysis_url"]),
			FinancialStatementsURL: getBusinessStringValue(data["financial_statements_url"]),
			MarketResearchURL:      getBusinessStringValue(data["market_research_url"]),
			RiskAssessmentURL:      getBusinessStringValue(data["risk_assessment_url"]),
		}
	}

	// Check if user owns this business
	if business.OwnerID != user.ID {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Access denied",
		}, "base")
	}

	return c.Render("business/edit", fiber.Map{
		"Title":    "Edit Bisnis - HajiFund",
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
