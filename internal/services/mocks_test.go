package services

import (
	"context"

	"comfunds/internal/entities"

	"github.com/google/uuid"
	"github.com/stretchr/testify/mock"
)

// MockUserRepositorySharded for testing
type MockUserRepositorySharded struct {
	mock.Mock
}

func (m *MockUserRepositorySharded) Create(ctx context.Context, user *entities.User) (*entities.User, error) {
	args := m.Called(ctx, user)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.User), args.Error(1)
}

func (m *MockUserRepositorySharded) GetByID(ctx context.Context, id uuid.UUID) (*entities.User, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.User), args.Error(1)
}

func (m *MockUserRepositorySharded) GetByEmail(ctx context.Context, email string) (*entities.User, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.User), args.Error(1)
}

func (m *MockUserRepositorySharded) Update(ctx context.Context, id uuid.UUID, user *entities.User) (*entities.User, error) {
	args := m.Called(ctx, id, user)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.User), args.Error(1)
}

func (m *MockUserRepositorySharded) Delete(ctx context.Context, id uuid.UUID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockUserRepositorySharded) GetAll(ctx context.Context, limit, offset int) ([]*entities.User, error) {
	args := m.Called(ctx, limit, offset)
	return args.Get(0).([]*entities.User), args.Error(1)
}

func (m *MockUserRepositorySharded) GetByCooperativeID(ctx context.Context, cooperativeID uuid.UUID, limit, offset int) ([]*entities.User, error) {
	args := m.Called(ctx, cooperativeID, limit, offset)
	return args.Get(0).([]*entities.User), args.Error(1)
}

func (m *MockUserRepositorySharded) Count(ctx context.Context) (int, error) {
	args := m.Called(ctx)
	return args.Int(0), args.Error(1)
}

// MockCooperativeRepository for testing
type MockCooperativeRepository struct {
	mock.Mock
}

func (m *MockCooperativeRepository) Create(ctx context.Context, cooperative *entities.Cooperative) (*entities.Cooperative, error) {
	args := m.Called(ctx, cooperative)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Cooperative), args.Error(1)
}

func (m *MockCooperativeRepository) GetByID(ctx context.Context, id uuid.UUID) (*entities.Cooperative, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Cooperative), args.Error(1)
}

func (m *MockCooperativeRepository) GetByRegistrationNumber(ctx context.Context, regNumber string) (*entities.Cooperative, error) {
	args := m.Called(ctx, regNumber)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Cooperative), args.Error(1)
}

func (m *MockCooperativeRepository) GetAll(ctx context.Context, limit, offset int) ([]*entities.Cooperative, error) {
	args := m.Called(ctx, limit, offset)
	return args.Get(0).([]*entities.Cooperative), args.Error(1)
}

func (m *MockCooperativeRepository) Update(ctx context.Context, id uuid.UUID, cooperative *entities.Cooperative) (*entities.Cooperative, error) {
	args := m.Called(ctx, id, cooperative)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.Cooperative), args.Error(1)
}

func (m *MockCooperativeRepository) Delete(ctx context.Context, id uuid.UUID) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func (m *MockCooperativeRepository) Count(ctx context.Context) (int, error) {
	args := m.Called(ctx)
	return args.Int(0), args.Error(1)
}

// MockAuditRepository for testing
type MockAuditRepository struct {
	mock.Mock
}

func (m *MockAuditRepository) Create(ctx context.Context, auditLog *entities.AuditLog) error {
	args := m.Called(ctx, auditLog)
	return args.Error(0)
}

func (m *MockAuditRepository) GetByFilter(ctx context.Context, filter *entities.AuditLogFilter) ([]*entities.AuditLog, int, error) {
	args := m.Called(ctx, filter)
	return args.Get(0).([]*entities.AuditLog), args.Int(1), args.Error(2)
}

func (m *MockAuditRepository) GetByID(ctx context.Context, id string) (*entities.AuditLog, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.AuditLog), args.Error(1)
}

