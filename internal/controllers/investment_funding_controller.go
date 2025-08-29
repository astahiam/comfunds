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

// InvestmentFundingController handles investment and funding API endpoints
type InvestmentFundingController struct {
	investmentFundingService services.InvestmentFundingService
}

// NewInvestmentFundingController creates a new investment funding controller
func NewInvestmentFundingController(investmentFundingService services.InvestmentFundingService) *InvestmentFundingController {
	return &InvestmentFundingController{
		investmentFundingService: investmentFundingService,
	}
}

// CreateInvestment handles FR-041: Cooperative members can invest in approved projects
func (c *InvestmentFundingController) CreateInvestment(ctx *gin.Context) {
	var req entities.CreateInvestmentExtendedRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", nil)
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get investor ID from context (authenticated user)
	investorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	investorUUID, ok := investorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Create investment
	investment, err := c.investmentFundingService.CreateInvestment(ctx, &req, investorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create investment"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "Investment created successfully", "data": investment})
}

// ValidateInvestmentEligibility handles FR-042: Validate investor eligibility and funds availability
func (c *InvestmentFundingController) ValidateInvestmentEligibility(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid project ID", err)
		return
	}

	amountStr := ctx.Query("amount")
	amount, err := strconv.ParseFloat(amountStr, 64)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid amount", err)
		return
	}

	// Get investor ID from context
	investorID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	investorUUID, ok := investorID.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user ID format", nil)
		return
	}

	// Validate eligibility
	eligibility, err := c.investmentFundingService.ValidateInvestmentEligibility(ctx, investorUUID, projectID, amount)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to validate eligibility", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Eligibility check completed", eligibility)
}

// GetProjectInvestments handles FR-044: Multiple investors per project
func (c *InvestmentFundingController) GetProjectInvestments(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid project ID", err)
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	investments, total, err := c.investmentFundingService.GetProjectInvestments(ctx, projectID, page, limit)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get project investments", err)
		return
	}

	response := map[string]interface{}{
		"investments": investments,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Project investments retrieved successfully", response)
}

// GetProjectFundingProgress gets project funding progress
func (c *InvestmentFundingController) GetProjectFundingProgress(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid project ID", err)
		return
	}

	currentFunding, fundingGoal, investorCount, err := c.investmentFundingService.GetProjectFundingProgress(ctx, projectID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get funding progress", err)
		return
	}

	progress := map[string]interface{}{
		"current_funding":  currentFunding,
		"funding_goal":     fundingGoal,
		"funding_progress": (currentFunding / fundingGoal) * 100,
		"investor_count":   investorCount,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Funding progress retrieved successfully", progress)
}

// GetInvestment gets investment by ID
func (c *InvestmentFundingController) GetInvestment(ctx *gin.Context) {
	investmentIDStr := ctx.Param("id")
	investmentID, err := uuid.Parse(investmentIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid investment ID", err)
		return
	}

	investment, err := c.investmentFundingService.GetInvestment(ctx, investmentID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "Investment not found", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment retrieved successfully", investment)
}

// UpdateInvestment updates investment
func (c *InvestmentFundingController) UpdateInvestment(ctx *gin.Context) {
	investmentIDStr := ctx.Param("id")
	investmentID, err := uuid.Parse(investmentIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid investment ID", err)
		return
	}

	var req entities.UpdateInvestmentRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Get updater ID from context
	updaterID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	updaterUUID, ok := updaterID.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user ID format", nil)
		return
	}

	investment, err := c.investmentFundingService.UpdateInvestment(ctx, investmentID, &req, updaterUUID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to update investment", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment updated successfully", investment)
}

// ApproveInvestment approves an investment (admin/cooperative admin)
func (c *InvestmentFundingController) ApproveInvestment(ctx *gin.Context) {
	var req entities.InvestmentApprovalRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Get approver ID from context
	approverID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	approverUUID, ok := approverID.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user ID format", nil)
		return
	}

	err := c.investmentFundingService.ApproveInvestment(ctx, &req, approverUUID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to approve investment", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment approved successfully", nil)
}

// RejectInvestment rejects an investment (admin/cooperative admin)
func (c *InvestmentFundingController) RejectInvestment(ctx *gin.Context) {
	var req entities.InvestmentApprovalRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Get rejecter ID from context
	rejecterID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	rejecterUUID, ok := rejecterID.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user ID format", nil)
		return
	}

	err := c.investmentFundingService.RejectInvestment(ctx, &req, rejecterUUID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to reject investment", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment rejected successfully", nil)
}

