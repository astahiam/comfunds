package entities

import (
	"time"

	"github.com/google/uuid"
)

// FundTransfer represents fund transfer monitoring (FR-021)
type FundTransfer struct {
	ID                    uuid.UUID              `json:"id" db:"id"`
	TransferNumber        string                 `json:"transfer_number" db:"transfer_number"` // Unique transfer ID
	ProjectID             uuid.UUID              `json:"project_id" db:"project_id"`
	InvestmentID          *uuid.UUID             `json:"investment_id" db:"investment_id"`
	CooperativeID         uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	FromAccountID         uuid.UUID              `json:"from_account_id" db:"from_account_id"`
	ToAccountID           uuid.UUID              `json:"to_account_id" db:"to_account_id"`
	FromUserID            *uuid.UUID             `json:"from_user_id" db:"from_user_id"`     // Investor
	ToUserID              *uuid.UUID             `json:"to_user_id" db:"to_user_id"`       // Business Owner
	TransferType          string                 `json:"transfer_type" db:"transfer_type"`   // investment, profit_distribution, withdrawal, refund
	Amount                float64                `json:"amount" db:"amount"`
	Currency              string                 `json:"currency" db:"currency"`
	ExchangeRate          float64                `json:"exchange_rate" db:"exchange_rate"`
	Fee                   float64                `json:"fee" db:"fee"`
	NetAmount             float64                `json:"net_amount" db:"net_amount"`
	Status                string                 `json:"status" db:"status"`                 // pending, processing, completed, failed, cancelled
	PaymentMethod         string                 `json:"payment_method" db:"payment_method"` // bank_transfer, digital_wallet, cash
	PaymentReference      string                 `json:"payment_reference" db:"payment_reference"`
	BankTransactionID     string                 `json:"bank_transaction_id" db:"bank_transaction_id"`
	Description           string                 `json:"description" db:"description"`
	Notes                 string                 `json:"notes" db:"notes"`
	Metadata              map[string]interface{} `json:"metadata" db:"metadata"`
	ScheduledAt           *time.Time             `json:"scheduled_at" db:"scheduled_at"`
	ProcessedAt           *time.Time             `json:"processed_at" db:"processed_at"`
	CompletedAt           *time.Time             `json:"completed_at" db:"completed_at"`
	FailedAt              *time.Time             `json:"failed_at" db:"failed_at"`
	FailureReason         string                 `json:"failure_reason" db:"failure_reason"`
	RetryCount            int                    `json:"retry_count" db:"retry_count"`
	MaxRetries            int                    `json:"max_retries" db:"max_retries"`
	InitiatedBy           uuid.UUID              `json:"initiated_by" db:"initiated_by"`
	ApprovedBy            *uuid.UUID             `json:"approved_by" db:"approved_by"`
	CreatedAt             time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt             time.Time              `json:"updated_at" db:"updated_at"`
}

// ProfitDistributionMonitoring represents profit distribution tracking (FR-021)
type ProfitDistributionMonitoring struct {
	ID                     uuid.UUID              `json:"id" db:"id"`
	DistributionNumber     string                 `json:"distribution_number" db:"distribution_number"`
	ProjectID              uuid.UUID              `json:"project_id" db:"project_id"`
	CooperativeID          uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	PeriodStart            time.Time              `json:"period_start" db:"period_start"`
	PeriodEnd              time.Time              `json:"period_end" db:"period_end"`
	TotalRevenue           float64                `json:"total_revenue" db:"total_revenue"`
	TotalExpenses          float64                `json:"total_expenses" db:"total_expenses"`
	NetProfit              float64                `json:"net_profit" db:"net_profit"`
	DistributableProfit    float64                `json:"distributable_profit" db:"distributable_profit"`
	InvestorShare          float64                `json:"investor_share" db:"investor_share"`
	CooperativeShare       float64                `json:"cooperative_share" db:"cooperative_share"`
	BusinessOwnerShare     float64                `json:"business_owner_share" db:"business_owner_share"`
	AdminFee               float64                `json:"admin_fee" db:"admin_fee"`
	TotalDistributed       float64                `json:"total_distributed" db:"total_distributed"`
	PendingDistribution    float64                `json:"pending_distribution" db:"pending_distribution"`
	Status                 string                 `json:"status" db:"status"` // calculated, approved, distributed, completed
	CalculationMethod      string                 `json:"calculation_method" db:"calculation_method"`
	ApprovalRequired       bool                   `json:"approval_required" db:"approval_required"`
	Documents              []string               `json:"documents" db:"documents"`
	FinancialStatements    map[string]interface{} `json:"financial_statements" db:"financial_statements"`
	Adjustments            map[string]interface{} `json:"adjustments" db:"adjustments"`
	TaxCalculations        map[string]interface{} `json:"tax_calculations" db:"tax_calculations"`
	Notes                  string                 `json:"notes" db:"notes"`
	CalculatedBy           uuid.UUID              `json:"calculated_by" db:"calculated_by"`
	ApprovedBy             *uuid.UUID             `json:"approved_by" db:"approved_by"`
	DistributedBy          *uuid.UUID             `json:"distributed_by" db:"distributed_by"`
	CalculatedAt           time.Time              `json:"calculated_at" db:"calculated_at"`
	ApprovedAt             *time.Time             `json:"approved_at" db:"approved_at"`
	DistributedAt          *time.Time             `json:"distributed_at" db:"distributed_at"`
	CreatedAt              time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt              time.Time              `json:"updated_at" db:"updated_at"`
}

