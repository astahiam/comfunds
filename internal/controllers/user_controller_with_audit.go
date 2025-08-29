package controllers

import (
	"net/http"
	"strings"

	"comfunds/internal/auth"
	"comfunds/internal/entities"
	"comfunds/internal/services"
	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UserControllerWithAudit struct {
	userService   services.UserServiceWithAudit
	roleValidator *auth.RoleValidator
}

func NewUserControllerWithAudit(userService services.UserServiceWithAudit) *UserControllerWithAudit {
	return &UserControllerWithAudit{
		userService:   userService,
		roleValidator: auth.NewRoleValidator(),
	}
}

// GetUsers handles listing all users with audit trail (FR-011, FR-013)
// @Summary Get all users (with audit logging)
// @Tags users
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/admin/users [get]
func (c *UserControllerWithAudit) GetUsers(ctx *gin.Context) {
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

	// FR-012: Only authorized users can access user lists (admin only)
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to list users", nil)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	// Get client info for audit
	ipAddress := c.getClientIP(ctx)
	userAgent := ctx.GetHeader("User-Agent")

	users, total, err := c.userService.GetAllUsersWithAudit(ctx.Request.Context(), userID.(uuid.UUID), page, limit, ipAddress, userAgent)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get users", err)
		return
	}

	response := map[string]interface{}{
		"users": users,
		"page":  page,
		"limit": limit,
		"total": total,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Users retrieved successfully", response)
}

// GetUser handles getting a specific user with audit trail (FR-011, FR-013)
// @Summary Get user by ID (with audit logging)
// @Tags users
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID"
// @Success 200 {object} entities.User
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/admin/users/{id} [get]
func (c *UserControllerWithAudit) GetUser(ctx *gin.Context) {
	requestUserID, exists := ctx.Get("user_id")
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

	// FR-012: Only authorized users can access user details
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to view user details", nil)
		return
	}

	idParam := ctx.Param("id")
	targetUserID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	// Get client info for audit
	ipAddress := c.getClientIP(ctx)
	userAgent := ctx.GetHeader("User-Agent")

	user, err := c.userService.GetUserByIDWithAudit(ctx.Request.Context(), targetUserID, requestUserID.(uuid.UUID), ipAddress, userAgent)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User retrieved successfully", user)
}

// UpdateUser handles updating a user with audit trail (FR-011, FR-013)
// @Summary Update user (with audit logging)
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID"
// @Param user body entities.UpdateUserRequest true "Updated user data"
// @Param reason query string false "Reason for update"
// @Success 200 {object} entities.User
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/admin/users/{id} [put]
func (c *UserControllerWithAudit) UpdateUser(ctx *gin.Context) {
	requestUserID, exists := ctx.Get("user_id")
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

	// FR-012: Only authorized users can update user records
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to update users", nil)
		return
	}

	idParam := ctx.Param("id")
	targetUserID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	var req entities.UpdateUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Get client info for audit
	ipAddress := c.getClientIP(ctx)
	userAgent := ctx.GetHeader("User-Agent")
	reason := utils.GetStringQuery(ctx, "reason", "")

	user, err := c.userService.UpdateUserWithAudit(ctx.Request.Context(), targetUserID, requestUserID.(uuid.UUID), &req, ipAddress, userAgent, reason)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to update user", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User updated successfully", user)
}

// SoftDeleteUser handles soft deleting a user with audit trail (FR-014, FR-013)
// @Summary Soft delete user (with audit logging)
// @Tags users
// @Security BearerAuth
// @Param id path string true "User ID"
// @Param reason query string true "Reason for deletion"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/admin/users/{id} [delete]
func (c *UserControllerWithAudit) SoftDeleteUser(ctx *gin.Context) {
	requestUserID, exists := ctx.Get("user_id")
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

	// FR-012: Only authorized users can delete user records
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to delete users", nil)
		return
	}

	idParam := ctx.Param("id")
	targetUserID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	reason := utils.GetStringQuery(ctx, "reason", "")
	if reason == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Reason is required for user deletion", nil)
		return
	}

	// Get client info for audit
	ipAddress := c.getClientIP(ctx)
	userAgent := ctx.GetHeader("User-Agent")

	err = c.userService.SoftDeleteUser(ctx.Request.Context(), targetUserID, requestUserID.(uuid.UUID), ipAddress, userAgent, reason)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to delete user", err)
		return
	}

	response := map[string]interface{}{
		"id":      targetUserID,
		"status":  "soft_deleted",
		"reason":  reason,
		"message": "User soft deleted successfully",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User deleted successfully", response)
}

// GetUserAuditTrail handles getting user's audit trail (FR-013)
// @Summary Get user audit trail
// @Tags users
// @Produce json
// @Security BearerAuth
// @Param id path string true "User ID"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/admin/users/{id}/audit [get]
func (c *UserControllerWithAudit) GetUserAuditTrail(ctx *gin.Context) {
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

	// Only admin can view audit trails
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to view audit trails", nil)
		return
	}

	idParam := ctx.Param("id")
	userID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	auditLogs, total, err := c.userService.GetUserAuditTrail(ctx.Request.Context(), userID, page, limit)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get audit trail", err)
		return
	}

	response := map[string]interface{}{
		"audit_logs": auditLogs,
		"page":       page,
		"limit":      limit,
		"total":      total,
		"user_id":    userID,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User audit trail retrieved successfully", response)
}

// Helper method to get client IP address
func (c *UserControllerWithAudit) getClientIP(ctx *gin.Context) string {
	// Check for forwarded IP first
	forwarded := ctx.GetHeader("X-Forwarded-For")
	if forwarded != "" {
		// X-Forwarded-For can contain multiple IPs, take the first one
		ips := strings.Split(forwarded, ",")
		return strings.TrimSpace(ips[0])
	}

	// Check for real IP
	realIP := ctx.GetHeader("X-Real-IP")
	if realIP != "" {
		return realIP
	}

	// Fall back to remote address
	return ctx.ClientIP()
}
