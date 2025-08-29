package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"comfunds/internal/auth"
	"comfunds/internal/controllers"
	"comfunds/internal/database"
	"comfunds/internal/entities"
	"comfunds/internal/repositories"
	"comfunds/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/joho/godotenv"
	"github.com/stretchr/testify/suite"
)

type AuthIntegrationTestSuite struct {
	suite.Suite
	router          *gin.Engine
	authController  *controllers.AuthController
	userService     services.UserServiceAuth
	jwtManager      *auth.JWTManager
	shardMgr        *database.ShardManager
	testUsers       []entities.CreateUserRequest
	cleanupUserIDs  []uuid.UUID
}

func (suite *AuthIntegrationTestSuite) SetupSuite() {
	// Load test environment
	godotenv.Load(".env.test")
	
	gin.SetMode(gin.TestMode)
	
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
	suite.Require().NoError(err)
	
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
			authRoutes.POST("/login", suite.authController.LoginUser)
			authRoutes.POST("/refresh", suite.authController.RefreshToken)
		}
		
		protected := v1.Group("/")
		protected.Use(auth.AuthMiddleware(suite.jwtManager))
		{
			profile := protected.Group("/auth")
			{
				profile.GET("/profile", suite.authController.GetProfile)
				profile.PUT("/profile", suite.authController.UpdateProfile)
			}
		}
	}
	
	// Prepare test data
	suite.testUsers = []entities.CreateUserRequest{
		{
			Email:    "test1@example.com",
			Name:     "Test User 1",
			Password: "TestPassword123!",
			Phone:    "+1234567890",
			Address:  "123 Test St",
			Roles:    []string{"guest"},
		},
		{
			Email:    "test2@example.com",
			Name:     "Test User 2",
			Password: "TestPassword456!",
			Phone:    "+1234567891",
			Address:  "456 Test Ave",
			Roles:    []string{"member"},
		},
	}
}

func (suite *AuthIntegrationTestSuite) TearDownSuite() {
	// Clean up test users
	for _, userID := range suite.cleanupUserIDs {
		suite.userService.DeleteUser(suite.Suite.T().Context(), userID)
	}
	
	if suite.shardMgr != nil {
		suite.shardMgr.Close()
	}
}

func (suite *AuthIntegrationTestSuite) TestUserRegistrationFlow() {
	// Test user registration
	for _, testUser := range suite.testUsers {
		reqBody, err := json.Marshal(testUser)
		suite.Require().NoError(err)
		
		w := httptest.NewRecorder()
		req := httptest.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(reqBody))
		req.Header.Set("Content-Type", "application/json")
		
		suite.router.ServeHTTP(w, req)
		
		suite.Equal(http.StatusCreated, w.Code)
		
		var response map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &response)
		suite.NoError(err)
		
		suite.Equal("success", response["status"])
		suite.Contains(response, "data")
		
		data := response["data"].(map[string]interface{})
		suite.Contains(data, "user")
		suite.Contains(data, "access_token")
		suite.Contains(data, "refresh_token")
		
		// Extract user ID for cleanup
		user := data["user"].(map[string]interface{})
		userIDStr := user["id"].(string)
		userID, err := uuid.Parse(userIDStr)
		suite.NoError(err)
		suite.cleanupUserIDs = append(suite.cleanupUserIDs, userID)
	}
}

func (suite *AuthIntegrationTestSuite) TestUserLoginFlow() {
	// First register a user
	testUser := suite.testUsers[0]
	suite.registerTestUser(testUser)
	
	// Test login
	loginReq := map[string]string{
		"email":    testUser.Email,
		"password": testUser.Password,
	}
	
	reqBody, err := json.Marshal(loginReq)
	suite.Require().NoError(err)
	
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(reqBody))
	req.Header.Set("Content-Type", "application/json")
	
	suite.router.ServeHTTP(w, req)
	
	suite.Equal(http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err = json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	
	suite.Equal("success", response["status"])
	data := response["data"].(map[string]interface{})
	suite.Contains(data, "access_token")
	suite.Contains(data, "refresh_token")
}

