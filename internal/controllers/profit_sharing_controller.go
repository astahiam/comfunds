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

// ProfitSharingController handles profit sharing API endpoints
type ProfitSharingController struct {
	profitSharingService services.ProfitSharingService
}

// NewProfitSharingController creates a new profit sharing controller
func NewProfitSharingController(profitSharingService services.ProfitSharingService) *ProfitSharingController {
	return &ProfitSharingController{
		profitSharingService: profitSharingService,
	}
}

// CreateProfitCalculation handles FR-050 to FR-053: Sharia-compliant profit calculation
func (c *ProfitSharingController) CreateProfitCalculation(ctx *gin.Context) {
	var req entities.CreateProfitCalculationRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get creator ID from context
	creatorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	creatorUUID, ok := creatorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Create profit calculation
	calculation, err := c.profitSharingService.CreateProfitCalculation(ctx, &req, creatorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create profit calculation"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "Profit calculation created successfully", "data": calculation})
}

// VerifyProfitCalculation handles FR-053: Cooperative verification
func (c *ProfitSharingController) VerifyProfitCalculation(ctx *gin.Context) {
	var req entities.VerifyProfitCalculationRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
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

	err := c.profitSharingService.VerifyProfitCalculation(ctx, &req, verifierUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to verify profit calculation"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Profit calculation verified successfully"})
}

// GetProfitCalculation gets profit calculation by ID
func (c *ProfitSharingController) GetProfitCalculation(ctx *gin.Context) {
	calculationIDStr := ctx.Param("id")
	calculationID, err := uuid.Parse(calculationIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid calculation ID"})
		return
	}

	calculation, err := c.profitSharingService.GetProfitCalculation(ctx, calculationID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Profit calculation not found"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Profit calculation retrieved successfully", "data": calculation})
}

// GetProjectProfitCalculations gets project profit calculations
func (c *ProfitSharingController) GetProjectProfitCalculations(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	calculations, total, err := c.profitSharingService.GetProjectProfitCalculations(ctx, projectID, page, limit)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get project profit calculations"})
		return
	}

	response := map[string]interface{}{
		"calculations": calculations,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project profit calculations retrieved successfully", "data": response})
}

// CreateProfitDistribution handles FR-054 to FR-056: Profit distribution
func (c *ProfitSharingController) CreateProfitDistribution(ctx *gin.Context) {
	var req entities.CreateProfitDistributionExtendedRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get creator ID from context
	creatorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	creatorUUID, ok := creatorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Create profit distribution
	distribution, err := c.profitSharingService.CreateProfitDistribution(ctx, &req, creatorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create profit distribution"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "Profit distribution created successfully", "data": distribution})
}

// ProcessProfitDistribution processes the profit distribution
func (c *ProfitSharingController) ProcessProfitDistribution(ctx *gin.Context) {
	var req entities.ProcessProfitDistributionRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
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

	err := c.profitSharingService.ProcessProfitDistribution(ctx, &req, processorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to process profit distribution"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Profit distribution processing started successfully"})
}

// GetProfitDistribution gets profit distribution by ID
func (c *ProfitSharingController) GetProfitDistribution(ctx *gin.Context) {
	distributionIDStr := ctx.Param("id")
	distributionID, err := uuid.Parse(distributionIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid distribution ID"})
		return
	}

	distribution, err := c.profitSharingService.GetProfitDistribution(ctx, distributionID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Profit distribution not found"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Profit distribution retrieved successfully", "data": distribution})
}

// GetProjectProfitDistributions gets project profit distributions
func (c *ProfitSharingController) GetProjectProfitDistributions(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	distributions, total, err := c.profitSharingService.GetProjectProfitDistributions(ctx, projectID, page, limit)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get project profit distributions"})
		return
	}

	response := map[string]interface{}{
		"distributions": distributions,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project profit distributions retrieved successfully", "data": response})
}

