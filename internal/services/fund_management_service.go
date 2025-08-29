package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
)

// FundManagementService interface for FR-046 to FR-049
type FundManagementService interface {
	// FR-046: Cooperative manages fund disbursement to business owners upon milestones
	CreateFundDisbursement(ctx context.Context, req *entities.CreateFundDisbursementRequest, requesterID uuid.UUID) (*entities.FundDisbursement, error)
	ApproveFundDisbursement(ctx context.Context, disbursementID, approverID uuid.UUID, comments string) error
	RejectFundDisbursement(ctx context.Context, disbursementID, rejecterID uuid.UUID, reason string) error
	ProcessFundDisbursement(ctx context.Context, disbursementID, processorID uuid.UUID) error
	GetFundDisbursement(ctx context.Context, disbursementID uuid.UUID) (*entities.FundDisbursement, error)
	GetProjectDisbursements(ctx context.Context, projectID uuid.UUID, page, limit int) ([]*entities.FundDisbursement, int, error)
	SearchFundDisbursements(ctx context.Context, filter *entities.FundDisbursementFilter) ([]*entities.FundDisbursement, int, error)

	// FR-047: System shall track fund usage and business performance
	CreateFundUsage(ctx context.Context, req *entities.CreateFundUsageRequest, recorderID uuid.UUID) (*entities.FundUsage, error)
	VerifyFundUsage(ctx context.Context, usageID, verifierID uuid.UUID, comments string) error
	GetFundUsage(ctx context.Context, usageID uuid.UUID) (*entities.FundUsage, error)
	GetDisbursementUsage(ctx context.Context, disbursementID uuid.UUID, page, limit int) ([]*entities.FundUsage, int, error)
	SearchFundUsage(ctx context.Context, filter *entities.FundUsageFilter) ([]*entities.FundUsage, int, error)
	CalculateFundUsageROI(ctx context.Context, projectID uuid.UUID) (float64, error)

	// FR-048: Funds are held in cooperative account with proper audit trails
	GetCooperativeFundBalance(ctx context.Context, cooperativeID uuid.UUID) (float64, error)
	GetProjectFundBalance(ctx context.Context, projectID uuid.UUID) (float64, error)
	GetFundAuditTrail(ctx context.Context, projectID uuid.UUID, startDate, endDate time.Time) ([]map[string]interface{}, error)

	// FR-049: System shall support fund refunds if project fails to meet minimum funding
	CreateFundRefund(ctx context.Context, req *entities.CreateFundRefundRequest, initiatorID uuid.UUID) (*entities.FundRefund, error)
	ProcessFundRefund(ctx context.Context, refundID, processorID uuid.UUID) error
	CompleteFundRefund(ctx context.Context, refundID, completerID uuid.UUID) error
	GetFundRefund(ctx context.Context, refundID uuid.UUID) (*entities.FundRefund, error)
	GetProjectRefunds(ctx context.Context, projectID uuid.UUID, page, limit int) ([]*entities.FundRefund, int, error)
	SearchFundRefunds(ctx context.Context, filter *entities.FundRefundFilter) ([]*entities.FundRefund, int, error)
	CalculateRefundAmounts(ctx context.Context, projectID uuid.UUID, refundType string) (map[uuid.UUID]float64, error)

	// Fund management reporting
	GetFundManagementSummary(ctx context.Context, cooperativeID uuid.UUID, startDate, endDate time.Time) (*entities.FundManagementSummary, error)
	GetProjectFundAnalytics(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error)
}

// fundManagementService implements FundManagementService
type fundManagementService struct {
	auditService AuditService
	// Add repositories when implemented
}

// NewFundManagementService creates a new fund management service
func NewFundManagementService(auditService AuditService) FundManagementService {
	return &fundManagementService{
		auditService: auditService,
	}
}

