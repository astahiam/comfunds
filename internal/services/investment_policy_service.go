package services

import (
	"context"
	"fmt"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
)

type InvestmentPolicyService interface {
	// FR-023: Investment Policy Management
	CreateInvestmentPolicy(ctx context.Context, cooperativeID uuid.UUID, req *entities.CreateInvestmentPolicyRequest, creatorID uuid.UUID) (*entities.InvestmentPolicyExtended, error)
	GetInvestmentPolicy(ctx context.Context, cooperativeID, policyID uuid.UUID) (*entities.InvestmentPolicyExtended, error)
	GetActiveInvestmentPolicies(ctx context.Context, cooperativeID uuid.UUID) ([]*entities.InvestmentPolicyExtended, error)
	UpdateInvestmentPolicy(ctx context.Context, cooperativeID, policyID uuid.UUID, req *entities.UpdateInvestmentPolicyRequest, updaterID uuid.UUID) (*entities.InvestmentPolicyExtended, error)
	DeactivateInvestmentPolicy(ctx context.Context, cooperativeID, policyID, deactivatorID uuid.UUID) error
	
	// FR-023: Profit Sharing Rules Management
	CreateProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID, req *entities.CreateProfitSharingRulesRequest, creatorID uuid.UUID) (*entities.ProfitSharingRulesExtended, error)
	GetProfitSharingRules(ctx context.Context, cooperativeID, rulesID uuid.UUID) (*entities.ProfitSharingRulesExtended, error)
	GetActiveProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID) ([]*entities.ProfitSharingRulesExtended, error)
	UpdateProfitSharingRules(ctx context.Context, cooperativeID, rulesID uuid.UUID, req *entities.UpdateProfitSharingRulesRequest, updaterID uuid.UUID) (*entities.ProfitSharingRulesExtended, error)
	DeactivateProfitSharingRules(ctx context.Context, cooperativeID, rulesID, deactivatorID uuid.UUID) error
	
	// Validation and compliance
	ValidatePolicyCompliance(ctx context.Context, projectID, policyID uuid.UUID) (bool, []string, error)
	ValidateInvestmentAmount(ctx context.Context, cooperativeID uuid.UUID, amount float64) (bool, string, error)
	ValidateInvestorEligibility(ctx context.Context, cooperativeID, userID uuid.UUID) (bool, []string, error)
}

type investmentPolicyService struct {
	auditService AuditService
}

func NewInvestmentPolicyService(auditService AuditService) InvestmentPolicyService {
	return &investmentPolicyService{
		auditService: auditService,
	}
}

func (s *investmentPolicyService) CreateInvestmentPolicy(ctx context.Context, cooperativeID uuid.UUID, req *entities.CreateInvestmentPolicyRequest, creatorID uuid.UUID) (*entities.InvestmentPolicyExtended, error) {
	// Validate percentage shares
	if err := s.validateInvestmentPolicy(req); err != nil {
		return nil, err
	}

	policy := &entities.InvestmentPolicyExtended{
		ID:                    uuid.New(),
		CooperativeID:         cooperativeID,
		Name:                  req.Name,
		Description:           req.Description,
		MinInvestmentAmount:   req.MinInvestmentAmount,
		MaxInvestmentAmount:   req.MaxInvestmentAmount,
		AllowedSectors:        req.AllowedSectors,
		RiskLevels:            req.RiskLevels,
		ShariaCompliantOnly:   req.ShariaCompliantOnly,
		MaxProjectDuration:    req.MaxProjectDuration,
		RequiredDocuments:     req.RequiredDocuments,
		ApprovalThreshold:     req.ApprovalThreshold,
		CustomRules:           req.CustomRules,
		InvestorEligibility:   req.InvestorEligibility,
		WithdrawalPenalty:     req.WithdrawalPenalty,
		WithdrawalNoticeDays:  req.WithdrawalNoticeDays,
		IsActive:              true,
		EffectiveDate:         req.EffectiveDate,
		ExpiryDate:            req.ExpiryDate,
		CreatedBy:             creatorID,
		CreatedAt:             time.Now(),
		UpdatedAt:             time.Now(),
	}

	// In a real implementation, save to repository
	// createdPolicy, err := s.policyRepo.CreateInvestmentPolicy(ctx, policy)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityCooperative,
		EntityID:   cooperativeID,
		Operation:  entities.AuditOperationCreate,
		UserID:     creatorID,
		Changes:    map[string]interface{}{"action": "create_investment_policy", "policy_id": policy.ID},
		NewValues:  policy,
		Status:     entities.AuditStatusSuccess,
	})

	return policy, nil
}

