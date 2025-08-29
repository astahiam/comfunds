package entities

import (
	"time"

	"github.com/google/uuid"
)

// ProfitCalculation represents Sharia-compliant profit calculation (FR-050 to FR-053)
type ProfitCalculation struct {
	ID                 uuid.UUID              `json:"id" db:"id"`
	ProjectID          uuid.UUID              `json:"project_id" db:"project_id"`
	BusinessID         uuid.UUID              `json:"business_id" db:"business_id"`
	CooperativeID      uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	CalculationPeriod  string                 `json:"calculation_period" db:"calculation_period"` // monthly, quarterly, annual
	StartDate          time.Time              `json:"start_date" db:"start_date"`
	EndDate            time.Time              `json:"end_date" db:"end_date"`
	TotalRevenue       float64                `json:"total_revenue" db:"total_revenue"`
	TotalExpenses      float64                `json:"total_expenses" db:"total_expenses"`
	NetProfit          float64                `json:"net_profit" db:"net_profit"`
	TotalLoss          float64                `json:"total_loss" db:"total_loss"`
	ProfitSharingRatio map[string]float64     `json:"profit_sharing_ratio" db:"profit_sharing_ratio"` // investor: 70, business: 30
	InvestorShare      float64                `json:"investor_share" db:"investor_share"`
	BusinessShare      float64                `json:"business_share" db:"business_share"`
	CooperativeShare   float64                `json:"cooperative_share" db:"cooperative_share"`
	ShariaCompliant    bool                   `json:"sharia_compliant" db:"sharia_compliant"`
	ComplianceNotes    string                 `json:"compliance_notes" db:"compliance_notes"`
	VerificationStatus string                 `json:"verification_status" db:"verification_status"` // pending, verified, rejected
	VerifiedBy         *uuid.UUID             `json:"verified_by" db:"verified_by"`
	VerifiedAt         *time.Time             `json:"verified_at" db:"verified_at"`
	RejectionReason    string                 `json:"rejection_reason" db:"rejection_reason"`
	Documents          []string               `json:"documents" db:"documents"`
	Metadata           map[string]interface{} `json:"metadata" db:"metadata"`
	IsActive           bool                   `json:"is_active" db:"is_active"`
	CreatedAt          time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time              `json:"updated_at" db:"updated_at"`
}

// ProfitDistributionExtended represents profit distribution to investors (FR-054 to FR-057)
type ProfitDistributionExtended struct {
	ID                      uuid.UUID              `json:"id" db:"id"`
	ProfitCalculationID     uuid.UUID              `json:"profit_calculation_id" db:"profit_calculation_id"`
	ProjectID               uuid.UUID              `json:"project_id" db:"project_id"`
	CooperativeID           uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	DistributionType        string                 `json:"distribution_type" db:"distribution_type"` // profit, loss_compensation
	TotalDistributionAmount float64                `json:"total_distribution_amount" db:"total_distribution_amount"`
	Currency                string                 `json:"currency" db:"currency"`
	DistributionDate        time.Time              `json:"distribution_date" db:"distribution_date"`
	Status                  string                 `json:"status" db:"status"` // pending, processing, completed, failed, cancelled
	ProcessedBy             *uuid.UUID             `json:"processed_by" db:"processed_by"`
	ProcessedAt             *time.Time             `json:"processed_at" db:"processed_at"`
	CompletedAt             *time.Time             `json:"completed_at" db:"completed_at"`
	EscrowAccountID         uuid.UUID              `json:"escrow_account_id" db:"escrow_account_id"`
	TransactionReference    string                 `json:"transaction_reference" db:"transaction_reference"`
	TaxDocumentationID      *uuid.UUID             `json:"tax_documentation_id" db:"tax_documentation_id"`
	Documents               []string               `json:"documents" db:"documents"`
	Metadata                map[string]interface{} `json:"metadata" db:"metadata"`
	IsActive                bool                   `json:"is_active" db:"is_active"`
	CreatedAt               time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt               time.Time              `json:"updated_at" db:"updated_at"`
}

