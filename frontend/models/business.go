package models

import "time"

type Business struct {
	ID             string       `json:"id"`
	Name           string       `json:"name"`
	Description    string       `json:"description"`
	Type           string       `json:"type"`
	Address        string       `json:"address"`
	OwnerID        string       `json:"owner_id"`
	CooperativeID  string       `json:"cooperative_id"`
	Status         string       `json:"status"`
	ApprovalStatus string       `json:"approval_status"`
	CreatedAt      time.Time    `json:"created_at"`
	UpdatedAt      time.Time    `json:"updated_at"`
	Owner          *User        `json:"owner,omitempty"`
	Cooperative    *Cooperative `json:"cooperative,omitempty"`
}

type CreateBusinessRequest struct {
	Name               string   `json:"name"`
	Type               string   `json:"type"`
	Description        string   `json:"description"`
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
}