// FundTransferConstants
const (
	TransferTypeLnvestment         = "investment"
	TransferTypeProfitDistribution = "profit_distribution"
	TransferTypeWithdrawal         = "withdrawal"
	TransferTypeRefund             = "refund"
	TransferTypeFee                = "fee"

	TransferStatusPending    = "pending"
	TransferStatusProcessing = "processing"
	TransferStatusCompleted  = "completed"
	TransferStatusFailed     = "failed"
	TransferStatusCancelled  = "cancelled"

	PaymentMethodBankTransfer  = "bank_transfer"
	PaymentMethodDigitalWallet = "digital_wallet"
	PaymentMethodCash          = "cash"
	PaymentMethodCheck         = "check"

	DistributionStatusCalculated = "calculated"
	DistributionStatusApproved   = "approved"
	DistributionStatusDistributed = "distributed"
	DistributionStatusCompleted  = "completed"
	DistributionStatusCancelled  = "cancelled"
)

// CreateFundTransferRequest for initiating transfers
type CreateFundTransferRequest struct {
	ProjectID         uuid.UUID              `json:"project_id" validate:"required"`
	InvestmentID      *uuid.UUID             `json:"investment_id"`
	FromAccountID     uuid.UUID              `json:"from_account_id" validate:"required"`
	ToAccountID       uuid.UUID              `json:"to_account_id" validate:"required"`
	FromUserID        *uuid.UUID             `json:"from_user_id"`
	ToUserID          *uuid.UUID             `json:"to_user_id"`
	TransferType      string                 `json:"transfer_type" validate:"required,oneof=investment profit_distribution withdrawal refund fee"`
	Amount            float64                `json:"amount" validate:"required,gt=0"`
	Currency          string                 `json:"currency" validate:"required,len=3"`
	PaymentMethod     string                 `json:"payment_method" validate:"required,oneof=bank_transfer digital_wallet cash check"`
	PaymentReference  string                 `json:"payment_reference"`
	Description       string                 `json:"description" validate:"required,max=500"`
	Notes             string                 `json:"notes" validate:"max=1000"`
	ScheduledAt       *time.Time             `json:"scheduled_at"`
	Metadata          map[string]interface{} `json:"metadata"`
}

// UpdateFundTransferRequest for updating transfer details
type UpdateFundTransferRequest struct {
	Status              string     `json:"status" validate:"oneof=pending processing completed failed cancelled"`
	PaymentReference    string     `json:"payment_reference"`
	BankTransactionID   string     `json:"bank_transaction_id"`
	Notes               string     `json:"notes" validate:"max=1000"`
	FailureReason       string     `json:"failure_reason" validate:"max=500"`
	ProcessedAt         *time.Time `json:"processed_at"`
	CompletedAt         *time.Time `json:"completed_at"`
	FailedAt            *time.Time `json:"failed_at"`
}

// FundTransferFilter for querying transfers
type FundTransferFilter struct {
	ProjectID        *uuid.UUID `json:"project_id"`
	CooperativeID    *uuid.UUID `json:"cooperative_id"`
	FromUserID       *uuid.UUID `json:"from_user_id"`
	ToUserID         *uuid.UUID `json:"to_user_id"`
	TransferType     string     `json:"transfer_type"`
	Status           string     `json:"status"`
	PaymentMethod    string     `json:"payment_method"`
	Currency         string     `json:"currency"`
	MinAmount        float64    `json:"min_amount"`
	MaxAmount        float64    `json:"max_amount"`
	StartDate        *time.Time `json:"start_date"`
	EndDate          *time.Time `json:"end_date"`
	Page             int        `json:"page"`
	Limit            int        `json:"limit"`
	SortBy           string     `json:"sort_by"`    // created_at, amount, completed_at
	SortOrder        string     `json:"sort_order"` // asc, desc
}

// CreateProfitDistributionRequest for calculating distributions
type CreateProfitDistributionRequest struct {
	ProjectID           uuid.UUID              `json:"project_id" validate:"required"`
	PeriodStart         time.Time              `json:"period_start" validate:"required"`
	PeriodEnd           time.Time              `json:"period_end" validate:"required"`
	TotalRevenue        float64                `json:"total_revenue" validate:"required,gte=0"`
	TotalExpenses       float64                `json:"total_expenses" validate:"required,gte=0"`
	CalculationMethod   string                 `json:"calculation_method" validate:"required"`
	Documents           []string               `json:"documents"`
	FinancialStatements map[string]interface{} `json:"financial_statements"`
	Adjustments         map[string]interface{} `json:"adjustments"`
	Notes               string                 `json:"notes" validate:"max=1000"`
}

// ProfitDistributionFilter for querying distributions
type ProfitDistributionFilter struct {
	ProjectID     *uuid.UUID `json:"project_id"`
	CooperativeID *uuid.UUID `json:"cooperative_id"`
	Status        string     `json:"status"`
	PeriodStart   *time.Time `json:"period_start"`
	PeriodEnd     *time.Time `json:"period_end"`
	MinProfit     float64    `json:"min_profit"`
	MaxProfit     float64    `json:"max_profit"`
	Page          int        `json:"page"`
	Limit         int        `json:"limit"`
	SortBy        string     `json:"sort_by"`    // created_at, net_profit, period_end
	SortOrder     string     `json:"sort_order"` // asc, desc
}
