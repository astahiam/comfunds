package auth

import (
	"net/http"
	"strings"

	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware(jwtManager *JWTManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Authorization header required", nil)
			c.Abort()
			return
		}

		// Check if the header starts with "Bearer "
		const bearerPrefix = "Bearer "
		if !strings.HasPrefix(authHeader, bearerPrefix) {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Invalid authorization header format", nil)
			c.Abort()
			return
		}

		// Extract the token
		tokenString := authHeader[len(bearerPrefix):]
		if tokenString == "" {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Token is required", nil)
			c.Abort()
			return
		}

		// Verify the token
		claims, err := jwtManager.Verify(tokenString)
		if err != nil {
			utils.ErrorResponse(c, http.StatusUnauthorized, "Invalid token", err)
			c.Abort()
			return
		}

		// Set user information in context
		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Set("user_roles", claims.Roles)
		if claims.CooperativeID != nil {
			c.Set("cooperative_id", *claims.CooperativeID)
		}

		c.Next()
	}
}

// RequireRoles middleware ensures the user has at least one of the required roles
func RequireRoles(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRoles, exists := c.Get("user_roles")
		if !exists {
			utils.ErrorResponse(c, http.StatusUnauthorized, "User roles not found", nil)
			c.Abort()
			return
		}

		userRolesList, ok := userRoles.([]string)
		if !ok {
			utils.ErrorResponse(c, http.StatusInternalServerError, "Invalid user roles format", nil)
			c.Abort()
			return
		}

		// Check if user has any of the required roles
		hasRequiredRole := false
		for _, userRole := range userRolesList {
			for _, requiredRole := range roles {
				if userRole == requiredRole {
					hasRequiredRole = true
					break
				}
			}
			if hasRequiredRole {
				break
			}
		}

		if !hasRequiredRole {
			utils.ErrorResponse(c, http.StatusForbidden, "Insufficient permissions", nil)
			c.Abort()
			return
		}

		c.Next()
	}
}

// OptionalAuth middleware that doesn't require authentication but extracts user info if present
func OptionalAuth(jwtManager *JWTManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.Next()
			return
		}

		const bearerPrefix = "Bearer "
		if !strings.HasPrefix(authHeader, bearerPrefix) {
			c.Next()
			return
		}

		tokenString := authHeader[len(bearerPrefix):]
		if tokenString == "" {
			c.Next()
			return
		}

		// Try to verify the token, but don't fail if it's invalid
		claims, err := jwtManager.Verify(tokenString)
		if err == nil {
			c.Set("user_id", claims.UserID)
			c.Set("user_email", claims.Email)
			c.Set("user_roles", claims.Roles)
			if claims.CooperativeID != nil {
				c.Set("cooperative_id", *claims.CooperativeID)
			}
		}

		c.Next()
	}
}
