package services

import (
	"context"
	"fmt"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
)

type FundMonitoringService interface {
	// FR-021: Fund Transfer Monitoring
	CreateFundTransfer(ctx context.Context, req *entities.CreateFundTransferRequest, initiatorID uuid.UUID) (*entities.FundTransfer, error)
	UpdateFundTransfer(ctx context.Context, transferID uuid.UUID, req *entities.UpdateFundTransferRequest, updaterID uuid.UUID) (*entities.FundTransfer, error)
	GetFundTransfer(ctx context.Context, transferID uuid.UUID) (*entities.FundTransfer, error)
	GetFundTransfers(ctx context.Context, filter *entities.FundTransferFilter) ([]*entities.FundTransfer, int, error)
	CancelFundTransfer(ctx context.Context, transferID, cancellerID uuid.UUID, reason string) error
	ProcessPendingTransfers(ctx context.Context) (int, error)
	
	// FR-021: Profit Distribution Monitoring
	CreateProfitDistribution(ctx context.Context, req *entities.CreateProfitDistributionRequest, calculatorID uuid.UUID) (*entities.ProfitDistributionMonitoring, error)
	ApproveProfitDistribution(ctx context.Context, distributionID, approverID uuid.UUID) error
	DistributeProfits(ctx context.Context, distributionID, distributorID uuid.UUID) error
	GetProfitDistribution(ctx context.Context, distributionID uuid.UUID) (*entities.ProfitDistributionMonitoring, error)
	GetProfitDistributions(ctx context.Context, filter *entities.ProfitDistributionFilter) ([]*entities.ProfitDistributionMonitoring, int, error)
	
	// Monitoring and reporting
	GetCooperativeFundSummary(ctx context.Context, cooperativeID uuid.UUID, startDate, endDate time.Time) (map[string]interface{}, error)
	GetProjectFundingStatus(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error)
	GenerateFinancialReport(ctx context.Context, cooperativeID uuid.UUID, period string) (map[string]interface{}, error)
	DetectSuspiciousTransactions(ctx context.Context, cooperativeID uuid.UUID) ([]*entities.FundTransfer, error)
	
	// Integration with external payment systems
	SyncBankTransactions(ctx context.Context, cooperativeID uuid.UUID) (int, error)
	ValidatePaymentReference(ctx context.Context, reference string) (bool, error)
}

type fundMonitoringService struct {
	auditService AuditService
}

func NewFundMonitoringService(auditService AuditService) FundMonitoringService {
	return &fundMonitoringService{
		auditService: auditService,
	}
}

func (s *fundMonitoringService) CreateFundTransfer(ctx context.Context, req *entities.CreateFundTransferRequest, initiatorID uuid.UUID) (*entities.FundTransfer, error) {
	// Validate transfer request
	if err := s.validateTransferRequest(req); err != nil {
		return nil, err
	}

	// Generate unique transfer number
	transferNumber := s.generateTransferNumber()

	// Calculate fees and net amount
	fee := s.calculateTransferFee(req.Amount, req.TransferType, req.PaymentMethod)
	netAmount := req.Amount - fee

	transfer := &entities.FundTransfer{
		ID:                uuid.New(),
		TransferNumber:    transferNumber,
		ProjectID:         req.ProjectID,
		InvestmentID:      req.InvestmentID,
		CooperativeID:     uuid.New(), // Would get from project
		FromAccountID:     req.FromAccountID,
		ToAccountID:       req.ToAccountID,
		FromUserID:        req.FromUserID,
		ToUserID:          req.ToUserID,
		TransferType:      req.TransferType,
		Amount:            req.Amount,
		Currency:          req.Currency,
		ExchangeRate:      1.0, // Default for same currency
		Fee:               fee,
		NetAmount:         netAmount,
		Status:            entities.TransferStatusPending,
		PaymentMethod:     req.PaymentMethod,
		PaymentReference:  req.PaymentReference,
		Description:       req.Description,
		Notes:             req.Notes,
		ScheduledAt:       req.ScheduledAt,
		Metadata:          req.Metadata,
		MaxRetries:        3,
		InitiatedBy:       initiatorID,
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
	}

	// If scheduled for future, keep as pending; otherwise process immediately
	if req.ScheduledAt == nil || req.ScheduledAt.Before(time.Now()) {
		transfer.Status = entities.TransferStatusProcessing
		now := time.Now()
		transfer.ProcessedAt = &now
	}

	// In real implementation, save to repository
	// createdTransfer, err := s.transferRepo.Create(ctx, transfer)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: "fund_transfer",
		EntityID:   transfer.ID,
		Operation:  entities.AuditOperationCreate,
		UserID:     initiatorID,
		Changes:    map[string]interface{}{"transfer_type": req.TransferType, "amount": req.Amount},
		NewValues:  transfer,
		Status:     entities.AuditStatusSuccess,
	})

	return transfer, nil
}

