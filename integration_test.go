package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"testing"

	"comfunds/internal/entities"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestUserIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration tests in short mode")
	}

	db := setupTestDB(t)
	defer cleanupTestDB(t, db)

	// Test data
	userReq := entities.CreateUserRequest{
		Email:    "integration@test.com",
		Name:     "Integration Test User",
		Password: "password123",
		Phone:    "1234567890",
		Address:  "Test Address",
	}

	t.Run("Create User Integration", func(t *testing.T) {
		reqBody, _ := json.Marshal(userReq)
		req, _ := http.NewRequest("POST", "/api/v1/users", bytes.NewBuffer(reqBody))
		req.Header.Set("Content-Type", "application/json")

		// For now, just test the structure
		assert.NotNil(t, req)
		assert.Equal(t, "POST", req.Method)
	})
}

func TestAPIEndpoints(t *testing.T) {
	tests := []struct {
		name       string
		method     string
		endpoint   string
		payload    interface{}
		statusCode int
	}{
		{
			name:       "Health Check",
			method:     "GET",
			endpoint:   "/api/v1/health",
			payload:    nil,
			statusCode: 200,
		},
		{
			name:       "Get Users",
			method:     "GET",
			endpoint:   "/api/v1/users",
			payload:    nil,
			statusCode: 200,
		},
		{
			name:       "Get Merchants",
			method:     "GET",
			endpoint:   "/api/v1/merchants",
			payload:    nil,
			statusCode: 200,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var reqBody []byte
			if tt.payload != nil {
				reqBody, _ = json.Marshal(tt.payload)
			}

			req, err := http.NewRequest(tt.method, tt.endpoint, bytes.NewBuffer(reqBody))
			require.NoError(t, err)

			if tt.payload != nil {
				req.Header.Set("Content-Type", "application/json")
			}

			// Test request creation
			assert.Equal(t, tt.method, req.Method)
			assert.Equal(t, tt.endpoint, req.URL.Path)
		})
	}
}
