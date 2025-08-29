package services

import (
	"context"
	"fmt"
	"strings"
	"time"

	"comfunds/internal/entities"
	"comfunds/internal/repositories"

	"github.com/google/uuid"
)

type CooperativeService interface {
	// FR-015 to FR-018: Cooperative Registration and Creation
	CreateCooperative(ctx context.Context, req *entities.CreateCooperativeRequest, creatorID uuid.UUID) (*entities.Cooperative, error)
	VerifyCooperativeRegistration(ctx context.Context, registrationNumber string) (bool, error)

	// FR-019: CRUD Operations
	GetCooperativeByID(ctx context.Context, id uuid.UUID) (*entities.Cooperative, error)
	GetAllCooperatives(ctx context.Context, page, limit int) ([]*entities.Cooperative, int, error)
	UpdateCooperative(ctx context.Context, id uuid.UUID, req *entities.UpdateCooperativeRequest, updaterID uuid.UUID) (*entities.Cooperative, error)
	DeleteCooperative(ctx context.Context, id uuid.UUID, deleterID uuid.UUID) error

	// FR-020: Project Approval/Rejection
	ApproveProject(ctx context.Context, cooperativeID, projectID, approverID uuid.UUID, comments string) error
	RejectProject(ctx context.Context, cooperativeID, projectID, approverID uuid.UUID, reason string) error
	GetPendingProjects(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.Project, int, error)

	// FR-021: Fund Monitoring
	GetFundTransfers(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]interface{}, int, error)
	GetProfitDistributions(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]interface{}, int, error)

	// FR-022: Member Registry
	GetCooperativeMembers(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.User, int, error)
	AddMember(ctx context.Context, cooperativeID, userID, adderID uuid.UUID) error
	RemoveMember(ctx context.Context, cooperativeID, userID, removerID uuid.UUID) error

	// FR-023: Investment Policies and Profit-Sharing Rules (integrated with dedicated services)
	SetInvestmentPolicy(ctx context.Context, cooperativeID uuid.UUID, policy *entities.InvestmentPolicy, setterID uuid.UUID) error
	GetInvestmentPolicy(ctx context.Context, cooperativeID uuid.UUID) (*entities.InvestmentPolicy, error)
	SetProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID, rules *entities.ProfitSharingRules, setterID uuid.UUID) error
	GetProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID) (*entities.ProfitSharingRules, error)

	// Integration with specialized services
	GetCooperativeManagementSummary(ctx context.Context, cooperativeID uuid.UUID) (map[string]interface{}, error)
}

type cooperativeService struct {
	cooperativeRepo         repositories.CooperativeRepository
	userRepo                repositories.UserRepositorySharded
	auditService            AuditService
	investmentPolicyService InvestmentPolicyService
	projectApprovalService  ProjectApprovalService
	fundMonitoringService   FundMonitoringService
	memberRegistryService   MemberRegistryService
}

func NewCooperativeService(
	cooperativeRepo repositories.CooperativeRepository,
	userRepo repositories.UserRepositorySharded,
	auditService AuditService,
	investmentPolicyService InvestmentPolicyService,
	projectApprovalService ProjectApprovalService,
	fundMonitoringService FundMonitoringService,
	memberRegistryService MemberRegistryService,
) CooperativeService {
	return &cooperativeService{
		cooperativeRepo:         cooperativeRepo,
		userRepo:                userRepo,
		auditService:            auditService,
		investmentPolicyService: investmentPolicyService,
		projectApprovalService:  projectApprovalService,
		fundMonitoringService:   fundMonitoringService,
		memberRegistryService:   memberRegistryService,
	}
}

func (s *cooperativeService) CreateCooperative(ctx context.Context, req *entities.CreateCooperativeRequest, creatorID uuid.UUID) (*entities.Cooperative, error) {
	// FR-016: Validate required fields
	if err := s.validateRequiredFields(req); err != nil {
		return nil, err
	}

	// FR-017: Verify legal registration status
	isValid, err := s.VerifyCooperativeRegistration(ctx, req.RegistrationNumber)
	if err != nil {
		return nil, fmt.Errorf("failed to verify registration: %w", err)
	}
	if !isValid {
		return nil, fmt.Errorf("invalid cooperative registration number")
	}

	// Check for duplicate registration number
	existing, _ := s.cooperativeRepo.GetByRegistrationNumber(ctx, req.RegistrationNumber)
	if existing != nil {
		return nil, fmt.Errorf("cooperative with registration number %s already exists", req.RegistrationNumber)
	}

	// Create cooperative entity
	cooperative := &entities.Cooperative{
		ID:                  uuid.New(),
		Name:                req.Name,
		RegistrationNumber:  req.RegistrationNumber,
		Address:             req.Address,
		Phone:               req.Phone,
		Email:               req.Email,
		BankAccount:         req.BankAccount,
		ProfitSharingPolicy: req.ProfitSharingPolicy,
		IsActive:            true,
	}

	// Create in repository
	createdCooperative, err := s.cooperativeRepo.Create(ctx, cooperative)
	if err != nil {
		return nil, fmt.Errorf("failed to create cooperative: %w", err)
	}

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityCooperative,
		EntityID:   createdCooperative.ID,
		Operation:  entities.AuditOperationCreate,
		UserID:     creatorID,
		NewValues:  createdCooperative,
		Status:     entities.AuditStatusSuccess,
	})

	return createdCooperative, nil
}

