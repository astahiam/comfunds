package handlers

import (
	"fmt"
	"hajifund-frontend/models"
	"hajifund-frontend/utils"

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
	// Get available cooperatives for dropdown
	cooperativesResp, err := utils.MakeAPIRequest("GET", "/api/v1/public/cooperatives", nil, nil)
	var cooperatives []models.Cooperative
	if err == nil && cooperativesResp.Data != nil {
		if data, ok := cooperativesResp.Data.(map[string]interface{}); ok {
			if coopData, ok := data["cooperatives"].([]interface{}); ok {
				cooperatives = make([]models.Cooperative, len(coopData))
				for i, coop := range coopData {
					if coopMap, ok := coop.(map[string]interface{}); ok {
						cooperatives[i] = models.Cooperative{
							ID:   coopMap["id"].(string),
							Name: coopMap["name"].(string),
						}
					}
				}
			}
		}
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
	var req models.RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body: " + err.Error(),
		})
	}

	// Prepare backend request payload
	backendReq := map[string]interface{}{
		"name":     req.Name,
		"email":    req.Email,
		"password": req.Password,
		"phone":    req.Phone,
		"address":  req.Address,
		"roles":    req.Roles,
	}

	// Handle cooperative_id conversion (string to UUID or null)
	if req.CooperativeID != nil && *req.CooperativeID != "" {
		backendReq["cooperative_id"] = *req.CooperativeID
	} else {
		backendReq["cooperative_id"] = nil
	}

	// Make API request to backend
	resp, err := utils.MakeAPIRequest("POST", "/api/v1/auth/register", backendReq, nil)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": "Registration failed: " + err.Error(),
		})
	}

	// Check if backend returned an error
	if resp.Status != "success" {
		return c.Status(400).JSON(fiber.Map{
			"status":  "error",
			"message": resp.Message,
		})
	}

	// Extract user data
	var authResp models.AuthResponse
	if data, ok := resp.Data.(map[string]interface{}); ok {
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
	c.Cookie(&fiber.Cookie{
		Name:     "auth_token",
		Value:    authResp.AccessToken,
		HTTPOnly: true,
		Secure:   false, // Set to true in production
		SameSite: "Lax",
		MaxAge:   24 * 60 * 60, // 24 hours
		Path:     "/",
	})

	return c.JSON(fiber.Map{
		"status":   "success",
		"message":  "Registration successful",
		"redirect": "/dashboard",
	})
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
func getStringValue(value interface{}) string {
	if value == nil {
		return ""
	}
	if str, ok := value.(string); ok {
		return str
	}
	return ""
}

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
