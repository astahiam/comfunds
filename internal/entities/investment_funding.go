package entities

import (
	"time"

	"github.com/google/uuid"
)

// InvestmentExtended represents a cooperative member's investment in a project (FR-041 to FR-045)
type InvestmentExtended struct {
	ID                   uuid.UUID              `json:"id" db:"id"`
	InvestorID           uuid.UUID              `json:"investor_id" db:"investor_id"`
	ProjectID            uuid.UUID              `json:"project_id" db:"project_id"`
	CooperativeID        uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	Amount               float64                `json:"amount" db:"amount"`
	Currency             string                 `json:"currency" db:"currency"`
	InvestmentType       string                 `json:"investment_type" db:"investment_type"`             // full, partial
	InvestmentPercentage float64                `json:"investment_percentage" db:"investment_percentage"` // percentage of total funding
	Status               string                 `json:"status" db:"status"`                               // pending, approved, rejected, active, completed, cancelled
	ApprovalStatus       string                 `json:"approval_status" db:"approval_status"`
	ApprovedBy           *uuid.UUID             `json:"approved_by" db:"approved_by"`
	ApprovedAt           *time.Time             `json:"approved_at" db:"approved_at"`
	RejectionReason      string                 `json:"rejection_reason" db:"rejection_reason"`
	EscrowAccountID      uuid.UUID              `json:"escrow_account_id" db:"escrow_account_id"`
	TransferReference    string                 `json:"transfer_reference" db:"transfer_reference"`
	TransferDate         *time.Time             `json:"transfer_date" db:"transfer_date"`
	ExpectedReturn       float64                `json:"expected_return" db:"expected_return"` // percentage
	ExpectedReturnDate   *time.Time             `json:"expected_return_date" db:"expected_return_date"`
	ActualReturn         float64                `json:"actual_return" db:"actual_return"`
	ActualReturnDate     *time.Time             `json:"actual_return_date" db:"actual_return_date"`
	ProfitSharingAmount  float64                `json:"profit_sharing_amount" db:"profit_sharing_amount"`
	ProfitSharingDate    *time.Time             `json:"profit_sharing_date" db:"profit_sharing_date"`
	RiskLevel            string                 `json:"risk_level" db:"risk_level"` // low, medium, high
	ShariaCompliant      bool                   `json:"sharia_compliant" db:"sharia_compliant"`
	ComplianceNotes      string                 `json:"compliance_notes" db:"compliance_notes"`
	Documents            []string               `json:"documents" db:"documents"`
	Metadata             map[string]interface{} `json:"metadata" db:"metadata"`
	IsActive             bool                   `json:"is_active" db:"is_active"`
	CreatedAt            time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time              `json:"updated_at" db:"updated_at"`
}

// EscrowAccount represents the cooperative's escrow account for holding investments (FR-043)
type EscrowAccount struct {
	ID                 uuid.UUID `json:"id" db:"id"`
	CooperativeID      uuid.UUID `json:"cooperative_id" db:"cooperative_id"`
	AccountNumber      string    `json:"account_number" db:"account_number"`
	AccountName        string    `json:"account_name" db:"account_name"`
	BankName           string    `json:"bank_name" db:"bank_name"`
	BankCode           string    `json:"bank_code" db:"bank_code"`
	Currency           string    `json:"currency" db:"currency"`
	Balance            float64   `json:"balance" db:"balance"`
	TotalInvestments   float64   `json:"total_investments" db:"total_investments"`
	TotalDistributions float64   `json:"total_distributions" db:"total_distributions"`
	Status             string    `json:"status" db:"status"` // active, suspended, closed
	IsActive           bool      `json:"is_active" db:"is_active"`
	CreatedAt          time.Time `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time `json:"updated_at" db:"updated_at"`
}

// InvestmentRequest represents a request to invest in a project (FR-041, FR-042)
type InvestmentRequest struct {
	ID              uuid.UUID  `json:"id" db:"id"`
	InvestorID      uuid.UUID  `json:"investor_id" db:"investor_id"`
	ProjectID       uuid.UUID  `json:"project_id" db:"project_id"`
	CooperativeID   uuid.UUID  `json:"cooperative_id" db:"cooperative_id"`
	Amount          float64    `json:"amount" db:"amount"`
	Currency        string     `json:"currency" db:"currency"`
	InvestmentType  string     `json:"investment_type" db:"investment_type"`
	Status          string     `json:"status" db:"status"` // pending, approved, rejected
	ApprovedBy      *uuid.UUID `json:"approved_by" db:"approved_by"`
	ApprovedAt      *time.Time `json:"approved_at" db:"approved_at"`
	RejectionReason string     `json:"rejection_reason" db:"rejection_reason"`
	IsActive        bool       `json:"is_active" db:"is_active"`
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at" db:"updated_at"`
}