func (m *MockAuditRepository) DeleteOlderThan(ctx context.Context, days int) (int, error) {
	args := m.Called(ctx, days)
	return args.Int(0), args.Error(1)
}

// MockAuditService for testing
type MockAuditService struct {
	mock.Mock
}

func (m *MockAuditService) LogOperation(ctx context.Context, req *LogOperationRequest) error {
	args := m.Called(ctx, req)
	return args.Error(0)
}

func (m *MockAuditService) GetAuditLogs(ctx context.Context, filter *entities.AuditLogFilter) ([]*entities.AuditLog, int, error) {
	args := m.Called(ctx, filter)
	return args.Get(0).([]*entities.AuditLog), args.Int(1), args.Error(2)
}

func (m *MockAuditService) GetEntityAuditTrail(ctx context.Context, entityType string, entityID uuid.UUID, page, limit int) ([]*entities.AuditLog, int, error) {
	args := m.Called(ctx, entityType, entityID, page, limit)
	return args.Get(0).([]*entities.AuditLog), args.Int(1), args.Error(2)
}

func (m *MockAuditService) GetUserActivity(ctx context.Context, userID uuid.UUID, page, limit int) ([]*entities.AuditLog, int, error) {
	args := m.Called(ctx, userID, page, limit)
	return args.Get(0).([]*entities.AuditLog), args.Int(1), args.Error(2)
}

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

func (m *MockCooperativeService) GetCooperativeManagementSummary(ctx context.Context, cooperativeID uuid.UUID) (map[string]interface{}, error) {
	args := m.Called(ctx, cooperativeID)
	return args.Get(0).(map[string]interface{}), args.Error(1)
}

// Mock service interfaces for specialized services
type MockInvestmentPolicyService struct {
	mock.Mock
}

func (m *MockInvestmentPolicyService) CreatePolicy(ctx context.Context, req *entities.CreateInvestmentPolicyRequest, creatorID uuid.UUID) (*entities.InvestmentPolicy, error) {
	args := m.Called(ctx, req, creatorID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.InvestmentPolicy), args.Error(1)
}

func (m *MockInvestmentPolicyService) CreateInvestmentPolicy(ctx context.Context, req *entities.CreateInvestmentPolicyRequest, creatorID uuid.UUID) (*entities.InvestmentPolicy, error) {
	args := m.Called(ctx, req, creatorID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*entities.InvestmentPolicy), args.Error(1)
}

type MockProjectApprovalService struct {
	mock.Mock
}

func (m *MockProjectApprovalService) ApproveProject(ctx context.Context, projectID, approverID uuid.UUID, comments string) error {
	args := m.Called(ctx, projectID, approverID, comments)
	return args.Error(0)
}

func (m *MockProjectApprovalService) CalculateApprovalScore(ctx context.Context, projectID uuid.UUID) (float64, error) {
	args := m.Called(ctx, projectID)
	return args.Get(0).(float64), args.Error(1)
}

type MockFundMonitoringService struct {
	mock.Mock
}

func (m *MockFundMonitoringService) MonitorFunds(ctx context.Context, cooperativeID uuid.UUID) error {
	args := m.Called(ctx, cooperativeID)
	return args.Error(0)
}

func (m *MockFundMonitoringService) ApproveProfitDistribution(ctx context.Context, distributionID uuid.UUID, approverID uuid.UUID) error {
	args := m.Called(ctx, distributionID, approverID)
	return args.Error(0)
}

type MockMemberRegistryService struct {
	mock.Mock
}

func (m *MockMemberRegistryService) RegisterMember(ctx context.Context, cooperativeID, userID, registrarID uuid.UUID) error {
	args := m.Called(ctx, cooperativeID, userID, registrarID)
	return args.Error(0)
}

func (m *MockMemberRegistryService) AddMemberToCooperative(ctx context.Context, cooperativeID, userID, adderID uuid.UUID) error {
	args := m.Called(ctx, cooperativeID, userID, adderID)
	return args.Error(0)
}