// CreateTaxDocumentation handles FR-057: Tax-compliant documentation
func (c *ProfitSharingController) CreateTaxDocumentation(ctx *gin.Context) {
	var req entities.CreateTaxDocumentationRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get creator ID from context
	creatorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	creatorUUID, ok := creatorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Create tax documentation
	taxDoc, err := c.profitSharingService.CreateTaxDocumentation(ctx, &req, creatorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create tax documentation"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "Tax documentation created successfully", "data": taxDoc})
}

// GetTaxDocumentation gets tax documentation by ID
func (c *ProfitSharingController) GetTaxDocumentation(ctx *gin.Context) {
	documentIDStr := ctx.Param("id")
	documentID, err := uuid.Parse(documentIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid document ID"})
		return
	}

	taxDoc, err := c.profitSharingService.GetTaxDocumentation(ctx, documentID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Tax documentation not found"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Tax documentation retrieved successfully", "data": taxDoc})
}

// GetDistributionTaxDocuments gets tax documents for a distribution
func (c *ProfitSharingController) GetDistributionTaxDocuments(ctx *gin.Context) {
	distributionIDStr := ctx.Param("distribution_id")
	distributionID, err := uuid.Parse(distributionIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid distribution ID"})
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	documents, total, err := c.profitSharingService.GetDistributionTaxDocuments(ctx, distributionID, page, limit)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get distribution tax documents"})
		return
	}

	response := map[string]interface{}{
		"documents": documents,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Distribution tax documents retrieved successfully", "data": response})
}

// CreateComFundsFee creates a new ComFunds fee structure
func (c *ProfitSharingController) CreateComFundsFee(ctx *gin.Context) {
	var req entities.CreateComFundsFeeRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get creator ID from context
	creatorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	creatorUUID, ok := creatorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Create ComFunds fee
	fee, err := c.profitSharingService.CreateComFundsFee(ctx, &req, creatorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to create ComFunds fee"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "ComFunds fee created successfully", "data": fee})
}

// UpdateComFundsFee updates an existing ComFunds fee structure
func (c *ProfitSharingController) UpdateComFundsFee(ctx *gin.Context) {
	feeIDStr := ctx.Param("id")
	feeID, err := uuid.Parse(feeIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid fee ID"})
		return
	}

	var req entities.CreateComFundsFeeRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get updater ID from context
	updaterID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	updaterUUID, ok := updaterID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Update ComFunds fee
	fee, err := c.profitSharingService.UpdateComFundsFee(ctx, feeID, &req, updaterUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to update ComFunds fee"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ComFunds fee updated successfully", "data": fee})
}

// EnableComFundsFee enables a ComFunds fee structure
func (c *ProfitSharingController) EnableComFundsFee(ctx *gin.Context) {
	feeIDStr := ctx.Param("id")
	feeID, err := uuid.Parse(feeIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid fee ID"})
		return
	}

	// Get enabler ID from context
	enablerID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	enablerUUID, ok := enablerID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.profitSharingService.EnableComFundsFee(ctx, feeID, enablerUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to enable ComFunds fee"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ComFunds fee enabled successfully"})
}

// DisableComFundsFee disables a ComFunds fee structure
func (c *ProfitSharingController) DisableComFundsFee(ctx *gin.Context) {
	feeIDStr := ctx.Param("id")
	feeID, err := uuid.Parse(feeIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid fee ID"})
		return
	}

	// Get disabler ID from context
	disablerID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	disablerUUID, ok := disablerID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.profitSharingService.DisableComFundsFee(ctx, feeID, disablerUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to disable ComFunds fee"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ComFunds fee disabled successfully"})
}

// GetComFundsFee gets ComFunds fee by ID
func (c *ProfitSharingController) GetComFundsFee(ctx *gin.Context) {
	feeIDStr := ctx.Param("id")
	feeID, err := uuid.Parse(feeIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid fee ID"})
		return
	}

	fee, err := c.profitSharingService.GetComFundsFee(ctx, feeID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "ComFunds fee not found"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ComFunds fee retrieved successfully", "data": fee})
}

// GetActiveComFundsFees gets active ComFunds fees
func (c *ProfitSharingController) GetActiveComFundsFees(ctx *gin.Context) {
	feeType := ctx.Query("fee_type")

	fees, err := c.profitSharingService.GetActiveComFundsFees(ctx, feeType)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get active ComFunds fees"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Active ComFunds fees retrieved successfully", "data": fees})
}