// CreateInvestmentExtendedRequest for FR-041 and FR-042
type CreateInvestmentExtendedRequest struct {
	ProjectID      uuid.UUID `json:"project_id" validate:"required"`
	Amount         float64   `json:"amount" validate:"required,min=0"`
	Currency       string    `json:"currency" validate:"required,len=3"`
	InvestmentType string    `json:"investment_type" validate:"required,oneof=full partial"`
}

// UpdateInvestmentRequest for investment updates
type UpdateInvestmentRequest struct {
	Amount         *float64 `json:"amount" validate:"omitempty,min=0"`
	InvestmentType *string  `json:"investment_type" validate:"omitempty,oneof=full partial"`
	Status         *string  `json:"status" validate:"omitempty,oneof=pending approved rejected active completed cancelled"`
}

// InvestmentApprovalRequest for FR-042
type InvestmentApprovalRequest struct {
	InvestmentID    uuid.UUID `json:"investment_id" validate:"required"`
	ApprovalStatus  string    `json:"approval_status" validate:"required,oneof=approved rejected"`
	Comments        string    `json:"comments"`
	RejectionReason string    `json:"rejection_reason" validate:"required_if=ApprovalStatus rejected"`
}

// InvestmentFilter for searching investments
type InvestmentFilter struct {
	InvestorID     *uuid.UUID `json:"investor_id"`
	ProjectID      *uuid.UUID `json:"project_id"`
	CooperativeID  *uuid.UUID `json:"cooperative_id"`
	Status         *string    `json:"status"`
	MinAmount      *float64   `json:"min_amount"`
	MaxAmount      *float64   `json:"max_amount"`
	Currency       *string    `json:"currency"`
	InvestmentType *string    `json:"investment_type"`
	StartDate      *time.Time `json:"start_date"`
	EndDate        *time.Time `json:"end_date"`
	Page           int        `json:"page" validate:"min=1"`
	Limit          int        `json:"limit" validate:"min=1,max=100"`
}

// InvestmentEligibilityCheck for FR-042
type InvestmentEligibilityCheck struct {
	InvestorID     uuid.UUID `json:"investor_id"`
	ProjectID      uuid.UUID `json:"project_id"`
	Amount         float64   `json:"amount"`
	IsEligible     bool      `json:"is_eligible"`
	Reasons        []string  `json:"reasons"`
	AvailableFunds float64   `json:"available_funds"`
	MinInvestment  float64   `json:"min_investment"`
	MaxInvestment  float64   `json:"max_investment"`
}

// InvestmentSummary for reporting
type InvestmentSummary struct {
	TotalInvestments     int     `json:"total_investments"`
	TotalAmount          float64 `json:"total_amount"`
	ActiveInvestments    int     `json:"active_investments"`
	ActiveAmount         float64 `json:"active_amount"`
	CompletedInvestments int     `json:"completed_investments"`
	CompletedAmount      float64 `json:"completed_amount"`
	TotalReturns         float64 `json:"total_returns"`
	AverageReturn        float64 `json:"average_return"`
	Currency             string  `json:"currency"`
}

// Investment constants
const (
	InvestmentStatusPending   = "pending"
	InvestmentStatusApproved  = "approved"
	InvestmentStatusRejected  = "rejected"
	InvestmentStatusActive    = "active"
	InvestmentStatusCompleted = "completed"
	InvestmentStatusCancelled = "cancelled"

	InvestmentTypeFull    = "full"
	InvestmentTypePartial = "partial"

	EscrowAccountStatusActive    = "active"
	EscrowAccountStatusSuspended = "suspended"
	EscrowAccountStatusClosed    = "closed"
)
