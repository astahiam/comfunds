package entities

import (
	"time"

	"github.com/google/uuid"
)

// FundDisbursement represents fund disbursement to business owners upon milestones (FR-046)
type FundDisbursement struct {
	ID                   uuid.UUID              `json:"id" db:"id"`
	ProjectID            uuid.UUID              `json:"project_id" db:"project_id"`
	BusinessID           uuid.UUID              `json:"business_id" db:"business_id"`
	CooperativeID        uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	MilestoneID          uuid.UUID              `json:"milestone_id" db:"milestone_id"`
	DisbursementAmount   float64                `json:"disbursement_amount" db:"disbursement_amount"`
	Currency             string                 `json:"currency" db:"currency"`
	DisbursementType     string                 `json:"disbursement_type" db:"disbursement_type"` // milestone, partial, final
	DisbursementReason   string                 `json:"disbursement_reason" db:"disbursement_reason"`
	Status               string                 `json:"status" db:"status"` // pending, approved, disbursed, rejected, cancelled
	ApprovedBy           *uuid.UUID             `json:"approved_by" db:"approved_by"`
	ApprovedAt           *time.Time             `json:"approved_at" db:"approved_at"`
	DisbursedAt          *time.Time             `json:"disbursed_at" db:"disbursed_at"`
	RejectionReason      string                 `json:"rejection_reason" db:"rejection_reason"`
	BankAccount          string                 `json:"bank_account" db:"bank_account"`
	TransactionReference string                 `json:"transaction_reference" db:"transaction_reference"`
	EscrowAccountID      uuid.UUID              `json:"escrow_account_id" db:"escrow_account_id"`
	Documents            []string               `json:"documents" db:"documents"`
	Metadata             map[string]interface{} `json:"metadata" db:"metadata"`
	IsActive             bool                   `json:"is_active" db:"is_active"`
	CreatedAt            time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time              `json:"updated_at" db:"updated_at"`
}

// FundUsage represents tracking of fund usage and business performance (FR-047)
type FundUsage struct {
	ID                 uuid.UUID              `json:"id" db:"id"`
	ProjectID          uuid.UUID              `json:"project_id" db:"project_id"`
	BusinessID         uuid.UUID              `json:"business_id" db:"business_id"`
	DisbursementID     uuid.UUID              `json:"disbursement_id" db:"disbursement_id"`
	UsageCategory      string                 `json:"usage_category" db:"usage_category"` // equipment, marketing, operations, expansion, other
	UsageAmount        float64                `json:"usage_amount" db:"usage_amount"`
	Currency           string                 `json:"currency" db:"currency"`
	UsageDescription   string                 `json:"usage_description" db:"usage_description"`
	UsageDate          time.Time              `json:"usage_date" db:"usage_date"`
	PerformanceMetrics map[string]interface{} `json:"performance_metrics" db:"performance_metrics"`
	RevenueGenerated   float64                `json:"revenue_generated" db:"revenue_generated"`
	CostSavings        float64                `json:"cost_savings" db:"cost_savings"`
	ROI                float64                `json:"roi" db:"roi"` // Return on Investment percentage
	Documents          []string               `json:"documents" db:"documents"`
	Receipts           []string               `json:"receipts" db:"receipts"`
	IsVerified         bool                   `json:"is_verified" db:"is_verified"`
	VerifiedBy         *uuid.UUID             `json:"verified_by" db:"verified_by"`
	VerifiedAt         *time.Time             `json:"verified_at" db:"verified_at"`
	Metadata           map[string]interface{} `json:"metadata" db:"metadata"`
	IsActive           bool                   `json:"is_active" db:"is_active"`
	CreatedAt          time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time              `json:"updated_at" db:"updated_at"`
}

