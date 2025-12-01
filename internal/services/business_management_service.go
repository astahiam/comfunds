package services

import (
	"context"
	"fmt"
	"time"

	"comfunds/internal/entities"
	"comfunds/internal/repositories"

	"github.com/google/uuid"
)

type BusinessManagementService interface {
	// FR-024: Business Registration
	CreateBusiness(ctx context.Context, req *entities.CreateBusinessExtendedRequest, ownerID uuid.UUID) (*entities.BusinessExtended, error)
	ValidateBusinessRegistration(ctx context.Context, registrationNumber, taxID string) (bool, []string, error)

	// FR-025: Business Profile Management
	GetBusiness(ctx context.Context, businessID uuid.UUID) (*entities.BusinessExtended, error)
	UpdateBusiness(ctx context.Context, businessID uuid.UUID, req *entities.UpdateBusinessExtendedRequest, updaterID uuid.UUID) (*entities.BusinessExtended, error)

	// FR-026: Business Registration Document Validation
	ValidateBusinessDocuments(ctx context.Context, businessID uuid.UUID, documents []string) (bool, []string, error)
	UploadBusinessDocument(ctx context.Context, businessID uuid.UUID, documentType, documentURL string, uploaderID uuid.UUID) error

	// FR-027: Business Approval Process
	SubmitBusinessForApproval(ctx context.Context, businessID, submitterID uuid.UUID) error
	ApproveBusinessRegistration(ctx context.Context, req *entities.BusinessApprovalRequest, approverID uuid.UUID) error
	RejectBusinessRegistration(ctx context.Context, req *entities.BusinessRejectionRequest, approverID uuid.UUID) error
	GetPendingBusinessApprovals(ctx context.Context, cooperativeID *uuid.UUID, page, limit int) ([]*entities.BusinessExtended, int, error)

	// FR-028: Business CRUD Operations
	GetOwnerBusinesses(ctx context.Context, ownerID uuid.UUID, page, limit int) ([]*entities.BusinessExtended, int, error)
	GetCooperativeBusinesses(ctx context.Context, cooperativeID uuid.UUID, status string, page, limit int) ([]*entities.BusinessExtended, int, error)
	SearchBusinesses(ctx context.Context, filter *entities.BusinessFilter) ([]*entities.BusinessExtended, int, error)
	DeleteBusiness(ctx context.Context, businessID, deleterID uuid.UUID, reason string) error
	// New: list all businesses for admin
	ListAllBusinesses(ctx context.Context, page, limit int) ([]*entities.BusinessExtended, int, error)

	// FR-029: Multiple Business Management
	GetBusinessesByOwner(ctx context.Context, ownerID uuid.UUID) ([]*entities.BusinessExtended, error)
	TransferBusinessOwnership(ctx context.Context, businessID, currentOwnerID, newOwnerID, transferrerID uuid.UUID) error
	GetBusinessOwnershipHistory(ctx context.Context, businessID uuid.UUID) ([]map[string]interface{}, error)

	// FR-030: Business Performance Metrics
	RecordPerformanceMetrics(ctx context.Context, businessID uuid.UUID, req *entities.CreatePerformanceMetricsRequest, recorderID uuid.UUID) (*entities.BusinessPerformanceMetrics, error)
	GetPerformanceMetrics(ctx context.Context, businessID uuid.UUID, period string, startDate, endDate time.Time) ([]*entities.BusinessPerformanceMetrics, error)
	GetBusinessPerformanceSummary(ctx context.Context, businessID uuid.UUID) (map[string]interface{}, error)
	CompareBusinessPerformance(ctx context.Context, businessID uuid.UUID, compareWith []uuid.UUID, metric string) (map[string]interface{}, error)

	// FR-031: Financial Reporting for Investors
	GenerateFinancialReport(ctx context.Context, businessID uuid.UUID, req *entities.CreateFinancialReportRequest, generatorID uuid.UUID) (*entities.BusinessFinancialReport, error)
	GetFinancialReports(ctx context.Context, businessID uuid.UUID, reportType string, page, limit int) ([]*entities.BusinessFinancialReport, int, error)
	PublishFinancialReport(ctx context.Context, reportID, publisherID uuid.UUID) error
	GetInvestorReports(ctx context.Context, investorID uuid.UUID, page, limit int) ([]*entities.BusinessFinancialReport, int, error)

	// Analytics and insights
	GetBusinessAnalytics(ctx context.Context, businessID uuid.UUID, timeframe string) (map[string]interface{}, error)
	GetIndustryBenchmarks(ctx context.Context, industry, businessType string) (map[string]interface{}, error)
	GenerateBusinessInsights(ctx context.Context, businessID uuid.UUID) (map[string]interface{}, error)
}

