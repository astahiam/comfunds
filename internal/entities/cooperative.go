package entities

import (
	"time"

	"github.com/google/uuid"
)

type Cooperative struct {
	ID                  uuid.UUID              `json:"id" db:"id"`
	Name                string                 `json:"name" db:"name"`
	RegistrationNumber  string                 `json:"registration_number" db:"registration_number"`
	Address             string                 `json:"address" db:"address"`
	Phone               string                 `json:"phone" db:"phone"`
	Email               string                 `json:"email" db:"email"`
	BankAccount         string                 `json:"bank_account" db:"bank_account"`
	ProfitSharingPolicy map[string]interface{} `json:"profit_sharing_policy" db:"profit_sharing_policy"`
	IsActive            bool                   `json:"is_active" db:"is_active"`
	CreatedAt           time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt           time.Time              `json:"updated_at" db:"updated_at"`
}

// InvestmentPolicy for FR-023
type InvestmentPolicy struct {
	MinInvestmentAmount float64                `json:"min_investment_amount"`
	MaxInvestmentAmount float64                `json:"max_investment_amount"`
	AllowedSectors      []string               `json:"allowed_sectors"`
	RiskLevels          []string               `json:"risk_levels"`
	ShariaCompliantOnly bool                   `json:"sharia_compliant_only"`
	CustomRules         map[string]interface{} `json:"custom_rules"`
}

// ProfitSharingRules for FR-023
type ProfitSharingRules struct {
	InvestorShare      float64                `json:"investor_share"`       // Percentage for investors
	CooperativeShare   float64                `json:"cooperative_share"`    // Percentage for cooperative
	BusinessOwnerShare float64                `json:"business_owner_share"` // Percentage for business owner
	DistributionMethod string                 `json:"distribution_method"`  // monthly, quarterly, yearly
	MinProfitThreshold float64                `json:"min_profit_threshold"` // Minimum profit before distribution
	CustomRules        map[string]interface{} `json:"custom_rules"`
}

type CreateCooperativeRequest struct {
	Name                string                 `json:"name" validate:"required,min=2,max=255"`
	RegistrationNumber  string                 `json:"registration_number" validate:"required,max=100"`
	Address             string                 `json:"address" validate:"required"`
	Phone               string                 `json:"phone" validate:"required,max=50"`
	Email               string                 `json:"email" validate:"required,email"`
	BankAccount         string                 `json:"bank_account" validate:"required,max=100"`
	ProfitSharingPolicy map[string]interface{} `json:"profit_sharing_policy"`
}

type UpdateCooperativeRequest struct {
	Name                string                 `json:"name" validate:"min=2,max=255"`
	Address             string                 `json:"address"`
	Phone               string                 `json:"phone" validate:"max=50"`
	Email               string                 `json:"email" validate:"email"`
	BankAccount         string                 `json:"bank_account" validate:"max=100"`
	ProfitSharingPolicy map[string]interface{} `json:"profit_sharing_policy"`
}
