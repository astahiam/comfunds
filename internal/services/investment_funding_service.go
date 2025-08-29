package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
)

// InvestmentFundingService interface for FR-041 to FR-045
type InvestmentFundingService interface {
	// FR-041: Cooperative members can invest in approved projects
	CreateInvestment(ctx context.Context, req *entities.CreateInvestmentExtendedRequest, investorID uuid.UUID) (*entities.InvestmentExtended, error)
	ValidateInvestmentEligibility(ctx context.Context, investorID, projectID uuid.UUID, amount float64) (*entities.InvestmentEligibilityCheck, error)

	// FR-042: System shall validate investor eligibility and funds availability
	CheckInvestorEligibility(ctx context.Context, investorID, projectID uuid.UUID) (bool, []string, error)
	CheckFundsAvailability(ctx context.Context, investorID uuid.UUID, amount float64) (bool, float64, error)
	ValidateInvestmentAmount(ctx context.Context, projectID uuid.UUID, amount float64) (bool, float64, float64, error) // min, max

	// FR-043: Investments are transferred to cooperative's escrow account
	TransferToEscrowAccount(ctx context.Context, investmentID uuid.UUID, cooperativeID uuid.UUID) error
	GetEscrowAccount(ctx context.Context, cooperativeID uuid.UUID) (*entities.EscrowAccount, error)
	UpdateEscrowBalance(ctx context.Context, escrowAccountID uuid.UUID, amount float64, operation string) error

	// FR-044: System shall support partial funding and multiple investors per project
	GetProjectInvestments(ctx context.Context, projectID uuid.UUID, page, limit int) ([]*entities.InvestmentExtended, int, error)
	GetProjectFundingProgress(ctx context.Context, projectID uuid.UUID) (float64, float64, int, error) // current, goal, investor count
	CheckPartialFundingEligibility(ctx context.Context, projectID uuid.UUID, amount float64) (bool, error)

	// FR-045: Minimum and maximum investment amounts can be set per project
	SetProjectInvestmentLimits(ctx context.Context, projectID uuid.UUID, minAmount, maxAmount float64) error
	GetProjectInvestmentLimits(ctx context.Context, projectID uuid.UUID) (float64, float64, error)

	// Investment management
	GetInvestment(ctx context.Context, investmentID uuid.UUID) (*entities.InvestmentExtended, error)
	UpdateInvestment(ctx context.Context, investmentID uuid.UUID, req *entities.UpdateInvestmentRequest, updaterID uuid.UUID) (*entities.InvestmentExtended, error)
	ApproveInvestment(ctx context.Context, req *entities.InvestmentApprovalRequest, approverID uuid.UUID) error
	RejectInvestment(ctx context.Context, req *entities.InvestmentApprovalRequest, rejecterID uuid.UUID) error
	CancelInvestment(ctx context.Context, investmentID, cancellerID uuid.UUID, reason string) error

	// Investor portfolio
	GetInvestorInvestments(ctx context.Context, investorID uuid.UUID, page, limit int) ([]*entities.InvestmentExtended, int, error)
	GetInvestorPortfolio(ctx context.Context, investorID uuid.UUID) (*entities.InvestmentSummary, error)

	// Reporting and analytics
	GetInvestmentSummary(ctx context.Context, cooperativeID uuid.UUID, startDate, endDate time.Time) (*entities.InvestmentSummary, error)
	GetProjectInvestmentAnalytics(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error)
}

// investmentFundingService implements InvestmentFundingService
type investmentFundingService struct {
	auditService AuditService
	// Add repositories when implemented
}

// NewInvestmentFundingService creates a new investment funding service
func NewInvestmentFundingService(auditService AuditService) InvestmentFundingService {
	return &investmentFundingService{
		auditService: auditService,
	}
}

