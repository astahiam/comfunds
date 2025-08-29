package controllers

import (
	"net/http"

	"comfunds/internal/auth"
	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ProjectController struct {
	roleValidator *auth.RoleValidator
}

func NewProjectController() *ProjectController {
	return &ProjectController{
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
			"id":          uuid.New(),
			"title":       "Tech Startup Funding",
			"description": "Innovative tech startup seeking investment for expansion",
			"target_amount": 100000,
			"raised_amount": 25000,
			"status":      "active",
			"category":    "Technology",
			"created_at":  "2024-01-15T10:00:00Z",
		},
		{
			"id":          uuid.New(),
			"title":       "Sustainable Agriculture Project", 
			"description": "Organic farming initiative for community development",
			"target_amount": 50000,
			"raised_amount": 15000,
			"status":      "active",
			"category":    "Agriculture",
			"created_at":  "2024-01-10T09:00:00Z",
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
		Title         string  `json:"title" validate:"required,min=3,max=200"`
		Description   string  `json:"description" validate:"required,min=10,max=2000"`
		TargetAmount  float64 `json:"target_amount" validate:"required,min=1000"`
		Category      string  `json:"category" validate:"required"`
		BusinessID    *uuid.UUID `json:"business_id" validate:"required"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Mock project creation - this would use a project service
	project := map[string]interface{}{
		"id":            uuid.New(),
		"title":         req.Title,
		"description":   req.Description,
		"target_amount": req.TargetAmount,
		"raised_amount": 0,
		"category":      req.Category,
		"business_id":   req.BusinessID,
		"owner_id":      userID,
		"status":        "pending_approval",
		"created_at":    "2024-01-15T12:00:00Z",
	}

	response := map[string]interface{}{
		"project": project,
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

	// Mock data - this would come from a project service
	userProjects := []map[string]interface{}{
		{
			"id":            uuid.New(),
			"title":         "My Restaurant Chain",
			"description":   "Expanding my restaurant business to new locations",
			"target_amount": 150000,
			"raised_amount": 75000,
			"status":        "active",
			"category":      "Food & Beverage",
			"owner_id":      userID,
			"created_at":    "2024-01-10T10:00:00Z",
		},
	}

	response := map[string]interface{}{
		"projects":   userProjects,
		"page":       page,
		"limit":      limit,
		"total":      len(userProjects),
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