// InvestorProfitShare represents individual investor profit shares
type InvestorProfitShare struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	ProfitDistributionID uuid.UUID  `json:"profit_distribution_id" db:"profit_distribution_id"`
	InvestmentID         uuid.UUID  `json:"investment_id" db:"investment_id"`
	InvestorID           uuid.UUID  `json:"investor_id" db:"investor_id"`
	OriginalInvestment   float64    `json:"original_investment" db:"original_investment"`
	InvestmentPercentage float64    `json:"investment_percentage" db:"investment_percentage"` // percentage of total project investment
	ProfitShareAmount    float64    `json:"profit_share_amount" db:"profit_share_amount"`
	TaxAmount            float64    `json:"tax_amount" db:"tax_amount"`
	NetProfitShare       float64    `json:"net_profit_share" db:"net_profit_share"`
	Status               string     `json:"status" db:"status"` // pending, processed, completed, failed
	BankAccount          string     `json:"bank_account" db:"bank_account"`
	TransactionReference string     `json:"transaction_reference" db:"transaction_reference"`
	ProcessedAt          *time.Time `json:"processed_at" db:"processed_at"`
	CompletedAt          *time.Time `json:"completed_at" db:"completed_at"`
	TaxDocumentID        *uuid.UUID `json:"tax_document_id" db:"tax_document_id"`
	IsActive             bool       `json:"is_active" db:"is_active"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

// TaxDocumentation represents tax-compliant documentation for profit distributions (FR-057)
type TaxDocumentation struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	ProfitDistributionID uuid.UUID  `json:"profit_distribution_id" db:"profit_distribution_id"`
	DocumentType         string     `json:"document_type" db:"document_type"` // tax_certificate, withholding_tax, annual_report
	DocumentNumber       string     `json:"document_number" db:"document_number"`
	TaxYear              int        `json:"tax_year" db:"tax_year"`
	TaxPeriod            string     `json:"tax_period" db:"tax_period"` // monthly, quarterly, annual
	TotalTaxableAmount   float64    `json:"total_taxable_amount" db:"total_taxable_amount"`
	TotalTaxAmount       float64    `json:"total_tax_amount" db:"total_tax_amount"`
	TaxRate              float64    `json:"tax_rate" db:"tax_rate"`
	Currency             string     `json:"currency" db:"currency"`
	IssuedDate           time.Time  `json:"issued_date" db:"issued_date"`
	DueDate              time.Time  `json:"due_date" db:"due_date"`
	Status               string     `json:"status" db:"status"` // draft, issued, paid, overdue
	IssuedBy             uuid.UUID  `json:"issued_by" db:"issued_by"`
	PaidAt               *time.Time `json:"paid_at" db:"paid_at"`
	PaymentReference     string     `json:"payment_reference" db:"payment_reference"`
	Documents            []string   `json:"documents" db:"documents"`
	ComplianceNotes      string     `json:"compliance_notes" db:"compliance_notes"`
	IsActive             bool       `json:"is_active" db:"is_active"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

// CreateProfitCalculationRequest for FR-050 to FR-053
type CreateProfitCalculationRequest struct {
	ProjectID          uuid.UUID          `json:"project_id" validate:"required"`
	CalculationPeriod  string             `json:"calculation_period" validate:"required,oneof=monthly quarterly annual"`
	StartDate          time.Time          `json:"start_date" validate:"required"`
	EndDate            time.Time          `json:"end_date" validate:"required"`
	TotalRevenue       float64            `json:"total_revenue" validate:"required,min=0"`
	TotalExpenses      float64            `json:"total_expenses" validate:"required,min=0"`
	ProfitSharingRatio map[string]float64 `json:"profit_sharing_ratio" validate:"required"`
	Documents          []string           `json:"documents"`
	ComplianceNotes    string             `json:"compliance_notes"`
}

// VerifyProfitCalculationRequest for FR-053
type VerifyProfitCalculationRequest struct {
	CalculationID      uuid.UUID `json:"calculation_id" validate:"required"`
	VerificationStatus string    `json:"verification_status" validate:"required,oneof=verified rejected"`
	Comments           string    `json:"comments"`
	RejectionReason    string    `json:"rejection_reason" validate:"required_if=VerificationStatus rejected"`
}

