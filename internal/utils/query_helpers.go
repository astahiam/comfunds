package utils

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

// GetIntQuery extracts an integer query parameter with a default value
func GetIntQuery(ctx *gin.Context, key string, defaultValue int) int {
	value := ctx.DefaultQuery(key, strconv.Itoa(defaultValue))
	if intValue, err := strconv.Atoi(value); err == nil {
		return intValue
	}
	return defaultValue
}

// GetStringQuery extracts a string query parameter with a default value
func GetStringQuery(ctx *gin.Context, key string, defaultValue string) string {
	return ctx.DefaultQuery(key, defaultValue)
}

// GetBoolQuery extracts a boolean query parameter with a default value
func GetBoolQuery(ctx *gin.Context, key string, defaultValue bool) bool {
	value := ctx.DefaultQuery(key, strconv.FormatBool(defaultValue))
	if boolValue, err := strconv.ParseBool(value); err == nil {
		return boolValue
	}
	return defaultValue
}
