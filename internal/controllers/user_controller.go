package controllers

import (
	"net/http"
	"strconv"

	"comfunds/internal/entities"
	"comfunds/internal/services"
	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
)

type UserController struct {
	userService services.UserService
}

func NewUserController(userService services.UserService) *UserController {
	return &UserController{
		userService: userService,
	}
}

// CreateUser creates a new user
// @Summary Create a new user
// @Tags users
// @Accept json
// @Produce json
// @Param user body entities.CreateUserRequest true "User data"
// @Success 201 {object} entities.User
// @Failure 400 {object} utils.ErrorResponse
// @Failure 409 {object} utils.ErrorResponse
// @Router /api/v1/users [post]
func (c *UserController) CreateUser(ctx *gin.Context) {
	var req entities.CreateUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid request payload", err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err)
		return
	}

	user, err := c.userService.CreateUser(&req)
	if err != nil {
		if err.Error() == "user with email "+req.Email+" already exists" {
			utils.ErrorResponse(ctx, http.StatusConflict, "User already exists", err)
			return
		}
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create user", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusCreated, "User created successfully", user)
}

// GetUser retrieves a user by ID
// @Summary Get user by ID
// @Tags users
// @Produce json
// @Param id path int true "User ID"
// @Success 200 {object} entities.User
// @Failure 400 {object} utils.ErrorResponse
// @Failure 404 {object} utils.ErrorResponse
// @Router /api/v1/users/{id} [get]
func (c *UserController) GetUser(ctx *gin.Context) {
	idParam := ctx.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	user, err := c.userService.GetUserByID(id)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User retrieved successfully", user)
}

// GetUsers retrieves all users with pagination
// @Summary Get all users
// @Tags users
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Items per page" default(10)
// @Success 200 {object} utils.PaginatedResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/users [get]
func (c *UserController) GetUsers(ctx *gin.Context) {
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "10"))

	users, total, err := c.userService.GetAllUsers(page, limit)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve users", err)
		return
	}

	response := utils.PaginatedResponse{
		Data:       users,
		Page:       page,
		Limit:      limit,
		Total:      total,
		TotalPages: (total + limit - 1) / limit,
	}

	utils.SuccessResponse(ctx, http.StatusOK, "Users retrieved successfully", response)
}

// UpdateUser updates a user by ID
// @Summary Update user
// @Tags users
// @Accept json
// @Produce json
// @Param id path int true "User ID"
// @Param user body entities.UpdateUserRequest true "User update data"
// @Success 200 {object} entities.User
// @Failure 400 {object} utils.ErrorResponse
// @Failure 404 {object} utils.ErrorResponse
// @Router /api/v1/users/{id} [put]
func (c *UserController) UpdateUser(ctx *gin.Context) {
	idParam := ctx.Param("id")
	id, err := strconv.Atoi(idParam)
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

	user, err := c.userService.UpdateUser(id, &req)
	if err != nil {
		if err.Error() == "user not found" {
			utils.ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
			return
		}
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update user", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "User updated successfully", user)
}

// DeleteUser deletes a user by ID
// @Summary Delete user
// @Tags users
// @Param id path int true "User ID"
// @Success 204
// @Failure 400 {object} utils.ErrorResponse
// @Failure 404 {object} utils.ErrorResponse
// @Router /api/v1/users/{id} [delete]
func (c *UserController) DeleteUser(ctx *gin.Context) {
	idParam := ctx.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID", err)
		return
	}

	err = c.userService.DeleteUser(id)
	if err != nil {
		if err.Error() == "user not found" {
			utils.ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
			return
		}
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete user", err)
		return
	}

	ctx.Status(http.StatusNoContent)
}