// CreateInvestment implements FR-041: Cooperative members can invest in approved projects
func (s *investmentFundingService) CreateInvestment(ctx context.Context, req *entities.CreateInvestmentExtendedRequest, investorID uuid.UUID) (*entities.InvestmentExtended, error) {
	// Validate investment eligibility
	eligibility, err := s.ValidateInvestmentEligibility(ctx, investorID, req.ProjectID, req.Amount)
	if err != nil {
		return nil, fmt.Errorf("failed to validate investment eligibility: %w", err)
	}

	if !eligibility.IsEligible {
		return nil, fmt.Errorf("investment not eligible: %v", eligibility.Reasons)
	}

	// Create investment record
	investment := &entities.InvestmentExtended{
		ID:                   uuid.New(),
		InvestorID:           investorID,
		ProjectID:            req.ProjectID,
		CooperativeID:        uuid.Nil, // Will be set based on project's cooperative
		Amount:               req.Amount,
		Currency:             req.Currency,
		InvestmentType:       req.InvestmentType,
		InvestmentPercentage: 0, // Will be calculated
		Status:               entities.InvestmentStatusPending,
		ApprovalStatus:       "pending",
		EscrowAccountID:      uuid.Nil, // Will be set during transfer
		RiskLevel:            "medium", // Default
		ShariaCompliant:      true,     // Default for cooperative projects
		IsActive:             true,
		CreatedAt:            time.Now(),
		UpdatedAt:            time.Now(),
	}

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     investorID,
		Operation:  "create_investment",
		EntityType: "investment",
		EntityID:   investment.ID,
		NewValues:  fmt.Sprintf("Created investment of %f %s in project %s", req.Amount, req.Currency, req.ProjectID),
	})

	return investment, nil
}

// ValidateInvestmentEligibility implements FR-042 validation
func (s *investmentFundingService) ValidateInvestmentEligibility(ctx context.Context, investorID, projectID uuid.UUID, amount float64) (*entities.InvestmentEligibilityCheck, error) {
	check := &entities.InvestmentEligibilityCheck{
		InvestorID: investorID,
		ProjectID:  projectID,
		Amount:     amount,
		IsEligible: true,
		Reasons:    []string{},
	}

	// Check investor eligibility
	isEligible, reasons, err := s.CheckInvestorEligibility(ctx, investorID, projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to check investor eligibility: %w", err)
	}

	if !isEligible {
		check.IsEligible = false
		check.Reasons = append(check.Reasons, reasons...)
	}

	// Check funds availability
	hasFunds, availableFunds, err := s.CheckFundsAvailability(ctx, investorID, amount)
	if err != nil {
		return nil, fmt.Errorf("failed to check funds availability: %w", err)
	}

	check.AvailableFunds = availableFunds
	if !hasFunds {
		check.IsEligible = false
		check.Reasons = append(check.Reasons, "insufficient funds")
	}

	// Check investment amount limits
	isValidAmount, minInvestment, maxInvestment, err := s.ValidateInvestmentAmount(ctx, projectID, amount)
	if err != nil {
		return nil, fmt.Errorf("failed to validate investment amount: %w", err)
	}

	check.MinInvestment = minInvestment
	check.MaxInvestment = maxInvestment
	if !isValidAmount {
		check.IsEligible = false
		check.Reasons = append(check.Reasons, "investment amount outside allowed range")
	}

	return check, nil
}

// CheckInvestorEligibility checks if investor is eligible to invest in the project
func (s *investmentFundingService) CheckInvestorEligibility(ctx context.Context, investorID, projectID uuid.UUID) (bool, []string, error) {
	reasons := []string{}

	// Mock implementation - in real system would check:
	// 1. Investor is cooperative member
	// 2. Project is approved and active
	// 3. Investor hasn't exceeded investment limits
	// 4. Project is within investor's cooperative

	// For now, assume eligible
	return true, reasons, nil
}

// CheckFundsAvailability checks if investor has sufficient funds
func (s *investmentFundingService) CheckFundsAvailability(ctx context.Context, investorID uuid.UUID, amount float64) (bool, float64, error) {
	// Mock implementation - in real system would check:
	// 1. Investor's account balance
	// 2. Available credit limit
	// 3. Pending transactions

	// Mock available funds
	availableFunds := 10000.0 // Mock value
	return availableFunds >= amount, availableFunds, nil
}

// ValidateInvestmentAmount validates investment amount against project limits
func (s *investmentFundingService) ValidateInvestmentAmount(ctx context.Context, projectID uuid.UUID, amount float64) (bool, float64, float64, error) {
	// Mock implementation - in real system would get from project settings
	minInvestment := 100.0  // Mock minimum
	maxInvestment := 5000.0 // Mock maximum

	return amount >= minInvestment && amount <= maxInvestment, minInvestment, maxInvestment, nil
}

// TransferToEscrowAccount implements FR-043: Transfer to cooperative's escrow account
func (s *investmentFundingService) TransferToEscrowAccount(ctx context.Context, investmentID uuid.UUID, cooperativeID uuid.UUID) error {
	// Mock implementation - in real system would:
	// 1. Get escrow account for cooperative
	// 2. Update investment status
	// 3. Update escrow account balance
	// 4. Generate transfer reference
	// 5. Log transaction

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     uuid.Nil, // System operation
		Operation:  "transfer_to_escrow",
		EntityType: "investment",
		EntityID:   investmentID,
		NewValues:  fmt.Sprintf("Transferred investment %s to escrow account for cooperative %s", investmentID, cooperativeID),
	})

	return nil
}

