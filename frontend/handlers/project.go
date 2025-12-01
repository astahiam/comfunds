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

// UserProjectsPage renders user's projects page (FR-032, FR-036)
func (h *Handler) UserProjectsPage(c *fiber.Ctx) error {
	// Get user from context with proper type checking
	userLocal := c.Locals("user")
	if userLocal == nil {
		return c.Redirect("/login")
	}

	user, ok := userLocal.(*models.User)
	if !ok || user == nil {
		return c.Redirect("/login")
	}

	// Get user's projects from API - NO MOCK DATA, real database query filtered by owner_id
	var userProjects []models.Project

	// Fetch user-specific projects from database
	projectsResp, err := utils.MakeAPIRequest("GET", "/api/v1/user/projects", nil, utils.GetAuthHeaders(getTokenFromContext(c)))

	// Parse the response
	if err == nil && projectsResp != nil && projectsResp.Data != nil {
		if data, ok := projectsResp.Data.(map[string]interface{}); ok {
			if projectsData, ok := data["projects"].([]interface{}); ok {
				userProjects = parseProjectsFromAPI(projectsData)
			}
		}
	}

	return c.Render("projects/index", fiber.Map{
		"Title":    "Proyek Saya - HajiFund",
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
		}, "base")
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
	req, err := http.NewRequest("POST", backendURL+"/api/v1/projects", bytes.NewReader(body))
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
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(backendResp)
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Project created successfully",
		"redirect": "/projects",
		"data":     backendResp["data"],
	})
}

// ProjectDetail renders project detail page (FR-036)
func (h *Handler) ProjectDetail(c *fiber.Ctx) error {
	projectID := c.Params("id")
	user := c.Locals("user").(*models.User)

	// Get project details
	projectResp, err := utils.MakeAPIRequest("GET", "/api/v1/projects/"+projectID, nil, utils.GetAuthHeaders(getTokenFromContext(c)))
	if err != nil || projectResp.Status != "success" {
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
	projectsResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/projects", nil, nil)
	var projects []models.Project
	if err == nil && projectsResp != nil && projectsResp.Data != nil {
		if data, ok := projectsResp.Data.(map[string]interface{}); ok {
			if projectsData, ok := data["projects"].([]interface{}); ok {
				projects = parseProjectsFromAPI(projectsData)
			}
		}
	}

	return c.Render("projects/public", fiber.Map{
		"Title":    "Peluang Investasi - HajiFund",
		"User":     user,
		"Projects": projects,
	}, "base")
}

// UpdateProject handles frontend proxy for project updates
func (h *Handler) UpdateProject(c *fiber.Ctx) error {
	projectID := c.Params("id")
	_ = c.Locals("user").(*models.User) // User validation handled by middleware

	// Forward the request to backend API
	headers := utils.GetAuthHeaders(getTokenFromContext(c))
	// Read the request body
	body := c.Body()
	resp, err := utils.MakeAPIRequest("PUT", "/api/v1/projects/"+projectID, body, headers)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update project",
		})
	}

	return c.Status(200).JSON(resp.Data)
}

// UpdateProjectApproval handles frontend proxy for admin project approval updates
func (h *Handler) UpdateProjectApproval(c *fiber.Ctx) error {
	projectID := c.Params("id")
	user := c.Locals("user").(*models.User)

	// Check if user is admin
	if !h.hasRole(user.Roles, "admin") {
		return c.Status(403).JSON(fiber.Map{
			"status":  "error",
			"message": "Admin access required",
		})
	}

	// Forward the request to backend API
	headers := utils.GetAuthHeaders(getTokenFromContext(c))
	// Read the request body
	body := c.Body()
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/admin/projects/"+projectID+"/approve", body, headers)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update project approval",
		})
	}

	return c.Status(200).JSON(resp.Data)
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

// hasRole checks if the user has the specified role
func (h *Handler) hasRole(roles []string, role string) bool {
	for _, r := range roles {
		if r == role {
			return true
		}
	}
	return false
}