// CreateProfitDistributionExtendedRequest for FR-054 to FR-056
type CreateProfitDistributionExtendedRequest struct {
	ProfitCalculationID uuid.UUID `json:"profit_calculation_id" validate:"required"`
	DistributionType    string    `json:"distribution_type" validate:"required,oneof=profit loss_compensation"`
	DistributionDate    time.Time `json:"distribution_date" validate:"required"`
}

// ProcessProfitDistributionRequest for processing distributions
type ProcessProfitDistributionRequest struct {
	DistributionID uuid.UUID `json:"distribution_id" validate:"required"`
	ProcessAll     bool      `json:"process_all"` // Process all investor shares at once
}

// CreateTaxDocumentationRequest for FR-057
type CreateTaxDocumentationRequest struct {
	ProfitDistributionID uuid.UUID `json:"profit_distribution_id" validate:"required"`
	DocumentType         string    `json:"document_type" validate:"required,oneof=tax_certificate withholding_tax annual_report"`
	TaxYear              int       `json:"tax_year" validate:"required,min=2020"`
	TaxPeriod            string    `json:"tax_period" validate:"required,oneof=monthly quarterly annual"`
	TaxRate              float64   `json:"tax_rate" validate:"required,min=0,max=100"`
	DueDate              time.Time `json:"due_date" validate:"required"`
	ComplianceNotes      string    `json:"compliance_notes"`
}

// ProfitCalculationFilter for searching profit calculations
type ProfitCalculationFilter struct {
	ProjectID          *uuid.UUID `json:"project_id"`
	BusinessID         *uuid.UUID `json:"business_id"`
	CooperativeID      *uuid.UUID `json:"cooperative_id"`
	CalculationPeriod  *string    `json:"calculation_period"`
	VerificationStatus *string    `json:"verification_status"`
	ShariaCompliant    *bool      `json:"sharia_compliant"`
	StartDate          *time.Time `json:"start_date"`
	EndDate            *time.Time `json:"end_date"`
	MinProfit          *float64   `json:"min_profit"`
	MaxProfit          *float64   `json:"max_profit"`
	Page               int        `json:"page" validate:"min=1"`
	Limit              int        `json:"limit" validate:"min=1,max=100"`
}

// ProfitDistributionExtendedFilter for searching profit distributions
type ProfitDistributionExtendedFilter struct {
	ProjectID        *uuid.UUID `json:"project_id"`
	CooperativeID    *uuid.UUID `json:"cooperative_id"`
	DistributionType *string    `json:"distribution_type"`
	Status           *string    `json:"status"`
	StartDate        *time.Time `json:"start_date"`
	EndDate          *time.Time `json:"end_date"`
	MinAmount        *float64   `json:"min_amount"`
	MaxAmount        *float64   `json:"max_amount"`
	Page             int        `json:"page" validate:"min=1"`
	Limit            int        `json:"limit" validate:"min=1,max=100"`
}

// TaxDocumentationFilter for searching tax documentation
type TaxDocumentationFilter struct {
	ProfitDistributionID *uuid.UUID `json:"profit_distribution_id"`
	DocumentType         *string    `json:"document_type"`
	TaxYear              *int       `json:"tax_year"`
	Status               *string    `json:"status"`
	StartDate            *time.Time `json:"start_date"`
	EndDate              *time.Time `json:"end_date"`
	Page                 int        `json:"page" validate:"min=1"`
	Limit                int        `json:"limit" validate:"min=1,max=100"`
}