// FundRefund represents fund refunds if project fails to meet minimum funding (FR-049)
type FundRefund struct {
	ID                   uuid.UUID              `json:"id" db:"id"`
	ProjectID            uuid.UUID              `json:"project_id" db:"project_id"`
	CooperativeID        uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	RefundType           string                 `json:"refund_type" db:"refund_type"` // minimum_funding_failed, project_cancelled, investor_request
	RefundReason         string                 `json:"refund_reason" db:"refund_reason"`
	TotalRefundAmount    float64                `json:"total_refund_amount" db:"total_refund_amount"`
	Currency             string                 `json:"currency" db:"currency"`
	RefundPercentage     float64                `json:"refund_percentage" db:"refund_percentage"` // percentage of original investment
	ProcessingFee        float64                `json:"processing_fee" db:"processing_fee"`
	NetRefundAmount      float64                `json:"net_refund_amount" db:"net_refund_amount"`
	Status               string                 `json:"status" db:"status"` // pending, processing, completed, failed, cancelled
	InitiatedBy          uuid.UUID              `json:"initiated_by" db:"initiated_by"`
	InitiatedAt          time.Time              `json:"initiated_at" db:"initiated_at"`
	ProcessedAt          *time.Time             `json:"processed_at" db:"processed_at"`
	CompletedAt          *time.Time             `json:"completed_at" db:"completed_at"`
	EscrowAccountID      uuid.UUID              `json:"escrow_account_id" db:"escrow_account_id"`
	TransactionReference string                 `json:"transaction_reference" db:"transaction_reference"`
	Documents            []string               `json:"documents" db:"documents"`
	Metadata             map[string]interface{} `json:"metadata" db:"metadata"`
	IsActive             bool                   `json:"is_active" db:"is_active"`
	CreatedAt            time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time              `json:"updated_at" db:"updated_at"`
}

// InvestorRefund represents individual investor refunds
type InvestorRefund struct {
	ID                   uuid.UUID  `json:"id" db:"id"`
	FundRefundID         uuid.UUID  `json:"fund_refund_id" db:"fund_refund_id"`
	InvestmentID         uuid.UUID  `json:"investment_id" db:"investment_id"`
	InvestorID           uuid.UUID  `json:"investor_id" db:"investor_id"`
	OriginalInvestment   float64    `json:"original_investment" db:"original_investment"`
	RefundAmount         float64    `json:"refund_amount" db:"refund_amount"`
	ProcessingFee        float64    `json:"processing_fee" db:"processing_fee"`
	NetRefundAmount      float64    `json:"net_refund_amount" db:"net_refund_amount"`
	Status               string     `json:"status" db:"status"` // pending, processing, completed, failed
	BankAccount          string     `json:"bank_account" db:"bank_account"`
	TransactionReference string     `json:"transaction_reference" db:"transaction_reference"`
	ProcessedAt          *time.Time `json:"processed_at" db:"processed_at"`
	CompletedAt          *time.Time `json:"completed_at" db:"completed_at"`
	IsActive             bool       `json:"is_active" db:"is_active"`
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at" db:"updated_at"`
}

// CreateFundDisbursementRequest for FR-046
type CreateFundDisbursementRequest struct {
	ProjectID          uuid.UUID `json:"project_id" validate:"required"`
	MilestoneID        uuid.UUID `json:"milestone_id" validate:"required"`
	DisbursementAmount float64   `json:"disbursement_amount" validate:"required,min=0"`
	Currency           string    `json:"currency" validate:"required,len=3"`
	DisbursementType   string    `json:"disbursement_type" validate:"required,oneof=milestone partial final"`
	DisbursementReason string    `json:"disbursement_reason" validate:"required"`
	BankAccount        string    `json:"bank_account" validate:"required"`
}

// UpdateFundDisbursementRequest for disbursement updates
type UpdateFundDisbursementRequest struct {
	Status          *string `json:"status" validate:"omitempty,oneof=pending approved disbursed rejected cancelled"`
	RejectionReason *string `json:"rejection_reason"`
	BankAccount     *string `json:"bank_account"`
}

// CreateFundUsageRequest for FR-047
type CreateFundUsageRequest struct {
	ProjectID          uuid.UUID              `json:"project_id" validate:"required"`
	DisbursementID     uuid.UUID              `json:"disbursement_id" validate:"required"`
	UsageCategory      string                 `json:"usage_category" validate:"required,oneof=equipment marketing operations expansion other"`
	UsageAmount        float64                `json:"usage_amount" validate:"required,min=0"`
	Currency           string                 `json:"currency" validate:"required,len=3"`
	UsageDescription   string                 `json:"usage_description" validate:"required"`
	UsageDate          time.Time              `json:"usage_date" validate:"required"`
	RevenueGenerated   *float64               `json:"revenue_generated"`
	CostSavings        *float64               `json:"cost_savings"`
	PerformanceMetrics map[string]interface{} `json:"performance_metrics"`
	Documents          []string               `json:"documents"`
	Receipts           []string               `json:"receipts"`
}

