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

type BusinessController struct {
	businessService services.BusinessManagementService
	roleValidator   *auth.RoleValidator
}

func NewBusinessController(businessService services.BusinessManagementService) *BusinessController {
	return &BusinessController{
		businessService: businessService,
		roleValidator:   auth.NewRoleValidator(),
	}
}

// CreateBusiness handles business creation (FR-024) - Business Owners only
// @Summary Create a new business
// @Tags businesses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param business body entities.CreateBusinessRequest true "Business data"
// @Success 201 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/businesses [post]
func (c *BusinessController) CreateBusiness(ctx *gin.Context) {
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

	// FR-024: Only business owners can create businesses
	if !c.roleValidator.HasRole(userRolesList, auth.RoleBusinessOwner) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Business owner role required to create businesses", nil)
		return
	}

	var req entities.CreateBusinessExtendedRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	business, err := c.businessService.CreateBusiness(ctx.Request.Context(), &req, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to create business", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusCreated, "Business created successfully", business)
}

// GetBusiness handles getting a specific business (FR-028)
// @Summary Get business by ID
// @Tags businesses
// @Produce json
// @Security BearerAuth
// @Param id path string true "Business ID"
// @Success 200 {object} entities.BusinessExtended
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/businesses/{id} [get]
func (c *BusinessController) GetBusiness(ctx *gin.Context) {
	idParam := ctx.Param("id")
	businessID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid business ID", err)
		return
	}

	business, err := c.businessService.GetBusiness(ctx.Request.Context(), businessID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "Business not found", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Business retrieved successfully", business)
}

// GetOwnerBusinesses handles getting businesses owned by the authenticated user (FR-029)
// @Summary Get businesses owned by user
// @Tags businesses
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 401 {object} utils.ErrorResponseData
// @Router /api/v1/user/businesses [get]
func (c *BusinessController) GetOwnerBusinesses(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	businesses, total, err := c.businessService.GetOwnerBusinesses(ctx.Request.Context(), userID.(uuid.UUID), page, limit)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get businesses", err)
		return
	}

	response := map[string]interface{}{
		"businesses": businesses,
		"page":       page,
		"limit":      limit,
		"total":      total,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Businesses retrieved successfully", response)
}

// UpdateBusiness handles updating a business (FR-028) - Owner only
// @Summary Update business
// @Tags businesses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Business ID"
// @Param business body entities.UpdateBusinessRequest true "Updated business data"
// @Success 200 {object} entities.BusinessExtended
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/businesses/{id} [put]
func (c *BusinessController) UpdateBusiness(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	idParam := ctx.Param("id")
	businessID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid business ID", err)
		return
	}

	var req entities.UpdateBusinessExtendedRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	business, err := c.businessService.UpdateBusiness(ctx.Request.Context(), businessID, &req, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to update business", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Business updated successfully", business)
}

// SubmitBusinessForApproval handles submitting business for cooperative approval (FR-027)
// @Summary Submit business for approval
// @Tags businesses
// @Security BearerAuth
// @Param id path string true "Business ID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/businesses/{id}/submit-approval [post]
func (c *BusinessController) SubmitBusinessForApproval(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	idParam := ctx.Param("id")
	businessID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid business ID", err)
		return
	}

	err = c.businessService.SubmitBusinessForApproval(ctx.Request.Context(), businessID, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to submit business for approval", err)
		return
	}

	response := map[string]interface{}{
		"business_id": businessID,
		"status":      "submitted_for_approval",
		"message":     "Business submitted for cooperative approval",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Business submitted for approval successfully", response)
}

// ApproveBusiness handles business approval by cooperative admin (FR-027)
// @Summary Approve business registration
// @Tags businesses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param approval body entities.BusinessApprovalRequest true "Approval data"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/admin/businesses/approve [post]
func (c *BusinessController) ApproveBusiness(ctx *gin.Context) {
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

	// FR-027: Only admin can approve businesses
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to approve businesses", nil)
		return
	}

	var req entities.BusinessApprovalRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	err := c.businessService.ApproveBusinessRegistration(ctx.Request.Context(), &req, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to approve business", err)
		return
	}

	response := map[string]interface{}{
		"business_id": req.BusinessID,
		"status":      "approved",
		"comments":    req.Comments,
		"approved_by": userID,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Business approved successfully", response)
}

