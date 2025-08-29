package entities

import (
	"time"

	"github.com/google/uuid"
)

// InvestmentPolicyExtended represents comprehensive investment policies for cooperatives (FR-023)
type InvestmentPolicyExtended struct {
	ID                    uuid.UUID              `json:"id" db:"id"`
	CooperativeID         uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	Name                  string                 `json:"name" db:"name"`
	Description           string                 `json:"description" db:"description"`
	MinInvestmentAmount   float64                `json:"min_investment_amount" db:"min_investment_amount"`
	MaxInvestmentAmount   float64                `json:"max_investment_amount" db:"max_investment_amount"`
	AllowedSectors        []string               `json:"allowed_sectors" db:"allowed_sectors"`
	RiskLevels            []string               `json:"risk_levels" db:"risk_levels"`
	ShariaCompliantOnly   bool                   `json:"sharia_compliant_only" db:"sharia_compliant_only"`
	MaxProjectDuration    int                    `json:"max_project_duration" db:"max_project_duration"` // months
	RequiredDocuments     []string               `json:"required_documents" db:"required_documents"`
	ApprovalThreshold     float64                `json:"approval_threshold" db:"approval_threshold"` // percentage of committee votes
	CustomRules           map[string]interface{} `json:"custom_rules" db:"custom_rules"`
	InvestorEligibility   map[string]interface{} `json:"investor_eligibility" db:"investor_eligibility"`
	WithdrawalPenalty     float64                `json:"withdrawal_penalty" db:"withdrawal_penalty"`     // percentage
	WithdrawalNoticeDays  int                    `json:"withdrawal_notice_days" db:"withdrawal_notice_days"`
	IsActive              bool                   `json:"is_active" db:"is_active"`
	EffectiveDate         time.Time              `json:"effective_date" db:"effective_date"`
	ExpiryDate            *time.Time             `json:"expiry_date" db:"expiry_date"`
	CreatedBy             uuid.UUID              `json:"created_by" db:"created_by"`
	CreatedAt             time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt             time.Time              `json:"updated_at" db:"updated_at"`
}

// ProfitSharingRulesExtended represents detailed profit-sharing rules (FR-023)
type ProfitSharingRulesExtended struct {
	ID                    uuid.UUID              `json:"id" db:"id"`
	CooperativeID         uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	Name                  string                 `json:"name" db:"name"`
	Description           string                 `json:"description" db:"description"`
	InvestorShare         float64                `json:"investor_share" db:"investor_share"`         // percentage
	CooperativeShare      float64                `json:"cooperative_share" db:"cooperative_share"`   // percentage
	BusinessOwnerShare    float64                `json:"business_owner_share" db:"business_owner_share"` // percentage
	AdminFee              float64                `json:"admin_fee" db:"admin_fee"`                   // percentage
	DistributionMethod    string                 `json:"distribution_method" db:"distribution_method"` // monthly, quarterly, yearly
	DistributionDay       int                    `json:"distribution_day" db:"distribution_day"`     // day of month/quarter
	MinProfitThreshold    float64                `json:"min_profit_threshold" db:"min_profit_threshold"`
	MaxDistributionAmount float64                `json:"max_distribution_amount" db:"max_distribution_amount"`
	LossHandlingMethod    string                 `json:"loss_handling_method" db:"loss_handling_method"` // carry_forward, shared, absorb
	TaxHandling           string                 `json:"tax_handling" db:"tax_handling"`             // gross, net
	ReinvestmentOption    bool                   `json:"reinvestment_option" db:"reinvestment_option"`
	ReinvestmentRate      float64                `json:"reinvestment_rate" db:"reinvestment_rate"`   // percentage
	CustomRules           map[string]interface{} `json:"custom_rules" db:"custom_rules"`
	CalculationFormula    string                 `json:"calculation_formula" db:"calculation_formula"`
	IsActive              bool                   `json:"is_active" db:"is_active"`
	EffectiveDate         time.Time              `json:"effective_date" db:"effective_date"`
	ExpiryDate            *time.Time             `json:"expiry_date" db:"expiry_date"`
	CreatedBy             uuid.UUID              `json:"created_by" db:"created_by"`
	CreatedAt             time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt             time.Time              `json:"updated_at" db:"updated_at"`
}

// CreateInvestmentPolicyRequest for FR-023
type CreateInvestmentPolicyRequest struct {
	Name                  string                 `json:"name" validate:"required,min=3,max=100"`
	Description           string                 `json:"description" validate:"required,min=10,max=500"`
	MinInvestmentAmount   float64                `json:"min_investment_amount" validate:"required,min=1"`
	MaxInvestmentAmount   float64                `json:"max_investment_amount" validate:"required,gtfield=MinInvestmentAmount"`
	AllowedSectors        []string               `json:"allowed_sectors" validate:"required,min=1"`
	RiskLevels            []string               `json:"risk_levels" validate:"required,min=1,dive,oneof=low medium high"`
	ShariaCompliantOnly   bool                   `json:"sharia_compliant_only"`
	MaxProjectDuration    int                    `json:"max_project_duration" validate:"required,min=1,max=120"` // months
	RequiredDocuments     []string               `json:"required_documents" validate:"min=1"`
	ApprovalThreshold     float64                `json:"approval_threshold" validate:"required,min=0.5,max=1"` // 50-100%
	CustomRules           map[string]interface{} `json:"custom_rules"`
	InvestorEligibility   map[string]interface{} `json:"investor_eligibility"`
	WithdrawalPenalty     float64                `json:"withdrawal_penalty" validate:"min=0,max=0.2"` // 0-20%
	WithdrawalNoticeDays  int                    `json:"withdrawal_notice_days" validate:"min=0,max=365"`
	EffectiveDate         time.Time              `json:"effective_date" validate:"required"`
	ExpiryDate            *time.Time             `json:"expiry_date"`
}