// CreateFundDisbursement implements FR-046: Fund disbursement to business owners
func (s *fundManagementService) CreateFundDisbursement(ctx context.Context, req *entities.CreateFundDisbursementRequest, requesterID uuid.UUID) (*entities.FundDisbursement, error) {
	// Validate disbursement request
	if req.DisbursementAmount <= 0 {
		return nil, errors.New("disbursement amount must be greater than zero")
	}

	// Create disbursement record
	disbursement := &entities.FundDisbursement{
		ID:                 uuid.New(),
		ProjectID:          req.ProjectID,
		BusinessID:         uuid.Nil, // Will be set based on project's business
		CooperativeID:      uuid.Nil, // Will be set based on project's cooperative
		MilestoneID:        req.MilestoneID,
		DisbursementAmount: req.DisbursementAmount,
		Currency:           req.Currency,
		DisbursementType:   req.DisbursementType,
		DisbursementReason: req.DisbursementReason,
		Status:             entities.FundDisbursementStatusPending,
		BankAccount:        req.BankAccount,
		EscrowAccountID:    uuid.Nil, // Will be set during processing
		IsActive:           true,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     requesterID,
		Operation:  "create_fund_disbursement",
		EntityType: "fund_disbursement",
		EntityID:   disbursement.ID,
		NewValues:  fmt.Sprintf("Created disbursement request for %f %s", req.DisbursementAmount, req.Currency),
	})

	return disbursement, nil
}

// ApproveFundDisbursement approves a fund disbursement
func (s *fundManagementService) ApproveFundDisbursement(ctx context.Context, disbursementID, approverID uuid.UUID, comments string) error {
	// Mock implementation - would update disbursement status to approved

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     approverID,
		Operation:  "approve_fund_disbursement",
		EntityType: "fund_disbursement",
		EntityID:   disbursementID,
		NewValues:  fmt.Sprintf("Approved disbursement with comments: %s", comments),
	})

	return nil
}

// RejectFundDisbursement rejects a fund disbursement
func (s *fundManagementService) RejectFundDisbursement(ctx context.Context, disbursementID, rejecterID uuid.UUID, reason string) error {
	// Mock implementation - would update disbursement status to rejected

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     rejecterID,
		Operation:  "reject_fund_disbursement",
		EntityType: "fund_disbursement",
		EntityID:   disbursementID,
		NewValues:  fmt.Sprintf("Rejected disbursement: %s", reason),
	})

	return nil
}

// ProcessFundDisbursement processes the actual fund transfer
func (s *fundManagementService) ProcessFundDisbursement(ctx context.Context, disbursementID, processorID uuid.UUID) error {
	// Mock implementation - would:
	// 1. Transfer funds from escrow account to business account
	// 2. Update disbursement status to disbursed
	// 3. Generate transaction reference
	// 4. Update escrow account balance

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     processorID,
		Operation:  "process_fund_disbursement",
		EntityType: "fund_disbursement",
		EntityID:   disbursementID,
		NewValues:  "Processed fund disbursement transfer",
	})

	return nil
}

// GetFundDisbursement gets disbursement by ID
func (s *fundManagementService) GetFundDisbursement(ctx context.Context, disbursementID uuid.UUID) (*entities.FundDisbursement, error) {
	// Mock implementation
	return &entities.FundDisbursement{
		ID:                 disbursementID,
		ProjectID:          uuid.New(),
		BusinessID:         uuid.New(),
		CooperativeID:      uuid.New(),
		MilestoneID:        uuid.New(),
		DisbursementAmount: 50000.0,
		Currency:           "IDR",
		DisbursementType:   entities.FundDisbursementTypeMilestone,
		DisbursementReason: "Equipment purchase milestone completed",
		Status:             entities.FundDisbursementStatusApproved,
		BankAccount:        "1234567890",
		IsActive:           true,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}, nil
}

// GetProjectDisbursements gets project disbursements
func (s *fundManagementService) GetProjectDisbursements(ctx context.Context, projectID uuid.UUID, page, limit int) ([]*entities.FundDisbursement, int, error) {
	// Mock implementation
	disbursements := []*entities.FundDisbursement{
		{
			ID:                 uuid.New(),
			ProjectID:          projectID,
			BusinessID:         uuid.New(),
			CooperativeID:      uuid.New(),
			MilestoneID:        uuid.New(),
			DisbursementAmount: 50000.0,
			Currency:           "IDR",
			DisbursementType:   entities.FundDisbursementTypeMilestone,
			DisbursementReason: "Equipment purchase milestone completed",
			Status:             entities.FundDisbursementStatusDisbursed,
			BankAccount:        "1234567890",
			IsActive:           true,
			CreatedAt:          time.Now(),
			UpdatedAt:          time.Now(),
		},
	}

	return disbursements, 1, nil
}

// SearchFundDisbursements searches disbursements with filters
func (s *fundManagementService) SearchFundDisbursements(ctx context.Context, filter *entities.FundDisbursementFilter) ([]*entities.FundDisbursement, int, error) {
	// Mock implementation
	return s.GetProjectDisbursements(ctx, uuid.New(), filter.Page, filter.Limit)
}

