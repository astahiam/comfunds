package controllers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"comfunds/internal/entities"
	"comfunds/internal/services"
	"comfunds/internal/utils"
)

type ImageController struct {
	imageService *services.ImageService
}

func NewImageController(imageService *services.ImageService) *ImageController {
	return &ImageController{
		imageService: imageService,
	}
}

// CreateImage creates a new image record
// @Summary Create a new image
// @Description Create a new image record in the database
// @Tags images
// @Accept json
// @Produce json
// @Param image body entities.CreateImageRequest true "Image data"
// @Success 201 {object} utils.Response{data=entities.Image}
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /images [post]
func (c *ImageController) CreateImage(ctx *gin.Context) {
	var req entities.CreateImageRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.SendErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	image, err := c.imageService.CreateImage(&req)
	if err != nil {
		utils.SendErrorResponse(ctx, http.StatusInternalServerError, "Failed to create image", err.Error())
		return
	}

	utils.SendSuccessResponse(ctx, http.StatusCreated, "Image created successfully", image)
}

// GetImage retrieves an image by ID
// @Summary Get an image by ID
// @Description Get an image record by its ID
// @Tags images
// @Produce json
// @Param id path string true "Image ID"
// @Success 200 {object} utils.Response{data=entities.Image}
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /images/{id} [get]
func (c *ImageController) GetImage(ctx *gin.Context) {
	idParam := ctx.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		utils.SendErrorResponse(ctx, http.StatusBadRequest, "Invalid image ID", err.Error())
		return
	}

	image, err := c.imageService.GetImageByID(id)
	if err != nil {
		utils.SendErrorResponse(ctx, http.StatusInternalServerError, "Failed to get image", err.Error())
		return
	}

	if image == nil {
		utils.SendErrorResponse(ctx, http.StatusNotFound, "Image not found", "")
		return
	}

	utils.SendSuccessResponse(ctx, http.StatusOK, "Image retrieved successfully", image)
}

// GetImages retrieves images with pagination and optional filtering by used_by
// @Summary Get images with pagination
// @Description Get a list of images with pagination and optional filtering
// @Tags images
// @Produce json
// @Param used_by query string false "Filter by used_by field (projects, users, cooperatives, businesses)"
// @Param limit query int false "Number of images to return (default: 10, max: 100)"
// @Param offset query int false "Number of images to skip (default: 0)"
// @Success 200 {object} utils.Response{data=[]entities.Image}
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /images [get]
func (c *ImageController) GetImages(ctx *gin.Context) {
	// Parse pagination parameters
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "10"))
	offset, _ := strconv.Atoi(ctx.DefaultQuery("offset", "0"))
	usedBy := ctx.Query("used_by")

	// Validate limit
	if limit <= 0 || limit > 100 {
		limit = 10
	}

	if offset < 0 {
		offset = 0
	}

	var images []*entities.Image
	var err error

	if usedBy != "" {
		images, err = c.imageService.GetImagesByUsedBy(usedBy, limit, offset)
	} else {
		images, err = c.imageService.GetAllImages(limit, offset)
	}

	if err != nil {
		utils.SendErrorResponse(ctx, http.StatusInternalServerError, "Failed to get images", err.Error())
		return
	}

	utils.SendSuccessResponse(ctx, http.StatusOK, "Images retrieved successfully", images)
}

// UpdateImage updates an existing image
// @Summary Update an image
// @Description Update an existing image record
// @Tags images
// @Accept json
// @Produce json
// @Param id path string true "Image ID"
// @Param image body entities.UpdateImageRequest true "Updated image data"
// @Success 200 {object} utils.Response{data=entities.Image}
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /images/{id} [put]
func (c *ImageController) UpdateImage(ctx *gin.Context) {
	idParam := ctx.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		utils.SendErrorResponse(ctx, http.StatusBadRequest, "Invalid image ID", err.Error())
		return
	}

	var req entities.UpdateImageRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.SendErrorResponse(ctx, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.SendErrorResponse(ctx, http.StatusBadRequest, "Validation failed", err.Error())
		return
	}

	image, err := c.imageService.UpdateImage(id, &req)
	if err != nil {
		if err.Error() == "image not found" {
			utils.SendErrorResponse(ctx, http.StatusNotFound, "Image not found", "")
			return
		}
		utils.SendErrorResponse(ctx, http.StatusInternalServerError, "Failed to update image", err.Error())
		return
	}

	utils.SendSuccessResponse(ctx, http.StatusOK, "Image updated successfully", image)
}

// DeleteImage deletes an image
// @Summary Delete an image
// @Description Delete an image record from the database
// @Tags images
// @Produce json
// @Param id path string true "Image ID"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /images/{id} [delete]
func (c *ImageController) DeleteImage(ctx *gin.Context) {
	idParam := ctx.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		utils.SendErrorResponse(ctx, http.StatusBadRequest, "Invalid image ID", err.Error())
		return
	}

	err = c.imageService.DeleteImage(id)
	if err != nil {
		if err.Error() == "image not found" {
			utils.SendErrorResponse(ctx, http.StatusNotFound, "Image not found", "")
			return
		}
		utils.SendErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete image", err.Error())
		return
	}

	utils.SendSuccessResponse(ctx, http.StatusOK, "Image deleted successfully", nil)
}
