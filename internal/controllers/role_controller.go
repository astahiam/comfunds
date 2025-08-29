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

type RoleController struct {
	userService   services.UserServiceAuth
	roleValidator *auth.RoleValidator
}

func NewRoleController(userService services.UserServiceAuth) *RoleController {
	return &RoleController{
		userService:   userService,
		roleValidator: auth.NewRoleValidator(),
	}
}

// GetUserRoles returns the current user's roles and permissions
// @Summary Get user roles and permissions
// @Tags roles
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Router /api/v1/user/roles [get]
func (c *RoleController) GetUserRoles(ctx *gin.Context) {
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

	// Get user permissions
	permissions := c.roleValidator.GetUserPermissions(userRolesList)

	// Get role descriptions
	roleDescriptions := make(map[string]string)
	for _, role := range userRolesList {
		if description, exists := auth.RoleDescriptions[role]; exists {
			roleDescriptions[role] = description
		}
	}

	response := map[string]interface{}{
		"user_id":           userID,
		"roles":             userRolesList,
		"role_descriptions": roleDescriptions,
		"permissions":       permissions,
		"can_invest":        c.roleValidator.CanUserInvest(userRolesList),
		"can_create_business": c.roleValidator.CanUserCreateBusiness(userRolesList),
		"can_create_project":  c.roleValidator.CanUserCreateProject(userRolesList),
		"can_approve_projects": c.roleValidator.CanUserApproveProjects(userRolesList),
		"can_access_cooperative": c.roleValidator.CanUserAccessCooperativeData(userRolesList),
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User roles retrieved successfully", response)
}

// UpdateUserRoles allows users to update their own roles (with restrictions)
// @Summary Update user roles
// @Tags roles
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param roles body map[string][]string true "New roles"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/user/roles [put]
func (c *RoleController) UpdateUserRoles(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	var req struct {
		Roles []string `json:"roles" validate:"required,dive,oneof=guest member business_owner investor"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	// Users cannot assign admin role to themselves (check before validation)
	if c.roleValidator.HasRole(req.Roles, auth.RoleAdmin) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Cannot assign admin role", nil)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Validate roles
	if err := c.roleValidator.ValidateRoles(req.Roles); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid roles", err)
		return
	}

	// Update user roles
	updateReq := &entities.UpdateUserRequest{
		Roles: req.Roles,
	}

	user, err := c.userService.UpdateUser(ctx.Request.Context(), userID.(uuid.UUID), updateReq)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to update user roles", err)
		return
	}

	// Get updated permissions
	permissions := c.roleValidator.GetUserPermissions(user.Roles)

	response := map[string]interface{}{
		"user":        user,
		"permissions": permissions,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User roles updated successfully", response)
}

// GetRoleInfo provides information about available roles and permissions
// @Summary Get role information
// @Tags roles
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/roles/info [get]
func (c *RoleController) GetRoleInfo(ctx *gin.Context) {
	response := map[string]interface{}{
		"available_roles":  auth.ValidRoles,
		"role_descriptions": auth.RoleDescriptions,
		"role_permissions": auth.RolePermissions,
		"role_hierarchy":   c.roleValidator.GetRoleHierarchy(),
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Role information retrieved successfully", response)
}

// GetUsersByRole returns users filtered by role (admin only)
// @Summary Get users by role
// @Tags roles
// @Produce json
// @Security BearerAuth
// @Param role path string true "Role name"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/admin/users/role/{role} [get]
func (c *RoleController) GetUsersByRole(ctx *gin.Context) {
	role := ctx.Param("role")
	if role == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Role parameter is required", nil)
		return
	}

	// Validate role
	if err := c.roleValidator.ValidateRoles([]string{role}); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid role", err)
		return
	}

	// Get pagination parameters
	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	// Note: This would require a new service method to filter users by role
	// For now, we'll return a placeholder response
	response := map[string]interface{}{
		"role":         role,
		"page":         page,
		"limit":        limit,
		"users":        []interface{}{}, // Placeholder
		"total":        0,
		"message":      "Feature not yet implemented - requires service method to filter users by role",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Users by role retrieved", response)
}