func parseProjectFromAPI(projectMap map[string]interface{}) models.Project {
	project := models.Project{
		ID:             getStringValueFromMap(projectMap, "id"),
		Title:          getStringValueFromMap(projectMap, "title"),
		Description:    getStringValueFromMap(projectMap, "description"),
		BusinessID:     getStringValueFromMap(projectMap, "business_id"),
		ProjectType:    getStringValueFromMap(projectMap, "project_type"),
		Category:       getStringValueFromMap(projectMap, "category"),
		Status:         getStringValueFromMap(projectMap, "status"),
		ApprovalStatus: getStringValueFromMap(projectMap, "approval_status"),
		RiskLevel:      getStringValueFromMap(projectMap, "risk_level"),
		ExpectedReturn: getStringValueFromMap(projectMap, "expected_return"),
		CooperativeID:  getStringValueFromMap(projectMap, "cooperative_id"),
	}

	// Parse integer fields
	if investmentPeriod, ok := projectMap["investment_period"].(float64); ok {
		project.InvestmentPeriod = int(investmentPeriod)
	}

	// Parse boolean fields
	if shariaCompliant, ok := projectMap["sharia_compliant"].(bool); ok {
		project.ShariaCompliant = shariaCompliant
	}

	// Parse pointer string fields (optional fields)
	if rejectedBy, ok := projectMap["rejected_by"].(string); ok && rejectedBy != "" {
		project.RejectedBy = &rejectedBy
	}
	if rejectionReason, ok := projectMap["rejection_reason"].(string); ok && rejectionReason != "" {
		project.RejectionReason = &rejectionReason
	}
	if reviewerComments, ok := projectMap["reviewer_comments"].(string); ok && reviewerComments != "" {
		project.ReviewerComments = &reviewerComments
	}
	if approvedBy, ok := projectMap["approved_by"].(string); ok && approvedBy != "" {
		project.ApprovedBy = &approvedBy
	}

	// Parse documents array
	if docsData, ok := projectMap["documents"].([]interface{}); ok {
		documents := make([]string, 0, len(docsData))
		for _, doc := range docsData {
			if docStr, ok := doc.(string); ok {
				documents = append(documents, docStr)
			}
		}
		project.Documents = documents
	}

	// Handle funding amounts - support both old and new field names
	if fundingGoal, ok := projectMap["funding_goal"].(float64); ok {
		project.FundingGoal = fundingGoal
		project.TargetAmount = fundingGoal
	}
	if targetAmount, ok := projectMap["target_amount"].(float64); ok {
		project.TargetAmount = targetAmount
		if project.FundingGoal == 0 {
			project.FundingGoal = targetAmount
		}
	}

	if currentFunding, ok := projectMap["current_funding"].(float64); ok {
		project.CurrentFunding = currentFunding
		project.RaisedAmount = currentFunding
	}
	if raisedAmount, ok := projectMap["raised_amount"].(float64); ok {
		project.RaisedAmount = raisedAmount
		if project.CurrentFunding == 0 {
			project.CurrentFunding = raisedAmount
		}
	}

	if minimumFunding, ok := projectMap["minimum_funding"].(float64); ok {
		project.MinimumFunding = minimumFunding
	}
	if minInvestment, ok := projectMap["min_investment"].(float64); ok {
		project.MinInvestment = minInvestment
		if project.MinimumFunding == 0 {
			project.MinimumFunding = minInvestment
		}
	}

	// Calculate funding percentage
	targetForCalc := project.TargetAmount
	if targetForCalc == 0 {
		targetForCalc = project.FundingGoal
	}
	raisedForCalc := project.RaisedAmount
	if raisedForCalc == 0 {
		raisedForCalc = project.CurrentFunding
	}

	if targetForCalc > 0 {
		project.FundingPercentage = (raisedForCalc / targetForCalc) * 100
	}

	// Parse timestamps
	if createdAt, ok := projectMap["created_at"].(string); ok {
		if t, err := parseProjectTime(createdAt); err == nil {
			project.CreatedAt = t
		}
	}
	if updatedAt, ok := projectMap["updated_at"].(string); ok {
		if t, err := parseProjectTime(updatedAt); err == nil {
			project.UpdatedAt = t
		}
	}

	// Parse optional timestamp pointers
	if approvedAt, ok := projectMap["approved_at"].(string); ok && approvedAt != "" {
		if t, err := parseProjectTime(approvedAt); err == nil {
			project.ApprovedAt = &t
		}
	}
	if rejectedAt, ok := projectMap["rejected_at"].(string); ok && rejectedAt != "" {
		if t, err := parseProjectTime(rejectedAt); err == nil {
			project.RejectedAt = &t
		}
	}
	if startDate, ok := projectMap["start_date"].(string); ok && startDate != "" {
		if t, err := parseProjectTime(startDate); err == nil {
			project.StartDate = t
		}
	}
	if endDate, ok := projectMap["end_date"].(string); ok && endDate != "" {
		if t, err := parseProjectTime(endDate); err == nil {
			project.EndDate = t
		}
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

func parseProjectTime(timeStr string) (time.Time, error) {
	layouts := []string{
		time.RFC3339,
		"2006-01-02T15:04:05Z07:00",
		"2006-01-02 15:04:05",
		"2006-01-02",
	}

	for _, layout := range layouts {
		if t, err := time.Parse(layout, timeStr); err == nil {
			return t, nil
		}
	}

	return time.Time{}, fmt.Errorf("unable to parse time: %s", timeStr)
}

func getStringValueFromMap(data map[string]interface{}, key string) string {
	if value, ok := data[key]; ok {
		if str, ok := value.(string); ok {
			return str
		}
	}
	return ""
}