// GetEscrowAccount gets cooperative's escrow account
func (s *investmentFundingService) GetEscrowAccount(ctx context.Context, cooperativeID uuid.UUID) (*entities.EscrowAccount, error) {
	// Mock implementation
	return &entities.EscrowAccount{
		ID:                 uuid.New(),
		CooperativeID:      cooperativeID,
		AccountNumber:      "ESC001",
		AccountName:        "Cooperative Escrow Account",
		BankName:           "Islamic Bank",
		Currency:           "IDR",
		Balance:            50000.0,
		TotalInvestments:   100000.0,
		TotalDistributions: 50000.0,
		Status:             entities.EscrowAccountStatusActive,
		IsActive:           true,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}, nil
}

// UpdateEscrowBalance updates escrow account balance
func (s *investmentFundingService) UpdateEscrowBalance(ctx context.Context, escrowAccountID uuid.UUID, amount float64, operation string) error {
	// Mock implementation - in real system would update database
	return nil
}

// GetProjectInvestments implements FR-044: Multiple investors per project
func (s *investmentFundingService) GetProjectInvestments(ctx context.Context, projectID uuid.UUID, page, limit int) ([]*entities.InvestmentExtended, int, error) {
	// Mock implementation
	investments := []*entities.InvestmentExtended{
		{
			ID:             uuid.New(),
			InvestorID:     uuid.New(),
			ProjectID:      projectID,
			Amount:         1000.0,
			Currency:       "IDR",
			InvestmentType: entities.InvestmentTypePartial,
			Status:         entities.InvestmentStatusActive,
			IsActive:       true,
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		},
	}

	return investments, 1, nil
}

// GetProjectFundingProgress gets project funding progress
func (s *investmentFundingService) GetProjectFundingProgress(ctx context.Context, projectID uuid.UUID) (float64, float64, int, error) {
	// Mock implementation
	currentFunding := 50000.0
	fundingGoal := 100000.0
	investorCount := 25

	return currentFunding, fundingGoal, investorCount, nil
}

// CheckPartialFundingEligibility checks if partial funding is allowed
func (s *investmentFundingService) CheckPartialFundingEligibility(ctx context.Context, projectID uuid.UUID, amount float64) (bool, error) {
	// Mock implementation - check if project allows partial funding
	return true, nil
}

// SetProjectInvestmentLimits implements FR-045: Set investment limits
func (s *investmentFundingService) SetProjectInvestmentLimits(ctx context.Context, projectID uuid.UUID, minAmount, maxAmount float64) error {
	if minAmount < 0 || maxAmount < 0 || minAmount > maxAmount {
		return errors.New("invalid investment limits")
	}

	// Mock implementation - would update project settings

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     uuid.Nil, // System operation
		Operation:  "set_investment_limits",
		EntityType: "project",
		EntityID:   projectID,
		NewValues:  fmt.Sprintf("Set investment limits: min=%f, max=%f", minAmount, maxAmount),
	})

	return nil
}

// GetProjectInvestmentLimits gets project investment limits
func (s *investmentFundingService) GetProjectInvestmentLimits(ctx context.Context, projectID uuid.UUID) (float64, float64, error) {
	// Mock implementation
	return 100.0, 5000.0, nil
}

// GetInvestment gets investment by ID
func (s *investmentFundingService) GetInvestment(ctx context.Context, investmentID uuid.UUID) (*entities.InvestmentExtended, error) {
	// Mock implementation
	return &entities.InvestmentExtended{
		ID:             investmentID,
		InvestorID:     uuid.New(),
		ProjectID:      uuid.New(),
		Amount:         1000.0,
		Currency:       "IDR",
		InvestmentType: entities.InvestmentTypePartial,
		Status:         entities.InvestmentStatusActive,
		IsActive:       true,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}, nil
}

// UpdateInvestment updates investment
func (s *investmentFundingService) UpdateInvestment(ctx context.Context, investmentID uuid.UUID, req *entities.UpdateInvestmentRequest, updaterID uuid.UUID) (*entities.InvestmentExtended, error) {
	// Mock implementation
	investment, err := s.GetInvestment(ctx, investmentID)
	if err != nil {
		return nil, err
	}

	if req.Amount != nil {
		investment.Amount = *req.Amount
	}
	if req.InvestmentType != nil {
		investment.InvestmentType = *req.InvestmentType
	}
	if req.Status != nil {
		investment.Status = *req.Status
	}

	investment.UpdatedAt = time.Now()

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     updaterID,
		Operation:  "update_investment",
		EntityType: "investment",
		EntityID:   investmentID,
		NewValues:  "Updated investment details",
	})

	return investment, nil
}

