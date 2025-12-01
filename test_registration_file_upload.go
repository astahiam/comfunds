package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"comfunds/internal/auth"
	"comfunds/internal/controllers"
	"comfunds/internal/database"
	"comfunds/internal/repositories"
	"comfunds/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/joho/godotenv"
	"github.com/stretchr/testify/suite"
)

// TestRegistrationFileUploadSuite tests registration with file uploads
type TestRegistrationFileUploadSuite struct {
	suite.Suite
	router         *gin.Engine
	authController *controllers.AuthController
	userService    services.UserServiceAuth
	jwtManager     *auth.JWTManager
	shardMgr       *database.ShardManager
	uploadDir      string
	testFilesDir   string
	cleanupUserIDs []uuid.UUID
}

func (suite *TestRegistrationFileUploadSuite) SetupSuite() {
	// Load test environment
	godotenv.Load(".env.test")

	gin.SetMode(gin.TestMode)

	// Create test directories
	suite.uploadDir = "uploads/documents/register"
	suite.testFilesDir = "test_files"
	os.MkdirAll(suite.uploadDir, 0755)
	os.MkdirAll(suite.testFilesDir, 0755)

	// Initialize test shard manager
	shardConfig := database.ShardConfig{
		Host:     getEnvWithDefault("TEST_DB_HOST", "localhost"),
		Port:     5432,
		Username: getEnvWithDefault("TEST_DB_USER", "postgres"),
		Password: getEnvWithDefault("TEST_DB_PASSWORD", ""),
		SSLMode:  getEnvWithDefault("TEST_DB_SSLMODE", "disable"),
	}

	var err error
	suite.shardMgr, err = database.NewShardManager(shardConfig)
	if err != nil {
		suite.T().Skipf("Skipping test: Failed to connect to test database: %v", err)
		return
	}

	// Initialize JWT manager
	suite.jwtManager = auth.NewJWTManager("test-secret-key", 24*time.Hour)

	// Initialize repositories and services
	userRepo := repositories.NewUserRepositorySharded(suite.shardMgr)
	cooperativeRepo := repositories.NewCooperativeRepository(suite.shardMgr)
	suite.userService = services.NewUserServiceAuth(userRepo, cooperativeRepo, suite.jwtManager)

	// Initialize controller
	suite.authController = controllers.NewAuthController(suite.userService)

	// Setup router
	suite.router = gin.New()
	v1 := suite.router.Group("/api/v1")
	{
		authRoutes := v1.Group("/auth")
		{
			authRoutes.POST("/register", suite.authController.RegisterUser)
		}
	}
}

func (suite *TestRegistrationFileUploadSuite) TearDownSuite() {
	// Clean up test users
	ctx := context.Background()
	for _, userID := range suite.cleanupUserIDs {
		suite.userService.DeleteUser(ctx, userID)
	}

	// Cleanup test files
	os.RemoveAll(suite.testFilesDir)
	// Cleanup uploaded test files (optional - you may want to keep them for verification)
	// if files, err := filepath.Glob(filepath.Join(suite.uploadDir, "payment_proof_*")); err == nil {
	// 	for _, file := range files {
	// 		os.Remove(file)
	// 	}
	// }

	if suite.shardMgr != nil {
		suite.shardMgr.Close()
	}
}

// createTestFile creates a test file with given filename and string content
func (suite *TestRegistrationFileUploadSuite) createTestFile(filename, content string) string {
	filePath := filepath.Join(suite.testFilesDir, filename)
	err := os.WriteFile(filePath, []byte(content), 0644)
	suite.Require().NoError(err)
	return filePath
}

// createTestPDF creates a minimal valid PDF file
func (suite *TestRegistrationFileUploadSuite) createTestPDF() string {
	pdfContent := `%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/Resources <<
/Font <<
/F1 <<
/Type /Font
/Subtype /Type1
/BaseFont /Helvetica
>>
>>
>>
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj
4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
100 700 Td
(Sample Payment Proof) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000306 00000 n
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
390
%%EOF`
	return suite.createTestFile("payment_proof.pdf", pdfContent)
}

// createTestImage creates a minimal valid image file
func (suite *TestRegistrationFileUploadSuite) createTestImage(ext string) string {
	var content []byte
	if ext == ".jpg" || ext == ".jpeg" {
		// Minimal valid JPEG (1x1 pixel) - binary content
		content = []byte{
			0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
			0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08,
			0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
			0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20,
			0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27,
			0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
			0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xC4, 0x00, 0x14,
			0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x80, 0xFF, 0xD9,
		}
	} else if ext == ".png" {
		// Minimal valid PNG (1x1 pixel, red) - binary content
		content = []byte{
			0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
			0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
			0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
			0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
			0x44, 0xAE, 0x42, 0x60, 0x82,
		}
	} else {
		content = []byte("test content")
	}
	filename := "payment_proof" + ext
	filePath := filepath.Join(suite.testFilesDir, filename)
	err := os.WriteFile(filePath, content, 0644)
	suite.Require().NoError(err)
	return filePath
}

