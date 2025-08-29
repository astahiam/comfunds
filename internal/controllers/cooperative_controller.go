package controllers

import (
	"net/http"

	"comfunds/internal/auth"
	"comfunds/internal/entities"
	"comfunds/internal/services"
	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type CooperativeController struct {
	cooperativeService services.CooperativeService
	roleValidator      *auth.RoleValidator
}

func NewCooperativeController(cooperativeService services.CooperativeService) *CooperativeController {
	return &CooperativeController{
		cooperativeService: cooperativeService,
		roleValidator:      auth.NewRoleValidator(),
	}
}

// CreateCooperative handles cooperative creation (FR-015) - Admin only
// @Summary Create a new cooperative
// @Tags cooperatives
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param cooperative body entities.CreateCooperativeRequest true "Cooperative data"
// @Success 201 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/cooperatives [post]
func (c *CooperativeController) CreateCooperative(ctx *gin.Context) {
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

	// FR-015: Only authorized administrators can create cooperatives
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to create cooperatives", nil)
		return
	}

	var req entities.CreateCooperativeRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	cooperative, err := c.cooperativeService.CreateCooperative(ctx.Request.Context(), &req, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to create cooperative", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusCreated, "Cooperative created successfully", cooperative)
}

// GetCooperatives handles listing all cooperatives (FR-019)
// @Summary Get all cooperatives
// @Tags cooperatives
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Router /api/v1/cooperatives [get]
func (c *CooperativeController) GetCooperatives(ctx *gin.Context) {
	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	cooperatives, total, err := c.cooperativeService.GetAllCooperatives(ctx.Request.Context(), page, limit)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get cooperatives", err)
		return
	}

	response := map[string]interface{}{
		"cooperatives": cooperatives,
		"page":         page,
		"limit":        limit,
		"total":        total,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Cooperatives retrieved successfully", response)
}

// GetCooperative handles getting a specific cooperative (FR-019)
// @Summary Get cooperative by ID
// @Tags cooperatives
// @Produce json
// @Security BearerAuth
// @Param id path string true "Cooperative ID"
// @Success 200 {object} entities.Cooperative
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/cooperatives/{id} [get]
func (c *CooperativeController) GetCooperative(ctx *gin.Context) {
	idParam := ctx.Param("id")
	cooperativeID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid cooperative ID", err)
		return
	}

	cooperative, err := c.cooperativeService.GetCooperativeByID(ctx.Request.Context(), cooperativeID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "Cooperative not found", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Cooperative retrieved successfully", cooperative)
}

// UpdateCooperative handles updating a cooperative (FR-019) - Admin only
// @Summary Update cooperative
// @Tags cooperatives
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Cooperative ID"
// @Param cooperative body entities.UpdateCooperativeRequest true "Updated cooperative data"
// @Success 200 {object} entities.Cooperative
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/cooperatives/{id} [put]
func (c *CooperativeController) UpdateCooperative(ctx *gin.Context) {
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

	// Only admin can update cooperatives
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to update cooperatives", nil)
		return
	}

	idParam := ctx.Param("id")
	cooperativeID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid cooperative ID", err)
		return
	}

	var req entities.UpdateCooperativeRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	cooperative, err := c.cooperativeService.UpdateCooperative(ctx.Request.Context(), cooperativeID, &req, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to update cooperative", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Cooperative updated successfully", cooperative)
}

// DeleteCooperative handles soft deleting a cooperative (FR-019) - Admin only
// @Summary Delete cooperative
// @Tags cooperatives
// @Security BearerAuth
// @Param id path string true "Cooperative ID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/cooperatives/{id} [delete]
func (c *CooperativeController) DeleteCooperative(ctx *gin.Context) {
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

	// Only admin can delete cooperatives
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to delete cooperatives", nil)
		return
	}

	idParam := ctx.Param("id")
	cooperativeID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid cooperative ID", err)
		return
	}

	err = c.cooperativeService.DeleteCooperative(ctx.Request.Context(), cooperativeID, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to delete cooperative", err)
		return
	}

	response := map[string]interface{}{
		"id":      cooperativeID,
		"message": "Cooperative deleted successfully",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Cooperative deleted successfully", response)
}

// GetCooperativeMembers handles getting members of a cooperative (FR-022)
// @Summary Get cooperative members
// @Tags cooperatives
// @Produce json
// @Security BearerAuth
// @Param id path string true "Cooperative ID"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/cooperatives/{id}/members [get]
func (c *CooperativeController) GetCooperativeMembers(ctx *gin.Context) {
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

	// Only cooperative members and admins can view member list
	if !c.roleValidator.CanUserAccessCooperativeData(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Cooperative access required", nil)
		return
	}

	idParam := ctx.Param("id")
	cooperativeID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid cooperative ID", err)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	members, total, err := c.cooperativeService.GetCooperativeMembers(ctx.Request.Context(), cooperativeID, page, limit)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get cooperative members", err)
		return
	}

	response := map[string]interface{}{
		"members":        members,
		"page":           page,
		"limit":          limit,
		"total":          total,
		"cooperative_id": cooperativeID,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Cooperative members retrieved successfully", response)
}

// ApproveProject handles project approval by cooperative (FR-020)
// @Summary Approve a project
// @Tags cooperatives
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Cooperative ID"
// @Param project_id path string true "Project ID"
// @Param approval body map[string]string true "Approval data"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/cooperatives/{id}/projects/{project_id}/approve [post]
func (c *CooperativeController) ApproveProject(ctx *gin.Context) {
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

	// FR-020: Only admins can approve projects
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to approve projects", nil)
		return
	}

	cooperativeIDParam := ctx.Param("id")
	cooperativeID, err := uuid.Parse(cooperativeIDParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid cooperative ID", err)
		return
	}

	projectIDParam := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid project ID", err)
		return
	}

	var req struct {
		Comments string `json:"comments"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	err = c.cooperativeService.ApproveProject(ctx.Request.Context(), cooperativeID, projectID, userID.(uuid.UUID), req.Comments)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to approve project", err)
		return
	}

	response := map[string]interface{}{
		"cooperative_id": cooperativeID,
		"project_id":     projectID,
		"status":         "approved",
		"comments":       req.Comments,
		"approved_by":    userID,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Project approved successfully", response)
}