// ComFundsFee represents the platform fee structure
type ComFundsFee struct {
	ID            uuid.UUID  `json:"id" db:"id"`
	FeeType       string     `json:"fee_type" db:"fee_type"` // platform_fee, success_fee, transaction_fee
	FeePercentage float64    `json:"fee_percentage" db:"fee_percentage"`
	FeeAmount     float64    `json:"fee_amount" db:"fee_amount"`
	IsEnabled     bool       `json:"is_enabled" db:"is_enabled"`
	MinimumAmount float64    `json:"minimum_amount" db:"minimum_amount"`
	MaximumAmount float64    `json:"maximum_amount" db:"maximum_amount"`
	ApplicableTo  string     `json:"applicable_to" db:"applicable_to"` // all_projects, successful_funding, specific_projects
	ProjectID     *uuid.UUID `json:"project_id" db:"project_id"`
	CooperativeID *uuid.UUID `json:"cooperative_id" db:"cooperative_id"`
	EffectiveFrom time.Time  `json:"effective_from" db:"effective_from"`
	EffectiveTo   *time.Time `json:"effective_to" db:"effective_to"`
	Description   string     `json:"description" db:"description"`
	IsActive      bool       `json:"is_active" db:"is_active"`
	CreatedAt     time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at" db:"updated_at"`
}