func (suite *AuthIntegrationTestSuite) TestTokenRefreshFlow() {
	// Register and login a user first
	testUser := suite.testUsers[0]
	userID, accessToken, refreshToken := suite.registerAndLoginUser(testUser)
	
	// Test token refresh
	refreshReq := map[string]string{
		"refresh_token": refreshToken,
	}
	
	reqBody, err := json.Marshal(refreshReq)
	suite.Require().NoError(err)
	
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/refresh", bytes.NewBuffer(reqBody))
	req.Header.Set("Content-Type", "application/json")
	
	suite.router.ServeHTTP(w, req)
	
	suite.Equal(http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err = json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	
	suite.Equal("success", response["status"])
	data := response["data"].(map[string]interface{})
	suite.Contains(data, "access_token")
	
	// Verify the new token is different from the old one
	newAccessToken := data["access_token"].(string)
	suite.NotEqual(accessToken, newAccessToken)
	
	suite.cleanupUserIDs = append(suite.cleanupUserIDs, userID)
}

func (suite *AuthIntegrationTestSuite) TestGetProfileFlow() {
	// Register and login a user first
	testUser := suite.testUsers[0]
	userID, accessToken, _ := suite.registerAndLoginUser(testUser)
	
	// Test get profile
	w := httptest.NewRecorder()
	req := httptest.NewRequest("GET", "/api/v1/auth/profile", nil)
	req.Header.Set("Authorization", "Bearer "+accessToken)
	
	suite.router.ServeHTTP(w, req)
	
	suite.Equal(http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	
	suite.Equal("success", response["status"])
	userData := response["data"].(map[string]interface{})
	suite.Equal(testUser.Email, userData["email"])
	suite.Equal(testUser.Name, userData["name"])
	
	suite.cleanupUserIDs = append(suite.cleanupUserIDs, userID)
}

func (suite *AuthIntegrationTestSuite) TestUpdateProfileFlow() {
	// Register and login a user first
	testUser := suite.testUsers[0]
	userID, accessToken, _ := suite.registerAndLoginUser(testUser)
	
	// Test update profile
	updateReq := entities.UpdateUserRequest{
		Name:    "Updated Name",
		Phone:   "+9876543210",
		Address: "789 Updated St",
		Roles:   []string{"guest"},
	}
	
	reqBody, err := json.Marshal(updateReq)
	suite.Require().NoError(err)
	
	w := httptest.NewRecorder()
	req := httptest.NewRequest("PUT", "/api/v1/auth/profile", bytes.NewBuffer(reqBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+accessToken)
	
	suite.router.ServeHTTP(w, req)
	
	suite.Equal(http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err = json.Unmarshal(w.Body.Bytes(), &response)
	suite.NoError(err)
	
	suite.Equal("success", response["status"])
	userData := response["data"].(map[string]interface{})
	suite.Equal(updateReq.Name, userData["name"])
	suite.Equal(updateReq.Phone, userData["phone"])
	suite.Equal(updateReq.Address, userData["address"])
	
	suite.cleanupUserIDs = append(suite.cleanupUserIDs, userID)
}

func (suite *AuthIntegrationTestSuite) TestInvalidTokenAccess() {
	// Test with invalid token
	w := httptest.NewRecorder()
	req := httptest.NewRequest("GET", "/api/v1/auth/profile", nil)
	req.Header.Set("Authorization", "Bearer invalid-token")
	
	suite.router.ServeHTTP(w, req)
	
	suite.Equal(http.StatusUnauthorized, w.Code)
}

func (suite *AuthIntegrationTestSuite) TestMissingTokenAccess() {
	// Test without token
	w := httptest.NewRecorder()
	req := httptest.NewRequest("GET", "/api/v1/auth/profile", nil)
	
	suite.router.ServeHTTP(w, req)
	
	suite.Equal(http.StatusUnauthorized, w.Code)
}

// Helper methods

func (suite *AuthIntegrationTestSuite) registerTestUser(testUser entities.CreateUserRequest) uuid.UUID {
	reqBody, err := json.Marshal(testUser)
	suite.Require().NoError(err)
	
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(reqBody))
	req.Header.Set("Content-Type", "application/json")
	
	suite.router.ServeHTTP(w, req)
	suite.Require().Equal(http.StatusCreated, w.Code)
	
	var response map[string]interface{}
	err = json.Unmarshal(w.Body.Bytes(), &response)
	suite.Require().NoError(err)
	
	data := response["data"].(map[string]interface{})
	user := data["user"].(map[string]interface{})
	userIDStr := user["id"].(string)
	userID, err := uuid.Parse(userIDStr)
	suite.Require().NoError(err)
	
	return userID
}

func (suite *AuthIntegrationTestSuite) registerAndLoginUser(testUser entities.CreateUserRequest) (uuid.UUID, string, string) {
	// Register
	userID := suite.registerTestUser(testUser)
	
	// Login
	loginReq := map[string]string{
		"email":    testUser.Email,
		"password": testUser.Password,
	}
	
	reqBody, err := json.Marshal(loginReq)
	suite.Require().NoError(err)
	
	w := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(reqBody))
	req.Header.Set("Content-Type", "application/json")
	
	suite.router.ServeHTTP(w, req)
	suite.Require().Equal(http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err = json.Unmarshal(w.Body.Bytes(), &response)
	suite.Require().NoError(err)
	
	data := response["data"].(map[string]interface{})
	accessToken := data["access_token"].(string)
	refreshToken := data["refresh_token"].(string)
	
	return userID, accessToken, refreshToken
}

func getEnvWithDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func TestAuthIntegrationTestSuite(t *testing.T) {
	// Skip integration tests if TEST_INTEGRATION is not set
	if os.Getenv("TEST_INTEGRATION") == "" {
		t.Skip("Skipping integration tests. Set TEST_INTEGRATION=1 to run.")
	}
	
	suite.Run(t, new(AuthIntegrationTestSuite))
}
