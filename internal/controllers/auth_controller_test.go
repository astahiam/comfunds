package controllers

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"comfunds/internal/entities"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// Mock service
type MockUserServiceAuth struct {
	mock.Mock
}

func (m *MockUserServiceAuth) Register(ctx context.Context, req *entities.CreateUserRequest) (*entities.User, string, string, error) {
	args := m.Called(ctx, req)
	return args.Get(0).(*entities.User), args.String(1), args.String(2), args.Error(3)
}

func (m *MockUserServiceAuth) Login(ctx context.Context, email, password string) (*entities.User, string, string, error) {
	args := m.Called(ctx, email, password)
	if args.Get(0) == nil {
		return nil, args.String(1), args.String(2), args.Error(3)
	}
	return args.Get(0).(*entities.User), args.String(1), args.String(2), args.Error(3)
}

func (m *MockUserServiceAuth) RefreshToken(ctx context.Context, refreshToken string) (string, error) {
	args := m.Called(ctx, refreshToken)
	return args.String(0), args.Error(1)
}

func (m *MockUserServiceAuth) GetUserByID(ctx context.Context, id uuid.UUID) (*entities.User, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.User), args.Error(1)
}

func (m *MockUserServiceAuth) GetUserByEmail(ctx context.Context, email string) (*entities.User, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.User), args.Error(1)
}

func (m *MockUserServiceAuth) GetAllUsers(ctx context.Context, page, limit int) ([]*entities.User, int, error) {
	args := m.Called(ctx, page, limit)
	return args.Get(0).([]*entities.User), args.Int(1), args.Error(2)
}

func (m *MockUserServiceAuth) UpdateUser(ctx context.Context, id uuid.UUID, req *entities.UpdateUserRequest) (*entities.User, error) {
	args := m.Called(ctx, id, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.User), args.Error(1)
}

func (m *MockUserServiceAuth) DeleteUser(ctx context.Context, id uuid.UUID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockUserServiceAuth) VerifyCooperativeMembership(ctx context.Context, userID, cooperativeID uuid.UUID) (bool, error) {
	args := m.Called(ctx, userID, cooperativeID)
	return args.Bool(0), args.Error(1)
}

func setupAuthController() (*AuthController, *MockUserServiceAuth) {
	mockService := new(MockUserServiceAuth)
	controller := NewAuthController(mockService)
	return controller, mockService
}

func TestAuthController_RegisterUser_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, mockService := setupAuthController()

	userID := uuid.New()
	req := entities.CreateUserRequest{
		Email:    "test@example.com",
		Name:     "Test User",
		Password: "TestPassword123!",
		Phone:    "+1234567890",
		Address:  "123 Test St",
		Roles:    []string{"guest"},
	}

	expectedUser := &entities.User{
		ID:      userID,
		Email:   req.Email,
		Name:    req.Name,
		Phone:   req.Phone,
		Address: req.Address,
		Roles:   req.Roles,
	}

	mockService.On("Register", mock.Anything, &req).Return(
		expectedUser, "access_token", "refresh_token", nil)

	// Create request
	reqBody, _ := json.Marshal(req)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/auth/register", bytes.NewBuffer(reqBody))
	c.Request.Header.Set("Content-Type", "application/json")

	// Execute
	controller.RegisterUser(c)

	// Assertions
	assert.Equal(t, http.StatusCreated, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "success", response["status"])
	assert.Contains(t, response["data"], "access_token")
	assert.Contains(t, response["data"], "refresh_token")

	mockService.AssertExpectations(t)
}

func TestAuthController_RegisterUser_ValidationError(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupAuthController()

	// Invalid request (missing required fields)
	req := entities.CreateUserRequest{
		Email: "invalid-email", // Invalid email format
	}

	reqBody, _ := json.Marshal(req)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/auth/register", bytes.NewBuffer(reqBody))
	c.Request.Header.Set("Content-Type", "application/json")

	// Execute
	controller.RegisterUser(c)

	// Assertions
	assert.Equal(t, http.StatusBadRequest, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "error", response["status"])
}

