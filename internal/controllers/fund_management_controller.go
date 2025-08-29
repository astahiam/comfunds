package controllers

import (
	"net/http"
	"strconv"
	"time"

	"comfunds/internal/entities"
	"comfunds/internal/services"
	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// FundManagementController handles fund management API endpoints
type FundManagementController struct {
	fundManagementService services.FundManagementService
}

// NewFundManagementController creates a new fund management controller
func NewFundManagementController(fundManagementService services.FundManagementService) *FundManagementController {
	return &FundManagementController{
		fundManagementService: fundManagementService,
	}
}

// CreateFundDisbursement handles FR-046: Fund disbursement to business owners
func (c *FundManagementController) CreateFundDisbursement(ctx *gin.Context) {
	var req entities.CreateFundDisbursementRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get requester ID from context
	requesterID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	requesterUUID, ok := requesterID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Create fund disbursement
	disbursement, err := c.fundManagementService.CreateFundDisbursement(ctx, &req, requesterUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create fund disbursement"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "Fund disbursement created successfully", "data": disbursement})
}

// ApproveFundDisbursement approves a fund disbursement (admin/cooperative admin)
func (c *FundManagementController) ApproveFundDisbursement(ctx *gin.Context) {
	disbursementIDStr := ctx.Param("id")
	disbursementID, err := uuid.Parse(disbursementIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid disbursement ID"})
		return
	}

	var req struct {
		Comments string `json:"comments"`
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Get approver ID from context
	approverID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	approverUUID, ok := approverID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.fundManagementService.ApproveFundDisbursement(ctx, disbursementID, approverUUID, req.Comments)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to approve fund disbursement"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund disbursement approved successfully"})
}

// RejectFundDisbursement rejects a fund disbursement (admin/cooperative admin)
func (c *FundManagementController) RejectFundDisbursement(ctx *gin.Context) {
	disbursementIDStr := ctx.Param("id")
	disbursementID, err := uuid.Parse(disbursementIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid disbursement ID"})
		return
	}

	var req struct {
		Reason string `json:"reason" validate:"required"`
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get rejecter ID from context
	rejecterID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	rejecterUUID, ok := rejecterID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.fundManagementService.RejectFundDisbursement(ctx, disbursementID, rejecterUUID, req.Reason)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to reject fund disbursement"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund disbursement rejected successfully"})
}

// ProcessFundDisbursement processes the actual fund transfer
func (c *FundManagementController) ProcessFundDisbursement(ctx *gin.Context) {
	disbursementIDStr := ctx.Param("id")
	disbursementID, err := uuid.Parse(disbursementIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid disbursement ID"})
		return
	}

	// Get processor ID from context
	processorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	processorUUID, ok := processorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.fundManagementService.ProcessFundDisbursement(ctx, disbursementID, processorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to process fund disbursement"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund disbursement processed successfully"})
}

// GetFundDisbursement gets disbursement by ID
func (c *FundManagementController) GetFundDisbursement(ctx *gin.Context) {
	disbursementIDStr := ctx.Param("id")
	disbursementID, err := uuid.Parse(disbursementIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid disbursement ID"})
		return
	}

	disbursement, err := c.fundManagementService.GetFundDisbursement(ctx, disbursementID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Fund disbursement not found"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund disbursement retrieved successfully", "data": disbursement})
}

// GetProjectDisbursements gets project disbursements
func (c *FundManagementController) GetProjectDisbursements(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	disbursements, total, err := c.fundManagementService.GetProjectDisbursements(ctx, projectID, page, limit)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get project disbursements"})
		return
	}

	response := map[string]interface{}{
		"disbursements": disbursements,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project disbursements retrieved successfully", "data": response})
}

// CreateFundUsage handles FR-047: Track fund usage and business performance
func (c *FundManagementController) CreateFundUsage(ctx *gin.Context) {
	var req entities.CreateFundUsageRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get recorder ID from context
	recorderID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	recorderUUID, ok := recorderID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Create fund usage
	usage, err := c.fundManagementService.CreateFundUsage(ctx, &req, recorderUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create fund usage"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "Fund usage created successfully", "data": usage})
}

// VerifyFundUsage verifies fund usage (admin/cooperative admin)
func (c *FundManagementController) VerifyFundUsage(ctx *gin.Context) {
	usageIDStr := ctx.Param("id")
	usageID, err := uuid.Parse(usageIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid usage ID"})
		return
	}

	var req struct {
		Comments string `json:"comments"`
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Get verifier ID from context
	verifierID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	verifierUUID, ok := verifierID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.fundManagementService.VerifyFundUsage(ctx, usageID, verifierUUID, req.Comments)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to verify fund usage"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund usage verified successfully"})
}

// GetFundUsage gets fund usage by ID
func (c *FundManagementController) GetFundUsage(ctx *gin.Context) {
	usageIDStr := ctx.Param("id")
	usageID, err := uuid.Parse(usageIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid usage ID"})
		return
	}

	usage, err := c.fundManagementService.GetFundUsage(ctx, usageID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Fund usage not found"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund usage retrieved successfully", "data": usage})
}