// CalculateProjectFee calculates fee for a successfully funded project
func (c *ProfitSharingController) CalculateProjectFee(ctx *gin.Context) {
	var req entities.CalculateProjectFeeRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get calculator ID from context
	calculatorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	calculatorUUID, ok := calculatorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	// Calculate project fee
	calculation, err := c.profitSharingService.CalculateProjectFee(ctx, &req, calculatorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to calculate project fee"})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "Project fee calculated successfully", "data": calculation})
}

// CollectProjectFee collects the calculated project fee
func (c *ProfitSharingController) CollectProjectFee(ctx *gin.Context) {
	var req entities.CollectProjectFeeRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Validation failed"})
		return
	}

	// Get collector ID from context
	collectorID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	collectorUUID, ok := collectorID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err := c.profitSharingService.CollectProjectFee(ctx, &req, collectorUUID)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to collect project fee"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project fee collected successfully"})
}

// WaiveProjectFee waives a project fee
func (c *ProfitSharingController) WaiveProjectFee(ctx *gin.Context) {
	calculationIDStr := ctx.Param("id")
	calculationID, err := uuid.Parse(calculationIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid calculation ID"})
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

	// Get waiver ID from context
	waiverID, exists := ctx.Get("user_id")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	waiverUUID, ok := waiverID.(uuid.UUID)
	if !ok {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID format"})
		return
	}

	err = c.profitSharingService.WaiveProjectFee(ctx, calculationID, waiverUUID, req.Reason)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Failed to waive project fee"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project fee waived successfully"})
}

// GetProjectFeeCalculation gets project fee calculation by ID
func (c *ProfitSharingController) GetProjectFeeCalculation(ctx *gin.Context) {
	calculationIDStr := ctx.Param("id")
	calculationID, err := uuid.Parse(calculationIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid calculation ID"})
		return
	}

	calculation, err := c.profitSharingService.GetProjectFeeCalculation(ctx, calculationID)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Project fee calculation not found"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project fee calculation retrieved successfully", "data": calculation})
}

// GetProjectFeeCalculations gets project fee calculations
func (c *ProfitSharingController) GetProjectFeeCalculations(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "20"))

	calculations, total, err := c.profitSharingService.GetProjectFeeCalculations(ctx, projectID, page, limit)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get project fee calculations"})
		return
	}

	response := map[string]interface{}{
		"calculations": calculations,
		"pagination": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project fee calculations retrieved successfully", "data": response})
}

// GetProfitSharingSummary gets profit sharing summary
func (c *ProfitSharingController) GetProfitSharingSummary(ctx *gin.Context) {
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

	summary, err := c.profitSharingService.GetProfitSharingSummary(ctx, cooperativeID, startDate, endDate)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get profit sharing summary"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Profit sharing summary retrieved successfully", "data": summary})
}

// GetProjectProfitAnalytics gets project profit analytics
func (c *ProfitSharingController) GetProjectProfitAnalytics(ctx *gin.Context) {
	projectIDStr := ctx.Param("project_id")
	projectID, err := uuid.Parse(projectIDStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid project ID"})
		return
	}

	analytics, err := c.profitSharingService.GetProjectProfitAnalytics(ctx, projectID)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get project profit analytics"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Project profit analytics retrieved successfully", "data": analytics})
}

// GetComFundsFeeAnalytics gets ComFunds fee analytics
func (c *ProfitSharingController) GetComFundsFeeAnalytics(ctx *gin.Context) {
	startDateStr := ctx.Query("start_date")
	endDateStr := ctx.Query("end_date")

	var startDate, endDate time.Time
	var err error
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

	analytics, err := c.profitSharingService.GetComFundsFeeAnalytics(ctx, startDate, endDate)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get ComFunds fee analytics"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "ComFunds fee analytics retrieved successfully", "data": analytics})
}