type businessManagementService struct {
	auditService   AuditService
	mockBusinesses []*entities.BusinessExtended // Mock repository for testing
	businessRepo   repositories.BusinessRepository
}

func NewBusinessManagementService(auditService AuditService) BusinessManagementService {
	fmt.Printf("DEBUG: Creating new BusinessManagementService instance\n")
	return &businessManagementService{
		auditService:   auditService,
		mockBusinesses: make([]*entities.BusinessExtended, 0),
	}
}

func NewBusinessManagementServiceWithRepo(auditService AuditService, repo repositories.BusinessRepository) BusinessManagementService {
	fmt.Printf("DEBUG: Creating BusinessManagementService with repository\n")
	return &businessManagementService{
		auditService:   auditService,
		businessRepo:   repo,
		mockBusinesses: make([]*entities.BusinessExtended, 0),
	}
}

func (s *businessManagementService) CreateBusiness(ctx context.Context, req *entities.CreateBusinessExtendedRequest, ownerID uuid.UUID) (*entities.BusinessExtended, error) {
	fmt.Printf("DEBUG: CreateBusiness called for owner %s, business name: %s\n", ownerID.String(), req.Name)
	// FR-025: Validate required fields
	if err := s.validateBusinessRegistrationData(req); err != nil {
		return nil, err
	}

	// FR-026: Validate business registration documents
	valid, violations, err := s.ValidateBusinessRegistration(ctx, req.RegistrationNumber, req.TaxID)
	if err != nil {
		return nil, fmt.Errorf("failed to validate business registration: %w", err)
	}
	if !valid {
		return nil, fmt.Errorf("business registration validation failed: %v", violations)
	}

	business := &entities.BusinessExtended{
		ID:                 uuid.New(),
		Name:               req.Name,
		Type:               req.Type,
		Description:        req.Description,
		OwnerID:            ownerID,
		CooperativeID:      req.CooperativeID,
		RegistrationNumber: req.RegistrationNumber,
		TaxID:              req.TaxID,
		LegalStructure:     req.LegalStructure,
		Industry:           req.Industry,
		Sector:             req.Sector,
		Address:            req.Address,
		Phone:              req.Phone,
		Email:              req.Email,
		Website:            req.Website,
		EstablishedDate:    req.EstablishedDate,
		EmployeeCount:      req.EmployeeCount,
		AnnualRevenue:      req.AnnualRevenue,
		Currency:           req.Currency,
		BankAccount:        req.BankAccount,
		BusinessLicense:    req.BusinessLicense,
		BusinessImage:      req.BusinessImage,
		Documents:          req.Documents,
		Status:             entities.BusinessStatusDraft,
		ApprovalStatus:     "pending",
		Metadata:           req.Metadata,
		IsActive:           true,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
	}

	// Save to database using repository
	if s.businessRepo != nil {
		createdBusiness, err := s.businessRepo.Create(ctx, business)
		if err != nil {
			return nil, fmt.Errorf("failed to save business to database: %w", err)
		}
		business = createdBusiness
		fmt.Printf("DEBUG: Created business in database: %s\n", business.Name)
	} else {
		// Fallback to global business store for testing
		GlobalBusinessStore.AddBusiness(business)
		fmt.Printf("DEBUG: Created business %s, total businesses: %d\n", business.Name, len(GlobalBusinessStore.GetAllBusinesses()))
	}

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityBusiness,
		EntityID:   business.ID,
		Operation:  entities.AuditOperationCreate,
		UserID:     ownerID,
		Changes:    map[string]interface{}{"action": "create_business", "name": req.Name, "type": req.Type},
		NewValues:  business,
		Status:     entities.AuditStatusSuccess,
	})

	return business, nil
}