func (s *fundMonitoringService) CreateProfitDistribution(ctx context.Context, req *entities.CreateProfitDistributionRequest, calculatorID uuid.UUID) (*entities.ProfitDistributionMonitoring, error) {
	// Validate profit distribution request
	if err := s.validateProfitDistributionRequest(req); err != nil {
		return nil, err
	}

	// Calculate profit distribution based on rules
	netProfit := req.TotalRevenue - req.TotalExpenses
	distributableProfit := netProfit // Could apply adjustments

	// Get profit sharing rules (mock calculation)
	investorShare := distributableProfit * 0.6    // 60%
	cooperativeShare := distributableProfit * 0.2 // 20%
	businessOwnerShare := distributableProfit * 0.15 // 15%
	adminFee := distributableProfit * 0.05        // 5%

	distributionNumber := s.generateDistributionNumber()

	distribution := &entities.ProfitDistributionMonitoring{
		ID:                     uuid.New(),
		DistributionNumber:     distributionNumber,
		ProjectID:              req.ProjectID,
		CooperativeID:          uuid.New(), // Would get from project
		PeriodStart:            req.PeriodStart,
		PeriodEnd:              req.PeriodEnd,
		TotalRevenue:           req.TotalRevenue,
		TotalExpenses:          req.TotalExpenses,
		NetProfit:              netProfit,
		DistributableProfit:    distributableProfit,
		InvestorShare:          investorShare,
		CooperativeShare:       cooperativeShare,
		BusinessOwnerShare:     businessOwnerShare,
		AdminFee:               adminFee,
		TotalDistributed:       0, // Will be updated when distributed
		PendingDistribution:    distributableProfit,
		Status:                 entities.DistributionStatusCalculated,
		CalculationMethod:      req.CalculationMethod,
		ApprovalRequired:       true,
		Documents:              req.Documents,
		FinancialStatements:    req.FinancialStatements,
		Adjustments:            req.Adjustments,
		Notes:                  req.Notes,
		CalculatedBy:           calculatorID,
		CalculatedAt:           time.Now(),
		CreatedAt:              time.Now(),
		UpdatedAt:              time.Now(),
	}

	// In real implementation, save to repository
	// createdDistribution, err := s.distributionRepo.Create(ctx, distribution)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: "profit_distribution",
		EntityID:   distribution.ID,
		Operation:  entities.AuditOperationCreate,
		UserID:     calculatorID,
		Changes:    map[string]interface{}{"net_profit": netProfit, "distributable_profit": distributableProfit},
		NewValues:  distribution,
		Status:     entities.AuditStatusSuccess,
	})

	return distribution, nil
}

func (s *fundMonitoringService) GetCooperativeFundSummary(ctx context.Context, cooperativeID uuid.UUID, startDate, endDate time.Time) (map[string]interface{}, error) {
	// Mock fund summary calculation
	summary := map[string]interface{}{
		"cooperative_id": cooperativeID,
		"period": map[string]interface{}{
			"start": startDate,
			"end":   endDate,
		},
		"transfers": map[string]interface{}{
			"total_inbound":  150000.0,
			"total_outbound": 120000.0,
			"net_flow":       30000.0,
			"count_inbound":  45,
			"count_outbound": 38,
		},
		"investments": map[string]interface{}{
			"total_invested":    100000.0,
			"active_projects":   12,
			"pending_projects":  5,
			"completed_projects": 3,
		},
		"distributions": map[string]interface{}{
			"total_distributed": 15000.0,
			"pending_distribution": 5000.0,
			"distribution_cycles": 2,
		},
		"fees": map[string]interface{}{
			"transaction_fees": 2500.0,
			"admin_fees":      1800.0,
			"total_fees":      4300.0,
		},
		"balance": map[string]interface{}{
			"available_balance": 35700.0,
			"reserved_balance":  12000.0,
			"total_balance":    47700.0,
		},
	}

	return summary, nil
}

func (s *fundMonitoringService) DetectSuspiciousTransactions(ctx context.Context, cooperativeID uuid.UUID) ([]*entities.FundTransfer, error) {
	// Mock suspicious transaction detection
	// In real implementation, apply rules like:
	// - Unusually large amounts
	// - Rapid succession of transfers
	// - Transfers to/from blacklisted accounts
	// - Patterns indicating money laundering
	
	return []*entities.FundTransfer{}, nil
}

