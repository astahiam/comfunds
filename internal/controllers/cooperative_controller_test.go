package controllers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"comfunds/internal/entities"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockCooperativeService for testing
type MockCooperativeService struct {
	mock.Mock
}

func (m *MockCooperativeService) CreateCooperative(ctx context.Context, req *entities.CreateCooperativeRequest, creatorID uuid.UUID) (*entities.Cooperative, error) {
	args := m.Called(ctx, req, creatorID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Cooperative), args.Error(1)
}

func (m *MockCooperativeService) VerifyCooperativeRegistration(ctx context.Context, registrationNumber string) (bool, error) {
	args := m.Called(ctx, registrationNumber)
	return args.Bool(0), args.Error(1)
}

func (m *MockCooperativeService) GetCooperativeByID(ctx context.Context, id uuid.UUID) (*entities.Cooperative, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Cooperative), args.Error(1)
}

func (m *MockCooperativeService) GetAllCooperatives(ctx context.Context, page, limit int) ([]*entities.Cooperative, int, error) {
	args := m.Called(ctx, page, limit)
	return args.Get(0).([]*entities.Cooperative), args.Int(1), args.Error(2)
}

func (m *MockCooperativeService) UpdateCooperative(ctx context.Context, id uuid.UUID, req *entities.UpdateCooperativeRequest, updaterID uuid.UUID) (*entities.Cooperative, error) {
	args := m.Called(ctx, id, req, updaterID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Cooperative), args.Error(1)
}

func (m *MockCooperativeService) DeleteCooperative(ctx context.Context, id uuid.UUID, deleterID uuid.UUID) error {
	args := m.Called(ctx, id, deleterID)
	return args.Error(0)
}

func (m *MockCooperativeService) ApproveProject(ctx context.Context, cooperativeID, projectID, approverID uuid.UUID, comments string) error {
	args := m.Called(ctx, cooperativeID, projectID, approverID, comments)
	return args.Error(0)
}

func (m *MockCooperativeService) RejectProject(ctx context.Context, cooperativeID, projectID, approverID uuid.UUID, reason string) error {
	args := m.Called(ctx, cooperativeID, projectID, approverID, reason)
	return args.Error(0)
}

func (m *MockCooperativeService) GetPendingProjects(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.Project, int, error) {
	args := m.Called(ctx, cooperativeID, page, limit)
	return args.Get(0).([]*entities.Project), args.Int(1), args.Error(2)
}

func (m *MockCooperativeService) GetFundTransfers(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]interface{}, int, error) {
	args := m.Called(ctx, cooperativeID, page, limit)
	return args.Get(0).([]interface{}), args.Int(1), args.Error(2)
}

func (m *MockCooperativeService) GetProfitDistributions(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]interface{}, int, error) {
	args := m.Called(ctx, cooperativeID, page, limit)
	return args.Get(0).([]interface{}), args.Int(1), args.Error(2)
}

func (m *MockCooperativeService) GetCooperativeMembers(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.User, int, error) {
	args := m.Called(ctx, cooperativeID, page, limit)
	return args.Get(0).([]*entities.User), args.Int(1), args.Error(2)
}

func (m *MockCooperativeService) AddMember(ctx context.Context, cooperativeID, userID, adderID uuid.UUID) error {
	args := m.Called(ctx, cooperativeID, userID, adderID)
	return args.Error(0)
}

func (m *MockCooperativeService) RemoveMember(ctx context.Context, cooperativeID, userID, removerID uuid.UUID) error {
	args := m.Called(ctx, cooperativeID, userID, removerID)
	return args.Error(0)
}

func (m *MockCooperativeService) SetInvestmentPolicy(ctx context.Context, cooperativeID uuid.UUID, policy *entities.InvestmentPolicy, setterID uuid.UUID) error {
	args := m.Called(ctx, cooperativeID, policy, setterID)
	return args.Error(0)
}

func (m *MockCooperativeService) GetInvestmentPolicy(ctx context.Context, cooperativeID uuid.UUID) (*entities.InvestmentPolicy, error) {
	args := m.Called(ctx, cooperativeID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.InvestmentPolicy), args.Error(1)
}

func (m *MockCooperativeService) SetProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID, rules *entities.ProfitSharingRules, setterID uuid.UUID) error {
	args := m.Called(ctx, cooperativeID, rules, setterID)
	return args.Error(0)
}