func (s *businessManagementService) ValidateBusinessRegistration(ctx context.Context, registrationNumber, taxID string) (bool, []string, error) {
	var violations []string

	// Validate registration number format
	if len(registrationNumber) < 5 {
		violations = append(violations, "Registration number must be at least 5 characters")
	}

	// Validate tax ID format
	if taxID != "" && len(taxID) < 8 {
		violations = append(violations, "Tax ID must be at least 8 characters")
	}

	// In real implementation, check against external registries
	// - Government business registration database
	// - Tax authority records
	// - Industry-specific licensing bodies

	return len(violations) == 0, violations, nil
}

func (s *businessManagementService) ValidateBusinessDocuments(ctx context.Context, businessID uuid.UUID, documents []string) (bool, []string, error) {
	var violations []string

	requiredDocuments := []string{
		"business_registration_certificate",
		"tax_registration",
		"business_license",
		"owner_id_proof",
		"bank_account_verification",
	}

	documentTypes := make(map[string]bool)
	for _, doc := range documents {
		// Extract document type from document URL/metadata
		// In real implementation, parse document metadata
		documentTypes[doc] = true
	}

	// Check required documents
	for _, reqDoc := range requiredDocuments {
		if !documentTypes[reqDoc] {
			violations = append(violations, fmt.Sprintf("Missing required document: %s", reqDoc))
		}
	}

	return len(violations) == 0, violations, nil
}

func (s *businessManagementService) SubmitBusinessForApproval(ctx context.Context, businessID, submitterID uuid.UUID) error {
	// Get business
	// business, err := s.businessRepo.GetByID(ctx, businessID)

	// Validate all required documents are present
	// documents := business.Documents
	// valid, violations, err := s.ValidateBusinessDocuments(ctx, businessID, documents)

	// Update business status
	// business.Status = entities.BusinessStatusPendingApproval
	// business.UpdatedAt = time.Now()

	// In real implementation, update repository
	// s.businessRepo.Update(ctx, businessID, business)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityBusiness,
		EntityID:   businessID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     submitterID,
		Changes:    map[string]interface{}{"action": "submit_for_approval", "status": entities.BusinessStatusPendingApproval},
		Status:     entities.AuditStatusSuccess,
	})

	return nil
}

func (s *businessManagementService) ApproveBusinessRegistration(ctx context.Context, req *entities.BusinessApprovalRequest, approverID uuid.UUID) error {
	// If repo available, update DB, else fallback to in-memory
	if s.businessRepo != nil {
		if err := s.businessRepo.ApproveBusiness(ctx, req.BusinessID); err != nil {
			return err
		}
	} else {
		GlobalBusinessStore.UpdateBusinessStatus(req.BusinessID, "approved")
	}
	fmt.Printf("DEBUG: Approved business %s\n", req.BusinessID.String())

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityBusiness,
		EntityID:   req.BusinessID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     approverID,
		Changes:    map[string]interface{}{"action": "approve_business", "comments": req.Comments},
		Status:     entities.AuditStatusSuccess,
	})

	return nil
}

func (s *businessManagementService) RejectBusinessRegistration(ctx context.Context, req *entities.BusinessRejectionRequest, approverID uuid.UUID) error {
	if s.businessRepo != nil {
		if err := s.businessRepo.RejectBusiness(ctx, req.BusinessID, req.Reason); err != nil {
			return err
		}
	} else {
		GlobalBusinessStore.UpdateBusinessStatus(req.BusinessID, "rejected")
	}
	fmt.Printf("DEBUG: Rejected business %s\n", req.BusinessID.String())

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityBusiness,
		EntityID:   req.BusinessID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     approverID,
		Changes:    map[string]interface{}{"action": "reject_business", "reason": req.Reason, "feedback": req.Feedback},
		Status:     entities.AuditStatusSuccess,
	})

	return nil
}

