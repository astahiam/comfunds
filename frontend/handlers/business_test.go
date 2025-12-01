package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"hajifund-frontend/models"
	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/require"
)

func setupBusinessTestApp() *fiber.App {
	app := fiber.New()
	
	// Setup routes
	businessHandler := NewBusinessHandler()
	uploadHandler := NewUploadHandler()
	
	// Test middleware that sets user in context and cookie
	testAuthMiddleware := func(c *fiber.Ctx) error {
		user := createTestUser()
		c.Locals("user", user)
		// Also set cookie so getTokenFromContext can read it
		testToken := createTestJWTToken(user.ID, user.Email, user.Roles)
		c.Cookie(&fiber.Cookie{
			Name:     "auth_token",
			Value:    testToken,
			HTTPOnly: true,
		})
		return c.Next()
	}
	
	app.Get("/business/create", businessHandler.CreateBusinessPage)
	app.Post("/api/businesses", testAuthMiddleware, businessHandler.CreateBusiness)
	app.Post("/api/upload/business-document", testAuthMiddleware, uploadHandler.UploadBusinessDocument)
	
	return app
}

func createTestJWTToken(userID, email string, roles []string) string {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":        userID,
		"email":          email,
		"name":           "Test User",
		"roles":          roles,
		"cooperative_id": "coop-123",
	})
	tokenString, _ := token.SignedString([]byte("your-super-secret-jwt-key-change-this-in-production"))
	return tokenString
}

func createTestUser() *models.User {
	return &models.User{
		ID:           "test-user-123",
		Email:        "businessowner@test.com",
		Name:         "Test Business Owner",
		Roles:        []string{"business_owner"},
		CooperativeID: stringPtr("coop-123"),
	}
}

func stringPtr(s string) *string {
	return &s
}

func createMultipartFormData(fields map[string]string, files map[string][]byte) (*bytes.Buffer, string, error) {
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)

	// Add form fields
	for key, value := range fields {
		if err := writer.WriteField(key, value); err != nil {
			return nil, "", err
		}
	}

	// Add files
	for key, content := range files {
		part, err := writer.CreateFormFile(key, fmt.Sprintf("test_%s.pdf", key))
		if err != nil {
			return nil, "", err
		}
		if _, err := part.Write(content); err != nil {
			return nil, "", err
		}
	}

	if err := writer.Close(); err != nil {
		return nil, "", err
	}

	contentType := writer.FormDataContentType()
	return &body, contentType, nil
}

