package auth

import (
	"net/http"

	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// PermissionMiddleware provides permission-based access control
type PermissionMiddleware struct {
	roleValidator *RoleValidator
}

// NewPermissionMiddleware creates a new permission middleware
func NewPermissionMiddleware() *PermissionMiddleware {
	return &PermissionMiddleware{
		roleValidator: NewRoleValidator(),
	}
}

// RequirePermission middleware ensures the user has the required permission
func (pm *PermissionMiddleware) RequirePermission(permission string) gin.HandlerFunc {
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

		if !pm.roleValidator.HasPermission(userRolesList, permission) {
			utils.ErrorResponse(c, http.StatusForbidden, "Insufficient permissions", nil)
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireCooperativeAccess ensures user can access cooperative data
func (pm *PermissionMiddleware) RequireCooperativeAccess() gin.HandlerFunc {
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

		if !pm.roleValidator.CanUserAccessCooperativeData(userRolesList) {
			utils.ErrorResponse(c, http.StatusForbidden, "Cooperative access required", nil)
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireCooperativeMembership ensures user belongs to the specified cooperative
func (pm *PermissionMiddleware) RequireCooperativeMembership() gin.HandlerFunc {
	return func(c *gin.Context) {
		userCooperativeID, exists := c.Get("cooperative_id")
		if !exists {
			utils.ErrorResponse(c, http.StatusForbidden, "Cooperative membership required", nil)
			c.Abort()
			return
		}

		// Extract cooperative ID from URL parameter if present
		cooperativeParam := c.Param("cooperative_id")
		if cooperativeParam != "" {
			requestedCooperativeID, err := uuid.Parse(cooperativeParam)
			if err != nil {
				utils.ErrorResponse(c, http.StatusBadRequest, "Invalid cooperative ID", err)
				c.Abort()
				return
			}

			userCoopID, ok := userCooperativeID.(uuid.UUID)
			if !ok {
				utils.ErrorResponse(c, http.StatusInternalServerError, "Invalid cooperative ID format", nil)
				c.Abort()
				return
			}

			if userCoopID != requestedCooperativeID {
				utils.ErrorResponse(c, http.StatusForbidden, "Access denied: different cooperative", nil)
				c.Abort()
				return
			}
		}

		c.Next()
	}
}

// RequireBusinessOwnership ensures user owns the specified business
func (pm *PermissionMiddleware) RequireBusinessOwnership() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := c.Get("user_id")
		if !exists {
			utils.ErrorResponse(c, http.StatusUnauthorized, "User ID not found", nil)
			c.Abort()
			return
		}

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

		if !pm.roleValidator.CanUserCreateBusiness(userRolesList) {
			utils.ErrorResponse(c, http.StatusForbidden, "Business owner role required", nil)
			c.Abort()
			return
		}

		// Store user ID for business ownership verification in the handler
		c.Set("business_owner_id", userID)
		c.Next()
	}
}

// RequireProjectOwnership ensures user owns the specified project
func (pm *PermissionMiddleware) RequireProjectOwnership() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := c.Get("user_id")
		if !exists {
			utils.ErrorResponse(c, http.StatusUnauthorized, "User ID not found", nil)
			c.Abort()
			return
		}

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

		if !pm.roleValidator.CanUserCreateProject(userRolesList) {
			utils.ErrorResponse(c, http.StatusForbidden, "Business owner role required for project management", nil)
			c.Abort()
			return
		}

		// Store user ID for project ownership verification in the handler
		c.Set("project_owner_id", userID)
		c.Next()
	}
}

// RequireInvestorRole ensures user has investor role
func (pm *PermissionMiddleware) RequireInvestorRole() gin.HandlerFunc {
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

		if !pm.roleValidator.CanUserInvest(userRolesList) {
			utils.ErrorResponse(c, http.StatusForbidden, "Investor role required", nil)
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireAdminRole ensures user has admin role
func (pm *PermissionMiddleware) RequireAdminRole() gin.HandlerFunc {
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

		if !pm.roleValidator.CanUserApproveProjects(userRolesList) {
			utils.ErrorResponse(c, http.StatusForbidden, "Admin role required", nil)
			c.Abort()
			return
		}

		c.Next()
	}
}

// OptionalCooperativeFilter provides cooperative-based filtering for optional access
func (pm *PermissionMiddleware) OptionalCooperativeFilter() gin.HandlerFunc {
	return func(c *gin.Context) {
		userRoles, exists := c.Get("user_roles")
		if exists {
			userRolesList, ok := userRoles.([]string)
			if ok && pm.roleValidator.CanUserAccessCooperativeData(userRolesList) {
				c.Set("can_access_cooperative_data", true)
			} else {
				c.Set("can_access_cooperative_data", false)
			}
		} else {
			c.Set("can_access_cooperative_data", false)
		}

		c.Next()
	}
}