func (s *businessManagementService) RecordPerformanceMetrics(ctx context.Context, businessID uuid.UUID, req *entities.CreatePerformanceMetricsRequest, recorderID uuid.UUID) (*entities.BusinessPerformanceMetrics, error) {
	// Calculate derived metrics
	netProfit := req.Revenue - req.Expenses
	grossMargin := 0.0
	if req.Revenue > 0 {
		grossMargin = (req.Revenue - req.Expenses) / req.Revenue
	}

	var operatingMargin float64
	if req.Revenue > 0 {
		operatingMargin = netProfit / req.Revenue
	}

	metrics := &entities.BusinessPerformanceMetrics{
		ID:                   uuid.New(),
		BusinessID:           businessID,
		MetricType:           req.MetricType,
		Period:               req.Period,
		PeriodStart:          req.PeriodStart,
		PeriodEnd:            req.PeriodEnd,
		Revenue:              req.Revenue,
		Expenses:             req.Expenses,
		NetProfit:            netProfit,
		GrossMargin:          grossMargin,
		OperatingMargin:      operatingMargin,
		CustomerCount:        req.CustomerCount,
		OrderCount:           req.OrderCount,
		AverageOrderValue:    req.AverageOrderValue,
		CustomerAcquisition:  req.CustomerAcquisition,
		CustomerRetention:    req.CustomerRetention,
		MarketShare:          req.MarketShare,
		GrowthRate:           req.GrowthRate,
		EmployeeProductivity: req.EmployeeProductivity,
		KPIs:                 req.KPIs,
		Goals:                req.Goals,
		Notes:                req.Notes,
		RecordedBy:           recorderID,
		CreatedAt:            time.Now(),
		UpdatedAt:            time.Now(),
	}

	// In real implementation, save to repository
	// createdMetrics, err := s.metricsRepo.Create(ctx, metrics)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityBusiness,
		EntityID:   businessID,
		Operation:  entities.AuditOperationCreate,
		UserID:     recorderID,
		Changes:    map[string]interface{}{"action": "record_performance_metrics", "period": req.Period, "revenue": req.Revenue},
		NewValues:  metrics,
		Status:     entities.AuditStatusSuccess,
	})

	return metrics, nil
}

func (s *businessManagementService) GenerateFinancialReport(ctx context.Context, businessID uuid.UUID, req *entities.CreateFinancialReportRequest, generatorID uuid.UUID) (*entities.BusinessFinancialReport, error) {
	// Calculate financial ratios and metrics
	netIncome := req.TotalRevenue - req.TotalExpenses
	grossProfit := req.TotalRevenue // Simplified, would need cost of goods sold

	var roi, roe, debtToEquity, currentRatio float64
	equity := req.Assets - req.Liabilities

	if req.Assets > 0 {
		roi = netIncome / req.Assets
	}
	if equity > 0 {
		roe = netIncome / equity
	}
	if equity > 0 {
		debtToEquity = req.Liabilities / equity
	}

	// Generate period string
	periodStr := fmt.Sprintf("%s - %s", req.PeriodStart.Format("2006-01-02"), req.PeriodEnd.Format("2006-01-02"))

	report := &entities.BusinessFinancialReport{
		ID:               uuid.New(),
		BusinessID:       businessID,
		ReportType:       req.ReportType,
		ReportPeriod:     periodStr,
		PeriodStart:      req.PeriodStart,
		PeriodEnd:        req.PeriodEnd,
		Currency:         req.Currency,
		TotalRevenue:     req.TotalRevenue,
		TotalExpenses:    req.TotalExpenses,
		NetIncome:        netIncome,
		GrossProfit:      grossProfit,
		OperatingIncome:  netIncome, // Simplified
		Assets:           req.Assets,
		Liabilities:      req.Liabilities,
		Equity:           equity,
		CashFlow:         req.CashFlow,
		ROI:              roi,
		ROE:              roe,
		DebtToEquity:     debtToEquity,
		CurrentRatio:     currentRatio,
		FinancialDetails: req.FinancialDetails,
		Attachments:      req.Attachments,
		Summary:          req.Summary,
		Highlights:       req.Highlights,
		Challenges:       req.Challenges,
		Outlook:          req.Outlook,
		ApprovalRequired: true,
		Status:           "draft",
		GeneratedBy:      generatorID,
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}

	// In real implementation, save to repository
	// createdReport, err := s.reportRepo.Create(ctx, report)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityBusiness,
		EntityID:   businessID,
		Operation:  entities.AuditOperationCreate,
		UserID:     generatorID,
		Changes:    map[string]interface{}{"action": "generate_financial_report", "report_type": req.ReportType, "period": periodStr},
		NewValues:  report,
		Status:     entities.AuditStatusSuccess,
	})

	return report, nil
}

