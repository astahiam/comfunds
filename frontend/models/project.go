package models

import "time"

type Project struct {
	ID                 string                 `json:"id"`
	Title              string                 `json:"title"`
	Description        string                 `json:"description"`
	BusinessID         string                 `json:"business_id"`
	FundingGoal        float64                `json:"funding_goal"`
	MinimumFunding     float64                `json:"minimum_funding"`
	CurrentFunding     float64                `json:"current_funding"`
	FundingDeadline    *time.Time             `json:"funding_deadline"`
	ProfitSharingRatio map[string]interface{} `json:"profit_sharing_ratio"`
	ProjectType        string                 `json:"project_type"` // startup, expansion, equipment
	Status             string                 `json:"status"`       // draft, submitted, approved, active, funded, closed
	Milestones         map[string]interface{} `json:"milestones"`
	Documents          []string               `json:"documents"`
	ApprovalStatus     string                 `json:"approval_status"`
	ApprovedBy         *string                `json:"approved_by"`
	ApprovedAt         *time.Time             `json:"approved_at"`
	CreatedAt          time.Time              `json:"created_at"`
	UpdatedAt          time.Time              `json:"updated_at"`
	Business           *Business              `json:"business,omitempty"`
	Cooperative        *Cooperative           `json:"cooperative,omitempty"`
	InvestmentCount    int                    `json:"investment_count"`
	FundingPercentage  float64                `json:"funding_percentage"`
	DaysRemaining      int                    `json:"days_remaining"`

	// Legacy fields for backward compatibility
	Category      string    `json:"category"`
	TargetAmount  float64   `json:"target_amount"`
	RaisedAmount  float64   `json:"raised_amount"`
	MinInvestment float64   `json:"min_investment"`
	CooperativeID string    `json:"cooperative_id"`
	StartDate     time.Time `json:"start_date"`
	EndDate       time.Time `json:"end_date"`
}

type CreateProjectRequest struct {
	// Required fields
	Title        string  `json:"title"`
	Description  string  `json:"description"`
	BusinessID   string  `json:"business_id"`
	TargetAmount float64 `json:"target_amount"`
	Category     string  `json:"category"`

	// Optional fields
	MinInvestment    *float64 `json:"min_investment,omitempty"`
	RiskLevel        *string  `json:"risk_level,omitempty"`
	InvestmentPeriod *int     `json:"investment_period,omitempty"`
	ExpectedReturn   *string  `json:"expected_return,omitempty"`
	StartDate        *string  `json:"start_date,omitempty"`
	EndDate          *string  `json:"end_date,omitempty"`
}

type InvestmentRequest struct {
	ProjectID string  `json:"project_id"`
	Amount    float64 `json:"amount"`
}

type ProjectListResponse struct {
	Status  string      `json:"status"`
	Message string      `json:"message"`
	Data    ProjectData `json:"data"`
}

type ProjectData struct {
	Projects []Project `json:"projects"`
	Total    int       `json:"total"`
	Page     int       `json:"page"`
	Limit    int       `json:"limit"`
}