func TestAuthController_RegisterUser_UserExists(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, mockService := setupAuthController()

	req := entities.CreateUserRequest{
		Email:    "test@example.com",
		Name:     "Test User",
		Password: "TestPassword123!",
		Phone:    "+1234567890",
		Address:  "123 Test St",
		Roles:    []string{"guest"},
	}

	mockService.On("Register", mock.Anything, &req).Return(
		(*entities.User)(nil), "", "", errors.New("user with email test@example.com already exists"))

	reqBody, _ := json.Marshal(req)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/auth/register", bytes.NewBuffer(reqBody))
	c.Request.Header.Set("Content-Type", "application/json")

	// Execute
	controller.RegisterUser(c)

	// Assertions
	assert.Equal(t, http.StatusConflict, w.Code)

	mockService.AssertExpectations(t)
}

func TestAuthController_LoginUser_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, mockService := setupAuthController()

	userID := uuid.New()
	loginReq := map[string]string{
		"email":    "test@example.com",
		"password": "TestPassword123!",
	}

	expectedUser := &entities.User{
		ID:    userID,
		Email: loginReq["email"],
		Name:  "Test User",
	}

	mockService.On("Login", mock.Anything, loginReq["email"], loginReq["password"]).Return(
		expectedUser, "access_token", "refresh_token", nil)

	reqBody, _ := json.Marshal(loginReq)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/auth/login", bytes.NewBuffer(reqBody))
	c.Request.Header.Set("Content-Type", "application/json")

	// Execute
	controller.LoginUser(c)

	// Assertions
	assert.Equal(t, http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "success", response["status"])
	assert.Contains(t, response["data"], "access_token")

	mockService.AssertExpectations(t)
}

func TestAuthController_LoginUser_InvalidCredentials(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, mockService := setupAuthController()

	loginReq := map[string]string{
		"email":    "test@example.com",
		"password": "wrongpassword",
	}

	mockService.On("Login", mock.Anything, loginReq["email"], loginReq["password"]).Return(
		(*entities.User)(nil), "", "", errors.New("invalid credentials"))

	reqBody, _ := json.Marshal(loginReq)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/auth/login", bytes.NewBuffer(reqBody))
	c.Request.Header.Set("Content-Type", "application/json")

	// Execute
	controller.LoginUser(c)

	// Assertions
	assert.Equal(t, http.StatusUnauthorized, w.Code)

	mockService.AssertExpectations(t)
}

func TestAuthController_RefreshToken_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, mockService := setupAuthController()

	refreshReq := map[string]string{
		"refresh_token": "valid_refresh_token",
	}

	mockService.On("RefreshToken", mock.Anything, refreshReq["refresh_token"]).Return(
		"new_access_token", nil)

	reqBody, _ := json.Marshal(refreshReq)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/auth/refresh", bytes.NewBuffer(reqBody))
	c.Request.Header.Set("Content-Type", "application/json")

	// Execute
	controller.RefreshToken(c)

	// Assertions
	assert.Equal(t, http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "success", response["status"])
	
	data := response["data"].(map[string]interface{})
	assert.Equal(t, "new_access_token", data["access_token"])

	mockService.AssertExpectations(t)
}

func TestAuthController_GetProfile_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, mockService := setupAuthController()

	userID := uuid.New()
	expectedUser := &entities.User{
		ID:    userID,
		Email: "test@example.com",
		Name:  "Test User",
	}

	mockService.On("GetUserByID", mock.Anything, userID).Return(expectedUser, nil)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/auth/profile", nil)
	c.Set("user_id", userID) // Simulate authenticated user

	// Execute
	controller.GetProfile(c)

	// Assertions
	assert.Equal(t, http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "success", response["status"])

	mockService.AssertExpectations(t)
}

func TestAuthController_GetProfile_Unauthenticated(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupAuthController()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/auth/profile", nil)
	// No user_id set in context

	// Execute
	controller.GetProfile(c)

	// Assertions
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}