// ProjectFeeCalculation represents fee calculation for a specific project
type ProjectFeeCalculation struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	ProjectID            uuid.UUID  `json:"project_id" db:"project_id"`
	CooperativeID        uuid.UUID  `json:"cooperative_id" db:"cooperative_id"`
	TotalFundingAmount   float64    `json:"total_funding_amount" db:"total_funding_amount"`
	FeePercentage        float64    `json:"fee_percentage" db:"fee_percentage"`
	FeeAmount            float64    `json:"fee_amount" db:"fee_amount"`
	NetAmountAfterFee    float64    `json:"net_amount_after_fee" db:"net_amount_after_fee"`
	FeeStatus            string     `json:"fee_status" db:"fee_status"` // pending, calculated, collected, waived
	CalculatedAt         time.Time  `json:"calculated_at" db:"calculated_at"`
	CollectedAt          *time.Time `json:"collected_at" db:"collected_at"`
	CollectedBy          *uuid.UUID `json:"collected_by" db:"collected_by"`
	TransactionReference string     `json:"transaction_reference" db:"transaction_reference"`
	Notes                string     `json:"notes" db:"notes"`
	IsActive             bool       `json:"is_active" db:"is_active"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

// CreateComFundsFeeRequest for creating/updating fee structure
type CreateComFundsFeeRequest struct {
	FeeType       string     `json:"fee_type" validate:"required,oneof=platform_fee success_fee transaction_fee"`
	FeePercentage float64    `json:"fee_percentage" validate:"required,min=0,max=100"`
	IsEnabled     bool       `json:"is_enabled"`
	MinimumAmount float64    `json:"minimum_amount" validate:"min=0"`
	MaximumAmount float64    `json:"maximum_amount" validate:"min=0"`
	ApplicableTo  string     `json:"applicable_to" validate:"required,oneof=all_projects successful_funding specific_projects"`
	ProjectID     *uuid.UUID `json:"project_id"`
	CooperativeID *uuid.UUID `json:"cooperative_id"`
	EffectiveFrom time.Time  `json:"effective_from" validate:"required"`
	EffectiveTo   *time.Time `json:"effective_to"`
	Description   string     `json:"description"`
}

// CalculateProjectFeeRequest for calculating project fees
type CalculateProjectFeeRequest struct {
	ProjectID          uuid.UUID `json:"project_id" validate:"required"`
	TotalFundingAmount float64   `json:"total_funding_amount" validate:"required,min=0"`
	CalculateDate      time.Time `json:"calculate_date" validate:"required"`
}

// CollectProjectFeeRequest for collecting project fees
type CollectProjectFeeRequest struct {
	ProjectFeeCalculationID uuid.UUID `json:"project_fee_calculation_id" validate:"required"`
	CollectionMethod        string    `json:"collection_method" validate:"required,oneof=automatic manual bank_transfer"`
	TransactionReference    string    `json:"transaction_reference"`
	Notes                   string    `json:"notes"`
}

// ComFundsFeeFilter for searching fee structures
type ComFundsFeeFilter struct {
	FeeType       *string    `json:"fee_type"`
	IsEnabled     *bool      `json:"is_enabled"`
	ApplicableTo  *string    `json:"applicable_to"`
	ProjectID     *uuid.UUID `json:"project_id"`
	CooperativeID *uuid.UUID `json:"cooperative_id"`
	EffectiveFrom *time.Time `json:"effective_from"`
	EffectiveTo   *time.Time `json:"effective_to"`
	Page          int        `json:"page" validate:"min=1"`
	Limit         int        `json:"limit" validate:"min=1,max=100"`
}

// ProjectFeeCalculationFilter for searching project fee calculations
type ProjectFeeCalculationFilter struct {
	ProjectID     *uuid.UUID `json:"project_id"`
	CooperativeID *uuid.UUID `json:"cooperative_id"`
	FeeStatus     *string    `json:"fee_status"`
	StartDate     *time.Time `json:"start_date"`
	EndDate       *time.Time `json:"end_date"`
	MinAmount     *float64   `json:"min_amount"`
	MaxAmount     *float64   `json:"max_amount"`
	Page          int        `json:"page" validate:"min=1"`
	Limit         int        `json:"limit" validate:"min=1,max=100"`
}

// ProfitSharingSummary for reporting
type ProfitSharingSummary struct {
	TotalCalculations      int     `json:"total_calculations"`
	TotalProfit            float64 `json:"total_profit"`
	TotalLoss              float64 `json:"total_loss"`
	TotalDistributions     int     `json:"total_distributions"`
	TotalDistributedAmount float64 `json:"total_distributed_amount"`
	PendingDistributions   int     `json:"pending_distributions"`
	PendingAmount          float64 `json:"pending_amount"`
	TotalTaxAmount         float64 `json:"total_tax_amount"`
	TotalTaxDocuments      int     `json:"total_tax_documents"`
	TotalPlatformFees      float64 `json:"total_platform_fees"`
	TotalFeeCollections    int     `json:"total_fee_collections"`
	Currency               string  `json:"currency"`
}

// Profit constants
const (
	ProfitCalculationStatusPending  = "pending"
	ProfitCalculationStatusVerified = "verified"
	ProfitCalculationStatusRejected = "rejected"

	ProfitCalculationPeriodMonthly   = "monthly"
	ProfitCalculationPeriodQuarterly = "quarterly"
	ProfitCalculationPeriodAnnual    = "annual"

	ProfitDistributionStatusPending    = "pending"
	ProfitDistributionStatusProcessing = "processing"
	ProfitDistributionStatusCompleted  = "completed"
	ProfitDistributionStatusFailed     = "failed"
	ProfitDistributionStatusCancelled  = "cancelled"

	ProfitDistributionTypeProfit           = "profit"
	ProfitDistributionTypeLossCompensation = "loss_compensation"

	InvestorProfitShareStatusPending   = "pending"
	InvestorProfitShareStatusProcessed = "processed"
	InvestorProfitShareStatusCompleted = "completed"
	InvestorProfitShareStatusFailed    = "failed"

	TaxDocumentStatusDraft   = "draft"
	TaxDocumentStatusIssued  = "issued"
	TaxDocumentStatusPaid    = "paid"
	TaxDocumentStatusOverdue = "overdue"

	TaxDocumentTypeTaxCertificate = "tax_certificate"
	TaxDocumentTypeWithholdingTax = "withholding_tax"
	TaxDocumentTypeAnnualReport   = "annual_report"

	TaxPeriodMonthly   = "monthly"
	TaxPeriodQuarterly = "quarterly"
	TaxPeriodAnnual    = "annual"

	// Fee constants
	ComFundsFeeTypePlatformFee    = "platform_fee"
	ComFundsFeeTypeSuccessFee     = "success_fee"
	ComFundsFeeTypeTransactionFee = "transaction_fee"

	ComFundsFeeApplicableToAllProjects       = "all_projects"
	ComFundsFeeApplicableToSuccessfulFunding = "successful_funding"
	ComFundsFeeApplicableToSpecificProjects  = "specific_projects"

	ProjectFeeStatusPending    = "pending"
	ProjectFeeStatusCalculated = "calculated"
	ProjectFeeStatusCollected  = "collected"
	ProjectFeeStatusWaived     = "waived"

	ProjectFeeCollectionMethodAutomatic    = "automatic"
	ProjectFeeCollectionMethodManual       = "manual"
	ProjectFeeCollectionMethodBankTransfer = "bank_transfer"
)