// ApproveInvestment approves an investment
func (s *investmentFundingService) ApproveInvestment(ctx context.Context, req *entities.InvestmentApprovalRequest, approverID uuid.UUID) error {
	// Mock implementation
	// Would update investment status to approved

	// Log audit trail
	// TODO: Fix LogOperationRequest field names
	// s.auditService.LogOperation(ctx, &LogOperationRequest{
	// 	UserID:     approverID,
	// 	Operation:  "approve_investment",
	// 	EntityType: "investment",
	// 	EntityID:   req.InvestmentID,
	// 	NewValues:  fmt.Sprintf("Approved investment with comments: %s", req.Comments),
	// })

	return nil
}

// RejectInvestment rejects an investment
func (s *investmentFundingService) RejectInvestment(ctx context.Context, req *entities.InvestmentApprovalRequest, rejecterID uuid.UUID) error {
	// Mock implementation
	// Would update investment status to rejected

	// Log audit trail
	// TODO: Fix LogOperationRequest field names
	// s.auditService.LogOperation(ctx, &LogOperationRequest{
	// 	UserID:     rejecterID,
	// 	Operation:  "reject_investment",
	// 	EntityType: "investment",
	// 	EntityID:   req.InvestmentID,
	// 	NewValues:  fmt.Sprintf("Rejected investment: %s", req.RejectionReason),
	// })

	return nil
}

// CancelInvestment cancels an investment
func (s *investmentFundingService) CancelInvestment(ctx context.Context, investmentID, cancellerID uuid.UUID, reason string) error {
	// Mock implementation
	// Would update investment status to cancelled

	// Log audit trail
	// TODO: Fix LogOperationRequest field names
	// s.auditService.LogOperation(ctx, &LogOperationRequest{
	// 	UserID:     cancellerID,
	// 	Operation:  "cancel_investment",
	// 	EntityType: "investment",
	// 	EntityID:   investmentID,
	// 	NewValues:  fmt.Sprintf("Cancelled investment: %s", reason),
	// })

	return nil
}

// GetInvestorInvestments gets investor's investments
func (s *investmentFundingService) GetInvestorInvestments(ctx context.Context, investorID uuid.UUID, page, limit int) ([]*entities.InvestmentExtended, int, error) {
	// Mock implementation
	investments := []*entities.InvestmentExtended{
		{
			ID:             uuid.New(),
			InvestorID:     investorID,
			ProjectID:      uuid.New(),
			Amount:         1000.0,
			Currency:       "IDR",
			InvestmentType: entities.InvestmentTypePartial,
			Status:         entities.InvestmentStatusActive,
			IsActive:       true,
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		},
	}

	return investments, 1, nil
}

// GetInvestorPortfolio gets investor's portfolio summary
func (s *investmentFundingService) GetInvestorPortfolio(ctx context.Context, investorID uuid.UUID) (*entities.InvestmentSummary, error) {
	// Mock implementation
	return &entities.InvestmentSummary{
		TotalInvestments:     5,
		TotalAmount:          5000.0,
		ActiveInvestments:    3,
		ActiveAmount:         3000.0,
		CompletedInvestments: 2,
		CompletedAmount:      2000.0,
		TotalReturns:         500.0,
		AverageReturn:        10.0,
		Currency:             "IDR",
	}, nil
}

// GetInvestmentSummary gets investment summary for reporting
func (s *investmentFundingService) GetInvestmentSummary(ctx context.Context, cooperativeID uuid.UUID, startDate, endDate time.Time) (*entities.InvestmentSummary, error) {
	// Mock implementation
	return &entities.InvestmentSummary{
		TotalInvestments:     100,
		TotalAmount:          1000000.0,
		ActiveInvestments:    75,
		ActiveAmount:         750000.0,
		CompletedInvestments: 25,
		CompletedAmount:      250000.0,
		TotalReturns:         50000.0,
		AverageReturn:        5.0,
		Currency:             "IDR",
	}, nil
}

// GetProjectInvestmentAnalytics gets project investment analytics
func (s *investmentFundingService) GetProjectInvestmentAnalytics(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error) {
	// Mock implementation
	return map[string]interface{}{
		"total_investments":  25,
		"total_amount":       50000.0,
		"average_investment": 2000.0,
		"funding_progress":   50.0,
		"days_remaining":     30,
		"investor_demographics": map[string]interface{}{
			"new_investors": 15,
			"returning":     10,
		},
	}, nil
}