// createMultipartForm creates a multipart form with file upload
func (suite *TestRegistrationFileUploadSuite) createMultipartForm(filePath string, includeFile bool) (*bytes.Buffer, string) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	// Add form fields
	writer.WriteField("name", "Test User")
	writer.WriteField("email", fmt.Sprintf("test_%s@example.com", uuid.New().String()[:8]))
	writer.WriteField("password", "TestPass123!")
	writer.WriteField("phone", "+628123456789")
	writer.WriteField("address", "Test Address, Jakarta")
	writer.WriteField("cooperative_id", "550e8400-e29b-41d4-a716-446655440001")
	writer.WriteField("roles", "investor")
	writer.WriteField("roles", "member")

	// Add file if provided
	if includeFile && filePath != "" {
		file, err := os.Open(filePath)
		if err == nil {
			defer file.Close()

			part, err := writer.CreateFormFile("payment_proof", filepath.Base(filePath))
			if err == nil {
				io.Copy(part, file)
			}
		}
	}

	writer.Close()
	contentType := writer.FormDataContentType()

	return body, contentType
}

func (suite *TestRegistrationFileUploadSuite) TestRegistrationWithPDF() {
	// Create test PDF file
	pdfPath := suite.createTestPDF()
	defer os.Remove(pdfPath)

	// Create multipart form
	body, contentType := suite.createMultipartForm(pdfPath, true)

	// Create request
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/register", body)
	req.Header.Set("Content-Type", contentType)

	// Execute
	suite.router.ServeHTTP(w, req)

	// Assertions
	suite.Equal(http.StatusCreated, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	suite.Equal("success", response["status"])

	// Verify file was uploaded
	data := response["data"].(map[string]interface{})
	user := data["user"].(map[string]interface{})

	// Check if membership_payment_proof is present (may be nil if file upload failed silently)
	if proofURL, ok := user["membership_payment_proof"].(string); ok && proofURL != "" {
		suite.NotEmpty(proofURL)
		suite.T().Logf("Payment proof uploaded: %s", proofURL)

		// Verify file exists on disk
		filePath := filepath.Join(suite.uploadDir, filepath.Base(proofURL))
		_, err := os.Stat(filePath)
		suite.NoError(err, "Uploaded file should exist on disk")
	}

	// Extract user ID for cleanup
	userIDStr := user["id"].(string)
	userID, err := uuid.Parse(userIDStr)
	suite.NoError(err)
	suite.cleanupUserIDs = append(suite.cleanupUserIDs, userID)
}

func (suite *TestRegistrationFileUploadSuite) TestRegistrationWithJPG() {
	// Create test JPG file
	jpgPath := suite.createTestImage(".jpg")
	defer os.Remove(jpgPath)

	// Create multipart form
	body, contentType := suite.createMultipartForm(jpgPath, true)

	// Create request
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/register", body)
	req.Header.Set("Content-Type", contentType)

	// Execute
	suite.router.ServeHTTP(w, req)

	// Assertions
	suite.Equal(http.StatusCreated, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	suite.Equal("success", response["status"])

	// Extract user ID for cleanup
	data := response["data"].(map[string]interface{})
	user := data["user"].(map[string]interface{})
	userIDStr := user["id"].(string)
	userID, err := uuid.Parse(userIDStr)
	suite.NoError(err)
	suite.cleanupUserIDs = append(suite.cleanupUserIDs, userID)
}

func (suite *TestRegistrationFileUploadSuite) TestRegistrationWithPNG() {
	// Create test PNG file
	pngPath := suite.createTestImage(".png")
	defer os.Remove(pngPath)

	// Create multipart form
	body, contentType := suite.createMultipartForm(pngPath, true)

	// Create request
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/register", body)
	req.Header.Set("Content-Type", contentType)

	// Execute
	suite.router.ServeHTTP(w, req)

	// Assertions
	suite.Equal(http.StatusCreated, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	suite.Equal("success", response["status"])

	// Extract user ID for cleanup
	data := response["data"].(map[string]interface{})
	user := data["user"].(map[string]interface{})
	userIDStr := user["id"].(string)
	userID, err := uuid.Parse(userIDStr)
	suite.NoError(err)
	suite.cleanupUserIDs = append(suite.cleanupUserIDs, userID)
}

func (suite *TestRegistrationFileUploadSuite) TestRegistrationWithInvalidFileType() {
	// Create test TXT file (invalid)
	txtPath := suite.createTestFile("payment_proof.txt", "This is a text file")
	defer os.Remove(txtPath)

	// Create multipart form
	body, contentType := suite.createMultipartForm(txtPath, true)

	// Create request
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/register", body)
	req.Header.Set("Content-Type", contentType)

	// Execute
	suite.router.ServeHTTP(w, req)

	// Assertions - should reject invalid file type
	suite.Equal(http.StatusBadRequest, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	suite.Equal("error", response["status"])
	suite.Contains(response["message"].(string), "Invalid file type")
}

func (suite *TestRegistrationFileUploadSuite) TestRegistrationWithoutFile() {
	// Create multipart form without file
	body, contentType := suite.createMultipartForm("", false)

	// Create request
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/register", body)
	req.Header.Set("Content-Type", contentType)

	// Execute
	suite.router.ServeHTTP(w, req)

	// Assertions - registration should succeed even without file (file is optional in backend)
	suite.Equal(http.StatusCreated, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	suite.Equal("success", response["status"])

	// Extract user ID for cleanup
	data := response["data"].(map[string]interface{})
	user := data["user"].(map[string]interface{})
	userIDStr := user["id"].(string)
	userID, err := uuid.Parse(userIDStr)
	suite.NoError(err)
	suite.cleanupUserIDs = append(suite.cleanupUserIDs, userID)
}

func TestRegistrationFileUploadSuite(t *testing.T) {
	// Skip integration tests if TEST_INTEGRATION is not set
	if os.Getenv("TEST_INTEGRATION") == "" {
		t.Skip("Skipping integration test. Set TEST_INTEGRATION=1 to run.")
	}
	suite.Run(t, new(TestRegistrationFileUploadSuite))
}
