package middleware

import (
	"fmt"
	"net/http"
	"strings"

	"comfunds/internal/entities"
	"comfunds/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// IdempotencyMiddleware handles idempotency for HTTP requests
type IdempotencyMiddleware struct {
	idempotencyService interface{} // Will be properly typed when service is imported
}

// NewIdempotencyMiddleware creates a new idempotency middleware
func NewIdempotencyMiddleware(idempotencyService interface{}) *IdempotencyMiddleware {
	return &IdempotencyMiddleware{
		idempotencyService: idempotencyService,
	}
}

// HandleIdempotency processes idempotency headers and manages request deduplication
func (im *IdempotencyMiddleware) HandleIdempotency() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Only apply idempotency to POST, PUT, PATCH requests
		if !isModifyingMethod(c.Request.Method) {
			c.Next()
			return
		}

		// Get idempotency key from header
		idempotencyKey := c.GetHeader("Idempotency-Key")
		if idempotencyKey == "" {
			// No idempotency key provided, continue with normal processing
			c.Next()
			return
		}

		// Validate idempotency key format
		if err := entities.ValidateIdempotencyKey(idempotencyKey); err != nil {
			utils.ErrorResponse(c, http.StatusBadRequest, "Invalid idempotency key format", err)
			c.Abort()
			return
		}

		// Get user ID from context (set by auth middleware)
		userIDStr, exists := c.Get("user_id")
		if !exists {
			utils.ErrorResponse(c, http.StatusUnauthorized, "User ID not found in context", fmt.Errorf("authentication required for idempotency"))
			c.Abort()
			return
		}

		userID, ok := userIDStr.(string)
		if !ok {
			utils.ErrorResponse(c, http.StatusInternalServerError, "Invalid user ID format", fmt.Errorf("user ID must be a string"))
			c.Abort()
			return
		}

		parsedUserID, err := uuid.Parse(userID)
		if err != nil {
			utils.ErrorResponse(c, http.StatusBadRequest, "Invalid user ID", err)
			c.Abort()
			return
		}

		// Determine table name from endpoint
		tableName := extractTableName(c.Request.URL.Path)

		// Create idempotency request
		idempotencyReq := &entities.IdempotencyRequest{
			IdempotencyKey: idempotencyKey,
			UserID:         parsedUserID,
			Endpoint:       c.Request.URL.Path,
			TableName:      tableName,
			Data:           c.Request.Body, // Note: This will need to be read and stored
		}

		// Store the idempotency request in context for the service layer to use
		c.Set("idempotency_request", idempotencyReq)
		c.Set("idempotency_key", idempotencyKey)

		// Continue to next middleware/handler
		c.Next()
	}
}

// isModifyingMethod checks if the HTTP method modifies data
func isModifyingMethod(method string) bool {
	modifyingMethods := []string{"POST", "PUT", "PATCH", "DELETE"}
	for _, m := range modifyingMethods {
		if strings.EqualFold(method, m) {
			return true
		}
	}
	return false
}

// extractTableName extracts the table name from the URL path
func extractTableName(path string) string {
	// Remove leading slash and split by slashes
	parts := strings.Split(strings.TrimPrefix(path, "/"), "/")
	
	// Look for common patterns
	for i, part := range parts {
		switch part {
		case "api", "v1":
			// Skip version prefixes
			continue
		case "investments", "projects", "businesses", "cooperatives", "users", "funds", "profit-sharing":
			// Return the table name
			return part
		case "admin":
			// For admin routes, get the next part
			if i+1 < len(parts) {
				return parts[i+1]
			}
		}
	}
	
	// Default to "unknown" if no table name can be extracted
	return "unknown"
}

// GetIdempotencyRequestFromContext retrieves idempotency request from gin context
func GetIdempotencyRequestFromContext(c *gin.Context) (*entities.IdempotencyRequest, bool) {
	req, exists := c.Get("idempotency_request")
	if !exists {
		return nil, false
	}
	
	idempotencyReq, ok := req.(*entities.IdempotencyRequest)
	return idempotencyReq, ok
}

// GetIdempotencyKeyFromContext retrieves idempotency key from gin context
func GetIdempotencyKeyFromContext(c *gin.Context) (string, bool) {
	key, exists := c.Get("idempotency_key")
	if !exists {
		return "", false
	}
	
	idempotencyKey, ok := key.(string)
	return idempotencyKey, ok
}

// SetIdempotencyResponse sets idempotency response headers
func SetIdempotencyResponse(c *gin.Context, response *entities.IdempotencyResponse) {
	if response != nil {
		c.Header("Idempotency-Key", response.ID)
		c.Header("Idempotency-Status", response.Status)
		c.Header("Idempotency-Expires-At", response.ExpiresAt.Format("2006-01-02T15:04:05Z"))
		
		if response.IsDuplicate {
			c.Header("Idempotency-Duplicate", "true")
		}
	}
}

// ProcessIdempotentResponse processes the response for idempotent requests
func ProcessIdempotentResponse(c *gin.Context, response interface{}, err error) {
	idempotencyReq, exists := GetIdempotencyRequestFromContext(c)
	if !exists {
		// No idempotency request, return normal response
		if err != nil {
			utils.ErrorResponse(c, http.StatusInternalServerError, "Operation failed", err)
		} else {
			utils.SuccessResponse(c, http.StatusOK, "Operation completed successfully", response)
		}
		return
	}

	// TODO: Implement actual idempotency processing when service is properly integrated
	// For now, just add headers
	c.Header("Idempotency-Key", idempotencyReq.IdempotencyKey)
	c.Header("Idempotency-Status", "processed")
	
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Operation failed", err)
	} else {
		utils.SuccessResponse(c, http.StatusOK, "Operation completed successfully", response)
	}
}