func (s *businessManagementService) GetBusinessAnalytics(ctx context.Context, businessID uuid.UUID, timeframe string) (map[string]interface{}, error) {
	// Mock analytics data
	analytics := map[string]interface{}{
		"business_id": businessID,
		"timeframe":   timeframe,
		"performance": map[string]interface{}{
			"revenue_growth":   12.5,
			"profit_margin":    15.2,
			"customer_growth":  8.7,
			"market_share":     2.3,
			"efficiency_score": 78.5,
		},
		"trends": map[string]interface{}{
			"revenue_trend":  "increasing",
			"cost_trend":     "stable",
			"customer_trend": "growing",
			"profitability":  "improving",
		},
		"benchmarks": map[string]interface{}{
			"industry_average_margin": 12.8,
			"industry_growth_rate":    10.2,
			"peer_comparison":         "above_average",
		},
		"recommendations": []string{
			"Focus on customer retention programs",
			"Optimize operational costs",
			"Explore new market segments",
		},
		"generated_at": time.Now(),
	}

	return analytics, nil
}

// Mock implementations for interface compliance
func (s *businessManagementService) GetBusiness(ctx context.Context, businessID uuid.UUID) (*entities.BusinessExtended, error) {
	if s.businessRepo == nil {
		// Fallback to in-memory store
		business := GlobalBusinessStore.GetBusinessByID(businessID)
		if business == nil {
			return nil, fmt.Errorf("business not found")
		}
		return business, nil
	}
	business, err := s.businessRepo.GetByID(ctx, businessID)
	if err != nil {
		return nil, fmt.Errorf("failed to get business from repository: %w", err)
	}
	return business, nil
}

func (s *businessManagementService) UpdateBusiness(ctx context.Context, businessID uuid.UUID, req *entities.UpdateBusinessExtendedRequest, updaterID uuid.UUID) (*entities.BusinessExtended, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *businessManagementService) UploadBusinessDocument(ctx context.Context, businessID uuid.UUID, documentType, documentURL string, uploaderID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires document storage")
}

func (s *businessManagementService) GetPendingBusinessApprovals(ctx context.Context, cooperativeID *uuid.UUID, page, limit int) ([]*entities.BusinessExtended, int, error) {
	fmt.Printf("DEBUG: GetPendingBusinessApprovals called\n")
	if s.businessRepo != nil {
		offset := (page - 1) * limit
		return s.businessRepo.GetPendingBusinesses(ctx, cooperativeID, limit, offset)
	}

	// Get pending businesses from global store
	allPendingBusinesses := GlobalBusinessStore.GetPendingBusinesses(cooperativeID)
	fmt.Printf("DEBUG: Found %d pending businesses\n", len(allPendingBusinesses))

	// Simple pagination
	total := len(allPendingBusinesses)
	start := (page - 1) * limit
	end := start + limit

	if start > total {
		return []*entities.BusinessExtended{}, total, nil
	}

	if end > total {
		end = total
	}

	if start >= end {
		return []*entities.BusinessExtended{}, total, nil
	}

	return allPendingBusinesses[start:end], total, nil
}

func (s *businessManagementService) GetOwnerBusinesses(ctx context.Context, ownerID uuid.UUID, page, limit int) ([]*entities.BusinessExtended, int, error) {
	fmt.Printf("DEBUG: GetOwnerBusinesses called for owner %s\n", ownerID.String())
	if s.businessRepo != nil {
		offset := (page - 1) * limit
		return s.businessRepo.GetByOwner(ctx, ownerID, limit, offset)
	}

	// Get businesses from global store
	allBusinesses := GlobalBusinessStore.GetBusinessesByOwner(ownerID)
	fmt.Printf("DEBUG: Found %d businesses for owner %s\n", len(allBusinesses), ownerID.String())

	// Simple pagination
	total := len(allBusinesses)
	start := (page - 1) * limit
	end := start + limit

	if start > total {
		return []*entities.BusinessExtended{}, total, nil
	}

	if end > total {
		end = total
	}

	if start >= end {
		return []*entities.BusinessExtended{}, total, nil
	}

	return allBusinesses[start:end], total, nil
}