// CreateFundUsage implements FR-047: Track fund usage and business performance
func (s *fundManagementService) CreateFundUsage(ctx context.Context, req *entities.CreateFundUsageRequest, recorderID uuid.UUID) (*entities.FundUsage, error) {
	// Validate usage request
	if req.UsageAmount <= 0 {
		return nil, errors.New("usage amount must be greater than zero")
	}

	// Calculate ROI if revenue data is provided
	roi := 0.0
	if req.RevenueGenerated != nil && *req.RevenueGenerated > 0 {
		roi = (*req.RevenueGenerated / req.UsageAmount) * 100
	}

	// Handle optional fields
	revenueGenerated := 0.0
	if req.RevenueGenerated != nil {
		revenueGenerated = *req.RevenueGenerated
	}

	costSavings := 0.0
	if req.CostSavings != nil {
		costSavings = *req.CostSavings
	}

	// Create fund usage record
	usage := &entities.FundUsage{
		ID:                 uuid.New(),
		ProjectID:          req.ProjectID,
		BusinessID:         uuid.Nil, // Will be set based on project's business
		DisbursementID:     req.DisbursementID,
		UsageCategory:      req.UsageCategory,
		UsageAmount:        req.UsageAmount,
		Currency:           req.Currency,
		UsageDescription:   req.UsageDescription,
		UsageDate:          req.UsageDate,
		PerformanceMetrics: req.PerformanceMetrics,
		RevenueGenerated:   revenueGenerated,
		CostSavings:        costSavings,
		ROI:                roi,
		Documents:          req.Documents,
		Receipts:           req.Receipts,
		IsVerified:         false,
		IsActive:           true,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     recorderID,
		Operation:  "create_fund_usage",
		EntityType: "fund_usage",
		EntityID:   usage.ID,
		NewValues:  fmt.Sprintf("Recorded fund usage of %f %s for %s", req.UsageAmount, req.Currency, req.UsageCategory),
	})

	return usage, nil
}

// VerifyFundUsage verifies fund usage
func (s *fundManagementService) VerifyFundUsage(ctx context.Context, usageID, verifierID uuid.UUID, comments string) error {
	// Mock implementation - would update usage verification status

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     verifierID,
		Operation:  "verify_fund_usage",
		EntityType: "fund_usage",
		EntityID:   usageID,
		NewValues:  fmt.Sprintf("Verified fund usage with comments: %s", comments),
	})

	return nil
}

// GetFundUsage gets fund usage by ID
func (s *fundManagementService) GetFundUsage(ctx context.Context, usageID uuid.UUID) (*entities.FundUsage, error) {
	// Mock implementation
	return &entities.FundUsage{
		ID:               usageID,
		ProjectID:        uuid.New(),
		BusinessID:       uuid.New(),
		DisbursementID:   uuid.New(),
		UsageCategory:    entities.FundUsageCategoryEquipment,
		UsageAmount:      25000.0,
		Currency:         "IDR",
		UsageDescription: "Purchased new manufacturing equipment",
		UsageDate:        time.Now(),
		RevenueGenerated: 50000.0,
		CostSavings:      10000.0,
		ROI:              200.0,
		IsVerified:       true,
		IsActive:         true,
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}, nil
}

// GetDisbursementUsage gets usage for a specific disbursement
func (s *fundManagementService) GetDisbursementUsage(ctx context.Context, disbursementID uuid.UUID, page, limit int) ([]*entities.FundUsage, int, error) {
	// Mock implementation
	usage := []*entities.FundUsage{
		{
			ID:               uuid.New(),
			ProjectID:        uuid.New(),
			BusinessID:       uuid.New(),
			DisbursementID:   disbursementID,
			UsageCategory:    entities.FundUsageCategoryEquipment,
			UsageAmount:      25000.0,
			Currency:         "IDR",
			UsageDescription: "Purchased new manufacturing equipment",
			UsageDate:        time.Now(),
			RevenueGenerated: 50000.0,
			ROI:              200.0,
			IsVerified:       true,
			IsActive:         true,
			CreatedAt:        time.Now(),
			UpdatedAt:        time.Now(),
		},
	}

	return usage, 1, nil
}

