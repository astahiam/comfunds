package utils

import (
	"github.com/gin-gonic/gin"
)

type Response struct {
	Status  string      `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

type ErrorResponseData struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	Error   string `json:"error"`
}

type PaginatedResponse struct {
	Data       interface{} `json:"data"`
	Page       int         `json:"page"`
	Limit      int         `json:"limit"`
	Total      int         `json:"total"`
	TotalPages int         `json:"total_pages"`
}

func SuccessResponse(c *gin.Context, statusCode int, message string, data interface{}) {
	response := Response{
		Status:  "success",
		Message: message,
		Data:    data,
	}
	c.JSON(statusCode, response)
}

func ErrorResponse(c *gin.Context, statusCode int, message string, err error) {
	var errorMessage string
	if err != nil {
		errorMessage = err.Error()
	}

	response := ErrorResponseData{
		Status:  "error",
		Message: message,
		Error:   errorMessage,
	}
	c.JSON(statusCode, response)
}
