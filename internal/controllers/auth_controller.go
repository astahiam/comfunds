package controllers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"comfunds/internal/entities"
	"comfunds/internal/services"
	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AuthController struct {
	userService services.UserServiceAuth
}

func NewAuthController(userService services.UserServiceAuth) *AuthController {
	return &AuthController{
		userService: userService,
	}
}

// RegisterUser handles user registration
// @Summary Register a new user
// @Tags authentication
// @Accept multipart/form-data
// @Produce json
// @Param name formData string true "User name"
// @Param email formData string true "User email"
// @Param password formData string true "User password"
// @Param phone formData string true "User phone"
// @Param address formData string true "User address"
// @Param cooperative_id formData string false "Cooperative ID"
// @Param roles formData []string true "User roles"
// @Param payment_proof formData file false "Membership payment proof document"
// @Success 201 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 409 {object} utils.ErrorResponseData
// @Router /api/v1/auth/register [post]
func (c *AuthController) RegisterUser(ctx *gin.Context) {
	var req entities.CreateUserRequest
	var paymentProofURL *string

	// Parse multipart form with larger size limit
	// Note: This will work even if Content-Type is not explicitly set
	if err := ctx.Request.ParseMultipartForm(10 << 20); err != nil { // 10MB max
		utils.ErrorResponse(ctx, http.StatusBadRequest, fmt.Sprintf("Failed to parse form data: %v. Make sure Content-Type is multipart/form-data", err), err)
		return
	}

	// Get form values
	req.Name = ctx.PostForm("name")
	req.Email = ctx.PostForm("email")
	req.Password = ctx.PostForm("password")
	req.Phone = ctx.PostForm("phone")
	req.Address = ctx.PostForm("address")

	// Validate required fields before proceeding
	if req.Name == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Name is required", nil)
		return
	}
	if req.Email == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Email is required", nil)
		return
	}
	if req.Password == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Password is required", nil)
		return
	}
	if req.Phone == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Phone is required", nil)
		return
	}
	if req.Address == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Address is required", nil)
		return
	}

	// Handle cooperative_id
	if coopIDStr := ctx.PostForm("cooperative_id"); coopIDStr != "" {
		coopID, err := uuid.Parse(coopIDStr)
		if err == nil {
			req.CooperativeID = &coopID
		}
	}

	// Handle roles (from form array)
	req.Roles = ctx.PostFormArray("roles")
	if len(req.Roles) == 0 {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "At least one role is required", nil)
		return
	}

	// Handle file upload for payment proof (OPTIONAL)
	file, header, err := ctx.Request.FormFile("payment_proof")
	if err == nil && header != nil && header.Size > 0 {
		defer file.Close()

		// Validate file size (max 10MB)
		maxSize := int64(10 * 1024 * 1024) // 10MB
		if header.Size > maxSize {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "File size exceeds 10MB limit", nil)
			return
		}

		// Validate file type (PDF, JPG, PNG)
		allowedExtensions := []string{".pdf", ".jpg", ".jpeg", ".png"}
		ext := strings.ToLower(filepath.Ext(header.Filename))
		isAllowedExt := false
		for _, allowedExt := range allowedExtensions {
			if ext == allowedExt {
				isAllowedExt = true
				break
			}
		}
		if !isAllowedExt {
			utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid file type. Allowed: PDF, JPG, PNG", nil)
			return
		}

		// Create upload directory: uploads/documents/register
		uploadDir := "uploads/documents/register"
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create upload directory", err)
			return
		}

		// Generate unique filename
		timestamp := time.Now().Format("20060102_150405")
		uniqueID := uuid.New().String()[:8]
		filename := fmt.Sprintf("payment_proof_%s_%s%s", timestamp, uniqueID, ext)
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
		fileURL := fmt.Sprintf("/uploads/documents/register/%s", filename)
		paymentProofURL = &fileURL
		req.MembershipPaymentProof = paymentProofURL
	}
	// If payment_proof is not provided, req.MembershipPaymentProof remains nil (optional)

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	user, accessToken, refreshToken, err := c.userService.Register(ctx.Request.Context(), &req)
	if err != nil {
		if err.Error() == "user with email "+req.Email+" already exists" {
			utils.ErrorResponse(ctx, http.StatusConflict, "User already exists", err)
			return
		}
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Registration failed", err)
		return
	}

	response := map[string]interface{}{
		"user":          user,
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
	}

	utils.SuccessResponse(ctx, http.StatusCreated, "User registered successfully", response)
}

// LoginUser handles user login
// @Summary User login
// @Tags authentication
// @Accept json
// @Produce json
// @Param credentials body map[string]string true "Login credentials"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Router /api/v1/auth/login [post]
func (c *AuthController) LoginUser(ctx *gin.Context) {
	var req struct {
		Email    string `json:"email" validate:"required,email"`
		Password string `json:"password" validate:"required"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	user, accessToken, refreshToken, err := c.userService.Login(ctx.Request.Context(), req.Email, req.Password)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "Login failed", err)
		return
	}

	response := map[string]interface{}{
		"user":          user,
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"token_type":    "Bearer",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Login successful", response)
}

// RefreshToken handles token refresh
// @Summary Refresh access token
// @Tags authentication
// @Accept json
// @Produce json
// @Param refresh body map[string]string true "Refresh token"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Router /api/v1/auth/refresh [post]
func (c *AuthController) RefreshToken(ctx *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" validate:"required"`
	}

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	accessToken, err := c.userService.RefreshToken(ctx.Request.Context(), req.RefreshToken)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "Token refresh failed", err)
		return
	}

	response := map[string]interface{}{
		"access_token": accessToken,
		"token_type":   "Bearer",
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Token refreshed successfully", response)
}

// GetProfile handles getting user profile
// @Summary Get user profile
// @Tags authentication
// @Produce json
// @Security BearerAuth
// @Success 200 {object} entities.User
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/auth/profile [get]
func (c *AuthController) GetProfile(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	user, err := c.userService.GetUserByID(ctx.Request.Context(), userID.(uuid.UUID))
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Profile retrieved successfully", user)
}

// UpdateProfile handles updating user profile
// @Summary Update user profile
// @Tags authentication
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param user body entities.UpdateUserRequest true "Profile update data"
// @Success 200 {object} entities.User
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 401 {object} utils.ErrorResponseData
// @Failure 404 {object} utils.ErrorResponseData
// @Router /api/v1/auth/profile [put]
func (c *AuthController) UpdateProfile(ctx *gin.Context) {
	userID, exists := ctx.Get("user_id")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
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

	user, err := c.userService.UpdateUser(ctx.Request.Context(), userID.(uuid.UUID), &req)
	if err != nil {
		if err.Error() == "user not found" {
			utils.ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
			return
		}
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Profile update failed", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Profile updated successfully", user)
}