// CreateProfitSharingRulesRequest for FR-023
type CreateProfitSharingRulesRequest struct {
	Name                  string                 `json:"name" validate:"required,min=3,max=100"`
	Description           string                 `json:"description" validate:"required,min=10,max=500"`
	InvestorShare         float64                `json:"investor_share" validate:"required,min=0,max=1"`
	CooperativeShare      float64                `json:"cooperative_share" validate:"required,min=0,max=1"`
	BusinessOwnerShare    float64                `json:"business_owner_share" validate:"required,min=0,max=1"`
	AdminFee              float64                `json:"admin_fee" validate:"min=0,max=0.1"` // 0-10%
	DistributionMethod    string                 `json:"distribution_method" validate:"required,oneof=monthly quarterly yearly"`
	DistributionDay       int                    `json:"distribution_day" validate:"required,min=1,max=31"`
	MinProfitThreshold    float64                `json:"min_profit_threshold" validate:"required,min=0"`
	MaxDistributionAmount float64                `json:"max_distribution_amount" validate:"min=0"`
	LossHandlingMethod    string                 `json:"loss_handling_method" validate:"required,oneof=carry_forward shared absorb"`
	TaxHandling           string                 `json:"tax_handling" validate:"required,oneof=gross net"`
	ReinvestmentOption    bool                   `json:"reinvestment_option"`
	ReinvestmentRate      float64                `json:"reinvestment_rate" validate:"min=0,max=1"`
	CustomRules           map[string]interface{} `json:"custom_rules"`
	CalculationFormula    string                 `json:"calculation_formula"`
	EffectiveDate         time.Time              `json:"effective_date" validate:"required"`
	ExpiryDate            *time.Time             `json:"expiry_date"`
}

// UpdateInvestmentPolicyRequest for updating policies
type UpdateInvestmentPolicyRequest struct {
	Name                  string                 `json:"name" validate:"min=3,max=100"`
	Description           string                 `json:"description" validate:"min=10,max=500"`
	MinInvestmentAmount   float64                `json:"min_investment_amount" validate:"min=1"`
	MaxInvestmentAmount   float64                `json:"max_investment_amount"`
	AllowedSectors        []string               `json:"allowed_sectors" validate:"min=1"`
	RiskLevels            []string               `json:"risk_levels" validate:"min=1,dive,oneof=low medium high"`
	ShariaCompliantOnly   *bool                  `json:"sharia_compliant_only"`
	MaxProjectDuration    int                    `json:"max_project_duration" validate:"min=1,max=120"`
	RequiredDocuments     []string               `json:"required_documents"`
	ApprovalThreshold     float64                `json:"approval_threshold" validate:"min=0.5,max=1"`
	CustomRules           map[string]interface{} `json:"custom_rules"`
	InvestorEligibility   map[string]interface{} `json:"investor_eligibility"`
	WithdrawalPenalty     float64                `json:"withdrawal_penalty" validate:"min=0,max=0.2"`
	WithdrawalNoticeDays  int                    `json:"withdrawal_notice_days" validate:"min=0,max=365"`
	IsActive              *bool                  `json:"is_active"`
	ExpiryDate            *time.Time             `json:"expiry_date"`
}

// UpdateProfitSharingRulesRequest for updating profit sharing rules
type UpdateProfitSharingRulesRequest struct {
	Name                  string                 `json:"name" validate:"min=3,max=100"`
	Description           string                 `json:"description" validate:"min=10,max=500"`
	InvestorShare         float64                `json:"investor_share" validate:"min=0,max=1"`
	CooperativeShare      float64                `json:"cooperative_share" validate:"min=0,max=1"`
	BusinessOwnerShare    float64                `json:"business_owner_share" validate:"min=0,max=1"`
	AdminFee              float64                `json:"admin_fee" validate:"min=0,max=0.1"`
	DistributionMethod    string                 `json:"distribution_method" validate:"oneof=monthly quarterly yearly"`
	DistributionDay       int                    `json:"distribution_day" validate:"min=1,max=31"`
	MinProfitThreshold    float64                `json:"min_profit_threshold" validate:"min=0"`
	MaxDistributionAmount float64                `json:"max_distribution_amount" validate:"min=0"`
	LossHandlingMethod    string                 `json:"loss_handling_method" validate:"oneof=carry_forward shared absorb"`
	TaxHandling           string                 `json:"tax_handling" validate:"oneof=gross net"`
	ReinvestmentOption    *bool                  `json:"reinvestment_option"`
	ReinvestmentRate      float64                `json:"reinvestment_rate" validate:"min=0,max=1"`
	CustomRules           map[string]interface{} `json:"custom_rules"`
	CalculationFormula    string                 `json:"calculation_formula"`
	IsActive              *bool                  `json:"is_active"`
	ExpiryDate            *time.Time             `json:"expiry_date"`
}