// SearchFundUsage searches fund usage with filters
func (s *fundManagementService) SearchFundUsage(ctx context.Context, filter *entities.FundUsageFilter) ([]*entities.FundUsage, int, error) {
	// Mock implementation
	return s.GetDisbursementUsage(ctx, uuid.New(), filter.Page, filter.Limit)
}

// CalculateFundUsageROI calculates ROI for project fund usage
func (s *fundManagementService) CalculateFundUsageROI(ctx context.Context, projectID uuid.UUID) (float64, error) {
	// Mock implementation - would calculate total ROI from all fund usage
	return 150.0, nil
}

// GetCooperativeFundBalance implements FR-048: Get cooperative fund balance
func (s *fundManagementService) GetCooperativeFundBalance(ctx context.Context, cooperativeID uuid.UUID) (float64, error) {
	// Mock implementation - would get from escrow account
	return 1000000.0, nil
}

// GetProjectFundBalance gets project fund balance
func (s *fundManagementService) GetProjectFundBalance(ctx context.Context, projectID uuid.UUID) (float64, error) {
	// Mock implementation - would calculate from investments and disbursements
	return 250000.0, nil
}

// GetFundAuditTrail gets fund audit trail
func (s *fundManagementService) GetFundAuditTrail(ctx context.Context, projectID uuid.UUID, startDate, endDate time.Time) ([]map[string]interface{}, error) {
	// Mock implementation
	auditTrail := []map[string]interface{}{
		{
			"date":        time.Now(),
			"action":      "fund_disbursement",
			"amount":      50000.0,
			"currency":    "IDR",
			"description": "Milestone disbursement approved",
		},
		{
			"date":        time.Now().AddDate(0, 0, -1),
			"action":      "fund_usage",
			"amount":      25000.0,
			"currency":    "IDR",
			"description": "Equipment purchase recorded",
		},
	}

	return auditTrail, nil
}

// CreateFundRefund implements FR-049: Fund refunds if project fails
func (s *fundManagementService) CreateFundRefund(ctx context.Context, req *entities.CreateFundRefundRequest, initiatorID uuid.UUID) (*entities.FundRefund, error) {
	// Validate refund request
	if req.ProcessingFee < 0 {
		return nil, errors.New("processing fee cannot be negative")
	}

	// Calculate refund amounts
	refundAmounts, err := s.CalculateRefundAmounts(ctx, req.ProjectID, req.RefundType)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate refund amounts: %w", err)
	}

	totalRefundAmount := 0.0
	for _, amount := range refundAmounts {
		totalRefundAmount += amount
	}

	netRefundAmount := totalRefundAmount - req.ProcessingFee

	// Create fund refund record
	refund := &entities.FundRefund{
		ID:                uuid.New(),
		ProjectID:         req.ProjectID,
		CooperativeID:     uuid.Nil, // Will be set based on project's cooperative
		RefundType:        req.RefundType,
		RefundReason:      req.RefundReason,
		TotalRefundAmount: totalRefundAmount,
		Currency:          "IDR", // Will be set based on project currency
		RefundPercentage:  100.0, // Will be calculated based on refund type
		ProcessingFee:     req.ProcessingFee,
		NetRefundAmount:   netRefundAmount,
		Status:            entities.FundRefundStatusPending,
		InitiatedBy:       initiatorID,
		InitiatedAt:       time.Now(),
		EscrowAccountID:   uuid.Nil, // Will be set during processing
		IsActive:          true,
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
	}

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     initiatorID,
		Operation:  "create_fund_refund",
		EntityType: "fund_refund",
		EntityID:   refund.ID,
		NewValues:  fmt.Sprintf("Created refund request for %f %s", totalRefundAmount, refund.Currency),
	})

	return refund, nil
}

// ProcessFundRefund processes the refund
func (s *fundManagementService) ProcessFundRefund(ctx context.Context, refundID, processorID uuid.UUID) error {
	// Mock implementation - would:
	// 1. Calculate individual investor refunds
	// 2. Update refund status to processing
	// 3. Initiate bank transfers

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     processorID,
		Operation:  "process_fund_refund",
		EntityType: "fund_refund",
		EntityID:   refundID,
		NewValues:  "Processing fund refund transfers",
	})

	return nil
}