func (s *cooperativeService) VerifyCooperativeRegistration(ctx context.Context, registrationNumber string) (bool, error) {
	// FR-017: This would integrate with external registration verification system
	// For now, we'll implement basic validation

	// Check format (example: REG-YYYY-NNNNNN)
	if len(registrationNumber) < 10 {
		return false, fmt.Errorf("registration number too short")
	}

	if !strings.HasPrefix(registrationNumber, "REG-") {
		return false, fmt.Errorf("registration number must start with REG-")
	}

	// In a real implementation, this would call external APIs
	// to verify with government registration databases
	return true, nil
}

func (s *cooperativeService) GetCooperativeByID(ctx context.Context, id uuid.UUID) (*entities.Cooperative, error) {
	return s.cooperativeRepo.GetByID(ctx, id)
}

func (s *cooperativeService) GetAllCooperatives(ctx context.Context, page, limit int) ([]*entities.Cooperative, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	cooperatives, err := s.cooperativeRepo.GetAll(ctx, limit, (page-1)*limit)
	if err != nil {
		return nil, 0, err
	}

	total, err := s.cooperativeRepo.Count(ctx)
	if err != nil {
		return nil, 0, err
	}

	return cooperatives, total, nil
}

func (s *cooperativeService) UpdateCooperative(ctx context.Context, id uuid.UUID, req *entities.UpdateCooperativeRequest, updaterID uuid.UUID) (*entities.Cooperative, error) {
	// Get old data for audit
	oldCooperative, err := s.cooperativeRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	// Update fields
	if req.Name != "" {
		oldCooperative.Name = req.Name
	}
	if req.Address != "" {
		oldCooperative.Address = req.Address
	}
	if req.Phone != "" {
		oldCooperative.Phone = req.Phone
	}
	if req.Email != "" {
		oldCooperative.Email = req.Email
	}
	if req.BankAccount != "" {
		oldCooperative.BankAccount = req.BankAccount
	}

	updatedCooperative, err := s.cooperativeRepo.Update(ctx, id, oldCooperative)
	if err != nil {
		return nil, err
	}

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityCooperative,
		EntityID:   id,
		Operation:  entities.AuditOperationUpdate,
		UserID:     updaterID,
		Changes:    req,
		OldValues:  oldCooperative,
		NewValues:  updatedCooperative,
		Status:     entities.AuditStatusSuccess,
	})

	return updatedCooperative, nil
}

func (s *cooperativeService) DeleteCooperative(ctx context.Context, id uuid.UUID, deleterID uuid.UUID) error {
	// Get cooperative for audit
	cooperative, err := s.cooperativeRepo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	err = s.cooperativeRepo.Delete(ctx, id)
	if err != nil {
		return err
	}

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityCooperative,
		EntityID:   id,
		Operation:  entities.AuditOperationDelete,
		UserID:     deleterID,
		OldValues:  cooperative,
		Status:     entities.AuditStatusSuccess,
	})

	return nil
}

// FR-020: Project Approval/Rejection
func (s *cooperativeService) ApproveProject(ctx context.Context, cooperativeID, projectID, approverID uuid.UUID, comments string) error {
	// This would update project status and log the approval
	// Implementation depends on project repository which we'll need to create

	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   projectID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     approverID,
		Changes:    map[string]interface{}{"status": "approved", "comments": comments},
		Status:     entities.AuditStatusSuccess,
	})

	return fmt.Errorf("project approval functionality requires project repository implementation")
}

func (s *cooperativeService) RejectProject(ctx context.Context, cooperativeID, projectID, approverID uuid.UUID, reason string) error {
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   projectID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     approverID,
		Changes:    map[string]interface{}{"status": "rejected", "reason": reason},
		Status:     entities.AuditStatusSuccess,
	})

	return fmt.Errorf("project rejection functionality requires project repository implementation")
}

func (s *cooperativeService) GetPendingProjects(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.Project, int, error) {
	// Mock implementation - would require project repository
	return []*entities.Project{}, 0, nil
}