// Mock implementations for interface compliance
func (s *fundMonitoringService) UpdateFundTransfer(ctx context.Context, transferID uuid.UUID, req *entities.UpdateFundTransferRequest, updaterID uuid.UUID) (*entities.FundTransfer, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *fundMonitoringService) GetFundTransfer(ctx context.Context, transferID uuid.UUID) (*entities.FundTransfer, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *fundMonitoringService) GetFundTransfers(ctx context.Context, filter *entities.FundTransferFilter) ([]*entities.FundTransfer, int, error) {
	return []*entities.FundTransfer{}, 0, nil
}

func (s *fundMonitoringService) CancelFundTransfer(ctx context.Context, transferID, cancellerID uuid.UUID, reason string) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *fundMonitoringService) ProcessPendingTransfers(ctx context.Context) (int, error) {
	return 0, fmt.Errorf("not implemented - requires repository and payment gateway")
}

func (s *fundMonitoringService) ApproveProfitDistribution(ctx context.Context, distributionID, approverID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *fundMonitoringService) DistributeProfits(ctx context.Context, distributionID, distributorID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *fundMonitoringService) GetProfitDistribution(ctx context.Context, distributionID uuid.UUID) (*entities.ProfitDistributionMonitoring, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *fundMonitoringService) GetProfitDistributions(ctx context.Context, filter *entities.ProfitDistributionFilter) ([]*entities.ProfitDistributionMonitoring, int, error) {
	return []*entities.ProfitDistributionMonitoring{}, 0, nil
}

func (s *fundMonitoringService) GetProjectFundingStatus(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (s *fundMonitoringService) GenerateFinancialReport(ctx context.Context, cooperativeID uuid.UUID, period string) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (s *fundMonitoringService) SyncBankTransactions(ctx context.Context, cooperativeID uuid.UUID) (int, error) {
	return 0, fmt.Errorf("not implemented - requires bank API integration")
}

func (s *fundMonitoringService) ValidatePaymentReference(ctx context.Context, reference string) (bool, error) {
	return len(reference) > 5, nil
}

// Helper methods
func (s *fundMonitoringService) validateTransferRequest(req *entities.CreateFundTransferRequest) error {
	if req.Amount <= 0 {
		return fmt.Errorf("transfer amount must be positive")
	}

	if req.FromAccountID == req.ToAccountID {
		return fmt.Errorf("from and to accounts cannot be the same")
	}

	if len(req.Currency) != 3 {
		return fmt.Errorf("currency must be 3-character code")
	}

	return nil
}

func (s *fundMonitoringService) validateProfitDistributionRequest(req *entities.CreateProfitDistributionRequest) error {
	if req.TotalRevenue < 0 {
		return fmt.Errorf("total revenue cannot be negative")
	}

	if req.TotalExpenses < 0 {
		return fmt.Errorf("total expenses cannot be negative")
	}

	if req.PeriodEnd.Before(req.PeriodStart) {
		return fmt.Errorf("period end must be after period start")
	}

	return nil
}

func (s *fundMonitoringService) generateTransferNumber() string {
	// Generate unique transfer number
	timestamp := time.Now().Format("20060102150405")
	return fmt.Sprintf("TXN-%s-%s", timestamp, uuid.New().String()[:8])
}

func (s *fundMonitoringService) generateDistributionNumber() string {
	// Generate unique distribution number
	timestamp := time.Now().Format("200601")
	return fmt.Sprintf("DIST-%s-%s", timestamp, uuid.New().String()[:8])
}

func (s *fundMonitoringService) calculateTransferFee(amount float64, transferType, paymentMethod string) float64 {
	// Mock fee calculation
	baseFee := 0.0
	percentageFee := 0.0

	switch transferType {
	case entities.TransferTypeLnvestment:
		percentageFee = 0.005 // 0.5%
	case entities.TransferTypeProfitDistribution:
		percentageFee = 0.002 // 0.2%
	case entities.TransferTypeWithdrawal:
		percentageFee = 0.01 // 1%
		baseFee = 5.0
	default:
		percentageFee = 0.01 // 1%
	}

	switch paymentMethod {
	case entities.PaymentMethodBankTransfer:
		baseFee += 2.0
	case entities.PaymentMethodDigitalWallet:
		baseFee += 1.0
	case entities.PaymentMethodCash:
		baseFee += 0.0
	}

	return baseFee + (amount * percentageFee)
}
