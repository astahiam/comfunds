package controllers

import (
	"net/http"

	"comfunds/internal/auth"
	"comfunds/internal/entities"
	"comfunds/internal/repositories"
	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ProjectController struct {
	projectRepo   repositories.ProjectRepository
	roleValidator *auth.RoleValidator
}

func NewProjectController(projectRepo repositories.ProjectRepository) *ProjectController {
	return &ProjectController{
		projectRepo:   projectRepo,
		roleValidator: auth.NewRoleValidator(),
	}
}

// GetPublicProjects returns projects visible to guest users (FR-006)
// @Summary Get public projects
// @Tags projects
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/public/projects [get]
func (c *ProjectController) GetPublicProjects(ctx *gin.Context) {
	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	// Mock data for now - this would come from a project service
	projects := []map[string]interface{}{
		{
			"id":            uuid.New(),
			"title":         "Tech Startup Funding",
			"description":   "Innovative tech startup seeking investment for expansion",
			"target_amount": 100000,
			"raised_amount": 25000,
			"status":        "active",
			"category":      "Technology",
			"created_at":    "2024-01-15T10:00:00Z",
		},
		{
			"id":            uuid.New(),
			"title":         "Sustainable Agriculture Project",
			"description":   "Organic farming initiative for community development",
			"target_amount": 50000,
			"raised_amount": 15000,
			"status":        "active",
			"category":      "Agriculture",
			"created_at":    "2024-01-10T09:00:00Z",
		},
	}

	response := map[string]interface{}{
		"projects":     projects,
		"page":         page,
		"limit":        limit,
		"total":        len(projects),
		"access_level": "public",
		"message":      "Public projects visible to all users",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Public projects retrieved successfully", response)
}

// GetCooperativeProjects returns projects within user's cooperative (FR-007)
// @Summary Get cooperative projects
// @Tags projects
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/cooperative/projects [get]
func (c *ProjectController) GetCooperativeProjects(ctx *gin.Context) {
	userRoles, exists := ctx.Get("user_roles")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User roles not found", nil)
		return
	}

	userRolesList, ok := userRoles.([]string)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user roles format", nil)
		return
	}

	// Check if user can access cooperative data
	if !c.roleValidator.CanUserAccessCooperativeData(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Cooperative membership required", nil)
		return
	}

	cooperativeID, exists := ctx.Get("cooperative_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Cooperative membership required", nil)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	// Mock data for now - this would come from a project service
	cooperativeProjects := []map[string]interface{}{
		{
			"id":             uuid.New(),
			"title":          "Local Bakery Expansion",
			"description":    "Expanding local bakery to serve more community members",
			"target_amount":  75000,
			"raised_amount":  45000,
			"status":         "active",
			"category":       "Food & Beverage",
			"cooperative_id": cooperativeID,
			"created_at":     "2024-01-12T11:00:00Z",
		},
		{
			"id":             uuid.New(),
			"title":          "Community Center Renovation",
			"description":    "Renovating community center for better services",
			"target_amount":  200000,
			"raised_amount":  120000,
			"status":         "active",
			"category":       "Community Development",
			"cooperative_id": cooperativeID,
			"created_at":     "2024-01-08T14:00:00Z",
		},
	}

	response := map[string]interface{}{
		"projects":       cooperativeProjects,
		"page":           page,
		"limit":          limit,
		"total":          len(cooperativeProjects),
		"cooperative_id": cooperativeID,
		"access_level":   "cooperative",
		"user_roles":     userRolesList,
		"message":        "Cooperative projects accessible to members",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Cooperative projects retrieved successfully", response)
}

// CreateProject allows business owners to create projects (FR-008)
// @Summary Create a new project
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param project body entities.CreateProjectRequest true "Project data"
// @Success 201 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/projects [post]
func (c *ProjectController) CreateProject(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	userRoles, exists := ctx.Get("user_roles")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User roles not found", nil)
		return
	}

	userRolesList, ok := userRoles.([]string)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user roles format", nil)
		return
	}

	// Check if user can create projects (FR-008: Business Owners can create projects)
	if !c.roleValidator.CanUserCreateProject(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Business owner role required to create projects", nil)
		return
	}

	var req struct {
		Title            string     `json:"title" validate:"required,min=3,max=200"`
		Description      string     `json:"description" validate:"required,min=10,max=2000"`
		TargetAmount     float64    `json:"target_amount" validate:"required,min=1000"`
		Category         string     `json:"category" validate:"required"`
		BusinessID       *uuid.UUID `json:"business_id" validate:"required"`
		MinInvestment    *float64   `json:"min_investment" validate:"omitempty,min=100"`
		RiskLevel        *string    `json:"risk_level" validate:"omitempty,oneof=Low Medium High"`
		InvestmentPeriod *int       `json:"investment_period" validate:"omitempty,min=6,max=120"`
		ExpectedReturn   *string    `json:"expected_return" validate:"omitempty"`
		StartDate        *string    `json:"start_date" validate:"omitempty"`
		EndDate          *string    `json:"end_date" validate:"omitempty"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		// Log the error for debugging
		ctx.Error(err)
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	// Debug: Log the received request
	ctx.Set("debug_request", req)

	if err := utils.ValidateStruct(&req); err != nil {
		// Log validation errors
		ctx.Error(err)
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Parse user UUID and cooperative ID
	var userUUID uuid.UUID
	switch v := userID.(type) {
	case string:
		var err error
		userUUID, err = uuid.Parse(v)
		if err != nil {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
			return
		}
	case uuid.UUID:
		userUUID = v
	default:
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID format", nil)
		return
	}

	cooperativeID, exists := ctx.Get("cooperative_id")
	var cooperativeUUID uuid.UUID
	if exists && cooperativeID != nil {
		if coopIDStr, ok := cooperativeID.(string); ok {
			cooperativeUUID, _ = uuid.Parse(coopIDStr)
		}
	}

	// Create project entity
	newProject := &entities.Project{
		ID:             uuid.New(),
		Title:          req.Title,
		Description:    req.Description,
		TargetAmount:   req.TargetAmount,
		RaisedAmount:   0,
		Category:       req.Category,
		BusinessID:     *req.BusinessID,
		OwnerID:        userUUID,
		CooperativeID:  cooperativeUUID,
		Status:         "draft",
		ApprovalStatus: "pending",
	}

	// Add optional fields if provided
	if req.MinInvestment != nil {
		newProject.MinInvestment = *req.MinInvestment
	}
	if req.RiskLevel != nil {
		newProject.RiskLevel = *req.RiskLevel
	}
	if req.InvestmentPeriod != nil {
		newProject.InvestmentPeriod = *req.InvestmentPeriod
	}
	if req.ExpectedReturn != nil {
		newProject.ExpectedReturn = *req.ExpectedReturn
	}
	// Note: StartDate and EndDate require time.Time parsing, skipping for now

	// Save to database
	createdProject, err := c.projectRepo.Create(ctx, newProject)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create project", err)
		return
	}

	// Convert to response format
	projectResponse := map[string]interface{}{
		"id":              createdProject.ID.String(),
		"title":           createdProject.Title,
		"description":     createdProject.Description,
		"target_amount":   createdProject.TargetAmount,
		"raised_amount":   createdProject.RaisedAmount,
		"min_investment":  createdProject.MinInvestment,
		"category":        createdProject.Category,
		"business_id":     createdProject.BusinessID.String(),
		"owner_id":        createdProject.OwnerID.String(),
		"cooperative_id":  createdProject.CooperativeID.String(),
		"status":          createdProject.Status,
		"approval_status": createdProject.ApprovalStatus,
		"risk_level":      createdProject.RiskLevel,
		"created_at":      createdProject.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	response := map[string]interface{}{
		"project": projectResponse,
		"message": "Project created successfully and pending cooperative approval",
	}

	utils.SuccessResponse(ctx, http.StatusCreated, "Project created successfully", response)
}

// GetUserProjects returns projects owned by the authenticated user (FR-008)
// @Summary Get user's own projects
// @Tags projects
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/user/projects [get]
func (c *ProjectController) GetUserProjects(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	userRoles, exists := ctx.Get("user_roles")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User roles not found", nil)
		return
	}

	userRolesList, ok := userRoles.([]string)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user roles format", nil)
		return
	}

	// Check if user can manage projects
	if !c.roleValidator.CanUserCreateProject(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Business owner role required", nil)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	// Parse user UUID
	var userUUID uuid.UUID
	switch v := userID.(type) {
	case string:
		var err error
		userUUID, err = uuid.Parse(v)
		if err != nil {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
			return
		}
	case uuid.UUID:
		userUUID = v
	default:
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID format", nil)
		return
	}

	// Fetch user's projects from repository
	projects, err := c.projectRepo.GetByOwnerID(ctx, userUUID, limit, offset)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to fetch user projects", err)
		return
	}

	// Convert to map format for response
	var userProjects []map[string]interface{}
	for _, project := range projects {
		projectMap := map[string]interface{}{
			"id":              project.ID.String(),
			"title":           project.Title,
			"description":     project.Description,
			"target_amount":   project.TargetAmount,
			"raised_amount":   project.RaisedAmount,
			"min_investment":  project.MinInvestment,
			"category":        project.Category,
			"status":          project.Status,
			"approval_status": project.ApprovalStatus,
			"risk_level":      project.RiskLevel,
			"business_id":     project.BusinessID.String(),
			"owner_id":        project.OwnerID.String(),
			"cooperative_id":  project.CooperativeID.String(),
			"created_at":      project.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		}

		if project.ApprovedBy != nil {
			projectMap["approved_by"] = project.ApprovedBy.String()
		}
		if project.ApprovedAt != nil {
			projectMap["approved_at"] = project.ApprovedAt.Format("2006-01-02T15:04:05Z07:00")
		}
		if project.RejectedBy != nil {
			projectMap["rejected_by"] = project.RejectedBy.String()
		}
		if project.RejectedAt != nil {
			projectMap["rejected_at"] = project.RejectedAt.Format("2006-01-02T15:04:05Z07:00")
		}
		if project.RejectionReason != nil {
			projectMap["rejection_reason"] = *project.RejectionReason
		}
		if project.ReviewerComments != nil {
			projectMap["reviewer_comments"] = *project.ReviewerComments
		}

		userProjects = append(userProjects, projectMap)
	}

	// Get total count for pagination
	// Note: This is a simple count of returned projects.
	// For production, you'd want a separate Count method filtered by owner
	total := len(userProjects)

	response := map[string]interface{}{
		"projects":   userProjects,
		"page":       page,
		"limit":      limit,
		"total":      total,
		"owner_id":   userID,
		"user_roles": userRolesList,
		"message":    "User's projects retrieved successfully",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User projects retrieved successfully", response)
}

// GetInvestmentOpportunities returns projects available for investment (FR-009)
// @Summary Get investment opportunities
// @Tags projects
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Param category query string false "Filter by category"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/investments/opportunities [get]
func (c *ProjectController) GetInvestmentOpportunities(ctx *gin.Context) {
	userRoles, exists := ctx.Get("user_roles")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User roles not found", nil)
		return
	}

	userRolesList, ok := userRoles.([]string)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user roles format", nil)
		return
	}

	// Check if user can invest (FR-009: Investors can invest in approved projects)
	if !c.roleValidator.CanUserInvest(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Investor role required", nil)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)
	category := utils.GetStringQuery(ctx, "category", "")

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	// Mock investment opportunities - this would come from a project service
	opportunities := []map[string]interface{}{
		{
			"id":                uuid.New(),
			"title":             "Halal Food Processing Plant",
			"description":       "State-of-the-art halal food processing facility",
			"target_amount":     500000,
			"raised_amount":     200000,
			"min_investment":    1000,
			"expected_return":   "8-12% annually",
			"investment_period": "24 months",
			"status":            "approved",
			"category":          "Food Processing",
			"risk_level":        "Medium",
			"sharia_compliant":  true,
			"created_at":        "2024-01-05T09:00:00Z",
		},
		{
			"id":                uuid.New(),
			"title":             "Renewable Energy Project",
			"description":       "Solar panel installation for community buildings",
			"target_amount":     300000,
			"raised_amount":     150000,
			"min_investment":    500,
			"expected_return":   "6-10% annually",
			"investment_period": "36 months",
			"status":            "approved",
			"category":          "Renewable Energy",
			"risk_level":        "Low",
			"sharia_compliant":  true,
			"created_at":        "2024-01-03T11:00:00Z",
		},
	}

	// Filter by category if provided
	if category != "" {
		var filteredOpportunities []map[string]interface{}
		for _, opp := range opportunities {
			if oppCategory, ok := opp["category"].(string); ok && oppCategory == category {
				filteredOpportunities = append(filteredOpportunities, opp)
			}
		}
		opportunities = filteredOpportunities
	}

	response := map[string]interface{}{
		"opportunities": opportunities,
		"page":          page,
		"limit":         limit,
		"total":         len(opportunities),
		"category":      category,
		"user_roles":    userRolesList,
		"message":       "Investment opportunities for investors",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment opportunities retrieved successfully", response)
}

// GetProjects returns all projects with optional filtering
// @Summary Get all projects
// @Tags projects
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Param status query string false "Filter by status"
// @Param category query string false "Filter by category"
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Router /api/v1/projects [get]
func (c *ProjectController) GetProjects(ctx *gin.Context) {
	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)
	status := utils.GetStringQuery(ctx, "status", "")
	category := utils.GetStringQuery(ctx, "category", "")
	approvalStatus := utils.GetStringQuery(ctx, "approval_status", "")

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 1000 {
		limit = 10
	}

	offset := (page - 1) * limit

	// Fetch projects from repository
	projects, err := c.projectRepo.GetAll(ctx, limit*10, 0) // Fetch more to filter
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to fetch projects", err)
		return
	}

	// Convert to map format and apply filters
	var filteredProjects []map[string]interface{}
	for _, project := range projects {
		includeProject := true

		if status != "" && project.Status != status {
			includeProject = false
		}

		if category != "" && includeProject && project.Category != category {
			includeProject = false
		}

		if approvalStatus != "" && includeProject && project.ApprovalStatus != approvalStatus {
			includeProject = false
		}

		if includeProject {
			projectMap := map[string]interface{}{
				"id":              project.ID.String(),
				"title":           project.Title,
				"description":     project.Description,
				"target_amount":   project.TargetAmount,
				"raised_amount":   project.RaisedAmount,
				"min_investment":  project.MinInvestment,
				"category":        project.Category,
				"status":          project.Status,
				"approval_status": project.ApprovalStatus,
				"risk_level":      project.RiskLevel,
				"business_id":     project.BusinessID.String(),
				"owner_id":        project.OwnerID.String(),
				"cooperative_id":  project.CooperativeID.String(),
				"created_at":      project.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
			}

			if project.ApprovedBy != nil {
				projectMap["approved_by"] = project.ApprovedBy.String()
			}
			if project.ApprovedAt != nil {
				projectMap["approved_at"] = project.ApprovedAt.Format("2006-01-02T15:04:05Z07:00")
			}
			if project.RejectedBy != nil {
				projectMap["rejected_by"] = project.RejectedBy.String()
			}
			if project.RejectedAt != nil {
				projectMap["rejected_at"] = project.RejectedAt.Format("2006-01-02T15:04:05Z07:00")
			}
			if project.RejectionReason != nil {
				projectMap["rejection_reason"] = *project.RejectionReason
			}
			if project.ReviewerComments != nil {
				projectMap["reviewer_comments"] = *project.ReviewerComments
			}

			filteredProjects = append(filteredProjects, projectMap)
		}
	}

	// Apply pagination
	total := len(filteredProjects)
	start := offset
	end := start + limit

	if start > total {
		filteredProjects = []map[string]interface{}{}
	} else if end > total {
		filteredProjects = filteredProjects[start:]
	} else {
		filteredProjects = filteredProjects[start:end]
	}

	response := map[string]interface{}{
		"projects": filteredProjects,
		"page":     page,
		"limit":    limit,
		"total":    total,
		"filters": map[string]interface{}{
			"status":          status,
			"category":        category,
			"approval_status": approvalStatus,
		},
		"message": "Projects retrieved successfully",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Projects retrieved successfully", response)
}

// GetProjectByID returns a single project by ID
// @Summary Get project by ID
// @Tags projects
// @Produce json
// @Security BearerAuth
// @Param id path string true "Project ID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/projects/{id} [get]
func (c *ProjectController) GetProjectByID(ctx *gin.Context) {
	projectIDStr := ctx.Param("id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid project ID", err)
		return
	}

	// Fetch project from repository
	project, err := c.projectRepo.GetByID(ctx, projectID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "Project not found", err)
		return
	}

	// Convert to map format
	projectMap := map[string]interface{}{
		"id":                project.ID.String(),
		"title":             project.Title,
		"description":       project.Description,
		"target_amount":     project.TargetAmount,
		"raised_amount":     project.RaisedAmount,
		"min_investment":    project.MinInvestment,
		"category":          project.Category,
		"status":            project.Status,
		"approval_status":   project.ApprovalStatus,
		"risk_level":        project.RiskLevel,
		"investment_period": project.InvestmentPeriod,
		"expected_return":   project.ExpectedReturn,
		"business_id":       project.BusinessID.String(),
		"owner_id":          project.OwnerID.String(),
		"cooperative_id":    project.CooperativeID.String(),
		"created_at":        project.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		"updated_at":        project.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	// Add optional fields
	if project.ApprovedBy != nil {
		projectMap["approved_by"] = project.ApprovedBy.String()
	}
	if project.ApprovedAt != nil {
		projectMap["approved_at"] = project.ApprovedAt.Format("2006-01-02T15:04:05Z07:00")
	}
	if project.RejectedBy != nil {
		projectMap["rejected_by"] = project.RejectedBy.String()
	}
	if project.RejectedAt != nil {
		projectMap["rejected_at"] = project.RejectedAt.Format("2006-01-02T15:04:05Z07:00")
	}
	if project.RejectionReason != nil {
		projectMap["rejection_reason"] = *project.RejectionReason
	}
	if project.ReviewerComments != nil {
		projectMap["reviewer_comments"] = *project.ReviewerComments
	}
	if project.StartDate != nil {
		projectMap["start_date"] = project.StartDate.Format("2006-01-02T15:04:05Z07:00")
	}
	if project.EndDate != nil {
		projectMap["end_date"] = project.EndDate.Format("2006-01-02T15:04:05Z07:00")
	}
	if project.ProjectImage1 != nil {
		projectMap["project_image_1"] = *project.ProjectImage1
	}
	if project.ProjectImage2 != nil {
		projectMap["project_image_2"] = *project.ProjectImage2
	}
	if project.ProjectImage3 != nil {
		projectMap["project_image_3"] = *project.ProjectImage3
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Project retrieved successfully", projectMap)
}

// GetProjectsAvailableForInvestment returns projects available for investment
// @Summary Get projects available for investment
// @Tags projects
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Router /api/v1/projects/available-for-investment [get]
func (c *ProjectController) GetProjectsAvailableForInvestment(ctx *gin.Context) {
	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	// Mock data - projects that are approved and available for investment
	availableProjects := []map[string]interface{}{
		{
			"id":                uuid.New(),
			"title":             "Halal Food Processing Plant",
			"description":       "State-of-the-art halal food processing facility",
			"target_amount":     500000,
			"raised_amount":     200000,
			"remaining_amount":  300000,
			"min_investment":    1000,
			"max_investment":    50000,
			"expected_return":   "8-12% annually",
			"investment_period": "24 months",
			"status":            "approved",
			"category":          "Food Processing",
			"risk_level":        "Medium",
			"sharia_compliant":  true,
			"deadline":          "2024-06-30T23:59:59Z",
			"created_at":        "2024-01-05T09:00:00Z",
		},
		{
			"id":                uuid.New(),
			"title":             "Renewable Energy Project",
			"description":       "Solar panel installation for community buildings",
			"target_amount":     300000,
			"raised_amount":     150000,
			"remaining_amount":  150000,
			"min_investment":    500,
			"max_investment":    25000,
			"expected_return":   "6-10% annually",
			"investment_period": "36 months",
			"status":            "approved",
			"category":          "Renewable Energy",
			"risk_level":        "Low",
			"sharia_compliant":  true,
			"deadline":          "2024-05-31T23:59:59Z",
			"created_at":        "2024-01-03T11:00:00Z",
		},
	}

	// Apply pagination
	total := len(availableProjects)
	start := (page - 1) * limit
	end := start + limit

	if start > total {
		availableProjects = []map[string]interface{}{}
	} else if end > total {
		availableProjects = availableProjects[start:]
	} else {
		availableProjects = availableProjects[start:end]
	}

	response := map[string]interface{}{
		"projects": availableProjects,
		"page":     page,
		"limit":    limit,
		"total":    total,
		"message":  "Investment-ready projects retrieved successfully",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Available investment projects retrieved successfully", response)
}