// CreateFundRefundRequest for FR-049
type CreateFundRefundRequest struct {
	ProjectID     uuid.UUID `json:"project_id" validate:"required"`
	RefundType    string    `json:"refund_type" validate:"required,oneof=minimum_funding_failed project_cancelled investor_request"`
	RefundReason  string    `json:"refund_reason" validate:"required"`
	ProcessingFee float64   `json:"processing_fee" validate:"min=0"`
}

// FundDisbursementFilter for searching disbursements
type FundDisbursementFilter struct {
	ProjectID        *uuid.UUID `json:"project_id"`
	BusinessID       *uuid.UUID `json:"business_id"`
	CooperativeID    *uuid.UUID `json:"cooperative_id"`
	Status           *string    `json:"status"`
	DisbursementType *string    `json:"disbursement_type"`
	StartDate        *time.Time `json:"start_date"`
	EndDate          *time.Time `json:"end_date"`
	MinAmount        *float64   `json:"min_amount"`
	MaxAmount        *float64   `json:"max_amount"`
	Page             int        `json:"page" validate:"min=1"`
	Limit            int        `json:"limit" validate:"min=1,max=100"`
}

// FundUsageFilter for searching fund usage
type FundUsageFilter struct {
	ProjectID      *uuid.UUID `json:"project_id"`
	BusinessID     *uuid.UUID `json:"business_id"`
	DisbursementID *uuid.UUID `json:"disbursement_id"`
	UsageCategory  *string    `json:"usage_category"`
	IsVerified     *bool      `json:"is_verified"`
	StartDate      *time.Time `json:"start_date"`
	EndDate        *time.Time `json:"end_date"`
	MinAmount      *float64   `json:"min_amount"`
	MaxAmount      *float64   `json:"max_amount"`
	Page           int        `json:"page" validate:"min=1"`
	Limit          int        `json:"limit" validate:"min=1,max=100"`
}

// FundRefundFilter for searching refunds
type FundRefundFilter struct {
	ProjectID     *uuid.UUID `json:"project_id"`
	CooperativeID *uuid.UUID `json:"cooperative_id"`
	RefundType    *string    `json:"refund_type"`
	Status        *string    `json:"status"`
	InitiatedBy   *uuid.UUID `json:"initiated_by"`
	StartDate     *time.Time `json:"start_date"`
	EndDate       *time.Time `json:"end_date"`
	Page          int        `json:"page" validate:"min=1"`
	Limit         int        `json:"limit" validate:"min=1,max=100"`
}

// FundManagementSummary for reporting
type FundManagementSummary struct {
	TotalDisbursements   int     `json:"total_disbursements"`
	TotalDisbursedAmount float64 `json:"total_disbursed_amount"`
	PendingDisbursements int     `json:"pending_disbursements"`
	PendingAmount        float64 `json:"pending_amount"`
	TotalFundUsage       int     `json:"total_fund_usage"`
	TotalUsageAmount     float64 `json:"total_usage_amount"`
	TotalRefunds         int     `json:"total_refunds"`
	TotalRefundAmount    float64 `json:"total_refund_amount"`
	ProcessingRefunds    int     `json:"processing_refunds"`
	ProcessingAmount     float64 `json:"processing_amount"`
	Currency             string  `json:"currency"`
}

// Fund constants
const (
	FundDisbursementStatusPending   = "pending"
	FundDisbursementStatusApproved  = "approved"
	FundDisbursementStatusDisbursed = "disbursed"
	FundDisbursementStatusRejected  = "rejected"
	FundDisbursementStatusCancelled = "cancelled"

	FundDisbursementTypeMilestone = "milestone"
	FundDisbursementTypePartial   = "partial"
	FundDisbursementTypeFinal     = "final"

	FundUsageCategoryEquipment  = "equipment"
	FundUsageCategoryMarketing  = "marketing"
	FundUsageCategoryOperations = "operations"
	FundUsageCategoryExpansion  = "expansion"
	FundUsageCategoryOther      = "other"

	FundRefundStatusPending    = "pending"
	FundRefundStatusProcessing = "processing"
	FundRefundStatusCompleted  = "completed"
	FundRefundStatusFailed     = "failed"
	FundRefundStatusCancelled  = "cancelled"

	FundRefundTypeMinimumFundingFailed = "minimum_funding_failed"
	FundRefundTypeProjectCancelled     = "project_cancelled"
	FundRefundTypeInvestorRequest      = "investor_request"
)