func (s *businessManagementService) GetCooperativeBusinesses(ctx context.Context, cooperativeID uuid.UUID, status string, page, limit int) ([]*entities.BusinessExtended, int, error) {
	return []*entities.BusinessExtended{}, 0, nil
}

func (s *businessManagementService) SearchBusinesses(ctx context.Context, filter *entities.BusinessFilter) ([]*entities.BusinessExtended, int, error) {
	return []*entities.BusinessExtended{}, 0, nil
}

func (s *businessManagementService) ListAllBusinesses(ctx context.Context, page, limit int) ([]*entities.BusinessExtended, int, error) {
	fmt.Printf("DEBUG: ListAllBusinesses called, businessRepo is nil: %v\n", s.businessRepo == nil)
	if s.businessRepo == nil {
		// Fallback to in-memory store contents
		all := GlobalBusinessStore.GetAllBusinesses()
		total := len(all)
		fmt.Printf("DEBUG: Using in-memory store, found %d businesses\n", total)
		start := (page - 1) * limit
		end := start + limit
		if start > total {
			return []*entities.BusinessExtended{}, total, nil
		}
		if end > total {
			end = total
		}
		if start >= end {
			return []*entities.BusinessExtended{}, total, nil
		}
		return all[start:end], total, nil
	}
	fmt.Printf("DEBUG: Using database repository\n")
	offset := (page - 1) * limit
	businesses, total, err := s.businessRepo.GetAll(ctx, limit, offset)
	fmt.Printf("DEBUG: Repository returned %d businesses, total=%d, error=%v\n", len(businesses), total, err)
	return businesses, total, err
}

func (s *businessManagementService) DeleteBusiness(ctx context.Context, businessID, deleterID uuid.UUID, reason string) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *businessManagementService) GetBusinessesByOwner(ctx context.Context, ownerID uuid.UUID) ([]*entities.BusinessExtended, error) {
	return []*entities.BusinessExtended{}, nil
}

func (s *businessManagementService) TransferBusinessOwnership(ctx context.Context, businessID, currentOwnerID, newOwnerID, transferrerID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *businessManagementService) GetBusinessOwnershipHistory(ctx context.Context, businessID uuid.UUID) ([]map[string]interface{}, error) {
	return []map[string]interface{}{}, nil
}

func (s *businessManagementService) GetPerformanceMetrics(ctx context.Context, businessID uuid.UUID, period string, startDate, endDate time.Time) ([]*entities.BusinessPerformanceMetrics, error) {
	return []*entities.BusinessPerformanceMetrics{}, nil
}

func (s *businessManagementService) GetBusinessPerformanceSummary(ctx context.Context, businessID uuid.UUID) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (s *businessManagementService) CompareBusinessPerformance(ctx context.Context, businessID uuid.UUID, compareWith []uuid.UUID, metric string) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (s *businessManagementService) GetFinancialReports(ctx context.Context, businessID uuid.UUID, reportType string, page, limit int) ([]*entities.BusinessFinancialReport, int, error) {
	return []*entities.BusinessFinancialReport{}, 0, nil
}

func (s *businessManagementService) PublishFinancialReport(ctx context.Context, reportID, publisherID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *businessManagementService) GetInvestorReports(ctx context.Context, investorID uuid.UUID, page, limit int) ([]*entities.BusinessFinancialReport, int, error) {
	return []*entities.BusinessFinancialReport{}, 0, nil
}

func (s *businessManagementService) GetIndustryBenchmarks(ctx context.Context, industry, businessType string) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (s *businessManagementService) GenerateBusinessInsights(ctx context.Context, businessID uuid.UUID) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

// Helper methods
func (s *businessManagementService) validateBusinessRegistrationData(req *entities.CreateBusinessExtendedRequest) error {
	if req.EstablishedDate.After(time.Now()) {
		return fmt.Errorf("established date cannot be in the future")
	}

	if req.EmployeeCount < 0 {
		return fmt.Errorf("employee count cannot be negative")
	}

	if req.AnnualRevenue < 0 {
		return fmt.Errorf("annual revenue cannot be negative")
	}

	return nil
}
