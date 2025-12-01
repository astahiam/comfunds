package handlers

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/require"
)

func setupAuthLoginTestApp() *fiber.App {
	app := fiber.New()
	app.Post("/api/auth/login", NewAuthHandler().Login)
	return app
}

func TestAuthHandler_Login_Success(t *testing.T) {
	app := setupAuthLoginTestApp()

	originalAPIBaseURL := utils.APIBaseURL
	t.Cleanup(func() {
		utils.APIBaseURL = originalAPIBaseURL
	})

	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "/api/v1/auth/login", r.URL.Path)
		w.Header().Set("Content-Type", "application/json")

		response := map[string]interface{}{
			"status":  "success",
			"message": "Login successful",
			"data": map[string]interface{}{
				"access_token": "token123",
				"user": map[string]interface{}{
					"id":        "user-1",
					"email":     "admin@hajifund.com",
					"name":      "Admin User",
					"roles":     []string{"admin"},
					"is_active": true,
				},
			},
		}
		json.NewEncoder(w).Encode(response)
	}))
	defer backend.Close()

	utils.APIBaseURL = backend.URL

	reqBody := `{"email":"admin@hajifund.com","password":"Password123!"}`
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewBufferString(reqBody))
	req.Header.Set("Content-Type", "application/json")

	resp, err := app.Test(req)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, resp.StatusCode)

	bodyBytes, err := io.ReadAll(resp.Body)
	require.NoError(t, err)

	var payload map[string]interface{}
	require.NoError(t, json.Unmarshal(bodyBytes, &payload))

	require.Equal(t, "success", payload["status"])
	require.Equal(t, "/admin", payload["redirect"])

	foundCookie := false
	for _, cookie := range resp.Cookies() {
		if cookie.Name == "auth_token" && cookie.Value == "token123" {
			foundCookie = true
			break
		}
	}
	require.True(t, foundCookie, "auth_token cookie should be set")
}

func TestAuthHandler_Login_InvalidCredentials(t *testing.T) {
	app := setupAuthLoginTestApp()

	originalAPIBaseURL := utils.APIBaseURL
	t.Cleanup(func() {
		utils.APIBaseURL = originalAPIBaseURL
	})

	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "/api/v1/auth/login", r.URL.Path)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		response := map[string]interface{}{
			"status":  "error",
			"message": "Invalid credentials",
			"error":   "invalid credentials",
		}
		json.NewEncoder(w).Encode(response)
	}))
	defer backend.Close()

	utils.APIBaseURL = backend.URL

	reqBody := `{"email":"admin@hajifund.com","password":"WrongPassword"}`
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewBufferString(reqBody))
	req.Header.Set("Content-Type", "application/json")

	resp, err := app.Test(req)
	require.NoError(t, err)
	require.Equal(t, http.StatusUnauthorized, resp.StatusCode)

	bodyBytes, err := io.ReadAll(resp.Body)
	require.NoError(t, err)

	var payload map[string]interface{}
	require.NoError(t, json.Unmarshal(bodyBytes, &payload))

	require.Equal(t, "error", payload["status"])
	require.Equal(t, "Login failed", payload["message"])
}