func (s *investmentPolicyService) CreateProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID, req *entities.CreateProfitSharingRulesRequest, creatorID uuid.UUID) (*entities.ProfitSharingRulesExtended, error) {
	// Validate percentage shares sum to 100%
	if err := s.validateProfitSharingRules(req); err != nil {
		return nil, err
	}

	rules := &entities.ProfitSharingRulesExtended{
		ID:                    uuid.New(),
		CooperativeID:         cooperativeID,
		Name:                  req.Name,
		Description:           req.Description,
		InvestorShare:         req.InvestorShare,
		CooperativeShare:      req.CooperativeShare,
		BusinessOwnerShare:    req.BusinessOwnerShare,
		AdminFee:              req.AdminFee,
		DistributionMethod:    req.DistributionMethod,
		DistributionDay:       req.DistributionDay,
		MinProfitThreshold:    req.MinProfitThreshold,
		MaxDistributionAmount: req.MaxDistributionAmount,
		LossHandlingMethod:    req.LossHandlingMethod,
		TaxHandling:           req.TaxHandling,
		ReinvestmentOption:    req.ReinvestmentOption,
		ReinvestmentRate:      req.ReinvestmentRate,
		CustomRules:           req.CustomRules,
		CalculationFormula:    req.CalculationFormula,
		IsActive:              true,
		EffectiveDate:         req.EffectiveDate,
		ExpiryDate:            req.ExpiryDate,
		CreatedBy:             creatorID,
		CreatedAt:             time.Now(),
		UpdatedAt:             time.Now(),
	}

	// In a real implementation, save to repository
	// createdRules, err := s.rulesRepo.CreateProfitSharingRules(ctx, rules)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityCooperative,
		EntityID:   cooperativeID,
		Operation:  entities.AuditOperationCreate,
		UserID:     creatorID,
		Changes:    map[string]interface{}{"action": "create_profit_sharing_rules", "rules_id": rules.ID},
		NewValues:  rules,
		Status:     entities.AuditStatusSuccess,
	})

	return rules, nil
}

func (s *investmentPolicyService) ValidatePolicyCompliance(ctx context.Context, projectID, policyID uuid.UUID) (bool, []string, error) {
	var violations []string

	// Get project details and policy
	// project, err := s.projectRepo.GetByID(ctx, projectID)
	// policy, err := s.policyRepo.GetByID(ctx, policyID)

	// Mock validation logic
	// In real implementation, check:
	// - Project amount within policy limits
	// - Project sector in allowed sectors
	// - Project duration within limits
	// - Risk level acceptable
	// - Sharia compliance if required
	// - Required documents provided

	// For now, return compliant
	return true, violations, nil
}

func (s *investmentPolicyService) ValidateInvestmentAmount(ctx context.Context, cooperativeID uuid.UUID, amount float64) (bool, string, error) {
	// Get active investment policies
	policies, err := s.GetActiveInvestmentPolicies(ctx, cooperativeID)
	if err != nil {
		return false, "Failed to retrieve investment policies", err
	}

	if len(policies) == 0 {
		return false, "No active investment policies found", nil
	}

	// Check against the most recent policy
	policy := policies[0] // Assuming sorted by creation date

	if amount < policy.MinInvestmentAmount {
		return false, fmt.Sprintf("Investment amount %.2f is below minimum of %.2f", amount, policy.MinInvestmentAmount), nil
	}

	if amount > policy.MaxInvestmentAmount {
		return false, fmt.Sprintf("Investment amount %.2f exceeds maximum of %.2f", amount, policy.MaxInvestmentAmount), nil
	}

	return true, "Investment amount is valid", nil
}

