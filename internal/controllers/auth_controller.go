package controllers

import (
	"net/http"

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
// @Accept json
// @Produce json
// @Param user body entities.CreateUserRequest true "User registration data"
// @Success 201 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 409 {object} utils.ErrorResponseData
// @Router /api/v1/auth/register [post]
func (c *AuthController) RegisterUser(ctx *gin.Context) {
	var req entities.CreateUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

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
