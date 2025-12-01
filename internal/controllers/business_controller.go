package controllers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

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
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param name formData string true "Business name"
// @Param type formData string true "Business type"
// @Param description formData string true "Business description"
// @Param cooperative_id formData string true "Cooperative ID"
// @Param business_image formData file false "Business image"
// @Success 201 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 403 {object} utils.ErrorResponseData
// @Router /api/v1/businesses [post]
func (c *BusinessController) CreateBusiness(ctx *gin.Context) {
	fmt.Printf("DEBUG: CreateBusiness controller called\n")
	fmt.Printf("DEBUG: Request URL: %s\n", ctx.Request.URL.String())
	fmt.Printf("DEBUG: Request Method: %s\n", ctx.Request.Method)
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

	// Parse multipart form with larger size limit (10MB for file uploads)
	if err := ctx.Request.ParseMultipartForm(10 << 20); err != nil { // 10MB max
		utils.ErrorResponse(ctx, http.StatusBadRequest, fmt.Sprintf("Failed to parse form data: %v", err), err)
		return
	}

	var req entities.CreateBusinessExtendedRequest
	var businessImageURL *string

	// Get form values
	req.Name = ctx.PostForm("name")
	req.Type = ctx.PostForm("type")
	req.Description = ctx.PostForm("description")

	// Parse cooperative_id
	if coopIDStr := ctx.PostForm("cooperative_id"); coopIDStr != "" {
		coopID, err := uuid.Parse(coopIDStr)
		if err == nil {
			req.CooperativeID = coopID
		}
	}

	req.RegistrationNumber = ctx.PostForm("registration_number")
	req.TaxID = ctx.PostForm("tax_id")
	req.LegalStructure = ctx.PostForm("legal_structure")
	req.Industry = ctx.PostForm("industry")
	req.Sector = ctx.PostForm("sector")
	req.Address = ctx.PostForm("address")
	req.Phone = ctx.PostForm("phone")
	req.Email = ctx.PostForm("email")
	req.Website = ctx.PostForm("website")
	req.BankAccount = ctx.PostForm("bank_account")
	req.BusinessLicense = ctx.PostForm("business_license")

	// Parse employee_count
	if empCountStr := ctx.PostForm("employee_count"); empCountStr != "" {
		if empCount, err := strconv.Atoi(empCountStr); err == nil {
			req.EmployeeCount = empCount
		}
	}

	// Parse annual_revenue
	if revenueStr := ctx.PostForm("annual_revenue"); revenueStr != "" {
		if revenue, err := strconv.ParseFloat(revenueStr, 64); err == nil {
			req.AnnualRevenue = revenue
		}
	}

	req.Currency = ctx.PostForm("currency")
	if req.Currency == "" {
		req.Currency = "IDR" // Default to IDR
	}

	// Parse established_date
	if estDateStr := ctx.PostForm("established_date"); estDateStr != "" {
		if estDate, err := time.Parse("2006-01-02", estDateStr); err == nil {
			req.EstablishedDate = estDate
		}
	}

	// Handle business image file upload
	file, header, err := ctx.Request.FormFile("business_image")
	if err == nil {
		defer file.Close()

		// Validate file size (max 10MB)
		maxSize := int64(10 * 1024 * 1024) // 10MB
		if header.Size > maxSize {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "File size exceeds 10MB limit", nil)
			return
		}

		// Validate file type (JPG, PNG, JPEG)
		allowedExtensions := []string{".jpg", ".jpeg", ".png"}
		ext := strings.ToLower(filepath.Ext(header.Filename))
		isAllowedExt := false
		for _, allowedExt := range allowedExtensions {
			if ext == allowedExt {
				isAllowedExt = true
				break
			}
		}
		if !isAllowedExt {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid file type. Allowed: JPG, PNG", nil)
			return
		}

		// Create upload directory: uploads/images/business
		uploadDir := "uploads/images/business"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create upload directory", err)
			return
		}

		// Generate unique filename
		timestamp := time.Now().Format("20060102_150405")
		uniqueID := uuid.New().String()[:8]
		filename := fmt.Sprintf("business_%s_%s%s", timestamp, uniqueID, ext)
		filePath := filepath.Join(uploadDir, filename)

		// Create destination file
		dst, err := os.Create(filePath)
		if err != nil {
			utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create file", err)
			return
		}
		defer dst.Close()

		// Copy uploaded file to destination
		if _, err := io.Copy(dst, file); err != nil {
			utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to save file", err)
			return
		}

		// Generate file URL (relative path for storage in database)
		fileURL := fmt.Sprintf("/uploads/images/business/%s", filename)
		businessImageURL = &fileURL
		req.BusinessImage = businessImageURL
	}

	// Debug: Print all form values before validation
	fmt.Printf("DEBUG: Form values received:\n")
	fmt.Printf("  Name: %s\n", req.Name)
	fmt.Printf("  Type: %s\n", req.Type)
	fmt.Printf("  Description: %s (len: %d)\n", req.Description, len(req.Description))
	fmt.Printf("  CooperativeID: %s\n", req.CooperativeID.String())
	fmt.Printf("  RegistrationNumber: %s\n", req.RegistrationNumber)
	fmt.Printf("  LegalStructure: %s\n", req.LegalStructure)
	fmt.Printf("  Industry: %s\n", req.Industry)
	fmt.Printf("  Address: %s\n", req.Address)
	fmt.Printf("  Phone: %s\n", req.Phone)
	fmt.Printf("  Email: %s\n", req.Email)
	fmt.Printf("  EstablishedDate: %v (zero: %v)\n", req.EstablishedDate, req.EstablishedDate.IsZero())
	fmt.Printf("  Currency: %s\n", req.Currency)
	fmt.Printf("  BankAccount: %s\n", req.BankAccount)
	
	if err := utils.ValidateStruct(&req); err != nil {
		fmt.Printf("DEBUG: Validation failed: %v\n", err)
		utils.ErrorResponse(ctx, http.StatusBadRequest, err.Error(), err)
		return
	}

	fmt.Printf("DEBUG: Calling businessService.CreateBusiness for user %s\n", userID.(uuid.UUID).String())
	fmt.Printf("DEBUG: Request data - Name: %s, Type: %s, CooperativeID: %s, EstablishedDate: %v\n", 
		req.Name, req.Type, req.CooperativeID.String(), req.EstablishedDate)
	business, err := c.businessService.CreateBusiness(ctx.Request.Context(), &req, userID.(uuid.UUID))
	if err != nil {
		fmt.Printf("DEBUG: BusinessService.CreateBusiness error: %v\n", err)
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Failed to create business: "+err.Error(), err)
		return
	}

	fmt.Printf("DEBUG: Business created successfully: %s\n", business.Name)

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
	fmt.Printf("DEBUG: GetOwnerBusinesses controller called\n")
	fmt.Printf("DEBUG: Request URL: %s\n", ctx.Request.URL.String())
	fmt.Printf("DEBUG: Request Method: %s\n", ctx.Request.Method)
	userID, exists := ctx.Get("user_id")
	if !exists {
		fmt.Printf("DEBUG: User not authenticated\n")
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	fmt.Printf("DEBUG: Calling businessService.GetOwnerBusinesses for user %s\n", userID.(uuid.UUID).String())
	fmt.Printf("DEBUG: businessService is nil: %t\n", c.businessService == nil)
	businesses, total, err := c.businessService.GetOwnerBusinesses(ctx.Request.Context(), userID.(uuid.UUID), page, limit)
	fmt.Printf("DEBUG: GetOwnerBusinesses returned %d businesses, total: %d, error: %v\n", len(businesses), total, err)
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
// @Accept multipart/form-data
// @Produce json
// @Security BearerAuth
// @Param id path string true "Business ID"
// @Param business_image formData file false "Business image"
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

	// Parse multipart form with larger size limit (10MB for file uploads)
	if err := ctx.Request.ParseMultipartForm(10 << 20); err != nil {
		// If it's not multipart, try JSON (backward compatibility)
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
		return
	}

	// Handle multipart form data
	var req entities.UpdateBusinessExtendedRequest

	// Get form values
	if name := ctx.PostForm("name"); name != "" {
		req.Name = name
	}
	if businessType := ctx.PostForm("type"); businessType != "" {
		req.Type = businessType
	}
	if desc := ctx.PostForm("description"); desc != "" {
		req.Description = desc
	}
	req.Industry = ctx.PostForm("industry")
	req.Sector = ctx.PostForm("sector")
	req.Address = ctx.PostForm("address")
	req.Phone = ctx.PostForm("phone")
	req.Email = ctx.PostForm("email")
	req.Website = ctx.PostForm("website")
	req.BankAccount = ctx.PostForm("bank_account")
	req.BusinessLicense = ctx.PostForm("business_license")

	// Parse employee_count
	if empCountStr := ctx.PostForm("employee_count"); empCountStr != "" {
		if empCount, err := strconv.Atoi(empCountStr); err == nil {
			req.EmployeeCount = empCount
		}
	}

	// Parse annual_revenue
	if revenueStr := ctx.PostForm("annual_revenue"); revenueStr != "" {
		if revenue, err := strconv.ParseFloat(revenueStr, 64); err == nil {
			req.AnnualRevenue = revenue
		}
	}

	// Handle business image file upload
	file, header, err := ctx.Request.FormFile("business_image")
	if err == nil {
		defer file.Close()

		// Validate file size (max 10MB)
		maxSize := int64(10 * 1024 * 1024) // 10MB
		if header.Size > maxSize {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "File size exceeds 10MB limit", nil)
			return
		}

		// Validate file type (JPG, PNG, JPEG)
		allowedExtensions := []string{".jpg", ".jpeg", ".png"}
		ext := strings.ToLower(filepath.Ext(header.Filename))
		isAllowedExt := false
		for _, allowedExt := range allowedExtensions {
			if ext == allowedExt {
				isAllowedExt = true
				break
			}
		}
		if !isAllowedExt {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid file type. Allowed: JPG, PNG", nil)
			return
		}

		// Create upload directory: uploads/images/business
		uploadDir := "uploads/images/business"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create upload directory", err)
			return
		}

		// Generate unique filename
		timestamp := time.Now().Format("20060102_150405")
		uniqueID := uuid.New().String()[:8]
		filename := fmt.Sprintf("business_%s_%s%s", timestamp, uniqueID, ext)
		filePath := filepath.Join(uploadDir, filename)

		// Create destination file
		dst, err := os.Create(filePath)
		if err != nil {
			utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create file", err)
			return
		}
		defer dst.Close()

		// Copy uploaded file to destination
		if _, err := io.Copy(dst, file); err != nil {
			utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to save file", err)
			return
		}

		// Generate file URL (relative path for storage in database)
		fileURL := fmt.Sprintf("/uploads/images/business/%s", filename)
		req.BusinessImage = &fileURL
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
	fmt.Printf("DEBUG: GetPendingBusinessApprovals controller called\n")
	userRoles, exists := ctx.Get("user_roles")
	if !exists {
		fmt.Printf("DEBUG: User roles not found\n")
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User roles not found", nil)
		return
	}

	userRolesList, ok := userRoles.([]string)
	if !ok {
		fmt.Printf("DEBUG: Invalid user roles format\n")
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Invalid user roles format", nil)
		return
	}

	// Only admin can view pending approvals
	if !c.roleValidator.CanUserApproveProjects(userRolesList) {
		fmt.Printf("DEBUG: Admin role required\n")
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required to view pending approvals", nil)
		return
	}

	cooperativeIDParam := ctx.Query("cooperative_id")
	var cooperativeID *uuid.UUID
	if cooperativeIDParam != "" && cooperativeIDParam != "null" {
		parsedID, err := uuid.Parse(cooperativeIDParam)
		if err != nil {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid cooperative ID", err)
			return
		}
		cooperativeID = &parsedID
	}

	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 10)

	fmt.Printf("DEBUG: Calling businessService.GetPendingBusinessApprovals\n")
	fmt.Printf("DEBUG: businessService is nil: %t\n", c.businessService == nil)
	businesses, total, err := c.businessService.GetPendingBusinessApprovals(ctx.Request.Context(), cooperativeID, page, limit)
	fmt.Printf("DEBUG: GetPendingBusinessApprovals returned %d businesses, total: %d, error: %v\n", len(businesses), total, err)
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

