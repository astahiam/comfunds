package controllers

import (
	"fmt"
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
		"user_id":                userID,
		"roles":                  userRolesList,
		"role_descriptions":      roleDescriptions,
		"permissions":            permissions,
		"can_invest":             c.roleValidator.CanUserInvest(userRolesList),
		"can_create_business":    c.roleValidator.CanUserCreateBusiness(userRolesList),
		"can_create_project":     c.roleValidator.CanUserCreateProject(userRolesList),
		"can_approve_projects":   c.roleValidator.CanUserApproveProjects(userRolesList),
		"can_access_cooperative": c.roleValidator.CanUserAccessCooperativeData(userRolesList),
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User roles retrieved successfully", response)
}

// UpdateUserRoles allows users to update their own roles (with restrictions)
// @Summary Update user roles (replace all roles)
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

	// Check for role conflicts
	if err := c.validateRoleConflicts(req.Roles); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Role conflicts detected", err)
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
		"role_changes": map[string]interface{}{
			"operation": "replace_all",
			"new_roles": req.Roles,
		},
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User roles updated successfully", response)
}

// AddUserRole allows users to add a single role to their existing roles
// @Summary Add a role to user
// @Tags roles
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param role body map[string]string true "Role to add"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/user/roles/add [post]
func (c *RoleController) AddUserRole(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	var req struct {
		Role string `json:"role" validate:"required,oneof=guest member business_owner investor"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	// Users cannot assign admin role to themselves
	if req.Role == auth.RoleAdmin {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Cannot assign admin role", nil)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Get current user
	user, err := c.userService.GetUserByID(ctx.Request.Context(), userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
		return
	}

	// Check if role already exists
	if c.roleValidator.HasRole(user.Roles, req.Role) {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "User already has this role", nil)
		return
	}

	// Add role to existing roles
	newRoles := append(user.Roles, req.Role)

	// Check for role conflicts
	if err := c.validateRoleConflicts(newRoles); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Role conflicts detected", err)
		return
	}

	// Update user roles
	updateReq := &entities.UpdateUserRequest{
		Roles: newRoles,
	}

	updatedUser, err := c.userService.UpdateUser(ctx.Request.Context(), userID.(uuid.UUID), updateReq)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to add role", err)
		return
	}

	// Get updated permissions
	permissions := c.roleValidator.GetUserPermissions(updatedUser.Roles)

	response := map[string]interface{}{
		"user":        updatedUser,
		"permissions": permissions,
		"role_changes": map[string]interface{}{
			"operation":  "add",
			"added_role": req.Role,
			"new_roles":  newRoles,
		},
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Role added successfully", response)
}

// RemoveUserRole allows users to remove a single role from their existing roles
// @Summary Remove a role from user
// @Tags roles
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param role body map[string]string true "Role to remove"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/user/roles/remove [post]
func (c *RoleController) RemoveUserRole(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	var req struct {
		Role string `json:"role" validate:"required,oneof=guest member business_owner investor"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Get current user
	user, err := c.userService.GetUserByID(ctx.Request.Context(), userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
		return
	}

	// Check if role exists
	if !c.roleValidator.HasRole(user.Roles, req.Role) {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "User does not have this role", nil)
		return
	}

	// Remove role from existing roles
	var newRoles []string
	for _, role := range user.Roles {
		if role != req.Role {
			newRoles = append(newRoles, role)
		}
	}

	// Ensure user has at least one role
	if len(newRoles) == 0 {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "User must have at least one role", nil)
		return
	}

	// Update user roles
	updateReq := &entities.UpdateUserRequest{
		Roles: newRoles,
	}

	updatedUser, err := c.userService.UpdateUser(ctx.Request.Context(), userID.(uuid.UUID), updateReq)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to remove role", err)
		return
	}

	// Get updated permissions
	permissions := c.roleValidator.GetUserPermissions(updatedUser.Roles)

	response := map[string]interface{}{
		"user":        updatedUser,
		"permissions": permissions,
		"role_changes": map[string]interface{}{
			"operation":    "remove",
			"removed_role": req.Role,
			"new_roles":    newRoles,
		},
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Role removed successfully", response)
}

// GetRoleInfo provides information about available roles and permissions
// @Summary Get role information
// @Tags roles
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/roles/info [get]
func (c *RoleController) GetRoleInfo(ctx *gin.Context) {
	response := map[string]interface{}{
		"available_roles":   auth.ValidRoles,
		"role_descriptions": auth.RoleDescriptions,
		"role_permissions":  auth.RolePermissions,
		"role_hierarchy":    c.roleValidator.GetRoleHierarchy(),
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
		"role":    role,
		"page":    page,
		"limit":   limit,
		"users":   []interface{}{}, // Placeholder
		"total":   0,
		"message": "Feature not yet implemented - requires service method to filter users by role",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Users by role retrieved", response)
}

// validateRoleConflicts checks for potential conflicts between roles
func (c *RoleController) validateRoleConflicts(roles []string) error {
	// Define role conflicts - roles that cannot be combined
	conflicts := map[string][]string{
		"guest": {"member", "business_owner", "investor", "admin"},
		"admin": {"guest"}, // Admin cannot be guest
	}

	// Check for conflicts
	for _, role := range roles {
		if conflictingRoles, exists := conflicts[role]; exists {
			for _, conflictingRole := range conflictingRoles {
				if c.roleValidator.HasRole(roles, conflictingRole) {
					return fmt.Errorf("role '%s' conflicts with role '%s'", role, conflictingRole)
				}
			}
		}
	}

	return nil
}

// GetRoleCompatibility returns information about role compatibility
// @Summary Get role compatibility information
// @Tags roles
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/roles/compatibility [get]
func (c *RoleController) GetRoleCompatibility(ctx *gin.Context) {
	// Define role compatibility matrix
	compatibility := map[string]interface{}{
		"compatible_combinations": []map[string]interface{}{
			{
				"roles":       []string{"member", "business_owner"},
				"description": "Member can also be a business owner",
				"permissions": "Combined permissions from both roles",
			},
			{
				"roles":       []string{"member", "investor"},
				"description": "Member can also be an investor",
				"permissions": "Combined permissions from both roles",
			},
			{
				"roles":       []string{"business_owner", "investor"},
				"description": "Business owner can also invest in other projects",
				"permissions": "Full business and investment capabilities",
			},
			{
				"roles":       []string{"member", "business_owner", "investor"},
				"description": "Full member with business and investment capabilities",
				"permissions": "All member, business, and investment permissions",
			},
		},
		"incompatible_combinations": []map[string]interface{}{
			{
				"roles":  []string{"guest", "member"},
				"reason": "Guest is for unregistered users only",
			},
			{
				"roles":  []string{"guest", "business_owner"},
				"reason": "Guest is for unregistered users only",
			},
			{
				"roles":  []string{"guest", "investor"},
				"reason": "Guest is for unregistered users only",
			},
			{
				"roles":  []string{"guest", "admin"},
				"reason": "Guest is for unregistered users only",
			},
		},
		"role_hierarchy": map[string]interface{}{
			"lowest":  "guest",
			"highest": "admin",
			"order":   []string{"guest", "member", "business_owner", "investor", "admin"},
		},
		"special_rules": []string{
			"Admin role can only be assigned by other admins",
			"Users cannot assign admin role to themselves",
			"Guest role is automatically assigned to unregistered users",
			"At least one role is required for all users",
		},
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Role compatibility information retrieved successfully", compatibility)
}
