package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"hajifund-frontend/models"
	"hajifund-frontend/utils"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"time"

	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct{}

func NewAuthHandler() *Handler {
	return &Handler{}
}

// LoginPage renders the login page
func (h *Handler) LoginPage(c *fiber.Ctx) error {
	return c.Render("auth/login", fiber.Map{
		"Title": "Login - HajiFund",
	}, "base")
}

// RegisterPage renders the registration page
func (h *Handler) RegisterPage(c *fiber.Ctx) error {
	cooperatives := []models.Cooperative{
		{
			ID:   "550e8400-e29b-41d4-a716-446655440001",
			Name: "Koperasi Haji",
		},
	}

	return c.Render("auth/register", fiber.Map{
		"Title":        "Register - HajiFund",
		"Cooperatives": cooperatives,
	}, "base")
}

// Login handles user login
func (h *Handler) Login(c *fiber.Ctx) error {
	var req models.LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}

	// Make API request to backend
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/auth/login", req, nil)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"status":  "error",
			"message": "Login failed",
		})
	}

	// Extract user data
	var authResp models.AuthResponse
	if data, ok := resp.Data.(map[string]interface{}); ok {
		authResp.AccessToken = data["access_token"].(string)
		if userData, ok := data["user"].(map[string]interface{}); ok {
			authResp.User = &models.User{
				ID:            userData["id"].(string),
				Email:         userData["email"].(string),
				Name:          userData["name"].(string),
				Phone:         getStringValue(userData["phone"]),
				Address:       getStringValue(userData["address"]),
				CooperativeID: getStringPointer(userData["cooperative_id"]),
				Roles:         extractRolesFromInterface(userData["roles"]),
				KYCStatus:     getStringValue(userData["kyc_status"]),
				IsActive:      getBoolValue(userData["is_active"]),
			}
		}
	}

	// Set auth token in cookie with proper expiration
	c.Cookie(&fiber.Cookie{
		Name:     "auth_token",
		Value:    authResp.AccessToken,
		HTTPOnly: true,
		Secure:   false, // Set to true in production
		SameSite: "Lax",
		MaxAge:   24 * 60 * 60, // 24 hours
		Path:     "/",
	})

	// Determine redirect based on user roles
	redirectURL := "/dashboard"
	if authResp.User != nil {
		if utils.HasRole(authResp.User.Roles, "admin") {
			redirectURL = "/admin"
		} else if utils.HasRole(authResp.User.Roles, "cooperative_admin") {
			redirectURL = "/cooperative"
		}
	}

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Login successful",
		"redirect": redirectURL,
		"user":     authResp.User,
	})
}