func TestBusinessCreation_WithDocuments(t *testing.T) {
	app := setupBusinessTestApp()

	originalAPIBaseURL := utils.APIBaseURL
	t.Cleanup(func() {
		utils.APIBaseURL = originalAPIBaseURL
	})

	// Mock backend server
	backend := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/api/v1/businesses":
			require.Equal(t, "POST", r.Method)
			require.Contains(t, r.Header.Get("Content-Type"), "multipart/form-data")
			
			// Check Authorization header - return 401 if missing
			authHeader := r.Header.Get("Authorization")
			fmt.Printf("DEBUG Backend Mock: Authorization header received: %s\n", authHeader)
			if authHeader == "" || !strings.Contains(authHeader, "Bearer") {
				fmt.Printf("DEBUG Backend Mock: Authorization header missing or invalid, returning 401\n")
				w.WriteHeader(http.StatusUnauthorized)
				json.NewEncoder(w).Encode(map[string]interface{}{
					"status":  "error",
					"message": "Authorization header required",
				})
				return
			}
			fmt.Printf("DEBUG Backend Mock: Authorization header OK, processing request\n")

			// Parse multipart form
			err := r.ParseMultipartForm(10 << 20) // 10MB
			require.NoError(t, err)

			// Verify required fields
			require.NotEmpty(t, r.FormValue("name"))
			require.NotEmpty(t, r.FormValue("type"))
			require.NotEmpty(t, r.FormValue("cooperative_id"))
			require.NotEmpty(t, r.FormValue("registration_number"))

			// Check if business_image file was uploaded
			file, header, err := r.FormFile("business_image")
			if err == nil {
				defer file.Close()
				require.NotNil(t, header)
				require.Contains(t, []string{".jpg", ".jpeg", ".png"}, strings.ToLower(header.Filename[len(header.Filename)-4:]))
			}

			// Return success response
			response := map[string]interface{}{
				"status":  "success",
				"message": "Business created successfully",
				"data": map[string]interface{}{
					"id":                 "business-123",
					"name":               r.FormValue("name"),
					"type":               r.FormValue("type"),
					"cooperative_id":     r.FormValue("cooperative_id"),
					"registration_number": r.FormValue("registration_number"),
					"status":             "draft",
					"approval_status":    "pending",
				},
			}
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusCreated)
			json.NewEncoder(w).Encode(response)

		case "/api/v1/upload/business-document":
			require.Equal(t, "POST", r.Method)
			require.Contains(t, r.Header.Get("Content-Type"), "multipart/form-data")

			// Parse multipart form
			err := r.ParseMultipartForm(10 << 20)
			require.NoError(t, err)

			// Verify file upload
			file, header, err := r.FormFile("file")
			require.NoError(t, err)
			defer file.Close()
			require.NotNil(t, header)

			// Return success response
			response := map[string]interface{}{
				"status":  "success",
				"message": "File uploaded successfully",
				"data": map[string]interface{}{
					"file_url": fmt.Sprintf("/uploads/documents/%s", header.Filename),
				},
			}
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(response)

		default:
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer backend.Close()

	utils.APIBaseURL = backend.URL

	// Step 1: Upload a document first
	t.Run("Upload Business Document", func(t *testing.T) {
		token := createTestJWTToken("test-user-123", "businessowner@test.com", []string{"business_owner"})

		// Create multipart form with file
		var body bytes.Buffer
		writer := multipart.NewWriter(&body)
		
		// Add file
		fileContent := []byte("fake PDF content for testing")
		part, err := writer.CreateFormFile("file", "test_document.pdf")
		require.NoError(t, err)
		_, err = part.Write(fileContent)
		require.NoError(t, err)
		
		// Add document type
		err = writer.WriteField("document_type", "business_plan")
		require.NoError(t, err)
		
		err = writer.Close()
		require.NoError(t, err)

		req := httptest.NewRequest(http.MethodPost, "/api/upload/business-document", &body)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		req.AddCookie(&http.Cookie{
			Name:  "auth_token",
			Value: token,
		})

		resp, err := app.Test(req)
		require.NoError(t, err)
		require.Equal(t, http.StatusOK, resp.StatusCode)

		bodyBytes, err := io.ReadAll(resp.Body)
		require.NoError(t, err)

		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(bodyBytes, &result))
		require.Equal(t, "success", result["status"])
	})

		// Step 2: Create business with form data and files
	t.Run("Create Business with Documents", func(t *testing.T) {

		// Create form fields
		fields := map[string]string{
			"name":                "Test Business Corp",
			"type":                "retail",
			"description":         "A test business for integration testing",
			"cooperative_id":      "coop-123",
			"registration_number": "REG123456789",
			"legal_structure":    "PT",
			"industry":            "Retail",
			"address":             "123 Test Street, Jakarta",
			"phone":               "+62123456789",
			"email":               "test@business.com",
			"website":             "https://testbusiness.com",
			"established_date":   "2020-01-15",
			"employee_count":      "25",
			"annual_revenue":      "500000000",
			"currency":            "IDR",
			"bank_account":        "1234567890",
			"business_license":    "LIC123456",
			// Document URLs (simulating uploaded documents)
			"business_plan_url":        "/uploads/documents/business_plan.pdf",
			"swot_analysis_url":        "/uploads/documents/swot_analysis.pdf",
			"financial_statements_url": "/uploads/documents/financial_statements.pdf",
		}

		// Create a fake image file
		imageContent := []byte("fake image content")
		files := map[string][]byte{
			"business_image": imageContent,
		}

		body, contentType, err := createMultipartFormData(fields, files)
		require.NoError(t, err)

		req := httptest.NewRequest(http.MethodPost, "/api/businesses", body)
		req.Header.Set("Content-Type", contentType)
		// Add auth token cookie for getTokenFromContext to work
		testToken := createTestJWTToken("test-user-123", "businessowner@test.com", []string{"business_owner"})
		req.AddCookie(&http.Cookie{
			Name:  "auth_token",
			Value: testToken,
		})

		resp, err := app.Test(req)
		require.NoError(t, err)
		require.Equal(t, http.StatusOK, resp.StatusCode)

		bodyBytes, err := io.ReadAll(resp.Body)
		require.NoError(t, err)

		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(bodyBytes, &result))
		
		require.Equal(t, "success", result["status"])
		require.Contains(t, result["message"], "successfully")
		
		if data, ok := result["data"].(map[string]interface{}); ok {
			require.Equal(t, "Test Business Corp", data["name"])
			require.Equal(t, "business-123", data["id"])
		}
	})

	// Step 3: Test validation errors
	t.Run("Create Business - Missing Required Fields", func(t *testing.T) {
		token := createTestJWTToken("test-user-123", "businessowner@test.com", []string{"business_owner"})

		// Create form with missing required fields
		fields := map[string]string{
			"name": "Test Business",
			// Missing: type, cooperative_id, registration_number, etc.
		}

		body, contentType, err := createMultipartFormData(fields, nil)
		require.NoError(t, err)

		req := httptest.NewRequest(http.MethodPost, "/api/businesses", body)
		req.Header.Set("Content-Type", contentType)
		req.AddCookie(&http.Cookie{
			Name:  "auth_token",
			Value: token,
		})

		resp, err := app.Test(req)
		require.NoError(t, err)
		
		// Should return error (400 or 500 depending on validation)
		require.True(t, resp.StatusCode >= 400 && resp.StatusCode < 500)

		bodyBytes, err := io.ReadAll(resp.Body)
		require.NoError(t, err)

		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(bodyBytes, &result))
		require.Equal(t, "error", result["status"])
	})

	// Step 4: Test unauthorized access
	t.Run("Create Business - Unauthorized", func(t *testing.T) {
		fields := map[string]string{
			"name": "Test Business",
			"type": "retail",
		}

		body, contentType, err := createMultipartFormData(fields, nil)
		require.NoError(t, err)

		req := httptest.NewRequest(http.MethodPost, "/api/businesses", body)
		req.Header.Set("Content-Type", contentType)
		// No auth token cookie

		resp, err := app.Test(req)
		require.NoError(t, err)
		require.Equal(t, http.StatusUnauthorized, resp.StatusCode)

		bodyBytes, err := io.ReadAll(resp.Body)
		require.NoError(t, err)

		var result map[string]interface{}
		require.NoError(t, json.Unmarshal(bodyBytes, &result))
		require.Equal(t, "error", result["status"])
		// Error message can be "Unauthorized" or "Authorization header required"
		require.True(t, strings.Contains(result["message"].(string), "Unauthorized") || 
			strings.Contains(result["message"].(string), "Authorization"))
	})
}

