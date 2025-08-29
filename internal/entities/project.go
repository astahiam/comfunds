package entities

import (
	"time"

	"github.com/google/uuid"
)

type Project struct {
	ID                uuid.UUID  `json:"id" db:"id"`
	Title             string     `json:"title" db:"title"`
	Description       string     `json:"description" db:"description"`
	TargetAmount      float64    `json:"target_amount" db:"target_amount"`
	RaisedAmount      float64    `json:"raised_amount" db:"raised_amount"`
	MinInvestment     float64    `json:"min_investment" db:"min_investment"`
	Category          string     `json:"category" db:"category"`
	Status            string     `json:"status" db:"status"` // pending_approval, approved, active, completed, cancelled
	RiskLevel         string     `json:"risk_level" db:"risk_level"` // Low, Medium, High
	InvestmentPeriod  int        `json:"investment_period" db:"investment_period"` // months
	ExpectedReturn    string     `json:"expected_return" db:"expected_return"`
	ShariaCompliant   bool       `json:"sharia_compliant" db:"sharia_compliant"`
	BusinessID        uuid.UUID  `json:"business_id" db:"business_id"`
	OwnerID           uuid.UUID  `json:"owner_id" db:"owner_id"`
	CooperativeID     uuid.UUID  `json:"cooperative_id" db:"cooperative_id"`
	ApprovedBy        *uuid.UUID `json:"approved_by" db:"approved_by"`
	ApprovedAt        *time.Time `json:"approved_at" db:"approved_at"`
	StartDate         *time.Time `json:"start_date" db:"start_date"`
	EndDate           *time.Time `json:"end_date" db:"end_date"`
	IsActive          bool       `json:"is_active" db:"is_active"`
	CreatedAt         time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at" db:"updated_at"`
}

type CreateProjectRequest struct {
	Title            string     `json:"title" validate:"required,min=3,max=200"`
	Description      string     `json:"description" validate:"required,min=10,max=2000"`
	TargetAmount     float64    `json:"target_amount" validate:"required,min=1000"`
	MinInvestment    float64    `json:"min_investment" validate:"required,min=100"`
	Category         string     `json:"category" validate:"required"`
	RiskLevel        string     `json:"risk_level" validate:"required,oneof=Low Medium High"`
	InvestmentPeriod int        `json:"investment_period" validate:"required,min=6,max=120"` // 6 months to 10 years
	ExpectedReturn   string     `json:"expected_return" validate:"required"`
	BusinessID       uuid.UUID  `json:"business_id" validate:"required"`
	StartDate        *time.Time `json:"start_date"`
	EndDate          *time.Time `json:"end_date"`
}

type UpdateProjectRequest struct {
	Title            string     `json:"title" validate:"min=3,max=200"`
	Description      string     `json:"description" validate:"min=10,max=2000"`
	TargetAmount     float64    `json:"target_amount" validate:"min=1000"`
	MinInvestment    float64    `json:"min_investment" validate:"min=100"`
	Category         string     `json:"category"`
	RiskLevel        string     `json:"risk_level" validate:"oneof=Low Medium High"`
	InvestmentPeriod int        `json:"investment_period" validate:"min=6,max=120"`
	ExpectedReturn   string     `json:"expected_return"`
	Status           string     `json:"status" validate:"oneof=pending_approval approved active completed cancelled"`
	StartDate        *time.Time `json:"start_date"`
	EndDate          *time.Time `json:"end_date"`
}

type ProjectApprovalRequest struct {
	Approved bool   `json:"approved" validate:"required"`
	Comments string `json:"comments" validate:"max=1000"`
}

// ProjectStatus constants
const (
	ProjectStatusPendingApproval = "pending_approval"
	ProjectStatusApproved        = "approved"
	ProjectStatusActive          = "active"
	ProjectStatusCompleted       = "completed"
	ProjectStatusCancelled       = "cancelled"
	ProjectStatusRejected        = "rejected"
)

// ProjectCategory constants
const (
	CategoryTechnology         = "Technology"
	CategoryAgriculture        = "Agriculture"
	CategoryFoodBeverage       = "Food & Beverage"
	CategoryRenewableEnergy    = "Renewable Energy"
	CategoryCommunityDev       = "Community Development"
	CategoryEducation          = "Education"
	CategoryHealthcare         = "Healthcare"
	CategoryManufacturing      = "Manufacturing"
	CategoryRetail             = "Retail"
	CategoryServices           = "Services"
)

// RiskLevel constants
const (
	RiskLevelLow    = "Low"
	RiskLevelMedium = "Medium"
	RiskLevelHigh   = "High"
)