func (m *MockCooperativeService) GetProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID) (*entities.ProfitSharingRules, error) {
	args := m.Called(ctx, cooperativeID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.ProfitSharingRules), args.Error(1)
}

func TestCooperativeController_CreateCooperative_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)

	mockService := new(MockCooperativeService)
	controller := NewCooperativeController(mockService)

	userID := uuid.New()
	req := entities.CreateCooperativeRequest{
		Name:               "Test Cooperative",
		RegistrationNumber: "REG-2024-123456",
		Address:            "123 Test Street",
		Phone:              "+1234567890",
		Email:              "test@cooperative.com",
		BankAccount:        "1234567890",
	}

	expectedCooperative := &entities.Cooperative{
		ID:                 uuid.New(),
		Name:               req.Name,
		RegistrationNumber: req.RegistrationNumber,
		Address:            req.Address,
		Phone:              req.Phone,
		Email:              req.Email,
		BankAccount:        req.BankAccount,
		IsActive:           true,
	}

	mockService.On("CreateCooperative", mock.Anything, &req, userID).Return(expectedCooperative, nil)

	// Create request
	reqJSON, _ := json.Marshal(req)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/cooperatives", bytes.NewBuffer(reqJSON))
	c.Request.Header.Set("Content-Type", "application/json")

	// Set auth context
	c.Set("user_id", userID)
	c.Set("user_roles", []string{"admin"})

	controller.CreateCooperative(c)

	assert.Equal(t, http.StatusCreated, w.Code)
	mockService.AssertExpectations(t)
}

func TestCooperativeController_CreateCooperative_Unauthorized(t *testing.T) {
	gin.SetMode(gin.TestMode)

	mockService := new(MockCooperativeService)
	controller := NewCooperativeController(mockService)

	userID := uuid.New()
	req := entities.CreateCooperativeRequest{
		Name:               "Test Cooperative",
		RegistrationNumber: "REG-2024-123456",
		Address:            "123 Test Street",
		Phone:              "+1234567890",
		Email:              "test@cooperative.com",
		BankAccount:        "1234567890",
	}

	// Create request
	reqJSON, _ := json.Marshal(req)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("POST", "/cooperatives", bytes.NewBuffer(reqJSON))
	c.Request.Header.Set("Content-Type", "application/json")

	// Set auth context with non-admin role
	c.Set("user_id", userID)
	c.Set("user_roles", []string{"member"})

	controller.CreateCooperative(c)

	assert.Equal(t, http.StatusForbidden, w.Code)
	// No service calls should be made
	mockService.AssertNotCalled(t, "CreateCooperative")
}

func TestCooperativeController_GetCooperatives_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)

	mockService := new(MockCooperativeService)
	controller := NewCooperativeController(mockService)

	expectedCooperatives := []*entities.Cooperative{
		{
			ID:                 uuid.New(),
			Name:               "Cooperative 1",
			RegistrationNumber: "REG-2024-123456",
		},
		{
			ID:                 uuid.New(),
			Name:               "Cooperative 2",
			RegistrationNumber: "REG-2024-123457",
		},
	}

	mockService.On("GetAllCooperatives", mock.Anything, 1, 10).Return(expectedCooperatives, 2, nil)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/cooperatives", nil)

	controller.GetCooperatives(c)

	assert.Equal(t, http.StatusOK, w.Code)
	mockService.AssertExpectations(t)
}

func TestCooperativeController_GetCooperative_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)

	mockService := new(MockCooperativeService)
	controller := NewCooperativeController(mockService)

	cooperativeID := uuid.New()
	expectedCooperative := &entities.Cooperative{
		ID:                 cooperativeID,
		Name:               "Test Cooperative",
		RegistrationNumber: "REG-2024-123456",
	}

	mockService.On("GetCooperativeByID", mock.Anything, cooperativeID).Return(expectedCooperative, nil)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/cooperatives/"+cooperativeID.String(), nil)
	c.Params = []gin.Param{{Key: "id", Value: cooperativeID.String()}}

	controller.GetCooperative(c)

	assert.Equal(t, http.StatusOK, w.Code)
	mockService.AssertExpectations(t)
}