// GetAllBusinesses (Admin) lists all businesses regardless of approval status
func (c *BusinessController) GetAllBusinesses(ctx *gin.Context) {
	fmt.Printf("DEBUG: GetAllBusinesses called\n")
	userRoles, exists := ctx.Get("user_roles")
	if !exists {
		fmt.Printf("DEBUG: User roles not found\n")
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User roles not found", nil)
		return
	}
	userRolesList, ok := userRoles.([]string)
	if !ok || !c.roleValidator.CanUserApproveProjects(userRolesList) {
		fmt.Printf("DEBUG: Admin role required\n")
		utils.ErrorResponse(ctx, http.StatusForbidden, "Admin role required", nil)
		return
	}
	page := utils.GetIntQuery(ctx, "page", 1)
	limit := utils.GetIntQuery(ctx, "limit", 50)
	fmt.Printf("DEBUG: Calling ListAllBusinesses with page=%d, limit=%d\n", page, limit)
	businesses, total, err := c.businessService.ListAllBusinesses(ctx.Request.Context(), page, limit)
	if err != nil {
		fmt.Printf("DEBUG: Error calling ListAllBusinesses: %v\n", err)
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to list businesses", err)
		return
	}
	fmt.Printf("DEBUG: Found %d businesses, total=%d\n", len(businesses), total)
	utils.SuccessResponse(ctx, http.StatusOK, "Businesses retrieved successfully", map[string]interface{}{
		"businesses": businesses,
		"page":       page,
		"limit":      limit,
		"total":      total,
	})
}
