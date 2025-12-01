package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"hajifund-frontend/models"
	"hajifund-frontend/utils"
	"io"
	"mime/multipart"
	"net/http"
	"os"
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
		return c.Render("business/no-access", fiber.Map{
			"Title":        "Akses Terbatas - HajiFund",
			"User":         user,
			"RequiredRole": "Pemilik Bisnis",
			"CurrentRoles": user.Roles,
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

	// Forward multipart form data to backend
	backendURL := os.Getenv("API_BASE_URL")
	if backendURL == "" {
		backendURL = "http://localhost:8080"
	}

	// Check Content-Type header
	contentType := c.Get("Content-Type")
	fmt.Printf("DEBUG CreateBusiness: Content-Type received: %s\n", contentType)
	if contentType == "" || len(contentType) < 19 || contentType[:19] != "multipart/form-data" {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": fmt.Sprintf("Invalid Content-Type. Expected multipart/form-data, got: %s", contentType),
		})
	}

	// Parse multipart form with size limit (10MB)
	// Note: Fiber's MultipartForm() automatically parses the request body
	form, err := c.MultipartForm()
	if err != nil {
		fmt.Printf("Error parsing multipart form: %v\n", err)
		fmt.Printf("DEBUG CreateBusiness: Content-Type was: %s\n", contentType)
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid form data: " + err.Error(),
			"details": fmt.Sprintf("Content-Type: %s", contentType),
		})
	}

	// Reconstruct multipart form data for backend
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)

	// Add form fields
	fmt.Printf("DEBUG CreateBusiness: Form fields received:\n")
	for key, values := range form.Value {
		for _, value := range values {
			fmt.Printf("  %s: %s\n", key, value)
			writer.WriteField(key, value)
		}
	}
	fmt.Printf("DEBUG CreateBusiness: Form files received: %d\n", len(form.File))

	// Add files
	for key, files := range form.File {
		for _, file := range files {
			fileWriter, err := writer.CreateFormFile(key, file.Filename)
			if err != nil {
				writer.Close()
				return c.Status(500).JSON(fiber.Map{
					"status":  "error",
					"message": "Failed to create form file: " + err.Error(),
				})
			}

			// Open and copy file
			src, err := file.Open()
			if err != nil {
				writer.Close()
				return c.Status(500).JSON(fiber.Map{
					"status":  "error",
					"message": "Failed to open file: " + err.Error(),
				})
			}

			io.Copy(fileWriter, src)
			src.Close()
		}
	}

	writer.Close()
	body := buf.Bytes()
	multipartContentType := writer.FormDataContentType()

	// Create a new request to backend with multipart form data
	req, err := http.NewRequest("POST", backendURL+"/api/v1/businesses", bytes.NewReader(body))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create backend request",
		})
	}

	// Set headers
	req.Header.Set("Content-Type", multipartContentType)
	req.ContentLength = int64(len(body))
	token := getTokenFromContext(c)
	fmt.Printf("DEBUG CreateBusiness: Token from context: %s (length: %d)\n", 
		token, len(token))
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
		fmt.Printf("DEBUG CreateBusiness: Authorization header set\n")
	} else {
		fmt.Printf("DEBUG CreateBusiness: WARNING - No token found, Authorization header not set\n")
	}

	// Make request to backend
	client := &http.Client{
		Timeout: 30 * time.Second, // 30 second timeout for file uploads
	}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error connecting to backend: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to connect to backend: " + err.Error(),
		})
	}
	defer resp.Body.Close()

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error reading backend response: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to read backend response",
		})
	}

	// Parse backend response
	var backendResp map[string]interface{}
	if err := json.Unmarshal(respBody, &backendResp); err != nil {
		fmt.Printf("Error parsing backend response: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to parse backend response: " + err.Error(),
			"details": string(respBody),
		})
	}

	// Check if backend returned an error
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(backendResp)
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Business created successfully",
		"redirect": "/business",
		"data":     backendResp["data"],
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

	// Forward multipart form data to backend
	backendURL := os.Getenv("API_BASE_URL")
	if backendURL == "" {
		backendURL = "http://localhost:8080"
	}

	// Parse multipart form with size limit (10MB)
	form, err := c.MultipartForm()
	if err != nil {
		fmt.Printf("Error parsing multipart form: %v\n", err)
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid form data: " + err.Error(),
		})
	}

	// Reconstruct multipart form data for backend
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)

	// Add form fields
	for key, values := range form.Value {
		for _, value := range values {
			writer.WriteField(key, value)
		}
	}

	// Add files
	for key, files := range form.File {
		for _, file := range files {
			fileWriter, err := writer.CreateFormFile(key, file.Filename)
			if err != nil {
				writer.Close()
				return c.Status(500).JSON(fiber.Map{
					"status":  "error",
					"message": "Failed to create form file: " + err.Error(),
				})
			}

			// Open and copy file
			src, err := file.Open()
			if err != nil {
				writer.Close()
				return c.Status(500).JSON(fiber.Map{
					"status":  "error",
					"message": "Failed to open file: " + err.Error(),
				})
			}

			io.Copy(fileWriter, src)
			src.Close()
		}
	}

	writer.Close()
	body := buf.Bytes()
	contentType := writer.FormDataContentType()

	// Create a new request to backend with multipart form data
	req, err := http.NewRequest("PUT", backendURL+"/api/v1/businesses/"+businessID, bytes.NewReader(body))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create backend request",
		})
	}

	// Set headers
	req.Header.Set("Content-Type", contentType)
	req.ContentLength = int64(len(body))
	token := getTokenFromContext(c)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	// Make request to backend
	client := &http.Client{
		Timeout: 30 * time.Second, // 30 second timeout for file uploads
	}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error connecting to backend: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to connect to backend: " + err.Error(),
		})
	}
	defer resp.Body.Close()

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error reading backend response: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to read backend response",
		})
	}

	// Parse backend response
	var backendResp map[string]interface{}
	if err := json.Unmarshal(respBody, &backendResp); err != nil {
		fmt.Printf("Error parsing backend response: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to parse backend response: " + err.Error(),
			"details": string(respBody),
		})
	}

	// Check if backend returned an error
	if resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(backendResp)
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Business updated successfully",
		"redirect": "/business/" + businessID,
		"data":     backendResp["data"],
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
