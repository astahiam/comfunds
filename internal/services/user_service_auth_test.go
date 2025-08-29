package services

import (
	"context"
	"errors"
	"testing"
	"time"

	"comfunds/internal/auth"
	"comfunds/internal/entities"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"golang.org/x/crypto/bcrypt"
)

// Mocks are now in mocks_test.go to avoid redeclaration

func TestUserServiceAuth_Register_Success(t *testing.T) {
	mockUserRepo := new(MockUserRepositorySharded)
	mockCooperativeRepo := new(MockCooperativeRepository)
	jwtManager := auth.NewJWTManager("test-secret", time.Hour)

	service := NewUserServiceAuth(mockUserRepo, mockCooperativeRepo, jwtManager)

	cooperativeID := uuid.New()
	req := &entities.CreateUserRequest{
		Email:         "test@example.com",
		Name:          "Test User",
		Password:      "TestPassword123!",
		Phone:         "+1234567890",
		Address:       "123 Test St",
		CooperativeID: &cooperativeID,
		Roles:         []string{"member"},
	}

	cooperative := &entities.Cooperative{
		ID:       cooperativeID,
		IsActive: true,
	}

	expectedUser := &entities.User{
		ID:            uuid.New(),
		Email:         req.Email,
		Name:          req.Name,
		Phone:         req.Phone,
		Address:       req.Address,
		CooperativeID: req.CooperativeID,
		Roles:         req.Roles,
		IsActive:      true,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	// Mock expectations
	mockUserRepo.On("GetByEmail", mock.Anything, req.Email).Return(nil, errors.New("user not found"))
	mockCooperativeRepo.On("GetByID", mock.Anything, cooperativeID).Return(cooperative, nil)
	mockUserRepo.On("Create", mock.Anything, mock.AnythingOfType("*entities.User")).Return(expectedUser, nil)

	// Execute
	user, accessToken, refreshToken, err := service.Register(context.Background(), req)

	// Assertions
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.NotEmpty(t, accessToken)
	assert.NotEmpty(t, refreshToken)
	assert.Equal(t, req.Email, user.Email)
	assert.Equal(t, req.Name, user.Name)

	mockUserRepo.AssertExpectations(t)
	mockCooperativeRepo.AssertExpectations(t)
}

func TestUserServiceAuth_Register_UserAlreadyExists(t *testing.T) {
	mockUserRepo := new(MockUserRepositorySharded)
	mockCooperativeRepo := new(MockCooperativeRepository)
	jwtManager := auth.NewJWTManager("test-secret", time.Hour)

	service := NewUserServiceAuth(mockUserRepo, mockCooperativeRepo, jwtManager)

	req := &entities.CreateUserRequest{
		Email:    "test@example.com",
		Name:     "Test User",
		Password: "TestPassword123!",
		Phone:    "+1234567890",
		Address:  "123 Test St",
		Roles:    []string{"guest"},
	}

	existingUser := &entities.User{
		ID:    uuid.New(),
		Email: req.Email,
	}

	// Mock expectations
	mockUserRepo.On("GetByEmail", mock.Anything, req.Email).Return(existingUser, nil)

	// Execute
	user, accessToken, refreshToken, err := service.Register(context.Background(), req)

	// Assertions
	assert.Error(t, err)
	assert.Nil(t, user)
	assert.Empty(t, accessToken)
	assert.Empty(t, refreshToken)
	assert.Contains(t, err.Error(), "already exists")

	mockUserRepo.AssertExpectations(t)
}

func TestUserServiceAuth_Register_WeakPassword(t *testing.T) {
	mockUserRepo := new(MockUserRepositorySharded)
	mockCooperativeRepo := new(MockCooperativeRepository)
	jwtManager := auth.NewJWTManager("test-secret", time.Hour)

	service := NewUserServiceAuth(mockUserRepo, mockCooperativeRepo, jwtManager)

	req := &entities.CreateUserRequest{
		Email:    "test@example.com",
		Name:     "Test User",
		Password: "weak", // Weak password
		Phone:    "+1234567890",
		Address:  "123 Test St",
		Roles:    []string{"guest"},
	}

	// Mock expectations
	mockUserRepo.On("GetByEmail", mock.Anything, req.Email).Return(nil, errors.New("user not found"))

	// Execute
	user, accessToken, refreshToken, err := service.Register(context.Background(), req)

	// Assertions
	assert.Error(t, err)
	assert.Nil(t, user)
	assert.Empty(t, accessToken)
	assert.Empty(t, refreshToken)
	assert.Contains(t, err.Error(), "password")

	mockUserRepo.AssertExpectations(t)
}

func TestUserServiceAuth_Login_Success(t *testing.T) {
	mockUserRepo := new(MockUserRepositorySharded)
	mockCooperativeRepo := new(MockCooperativeRepository)
	jwtManager := auth.NewJWTManager("test-secret", time.Hour)

	service := NewUserServiceAuth(mockUserRepo, mockCooperativeRepo, jwtManager)

	email := "test@example.com"
	password := "TestPassword123!"

	// Generate a proper hash for the test password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	assert.NoError(t, err)

	user := &entities.User{
		ID:       uuid.New(),
		Email:    email,
		Password: string(hashedPassword),
		Roles:    []string{"member"},
		IsActive: true,
	}

	// Mock expectations
	mockUserRepo.On("GetByEmail", mock.Anything, email).Return(user, nil)

	// Execute
	returnedUser, accessToken, refreshToken, err := service.Login(context.Background(), email, password)

	// Assertions
	assert.NoError(t, err)
	assert.NotNil(t, returnedUser)
	assert.NotEmpty(t, accessToken)
	assert.NotEmpty(t, refreshToken)
	assert.Equal(t, user.ID, returnedUser.ID)

	mockUserRepo.AssertExpectations(t)
}

func TestUserServiceAuth_Login_InvalidCredentials(t *testing.T) {
	mockUserRepo := new(MockUserRepositorySharded)
	mockCooperativeRepo := new(MockCooperativeRepository)
	jwtManager := auth.NewJWTManager("test-secret", time.Hour)

	service := NewUserServiceAuth(mockUserRepo, mockCooperativeRepo, jwtManager)

	email := "test@example.com"
	password := "wrongpassword"

	// Mock expectations
	mockUserRepo.On("GetByEmail", mock.Anything, email).Return(nil, errors.New("user not found"))

	// Execute
	user, accessToken, refreshToken, err := service.Login(context.Background(), email, password)

	// Assertions
	assert.Error(t, err)
	assert.Nil(t, user)
	assert.Empty(t, accessToken)
	assert.Empty(t, refreshToken)
	assert.Contains(t, err.Error(), "invalid credentials")

	mockUserRepo.AssertExpectations(t)
}

func TestUserServiceAuth_RefreshToken_Success(t *testing.T) {
	mockUserRepo := new(MockUserRepositorySharded)
	mockCooperativeRepo := new(MockCooperativeRepository)
	jwtManager := auth.NewJWTManager("test-secret", time.Hour)

	service := NewUserServiceAuth(mockUserRepo, mockCooperativeRepo, jwtManager)

	userID := uuid.New()
	user := &entities.User{
		ID:       userID,
		Email:    "test@example.com",
		Roles:    []string{"member"},
		IsActive: true,
	}

	// Generate a valid refresh token
	refreshToken, err := jwtManager.GenerateRefreshToken(userID)
	assert.NoError(t, err)

	// Mock expectations
	mockUserRepo.On("GetByID", mock.Anything, userID).Return(user, nil)

	// Execute
	accessToken, err := service.RefreshToken(context.Background(), refreshToken)

	// Assertions
	assert.NoError(t, err)
	assert.NotEmpty(t, accessToken)

	mockUserRepo.AssertExpectations(t)
}

func TestUserServiceAuth_ValidatePasswordComplexity(t *testing.T) {
	mockUserRepo := new(MockUserRepositorySharded)
	mockCooperativeRepo := new(MockCooperativeRepository)
	jwtManager := auth.NewJWTManager("test-secret", time.Hour)

	service := NewUserServiceAuth(mockUserRepo, mockCooperativeRepo, jwtManager).(*userServiceAuth)

	tests := []struct {
		password    string
		shouldFail  bool
		description string
	}{
		{"TestPassword123!", false, "valid password"},
		{"short", true, "too short"},
		{"onlylowercase123!", true, "no uppercase"},
		{"ONLYUPPERCASE123!", true, "no lowercase"},
		{"NoDigitsHere!", true, "no digits"},
		{"NoSpecialChars123", true, "no special characters"},
		{"ValidPassword123!", false, "valid complex password"},
	}

	for _, test := range tests {
		t.Run(test.description, func(t *testing.T) {
			err := service.validatePasswordComplexity(test.password)
			if test.shouldFail {
				assert.Error(t, err, "Password should be invalid: %s", test.password)
			} else {
				assert.NoError(t, err, "Password should be valid: %s", test.password)
			}
		})
	}
}
