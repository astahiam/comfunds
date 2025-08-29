package entities

import (
	"time"

	"github.com/google/uuid"
)

type Investment struct {
	ID                      uuid.UUID `json:"id" db:"id"`
	ProjectID               uuid.UUID `json:"project_id" db:"project_id"`
	InvestorID              uuid.UUID `json:"investor_id" db:"investor_id"`
	Amount                  float64   `json:"amount" db:"amount"`
	InvestmentDate          time.Time `json:"investment_date" db:"investment_date"`
	ProfitSharingPercentage float64   `json:"profit_sharing_percentage" db:"profit_sharing_percentage"`
	Status                  string    `json:"status" db:"status"`
	TransactionRef          string    `json:"transaction_ref" db:"transaction_ref"`
	CreatedAt               time.Time `json:"created_at" db:"created_at"`
	UpdatedAt               time.Time `json:"updated_at" db:"updated_at"`
}

type CreateInvestmentRequest struct {
	ProjectID  uuid.UUID `json:"project_id" validate:"required"`
	InvestorID uuid.UUID `json:"investor_id" validate:"required"`
	Amount     float64   `json:"amount" validate:"required,gt=0"`
}

type ProfitDistribution struct {
	ID               uuid.UUID `json:"id" db:"id"`
	ProjectID        uuid.UUID `json:"project_id" db:"project_id"`
	BusinessProfit   float64   `json:"business_profit" db:"business_profit"`
	DistributionDate time.Time `json:"distribution_date" db:"distribution_date"`
	TotalDistributed float64   `json:"total_distributed" db:"total_distributed"`
	Status           string    `json:"status" db:"status"`
	CreatedAt        time.Time `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time `json:"updated_at" db:"updated_at"`
}

type InvestmentReturn struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	InvestmentID     uuid.UUID  `json:"investment_id" db:"investment_id"`
	DistributionID   uuid.UUID  `json:"distribution_id" db:"distribution_id"`
	ReturnAmount     float64    `json:"return_amount" db:"return_amount"`
	ReturnPercentage float64    `json:"return_percentage" db:"return_percentage"`
	PaymentDate      *time.Time `json:"payment_date" db:"payment_date"`
	Status           string     `json:"status" db:"status"`
	TransactionRef   string     `json:"transaction_ref" db:"transaction_ref"`
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`
}