func (s *investmentPolicyService) ValidateInvestorEligibility(ctx context.Context, cooperativeID, userID uuid.UUID) (bool, []string, error) {
	var violations []string

	// Get active investment policies
	policies, err := s.GetActiveInvestmentPolicies(ctx, cooperativeID)
	if err != nil {
		return false, violations, err
	}

	if len(policies) == 0 {
		violations = append(violations, "No active investment policies found")
		return false, violations, nil
	}

	// Check investor eligibility based on policy requirements
	// In real implementation, check:
	// - User KYC status
	// - Cooperative membership
	// - Investment history
	// - Risk profile
	// - Age and other demographic requirements

	return true, violations, nil
}

// Mock implementations for interface compliance
func (s *investmentPolicyService) GetInvestmentPolicy(ctx context.Context, cooperativeID, policyID uuid.UUID) (*entities.InvestmentPolicyExtended, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *investmentPolicyService) GetActiveInvestmentPolicies(ctx context.Context, cooperativeID uuid.UUID) ([]*entities.InvestmentPolicyExtended, error) {
	return []*entities.InvestmentPolicyExtended{}, nil
}

func (s *investmentPolicyService) UpdateInvestmentPolicy(ctx context.Context, cooperativeID, policyID uuid.UUID, req *entities.UpdateInvestmentPolicyRequest, updaterID uuid.UUID) (*entities.InvestmentPolicyExtended, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *investmentPolicyService) DeactivateInvestmentPolicy(ctx context.Context, cooperativeID, policyID, deactivatorID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *investmentPolicyService) GetProfitSharingRules(ctx context.Context, cooperativeID, rulesID uuid.UUID) (*entities.ProfitSharingRulesExtended, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *investmentPolicyService) GetActiveProfitSharingRules(ctx context.Context, cooperativeID uuid.UUID) ([]*entities.ProfitSharingRulesExtended, error) {
	return []*entities.ProfitSharingRulesExtended{}, nil
}

func (s *investmentPolicyService) UpdateProfitSharingRules(ctx context.Context, cooperativeID, rulesID uuid.UUID, req *entities.UpdateProfitSharingRulesRequest, updaterID uuid.UUID) (*entities.ProfitSharingRulesExtended, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *investmentPolicyService) DeactivateProfitSharingRules(ctx context.Context, cooperativeID, rulesID, deactivatorID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

// Helper validation methods
func (s *investmentPolicyService) validateInvestmentPolicy(req *entities.CreateInvestmentPolicyRequest) error {
	if req.MaxInvestmentAmount <= req.MinInvestmentAmount {
		return fmt.Errorf("maximum investment amount must be greater than minimum")
	}

	if req.ApprovalThreshold < 0.5 || req.ApprovalThreshold > 1.0 {
		return fmt.Errorf("approval threshold must be between 0.5 and 1.0")
	}

	if req.ExpiryDate != nil && req.ExpiryDate.Before(req.EffectiveDate) {
		return fmt.Errorf("expiry date must be after effective date")
	}

	return nil
}

func (s *investmentPolicyService) validateProfitSharingRules(req *entities.CreateProfitSharingRulesRequest) error {
	totalShare := req.InvestorShare + req.CooperativeShare + req.BusinessOwnerShare + req.AdminFee
	
	if totalShare < 0.99 || totalShare > 1.01 { // Allow small floating point tolerance
		return fmt.Errorf("total shares must equal 100%% (currently %.2f%%)", totalShare*100)
	}

	if req.DistributionDay < 1 || req.DistributionDay > 31 {
		return fmt.Errorf("distribution day must be between 1 and 31")
	}

	if req.ExpiryDate != nil && req.ExpiryDate.Before(req.EffectiveDate) {
		return fmt.Errorf("expiry date must be after effective date")
	}

	return nil
}
