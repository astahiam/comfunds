package models

import "time"

type Investment struct {
	ID              string    `json:"id"`
	ProjectID       string    `json:"project_id"`
	InvestorID      string    `json:"investor_id"`
	Amount          float64   `json:"amount"`
	Currency        string    `json:"currency"`
	Status          string    `json:"status"`
	ApprovalStatus  string    `json:"approval_status"`
	ReturnAmount    float64   `json:"return_amount"`
	ReturnDate      *time.Time `json:"return_date"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
	Project         *Project  `json:"project,omitempty"`
	Investor        *User     `json:"investor,omitempty"`
}

type CreateInvestmentRequest struct {
	ProjectID      string  `json:"project_id" validate:"required"`
	Amount         float64 `json:"amount" validate:"required,gt=0"`
	Currency       string  `json:"currency" validate:"required"`
	InvestmentType string  `json:"investment_type" validate:"required"`
}

type InvestmentListResponse struct {
	Status  string         `json:"status"`
	Message string         `json:"message"`
	Data    InvestmentData `json:"data"`
}

type InvestmentData struct {
	Investments []Investment `json:"investments"`
	Total       int          `json:"total"`
	Page        int          `json:"page"`
	Limit       int          `json:"limit"`
}