// CancelInvestment cancels an investment (investor or admin)
func (c *InvestmentFundingController) CancelInvestment(ctx *gin.Context) {
	investmentIDStr := ctx.Param("id")
	investmentID, err := uuid.Parse(investmentIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid investment ID", err)
		return
	}

	var req struct {
		Reason string `json:"reason" validate:"required"`
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	// Get canceller ID from context
	cancellerID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	cancellerUUID, ok := cancellerID.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user ID format", nil)
		return
	}

	err = c.investmentFundingService.CancelInvestment(ctx, investmentID, cancellerUUID, req.Reason)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to cancel investment", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment cancelled successfully", nil)
}

// GetInvestorInvestments gets investor's investments
func (c *InvestmentFundingController) GetInvestorInvestments(ctx *gin.Context) {
	// Get investor ID from context
	investorID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	investorUUID, ok := investorID.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user ID format", nil)
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	investments, total, err := c.investmentFundingService.GetInvestorInvestments(ctx, investorUUID, page, limit)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get investor investments", err)
		return
	}

	response := map[string]interface{}{
		"investments": investments,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investor investments retrieved successfully", response)
}

// GetInvestorPortfolio gets investor's portfolio summary
func (c *InvestmentFundingController) GetInvestorPortfolio(ctx *gin.Context) {
	// Get investor ID from context
	investorID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	investorUUID, ok := investorID.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user ID format", nil)
		return
	}

	portfolio, err := c.investmentFundingService.GetInvestorPortfolio(ctx, investorUUID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get investor portfolio", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investor portfolio retrieved successfully", portfolio)
}

// GetInvestmentSummary gets investment summary for reporting (admin/cooperative admin)
func (c *InvestmentFundingController) GetInvestmentSummary(ctx *gin.Context) {
	cooperativeIDStr := ctx.Param("cooperative_id")
	cooperativeID, err := uuid.Parse(cooperativeIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid cooperative ID", err)
		return
	}

	startDateStr := ctx.Query("start_date")
	endDateStr := ctx.Query("end_date")

	var startDate, endDate time.Time
	if startDateStr != "" {
		startDate, err = time.Parse("2006-01-02", startDateStr)
		if err != nil {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid start date format", err)
			return
		}
	} else {
		startDate = time.Now().AddDate(0, -1, 0) // Default to last month
	}

	if endDateStr != "" {
		endDate, err = time.Parse("2006-01-02", endDateStr)
		if err != nil {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid end date format", err)
			return
		}
	} else {
		endDate = time.Now() // Default to now
	}

	summary, err := c.investmentFundingService.GetInvestmentSummary(ctx, cooperativeID, startDate, endDate)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get investment summary", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment summary retrieved successfully", summary)
}

// GetProjectInvestmentAnalytics gets project investment analytics
func (c *InvestmentFundingController) GetProjectInvestmentAnalytics(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid project ID", err)
		return
	}

	analytics, err := c.investmentFundingService.GetProjectInvestmentAnalytics(ctx, projectID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get project analytics", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Project analytics retrieved successfully", analytics)
}

// SetProjectInvestmentLimits sets project investment limits (FR-045)
func (c *InvestmentFundingController) SetProjectInvestmentLimits(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid project ID", err)
		return
	}

	var req struct {
		MinAmount float64 `json:"min_amount" validate:"required,min=0"`
		MaxAmount float64 `json:"max_amount" validate:"required,min=0"`
	}
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err)
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	err = c.investmentFundingService.SetProjectInvestmentLimits(ctx, projectID, req.MinAmount, req.MaxAmount)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to set investment limits", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment limits set successfully", nil)
}

// GetProjectInvestmentLimits gets project investment limits
func (c *InvestmentFundingController) GetProjectInvestmentLimits(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid project ID", err)
		return
	}

	minAmount, maxAmount, err := c.investmentFundingService.GetProjectInvestmentLimits(ctx, projectID)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to get investment limits", err)
		return
	}

	limits := map[string]interface{}{
		"min_amount": minAmount,
		"max_amount": maxAmount,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Investment limits retrieved successfully", limits)
}
