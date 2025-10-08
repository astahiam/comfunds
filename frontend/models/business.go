package models

import "time"

type Business struct {
	ID                 string    `json:"id"`
	Name               string    `json:"name"`
	Description        string    `json:"description"`
	Type               string    `json:"type"`
	Address            string    `json:"address"`
	OwnerID            string    `json:"owner_id"`
	CooperativeID      string    `json:"cooperative_id"`
	Status             string    `json:"status"`
	ApprovalStatus     string    `json:"approval_status"`
	RegistrationNumber string    `json:"registration_number"`
	LegalStructure     string    `json:"legal_structure"`
	Industry           string    `json:"industry"`
	Phone              string    `json:"phone"`
	Email              string    `json:"email"`
	Website            string    `json:"website"`
	EstablishedDate    string    `json:"established_date"`
	EmployeeCount      int       `json:"employee_count"`
	AnnualRevenue      float64   `json:"annual_revenue"`
	Currency           string    `json:"currency"`
	BankAccount        string    `json:"bank_account"`
	BusinessLicense    string    `json:"business_license"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
	// Risk Assessment Documents
	BusinessPlanURL        string `json:"business_plan_url"`
	SWOTAnalysisURL        string `json:"swot_analysis_url"`
	FinancialStatementsURL string `json:"financial_statements_url"`
	MarketResearchURL      string `json:"market_research_url"`
	RiskAssessmentURL      string `json:"risk_assessment_url"`
	// Approval/Rejection fields
	ApprovedBy       *string      `json:"approved_by"`
	ApprovedAt       *time.Time   `json:"approved_at"`
	RejectedBy       *string      `json:"rejected_by"`
	RejectedAt       *time.Time   `json:"rejected_at"`
	RejectionReason  string       `json:"rejection_reason"`
	ReviewerComments string       `json:"reviewer_comments"`
	Owner            *User        `json:"owner,omitempty"`
	Cooperative      *Cooperative `json:"cooperative,omitempty"`
}

type CreateBusinessRequest struct {
	Name               string   `json:"name"`
	Type               string   `json:"type"`
	Description        string   `json:"description"`
	CooperativeID      string   `json:"cooperative_id"`
	RegistrationNumber string   `json:"registration_number"`
	LegalStructure     string   `json:"legal_structure"`
	Industry           string   `json:"industry"`
	Address            string   `json:"address"`
	Phone              string   `json:"phone"`
	Email              string   `json:"email"`
	EstablishedDate    string   `json:"established_date"`
	Currency           string   `json:"currency"`
	BankAccount        string   `json:"bank_account"`
	Website            string   `json:"website"`
	EmployeeCount      int      `json:"employee_count"`
	AnnualRevenue      float64  `json:"annual_revenue"`
	BusinessLicense    string   `json:"business_license"`
	Documents          []string `json:"documents"`
	// Risk Assessment Documents
	BusinessPlanURL        string `json:"business_plan_url"`
	SWOTAnalysisURL        string `json:"swot_analysis_url"`
	FinancialStatementsURL string `json:"financial_statements_url"`
	MarketResearchURL      string `json:"market_research_url"`
	RiskAssessmentURL      string `json:"risk_assessment_url"`
}
