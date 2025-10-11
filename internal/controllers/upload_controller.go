package controllers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UploadController struct{}

func NewUploadController() *UploadController {
	return &UploadController{}
}

// UploadBusinessDocument handles business document uploads
// @Summary Upload business document
// @Tags upload
// @Accept multipart/form-data
// @Produce json
// @Param file formData file true "Document file"
// @Param document_type formData string true "Document type (business_plan, swot_analysis, financial_statements, market_research, risk_assessment)"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 500 {object} utils.ErrorResponseData
// @Router /api/v1/upload/business-document [post]
func (c *UploadController) UploadBusinessDocument(ctx *gin.Context) {
	// Get authenticated user info from context
	userID, exists := ctx.Get("userID")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User not authenticated", nil)
		return
	}

	email, exists := ctx.Get("email")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User email not found", nil)
		return
	}

	// Get document type from form
	documentType := ctx.PostForm("document_type")
	if documentType == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Document type is required", nil)
		return
	}

	// Validate document type
	validTypes := []string{"business_plan", "swot_analysis", "financial_statements", "market_research", "risk_assessment"}
	isValid := false
	for _, t := range validTypes {
		if documentType == t {
			isValid = true
			break
		}
	}
	if !isValid {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid document type", nil)
		return
	}

	// Get file from form
	file, header, err := ctx.Request.FormFile("file")
	if err != nil {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "File is required", err)
		return
	}
	defer file.Close()

	// Validate file size (max 10MB)
	maxSize := int64(10 * 1024 * 1024) // 10MB
	if header.Size > maxSize {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "File size exceeds 10MB limit", nil)
		return
	}

	// Validate file type (PDF, DOC, DOCX, XLS, XLSX)
	allowedExtensions := []string{".pdf", ".doc", ".docx", ".xls", ".xlsx"}
	ext := strings.ToLower(filepath.Ext(header.Filename))
	isAllowedExt := false
	for _, allowedExt := range allowedExtensions {
		if ext == allowedExt {
			isAllowedExt = true
			break
		}
	}
	if !isAllowedExt {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "Invalid file type. Allowed: PDF, DOC, DOCX, XLS, XLSX", nil)
		return
	}

	// Create username-safe directory name from email
	username := strings.Split(email.(string), "@")[0]
	username = strings.ReplaceAll(username, ".", "_")
	username = strings.ReplaceAll(username, "+", "_")

	// Create upload directory structure: uploads/documents/{username}
	uploadDir := filepath.Join("uploads", "documents", username)
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create upload directory", err)
		return
	}

	// Generate unique filename with timestamp and UUID
	timestamp := time.Now().Format("20060102_150405")
	uniqueID := uuid.New().String()[:8]
	originalName := strings.TrimSuffix(filepath.Base(header.Filename), ext)
	// Sanitize filename
	originalName = strings.ReplaceAll(originalName, " ", "_")
	originalName = strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '_' || r == '-' {
			return r
		}
		return '_'
	}, originalName)

	filename := fmt.Sprintf("%s_%s_%s%s", documentType, timestamp, uniqueID, ext)
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
	fileURL := fmt.Sprintf("/uploads/documents/%s/%s", username, filename)

	// Return success response with file info
	utils.SuccessResponse(ctx, http.StatusOK, "File uploaded successfully", gin.H{
		"file_url":      fileURL,
		"file_name":     header.Filename,
		"file_size":     header.Size,
		"document_type": documentType,
		"uploaded_at":   time.Now().Format(time.RFC3339),
		"user_id":       userID,
	})
}

// DeleteBusinessDocument handles business document deletion
// @Summary Delete business document
// @Tags upload
// @Produce json
// @Param file_path query string true "File path to delete"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} utils.ErrorResponseData
// @Failure 500 {object} utils.ErrorResponseData
// @Router /api/v1/upload/business-document [delete]
func (c *UploadController) DeleteBusinessDocument(ctx *gin.Context) {
	// Get authenticated user info from context
	email, exists := ctx.Get("email")
	if !exists {
		utils.ErrorResponse(ctx, http.StatusUnauthorized, "User email not found", nil)
		return
	}

	// Get file path from query
	fileURL := ctx.Query("file_path")
	if fileURL == "" {
		utils.ErrorResponse(ctx, http.StatusBadRequest, "File path is required", nil)
		return
	}

	// Validate that the file belongs to the user
	username := strings.Split(email.(string), "@")[0]
	username = strings.ReplaceAll(username, ".", "_")
	username = strings.ReplaceAll(username, "+", "_")

	expectedPrefix := fmt.Sprintf("/uploads/documents/%s/", username)
	if !strings.HasPrefix(fileURL, expectedPrefix) {
		utils.ErrorResponse(ctx, http.StatusForbidden, "Access denied to this file", nil)
		return
	}

	// Convert URL to file path (remove leading slash)
	filePath := strings.TrimPrefix(fileURL, "/")

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		utils.ErrorResponse(ctx, http.StatusNotFound, "File not found", nil)
		return
	}

	// Delete the file
	if err := os.Remove(filePath); err != nil {
		utils.ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete file", err)
		return
	}

	utils.SuccessResponse(ctx, http.StatusOK, "File deleted successfully", gin.H{
		"file_path": fileURL,
	})
}