// FR-021: Fund Monitoring
func (s *cooperativeService) GetFundTransfers(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]interface{}, int, error) {
	// Mock implementation - would require fund transfer repository
	return []interface{}{}, 0, nil
}

func (s *cooperativeService) GetProfitDistributions(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]interface{}, int, error) {
	// Mock implementation - would require profit distribution repository
	return []interface{}{}, 0, nil
}

// FR-022: Member Registry (delegated to MemberRegistryService)
func (s *cooperativeService) GetCooperativeMembers(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.User, int, error) {
	return s.memberRegistryService.GetCooperativeMembers(ctx, cooperativeID, "active", page, limit)
}

func (s *cooperativeService) AddMember(ctx context.Context, cooperativeID, userID, adderID uuid.UUID) error {
	return s.memberRegistryService.AddMemberToCooperative(ctx, cooperativeID, userID, adderID, "basic")
}

func (s *cooperativeService) RemoveMember(ctx context.Context, cooperativeID, userID, removerID uuid.UUID) error {
	return s.memberRegistryService.RemoveMemberFromCooperative(ctx, cooperativeID, userID, removerID, "Administrative removal")
}

// FR-023: Investment Policies and Profit-Sharing Rules
func (s *cooperativeService) SetInvestmentPolicy(ctx context.Context, cooperativeID uuid.UUID, policy *entities.InvestmentPolicy, setterID uuid.UUID) error {
	// This would require updating cooperative's investment policy
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityCooperative,
		EntityID:   cooperativeID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     setterID,
		Changes:    map[string]interface{}{"action": "set_investment_policy"},
		NewValues:  policy,
		Status:     entities.AuditStatusSuccess,
	})

	return fmt.Errorf("investment policy functionality requires implementation")
}

func (s *cooperativeService) GetInvestmentPolicy(ctx context.Context, cooperativeID uuid.UUID) (*entities.InvestmentPolicy, error) {
	return nil, fmt.Errorf("investment policy functionality requires implementation")
}

func (s *cooperativeService) SetProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID, rules *entities.ProfitSharingRules, setterID uuid.UUID) error {
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityCooperative,
		EntityID:   cooperativeID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     setterID,
		Changes:    map[string]interface{}{"action": "set_profit_sharing_rules"},
		NewValues:  rules,
		Status:     entities.AuditStatusSuccess,
	})

	return fmt.Errorf("profit sharing rules functionality requires implementation")
}

func (s *cooperativeService) GetProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID) (*entities.ProfitSharingRules, error) {
	return nil, fmt.Errorf("profit sharing rules functionality requires implementation")
}

func (s *cooperativeService) GetCooperativeManagementSummary(ctx context.Context, cooperativeID uuid.UUID) (map[string]interface{}, error) {
	// Get cooperative basic info
	cooperative, err := s.cooperativeRepo.GetByID(ctx, cooperativeID)
	if err != nil {
		return nil, err
	}

	// Get member statistics
	memberStats, err := s.memberRegistryService.GetMemberStatistics(ctx, cooperativeID)
	if err != nil {
		memberStats = map[string]interface{}{"total_members": 0}
	}

	// Get fund summary (last 30 days)
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -30)
	fundSummary, err := s.fundMonitoringService.GetCooperativeFundSummary(ctx, cooperativeID, startDate, endDate)
	if err != nil {
		fundSummary = map[string]interface{}{"total_balance": 0}
	}

	// Get pending approvals
	pendingApprovals, _, err := s.projectApprovalService.GetPendingApprovals(ctx, cooperativeID, 1, 100)
	if err != nil {
		pendingApprovals = []*entities.ProjectApproval{}
	}

	summary := map[string]interface{}{
		"cooperative": map[string]interface{}{
			"id":                  cooperative.ID,
			"name":                cooperative.Name,
			"registration_number": cooperative.RegistrationNumber,
			"is_active":           cooperative.IsActive,
			"created_at":          cooperative.CreatedAt,
		},
		"members":           memberStats,
		"financial":         fundSummary,
		"pending_approvals": len(pendingApprovals),
		"summary_generated": time.Now(),
	}

	return summary, nil
}

// Helper method for FR-016: Validate required fields
func (s *cooperativeService) validateRequiredFields(req *entities.CreateCooperativeRequest) error {
	if req.Name == "" {
		return fmt.Errorf("cooperative name is required")
	}
	if req.RegistrationNumber == "" {
		return fmt.Errorf("registration number is required")
	}
	if req.Address == "" {
		return fmt.Errorf("address is required")
	}
	if req.Phone == "" {
		return fmt.Errorf("phone is required")
	}
	if req.Email == "" {
		return fmt.Errorf("email is required")
	}
	if req.BankAccount == "" {
		return fmt.Errorf("bank account is required")
	}
	return nil
}
