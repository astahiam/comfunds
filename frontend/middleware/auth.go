package middleware

import (
	"hajifund-frontend/models"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware validates JWT token from cookies
func AuthMiddleware(c *fiber.Ctx) error {
	// Get token from cookie
	tokenString := c.Cookies("auth_token")
	if tokenString == "" {
		// Check if this is an API request
		path := c.Path()
		if len(path) >= 4 && path[:4] == "/api" {
			return c.Status(401).JSON(fiber.Map{
				"status":  "error",
				"message": "Unauthorized: Authentication token not found",
			})
		}
		return c.Redirect("/login")
	}

	// Parse and validate token
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			secret = "your-super-secret-jwt-key-change-this-in-production" // Match backend default
		}
		return []byte(secret), nil
	})

	if err != nil || !token.Valid {
		// Clear invalid cookie
		c.Cookie(&fiber.Cookie{
			Name:     "auth_token",
			Value:    "",
			HTTPOnly: true,
			MaxAge:   -1,
		})
		// Check if this is an API request
		path := c.Path()
		if len(path) >= 4 && path[:4] == "/api" {
			return c.Status(401).JSON(fiber.Map{
				"status":  "error",
				"message": "Unauthorized: Invalid or expired token",
			})
		}
		return c.Redirect("/login")
	}

	// Extract claims
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		// Check if this is an API request
		path := c.Path()
		if len(path) >= 4 && path[:4] == "/api" {
			return c.Status(401).JSON(fiber.Map{
				"status":  "error",
				"message": "Unauthorized: Invalid token claims",
			})
		}
		return c.Redirect("/login")
	}

	// Set user data in context with all available fields
	user := &models.User{
		ID:            getStringFromClaims(claims, "user_id"),
		Email:         getStringFromClaims(claims, "email"),
		Name:          getStringFromClaims(claims, "name"), // Now includes name from JWT
		Phone:         getStringFromClaims(claims, "phone"),
		Address:       getStringFromClaims(claims, "address"),
		CooperativeID: getStringPointerFromClaims(claims, "cooperative_id"),
		Roles:         extractRoles(claims["roles"]),
		KYCStatus:     getStringFromClaims(claims, "kyc_status"),
		IsActive:      true,
	}

	c.Locals("user", user)
	return c.Next()
}

// OptionalAuthMiddleware validates JWT token but doesn't redirect if missing
func OptionalAuthMiddleware(c *fiber.Ctx) error {
	// Get token from cookie
	tokenString := c.Cookies("auth_token")
	if tokenString == "" {
		c.Locals("user", nil)
		return c.Next()
	}

	// Parse and validate token
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			secret = "your-super-secret-jwt-key-change-this-in-production" // Match backend default
		}
		return []byte(secret), nil
	})

	if err != nil || !token.Valid {
		// Clear invalid cookie
		c.Cookie(&fiber.Cookie{
			Name:     "auth_token",
			Value:    "",
			HTTPOnly: true,
			MaxAge:   -1,
		})
		c.Locals("user", nil)
		return c.Next()
	}

	// Extract claims
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		c.Locals("user", nil)
		return c.Next()
	}

	// Set user data in context
	user := &models.User{
		ID:            getStringFromClaims(claims, "user_id"),
		Email:         getStringFromClaims(claims, "email"),
		Name:          getStringFromClaims(claims, "name"), // Now includes name from JWT
		Phone:         getStringFromClaims(claims, "phone"),
		Address:       getStringFromClaims(claims, "address"),
		CooperativeID: getStringPointerFromClaims(claims, "cooperative_id"),
		Roles:         extractRoles(claims["roles"]),
		KYCStatus:     getStringFromClaims(claims, "kyc_status"),
		IsActive:      true,
	}

	c.Locals("user", user)
	return c.Next()
}

// RequireAdmin checks if user has admin role
func RequireAdmin(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	if !hasRole(user.Roles, "admin") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Admin access required",
		})
	}

	return c.Next()
}

// RequireCooperativeAdmin checks if user has cooperative admin role
func RequireCooperativeAdmin(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	if !hasRole(user.Roles, "cooperative_admin") && !hasRole(user.Roles, "admin") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Cooperative admin access required",
		})
	}

	return c.Next()
}

// RequireBusinessOwner checks if user has business_owner role
func RequireBusinessOwner(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	if !hasRole(user.Roles, "business_owner") && !hasRole(user.Roles, "admin") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Business owner role required",
		})
	}

	return c.Next()
}

// RequireInvestor checks if user has investor role
func RequireInvestor(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	if !hasRole(user.Roles, "investor") && !hasRole(user.Roles, "admin") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Investor role required",
		})
	}

	return c.Next()
}

// RequireCooperativeMember checks if user is a member of a cooperative
func RequireCooperativeMember(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	if user.CooperativeID == nil && !hasRole(user.Roles, "admin") {
		return c.Status(403).Render("error", fiber.Map{
			"Code":    403,
			"Message": "Cooperative membership required",
		})
	}

	return c.Next()
}

// Helper functions
func extractRoles(roles interface{}) []string {
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

func hasRole(userRoles []string, requiredRole string) bool {
	for _, role := range userRoles {
		if role == requiredRole {
			return true
		}
	}
	return false
}

func getStringFromClaims(claims jwt.MapClaims, key string) string {
	if value, ok := claims[key]; ok {
		if str, ok := value.(string); ok {
			return str
		}
	}
	return ""
}

func getStringPointerFromClaims(claims jwt.MapClaims, key string) *string {
	if value, ok := claims[key]; ok {
		if str, ok := value.(string); ok {
			return &str
		}
	}
	return nil
}