// Register handles user registration
func (h *Handler) Register(c *fiber.Ctx) error {
	// Forward multipart form data to backend
	backendURL := os.Getenv("API_BASE_URL")
	if backendURL == "" {
		backendURL = "http://localhost:8080"
	}

	// Parse multipart form with size limit (10MB)
	form, err := c.MultipartForm()
	if err != nil {
		// Log the error for debugging
		fmt.Printf("Error parsing multipart form: %v\n", err)
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid form data: " + err.Error(),
		})
	}

	// Log form fields for debugging
	fmt.Printf("Form fields received: %v\n", form.Value)
	fmt.Printf("Form files received: %v\n", len(form.File))

	// Reconstruct multipart form data for backend
	var buf bytes.Buffer
	writer := multipart.NewWriter(&buf)

	// Add form fields
	for key, values := range form.Value {
		for _, value := range values {
			writer.WriteField(key, value)
		}
	}

	// Add files
	for key, files := range form.File {
		for _, file := range files {
			fileWriter, err := writer.CreateFormFile(key, file.Filename)
			if err != nil {
				writer.Close()
				return c.Status(500).JSON(fiber.Map{
					"status":  "error",
					"message": "Failed to create form file: " + err.Error(),
				})
			}

			// Open and copy file
			src, err := file.Open()
			if err != nil {
				writer.Close()
				return c.Status(500).JSON(fiber.Map{
					"status":  "error",
					"message": "Failed to open file: " + err.Error(),
				})
			}

			io.Copy(fileWriter, src)
			src.Close()
		}
	}

	writer.Close()
	body := buf.Bytes()
	contentType := writer.FormDataContentType()

	// Create a new request to backend with multipart form data
	req, err := http.NewRequest("POST", backendURL+"/api/v1/auth/register", bytes.NewReader(body))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create backend request",
		})
	}

	// Copy content type header (including boundary)
	req.Header.Set("Content-Type", contentType)
	req.ContentLength = int64(len(body))

	// Make request to backend
	client := &http.Client{
		Timeout: 30 * time.Second, // 30 second timeout for file uploads
	}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error connecting to backend: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to connect to backend: " + err.Error(),
		})
	}
	defer resp.Body.Close()

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error reading backend response: %v\n", err)
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to read backend response",
		})
	}

	// Parse backend response
	var backendResp map[string]interface{}
	if err := json.Unmarshal(respBody, &backendResp); err != nil {
		fmt.Printf("Error parsing backend response: %v\n", err)
		fmt.Printf("Response body: %s\n", string(respBody))
		return c.Status(500).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to parse backend response: " + err.Error(),
			"details": string(respBody),
		})
	}

	// Log backend response for debugging
	fmt.Printf("Backend response status: %d\n", resp.StatusCode)
	fmt.Printf("Backend response: %+v\n", backendResp)

	// Check if backend returned an error
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		fmt.Printf("Backend returned error status: %d, message: %v\n", resp.StatusCode, backendResp)
		return c.Status(resp.StatusCode).JSON(backendResp)
	}

	// Extract user data and tokens
	var authResp models.AuthResponse
	if data, ok := backendResp["data"].(map[string]interface{}); ok {
		if accessToken, ok := data["access_token"].(string); ok {
			authResp.AccessToken = accessToken
		}
		if userData, ok := data["user"].(map[string]interface{}); ok {
			authResp.User = &models.User{
				ID:    getStringValue(userData["id"]),
				Email: getStringValue(userData["email"]),
				Name:  getStringValue(userData["name"]),
			}
		}
	}

	// Set auth token in cookie with proper expiration
	if authResp.AccessToken != "" {
		c.Cookie(&fiber.Cookie{
			Name:     "auth_token",
			Value:    authResp.AccessToken,
			HTTPOnly: true,
			Secure:   false, // Set to true in production
			SameSite: "Lax",
			MaxAge:   24 * 60 * 60, // 24 hours
			Path:     "/",
		})
	}

	return c.Status(resp.StatusCode).JSON(backendResp)
}

// Helper function to safely get string values
func getStringValue(v interface{}) string {
	if v == nil {
		return ""
	}
	if str, ok := v.(string); ok {
		return str
	}
	return fmt.Sprintf("%v", v)
}

// Logout handles user logout
func (h *Handler) Logout(c *fiber.Ctx) error {
	// Clear auth token cookie
	c.Cookie(&fiber.Cookie{
		Name:     "auth_token",
		Value:    "",
		HTTPOnly: true,
		Secure:   false,
		SameSite: "Lax",
		MaxAge:   -1, // Expire immediately
	})

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Logout successful",
		"redirect": "/",
	})
}

// Helper functions
func getStringPointer(value interface{}) *string {
	if value == nil {
		return nil
	}
	if str, ok := value.(string); ok {
		return &str
	}
	return nil
}

func getBoolValue(value interface{}) bool {
	if value == nil {
		return false
	}
	if b, ok := value.(bool); ok {
		return b
	}
	return false
}

func extractRolesFromInterface(roles interface{}) []string {
	if roles == nil {
		return []string{}
	}

	rolesSlice, ok := roles.([]interface{})
	if !ok {
		return []string{}
	}

	result := make([]string, len(rolesSlice))
	for i, role := range rolesSlice {
		if roleStr, ok := role.(string); ok {
			result[i] = roleStr
		}
	}

	return result
}
