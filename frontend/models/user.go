package models

import "time"

type User struct {
	ID            string    `json:"id"`
	Email         string    `json:"email"`
	Name          string    `json:"name"`
	Phone         string    `json:"phone"`
	Address       string    `json:"address"`
	CooperativeID *string   `json:"cooperative_id"`
	Roles         []string  `json:"roles"`
	KYCStatus     string    `json:"kyc_status"`
	IsActive      bool      `json:"is_active"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

type RegisterRequest struct {
	Name          string   `json:"name" validate:"required,min=2,max=100"`
	Email         string   `json:"email" validate:"required,email"`
	Password      string   `json:"password" validate:"required,min=6"`
	Phone         string   `json:"phone" validate:"required"`
	Address       string   `json:"address" validate:"required"`
	CooperativeID *string  `json:"cooperative_id"`
	Roles         []string `json:"roles" validate:"required"`
}

type UpdateProfileRequest struct {
	Name    string `json:"name"`
	Phone   string `json:"phone"`
	Address string `json:"address"`
}

type AuthResponse struct {
	Status       string `json:"status"`
	Message      string `json:"message"`
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	User         *User  `json:"user"`
}
