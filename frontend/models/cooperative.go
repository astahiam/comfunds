package models

import "time"

type Cooperative struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Address     string    `json:"address"`
	Phone       string    `json:"phone"`
	Email       string    `json:"email"`
	Status      string    `json:"status"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type CooperativeListResponse struct {
	Status  string           `json:"status"`
	Message string           `json:"message"`
	Data    CooperativeData  `json:"data"`
}

type CooperativeData struct {
	Cooperatives []Cooperative `json:"cooperatives"`
	Total        int           `json:"total"`
	Page         int           `json:"page"`
	Limit        int           `json:"limit"`
}