// GetDisbursementUsage gets usage for a specific disbursement
func (c *FundManagementController) GetDisbursementUsage(ctx *gin.Context) {
	disbursementIDStr := ctx.Param("disbursement_id")
	disbursementID, err := uuid.Parse(disbursementIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid disbursement ID"})
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	usage, total, err := c.fundManagementService.GetDisbursementUsage(ctx, disbursementID, page, limit)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get disbursement usage"})
		return
	}

	response := map[string]interface{}{
		"usage": usage,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Disbursement usage retrieved successfully", "data": response})
}

// GetCooperativeFundBalance handles FR-048: Get cooperative fund balance
func (c *FundManagementController) GetCooperativeFundBalance(ctx *gin.Context) {
	cooperativeIDStr := ctx.Param("cooperative_id")
	cooperativeID, err := uuid.Parse(cooperativeIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid cooperative ID"})
		return
	}

	balance, err := c.fundManagementService.GetCooperativeFundBalance(ctx, cooperativeID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get cooperative fund balance"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Cooperative fund balance retrieved successfully", "data": map[string]interface{}{
		"cooperative_id": cooperativeID,
		"balance":        balance,
		"currency":       "IDR",
	}})
}

// GetProjectFundBalance gets project fund balance
func (c *FundManagementController) GetProjectFundBalance(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	balance, err := c.fundManagementService.GetProjectFundBalance(ctx, projectID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get project fund balance"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project fund balance retrieved successfully", "data": map[string]interface{}{
		"project_id": projectID,
		"balance":    balance,
		"currency":   "IDR",
	}})
}

// GetFundAuditTrail gets fund audit trail
func (c *FundManagementController) GetFundAuditTrail(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	startDateStr := ctx.Query("start_date")
	endDateStr := ctx.Query("end_date")

	var startDate, endDate time.Time
	if startDateStr != "" {
		startDate, err = time.Parse("2006-01-02", startDateStr)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid start date format"})
			return
		}
	} else {
		startDate = time.Now().AddDate(0, -1, 0) // Default to last month
	}

	if endDateStr != "" {
		endDate, err = time.Parse("2006-01-02", endDateStr)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid end date format"})
			return
		}
	} else {
		endDate = time.Now() // Default to now
	}

	auditTrail, err := c.fundManagementService.GetFundAuditTrail(ctx, projectID, startDate, endDate)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fund audit trail"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund audit trail retrieved successfully", "data": auditTrail})
}

// CreateFundRefund handles FR-049: Fund refunds if project fails
func (c *FundManagementController) CreateFundRefund(ctx *gin.Context) {
	var req entities.CreateFundRefundRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get initiator ID from context
	initiatorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	initiatorUUID, ok := initiatorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Create fund refund
	refund, err := c.fundManagementService.CreateFundRefund(ctx, &req, initiatorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create fund refund"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "Fund refund created successfully", "data": refund})
}

// ProcessFundRefund processes the refund
func (c *FundManagementController) ProcessFundRefund(ctx *gin.Context) {
	refundIDStr := ctx.Param("id")
	refundID, err := uuid.Parse(refundIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid refund ID"})
		return
	}

	// Get processor ID from context
	processorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	processorUUID, ok := processorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.fundManagementService.ProcessFundRefund(ctx, refundID, processorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to process fund refund"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund refund processing started successfully"})
}

// CompleteFundRefund completes the refund process
func (c *FundManagementController) CompleteFundRefund(ctx *gin.Context) {
	refundIDStr := ctx.Param("id")
	refundID, err := uuid.Parse(refundIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid refund ID"})
		return
	}

	// Get completer ID from context
	completerID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	completerUUID, ok := completerID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.fundManagementService.CompleteFundRefund(ctx, refundID, completerUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to complete fund refund"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund refund completed successfully"})
}

// GetFundRefund gets refund by ID
func (c *FundManagementController) GetFundRefund(ctx *gin.Context) {
	refundIDStr := ctx.Param("id")
	refundID, err := uuid.Parse(refundIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid refund ID"})
		return
	}

	refund, err := c.fundManagementService.GetFundRefund(ctx, refundID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Fund refund not found"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund refund retrieved successfully", "data": refund})
}

// GetProjectRefunds gets project refunds
func (c *FundManagementController) GetProjectRefunds(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	refunds, total, err := c.fundManagementService.GetProjectRefunds(ctx, projectID, page, limit)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get project refunds"})
		return
	}

	response := map[string]interface{}{
		"refunds": refunds,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project refunds retrieved successfully", "data": response})
}

// GetFundManagementSummary gets fund management summary
func (c *FundManagementController) GetFundManagementSummary(ctx *gin.Context) {
	cooperativeIDStr := ctx.Param("cooperative_id")
	cooperativeID, err := uuid.Parse(cooperativeIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid cooperative ID"})
		return
	}

	startDateStr := ctx.Query("start_date")
	endDateStr := ctx.Query("end_date")

	var startDate, endDate time.Time
	if startDateStr != "" {
		startDate, err = time.Parse("2006-01-02", startDateStr)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid start date format"})
			return
		}
	} else {
		startDate = time.Now().AddDate(0, -1, 0) // Default to last month
	}

	if endDateStr != "" {
		endDate, err = time.Parse("2006-01-02", endDateStr)
		if err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid end date format"})
			return
		}
	} else {
		endDate = time.Now() // Default to now
	}

	summary, err := c.fundManagementService.GetFundManagementSummary(ctx, cooperativeID, startDate, endDate)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get fund management summary"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Fund management summary retrieved successfully", "data": summary})
}

// GetProjectFundAnalytics gets project fund analytics
func (c *FundManagementController) GetProjectFundAnalytics(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	analytics, err := c.fundManagementService.GetProjectFundAnalytics(ctx, projectID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get project fund analytics"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project fund analytics retrieved successfully", "data": analytics})
}
