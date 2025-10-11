package handlers

import (
	"bytes"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"

	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
)

type UploadHandler struct{}

func NewUploadHandler() *Handler {
	return &Handler{}
}

// UploadBusinessDocument handles file upload to backend
func (h *Handler) UploadBusinessDocument(c *fiber.Ctx) error {
	// Get authentication token from cookie
	token := c.Cookies("auth_token")
	if token == "" {
		return c.Status(401).JSON(fiber.Map{
			"status":  "error",
			"message": "Unauthorized",
		})
	}

	// Get document type from form
	documentType := c.FormValue("document_type")
	if documentType == "" {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Document type is required",
		})
	}

	// Get uploaded file
	file, err := c.FormFile("file")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "File is required",
		})
	}

	// Open the file
	src, err := file.Open()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to open file",
		})
	}
	defer src.Close()

	// Create multipart form data
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// Add file
	part, err := writer.CreateFormFile("file", file.Filename)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create form file",
		})
	}
	if _, err := io.Copy(part, src); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to copy file",
		})
	}

	// Add document type field
	if err := writer.WriteField("document_type", documentType); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to add document type",
		})
	}

	// Close writer
	writer.Close()

	// Create request to backend
	backendURL := utils.GetBackendURL() + "/api/v1/upload/business-document"
	req, err := http.NewRequest("POST", backendURL, body)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Set headers
	req.Header.Set("Content-Type", writer.FormDataContentType())
	req.Header.Set("Authorization", "Bearer "+token)

	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to upload file to backend: " + err.Error(),
		})
	}
	defer resp.Body.Close()

	// Read response
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to read backend response",
		})
	}

	// Check status code
	if resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend upload failed",
			"details": string(respBody),
		})
	}

	// Parse and return response
	var result map[string]interface{}
	if err := utils.ParseJSON(respBody, &result); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to parse response",
		})
	}

	return c.JSON(result)
}

// DeleteBusinessDocument handles file deletion
func (h *Handler) DeleteBusinessDocument(c *fiber.Ctx) error {
	// Get authentication token from cookie
	token := c.Cookies("auth_token")
	if token == "" {
		return c.Status(401).JSON(fiber.Map{
			"status":  "error",
			"message": "Unauthorized",
		})
	}

	// Get file path from query
	filePath := c.Query("file_path")
	if filePath == "" {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "File path is required",
		})
	}

	// Create request to backend
	backendURL := fmt.Sprintf("%s/api/v1/upload/business-document?file_path=%s", utils.GetBackendURL(), filePath)
	req, err := http.NewRequest("DELETE", backendURL, nil)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create request",
		})
	}

	// Set headers
	req.Header.Set("Authorization", "Bearer "+token)

	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to delete file: " + err.Error(),
		})
	}
	defer resp.Body.Close()

	// Read response
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to read backend response",
		})
	}

	// Check status code
	if resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(fiber.Map{
			"status":  "error",
			"message": "Backend deletion failed",
			"details": string(respBody),
		})
	}

	// Parse and return response
	var result map[string]interface{}
	if err := utils.ParseJSON(respBody, &result); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to parse response",
		})
	}

	return c.JSON(result)
}