// CompleteFundRefund completes the refund process
func (s *fundManagementService) CompleteFundRefund(ctx context.Context, refundID, completerID uuid.UUID) error {
	// Mock implementation - would update refund status to completed

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		UserID:     completerID,
		Operation:  "complete_fund_refund",
		EntityType: "fund_refund",
		EntityID:   refundID,
		NewValues:  "Completed fund refund process",
	})

	return nil
}

// GetFundRefund gets refund by ID
func (s *fundManagementService) GetFundRefund(ctx context.Context, refundID uuid.UUID) (*entities.FundRefund, error) {
	// Mock implementation
	return &entities.FundRefund{
		ID:                refundID,
		ProjectID:         uuid.New(),
		CooperativeID:     uuid.New(),
		RefundType:        entities.FundRefundTypeMinimumFundingFailed,
		RefundReason:      "Project failed to meet minimum funding requirement",
		TotalRefundAmount: 100000.0,
		Currency:          "IDR",
		RefundPercentage:  100.0,
		ProcessingFee:     1000.0,
		NetRefundAmount:   99000.0,
		Status:            entities.FundRefundStatusProcessing,
		InitiatedBy:       uuid.New(),
		InitiatedAt:       time.Now(),
		IsActive:          true,
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
	}, nil
}

// GetProjectRefunds gets project refunds
func (s *fundManagementService) GetProjectRefunds(ctx context.Context, projectID uuid.UUID, page, limit int) ([]*entities.FundRefund, int, error) {
	// Mock implementation
	refunds := []*entities.FundRefund{
		{
			ID:                uuid.New(),
			ProjectID:         projectID,
			CooperativeID:     uuid.New(),
			RefundType:        entities.FundRefundTypeMinimumFundingFailed,
			RefundReason:      "Project failed to meet minimum funding requirement",
			TotalRefundAmount: 100000.0,
			Currency:          "IDR",
			RefundPercentage:  100.0,
			ProcessingFee:     1000.0,
			NetRefundAmount:   99000.0,
			Status:            entities.FundRefundStatusProcessing,
			InitiatedBy:       uuid.New(),
			InitiatedAt:       time.Now(),
			IsActive:          true,
			CreatedAt:         time.Now(),
			UpdatedAt:         time.Now(),
		},
	}

	return refunds, 1, nil
}

// SearchFundRefunds searches refunds with filters
func (s *fundManagementService) SearchFundRefunds(ctx context.Context, filter *entities.FundRefundFilter) ([]*entities.FundRefund, int, error) {
	// Mock implementation
	return s.GetProjectRefunds(ctx, uuid.New(), filter.Page, filter.Limit)
}

// CalculateRefundAmounts calculates refund amounts for each investor
func (s *fundManagementService) CalculateRefundAmounts(ctx context.Context, projectID uuid.UUID, refundType string) (map[uuid.UUID]float64, error) {
	// Mock implementation - would calculate based on:
	// 1. Individual investment amounts
	// 2. Refund type and percentage
	// 3. Processing fees

	refundAmounts := map[uuid.UUID]float64{
		uuid.New(): 25000.0,
		uuid.New(): 30000.0,
		uuid.New(): 45000.0,
	}

	return refundAmounts, nil
}

// GetFundManagementSummary gets fund management summary
func (s *fundManagementService) GetFundManagementSummary(ctx context.Context, cooperativeID uuid.UUID, startDate, endDate time.Time) (*entities.FundManagementSummary, error) {
	// Mock implementation
	return &entities.FundManagementSummary{
		TotalDisbursements:   25,
		TotalDisbursedAmount: 2500000.0,
		PendingDisbursements: 5,
		PendingAmount:        500000.0,
		TotalFundUsage:       20,
		TotalUsageAmount:     2000000.0,
		TotalRefunds:         3,
		TotalRefundAmount:    300000.0,
		ProcessingRefunds:    1,
		ProcessingAmount:     100000.0,
		Currency:             "IDR",
	}, nil
}

// GetProjectFundAnalytics gets project fund analytics
func (s *fundManagementService) GetProjectFundAnalytics(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error) {
	// Mock implementation
	return map[string]interface{}{
		"total_investments":     1000000.0,
		"total_disbursements":   800000.0,
		"total_usage":           750000.0,
		"fund_utilization_rate": 93.75,
		"average_roi":           150.0,
		"pending_disbursements": 50000.0,
		"fund_balance":          150000.0,
		"usage_by_category": map[string]interface{}{
			"equipment":  400000.0,
			"marketing":  200000.0,
			"operations": 150000.0,
		},
	}, nil
}