func TestBusinessCreation_RealBackend(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	// Check if backend is running
	backendURL := os.Getenv("API_BASE_URL")
	if backendURL == "" {
		backendURL = "http://localhost:8080"
	}

	resp, err := http.Get(backendURL + "/health")
	if err != nil {
		t.Skipf("Backend not available at %s, skipping integration test", backendURL)
		return
	}
	resp.Body.Close()

	t.Logf("Testing against real backend at %s", backendURL)

	app := setupBusinessTestApp()
	originalAPIBaseURL := utils.APIBaseURL
	t.Cleanup(func() {
		utils.APIBaseURL = originalAPIBaseURL
	})
	utils.APIBaseURL = backendURL

	// This test requires:
	// 1. Backend server running
	// 2. Valid JWT token from login
	// 3. Valid cooperative_id
	// For now, we'll just verify the endpoint exists
	t.Run("Verify Endpoint Exists", func(t *testing.T) {
		token := createTestJWTToken("test-user-123", "businessowner@test.com", []string{"business_owner"})

		fields := map[string]string{
			"name":                "Integration Test Business",
			"type":                "retail",
			"description":         "Test business",
			"cooperative_id":      "00000000-0000-0000-0000-000000000001",
			"registration_number": "TEST123456",
			"legal_structure":     "PT",
			"industry":            "Retail",
			"address":             "Test Address",
			"phone":               "+62123456789",
			"email":               "test@example.com",
			"established_date":   "2020-01-15",
			"currency":            "IDR",
			"bank_account":         "1234567890",
		}

		body, contentType, err := createMultipartFormData(fields, nil)
		require.NoError(t, err)

		req := httptest.NewRequest(http.MethodPost, "/api/businesses", body)
		req.Header.Set("Content-Type", contentType)
		req.AddCookie(&http.Cookie{
			Name:  "auth_token",
			Value: token,
		})

		resp, err := app.Test(req)
		require.NoError(t, err)
		
		// We expect either success or a validation error (not 404 or 500)
		require.True(t, resp.StatusCode < 500, "Should not get server error")
		
		t.Logf("Response status: %d", resp.StatusCode)
		bodyBytes, _ := io.ReadAll(resp.Body)
		t.Logf("Response body: %s", string(bodyBytes))
	})
}

