package entities

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID            uuid.UUID  `json:"id" db:"id"`
	Email         string     `json:"email" db:"email"`
	Name          string     `json:"name" db:"name"`
	Password      string     `json:"-" db:"password"` // Hidden from JSON responses
	Phone         string     `json:"phone" db:"phone"`
	Address       string     `json:"address" db:"address"`
	CooperativeID *uuid.UUID `json:"cooperative_id" db:"cooperative_id"`
	Roles         []string   `json:"roles" db:"roles"`
	KYCStatus     string     `json:"kyc_status" db:"kyc_status"`
	IsActive      bool       `json:"is_active" db:"is_active"`
	CreatedAt     time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at" db:"updated_at"`
}

type CreateUserRequest struct {
	Email         string     `json:"email" validate:"required,email"`
	Name          string     `json:"name" validate:"required,min=2,max=100"`
	Password      string     `json:"password" validate:"required,min=6"`
	Phone         string     `json:"phone" validate:"required"`
	Address       string     `json:"address" validate:"required"`
	CooperativeID *uuid.UUID `json:"cooperative_id"`
	Roles         []string   `json:"roles" validate:"required,dive,oneof=guest member business_owner investor admin"`
}

type UpdateUserRequest struct {
	Name    string   `json:"name" validate:"min=2,max=100"`
	Phone   string   `json:"phone"`
	Address string   `json:"address"`
	Roles   []string `json:"roles" validate:"dive,oneof=guest member business_owner investor admin"`
}