// RejectBusiness handles business rejection by cooperative admin (FR-027)
// @Summary Reject business registration
// @Tags businesses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param rejection body entities.BusinessRejectionRequest true "Rejection data"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/admin/businesses/reject [post]
func (c *BusinessController) RejectBusiness(ctx *gin.Context) {
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

	// FR-027: Only admin can reject businesses
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to reject businesses", nil)
		return
	}

	var req entities.BusinessRejectionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	err := c.businessService.RejectBusinessRegistration(ctx.Request.Context(), &req, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to reject business", err)
		return
	}

	response := map[string]interface{}{
		"business_id": req.BusinessID,
		"status":      "rejected",
		"reason":      req.Reason,
		"feedback":    req.Feedback,
		"rejected_by": userID,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Business rejected successfully", response)
}

// RecordPerformanceMetrics handles recording business performance metrics (FR-030)
// @Summary Record business performance metrics
// @Tags businesses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Business ID"
// @Param metrics body entities.CreatePerformanceMetricsRequest true "Performance metrics data"
// @Success 201 {object} entities.BusinessPerformanceMetrics
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/businesses/{id}/metrics [post]
func (c *BusinessController) RecordPerformanceMetrics(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	idParam := ctx.Param("id")
	businessID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid business ID", err)
		return
	}

	var req entities.CreatePerformanceMetricsRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	metrics, err := c.businessService.RecordPerformanceMetrics(ctx.Request.Context(), businessID, &req, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to record performance metrics", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusCreated, "Performance metrics recorded successfully", metrics)
}

// GenerateFinancialReport handles generating financial reports for investors (FR-031)
// @Summary Generate financial report
// @Tags businesses
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Business ID"
// @Param report body entities.CreateFinancialReportRequest true "Financial report data"
// @Success 201 {object} entities.BusinessFinancialReport
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/businesses/{id}/reports [post]
func (c *BusinessController) GenerateFinancialReport(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	idParam := ctx.Param("id")
	businessID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid business ID", err)
		return
	}

	var req entities.CreateFinancialReportRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	report, err := c.businessService.GenerateFinancialReport(ctx.Request.Context(), businessID, &req, userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to generate financial report", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusCreated, "Financial report generated successfully", report)
}

// GetBusinessAnalytics handles getting business analytics (FR-030)
// @Summary Get business analytics
// @Tags businesses
// @Produce json
// @Security BearerAuth
// @Param id path string true "Business ID"
// @Param timeframe query string false "Analytics timeframe" default("monthly")
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Router /api/v1/businesses/{id}/analytics [get]
func (c *BusinessController) GetBusinessAnalytics(ctx *gin.Context) {
	idParam := ctx.Param("id")
	businessID, err := uuid.Parse(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid business ID", err)
		return
	}

	timeframe := utils.GetStringQuery(ctx, "timeframe", "monthly")

	analytics, err := c.businessService.GetBusinessAnalytics(ctx.Request.Context(), businessID, timeframe)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get business analytics", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Business analytics retrieved successfully", analytics)
}

// GetPendingBusinessApprovals handles getting pending business approvals for admin (FR-027)
// @Summary Get pending business approvals
// @Tags businesses
// @Produce json
// @Security BearerAuth
// @Param cooperative_id query string true "Cooperative ID"
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/admin/businesses/pending [get]
func (c *BusinessController) GetPendingBusinessApprovals(ctx *gin.Context) {
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

	// Only admin can view pending approvals
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to view pending approvals", nil)
		return
	}

	cooperativeIDParam := ctx.Query("cooperative_id")
	cooperativeID, err := uuid.Parse(cooperativeIDParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid cooperative ID", err)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	businesses, total, err := c.businessService.GetPendingBusinessApprovals(ctx.Request.Context(), cooperativeID, page, limit)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get pending approvals", err)
		return
	}

	response := map[string]interface{}{
		"businesses":     businesses,
		"page":           page,
		"limit":          limit,
		"total":          total,
		"cooperative_id": cooperativeID,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Pending business approvals retrieved successfully", response)
}
