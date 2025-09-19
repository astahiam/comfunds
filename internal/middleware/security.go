package middleware

import (
	"fmt"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

// SecurityHeaders middleware adds essential security headers
func SecurityHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Prevent clickjacking attacks
		c.Header("X-Frame-Options", "DENY")

		// Prevent MIME type sniffing
		c.Header("X-Content-Type-Options", "nosniff")

		// Enable XSS protection
		c.Header("X-XSS-Protection", "1; mode=block")

		// Control referrer information
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")

		// Content Security Policy
		csp := "default-src 'self'; " +
			"script-src 'self' 'unsafe-inline'; " +
			"style-src 'self' 'unsafe-inline'; " +
			"img-src 'self' data: https:; " +
			"font-src 'self' https:; " +
			"connect-src 'self'; " +
			"frame-ancestors 'none'"
		c.Header("Content-Security-Policy", csp)

		// Prevent caching of sensitive data
		if strings.Contains(c.Request.URL.Path, "/auth/") ||
			strings.Contains(c.Request.URL.Path, "/admin/") {
			c.Header("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate")
			c.Header("Pragma", "no-cache")
			c.Header("Expires", "0")
		}

		// HSTS for production
		if os.Getenv("ENVIRONMENT") == "production" {
			c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
		}

		c.Next()
	}
}

// CORSMiddleware provides secure CORS configuration
func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// Get allowed origins from environment
		allowedOrigins := getAllowedOrigins()

		// Check if origin is allowed
		if isOriginAllowed(origin, allowedOrigins) {
			c.Header("Access-Control-Allow-Origin", origin)
		} else if len(allowedOrigins) == 0 || (len(allowedOrigins) == 1 && allowedOrigins[0] == "*") {
			// Fallback for development - only allow localhost origins
			if isDevelopmentOrigin(origin) {
				c.Header("Access-Control-Allow-Origin", origin)
			}
		}

		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Max-Age", "86400") // 24 hours

		// Handle preflight requests
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// getAllowedOrigins returns the list of allowed origins from environment
func getAllowedOrigins() []string {
	allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
	if allowedOrigins == "" {
		return []string{} // Empty means no origins allowed in production
	}
	return strings.Split(allowedOrigins, ",")
}

// isOriginAllowed checks if the origin is in the allowed list
func isOriginAllowed(origin string, allowedOrigins []string) bool {
	for _, allowed := range allowedOrigins {
		allowed = strings.TrimSpace(allowed)
		if allowed == "*" || allowed == origin {
			return true
		}
		// Support wildcard subdomains like *.example.com
		if strings.HasPrefix(allowed, "*.") {
			domain := allowed[2:]
			if strings.HasSuffix(origin, "."+domain) || origin == domain {
				return true
			}
		}
	}
	return false
}

// isDevelopmentOrigin allows localhost origins for development
func isDevelopmentOrigin(origin string) bool {
	if origin == "" {
		return false
	}

	developmentOrigins := []string{
		"http://localhost",
		"https://localhost",
		"http://127.0.0.1",
		"https://127.0.0.1",
	}

	for _, devOrigin := range developmentOrigins {
		if strings.HasPrefix(origin, devOrigin) {
			return true
		}
	}
	return false
}

// Rate limiting structures
type rateLimiter struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

type rateLimiters struct {
	limiters map[string]*rateLimiter
	mu       sync.RWMutex
}

var (
	authRateLimiters = &rateLimiters{
		limiters: make(map[string]*rateLimiter),
	}
	generalRateLimiters = &rateLimiters{
		limiters: make(map[string]*rateLimiter),
	}
)

// RateLimitMiddleware provides rate limiting functionality
func RateLimitMiddleware(requestsPerMinute int, burstSize int) gin.HandlerFunc {
	return func(c *gin.Context) {
		clientIP := getClientIP(c)

		limiter := getRateLimiter(generalRateLimiters, clientIP, requestsPerMinute, burstSize)

		if !limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"status":  "error",
				"message": "Rate limit exceeded. Please try again later.",
				"error":   "Too many requests",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// AuthRateLimitMiddleware provides stricter rate limiting for authentication endpoints
func AuthRateLimitMiddleware() gin.HandlerFunc {
	// Auth endpoints: 5 requests per minute with burst of 10
	authRequestsPerMinute := 5
	authBurstSize := 10

	// Get from environment if set
	if rpm := os.Getenv("AUTH_RATE_LIMIT_RPM"); rpm != "" {
		if val := parseIntWithDefault(rpm, authRequestsPerMinute); val > 0 {
			authRequestsPerMinute = val
		}
	}

	if burst := os.Getenv("AUTH_RATE_LIMIT_BURST"); burst != "" {
		if val := parseIntWithDefault(burst, authBurstSize); val > 0 {
			authBurstSize = val
		}
	}

	return func(c *gin.Context) {
		clientIP := getClientIP(c)

		limiter := getRateLimiter(authRateLimiters, clientIP, authRequestsPerMinute, authBurstSize)

		if !limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"status":  "error",
				"message": "Authentication rate limit exceeded. Please wait before trying again.",
				"error":   "Too many authentication attempts",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// getRateLimiter gets or creates a rate limiter for a client
func getRateLimiter(limiters *rateLimiters, clientIP string, requestsPerMinute, burstSize int) *rate.Limiter {
	limiters.mu.Lock()
	defer limiters.mu.Unlock()

	// Clean up old limiters (older than 1 hour)
	now := time.Now()
	for ip, limiter := range limiters.limiters {
		if now.Sub(limiter.lastSeen) > time.Hour {
			delete(limiters.limiters, ip)
		}
	}

	// Get or create limiter for this IP
	limiter, exists := limiters.limiters[clientIP]
	if !exists {
		// Create new rate limiter
		// Convert requests per minute to requests per second
		rps := rate.Limit(float64(requestsPerMinute) / 60.0)
		limiter = &rateLimiter{
			limiter:  rate.NewLimiter(rps, burstSize),
			lastSeen: now,
		}
		limiters.limiters[clientIP] = limiter
	} else {
		limiter.lastSeen = now
	}

	return limiter.limiter
}

// getClientIP extracts the real client IP from the request
func getClientIP(c *gin.Context) string {
	// Check X-Forwarded-For header (for load balancers/proxies)
	if xff := c.GetHeader("X-Forwarded-For"); xff != "" {
		// Take the first IP (original client)
		if ips := strings.Split(xff, ","); len(ips) > 0 {
			return strings.TrimSpace(ips[0])
		}
	}

	// Check X-Real-IP header
	if xri := c.GetHeader("X-Real-IP"); xri != "" {
		return xri
	}

	// Fallback to RemoteAddr
	return c.ClientIP()
}

// parseIntWithDefault parses string to int with default fallback
func parseIntWithDefault(s string, defaultVal int) int {
	var val int
	if n, err := fmt.Sscanf(s, "%d", &val); n == 1 && err == nil {
		return val
	}
	return defaultVal
}

// TrustedProxyMiddleware configures trusted proxies for Gin
func TrustedProxyMiddleware() gin.HandlerFunc {
	return gin.HandlerFunc(func(c *gin.Context) {
		// This is handled in main.go router setup
		c.Next()
	})
}
