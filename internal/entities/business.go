package entities

import (
	"time"

	"github.com/google/uuid"
)

type Business struct {
	ID                    uuid.UUID              `json:"id" db:"id"`
	Name                  string                 `json:"name" db:"name"`
	BusinessType          string                 `json:"business_type" db:"business_type"`
	Description           string                 `json:"description" db:"description"`
	OwnerID               uuid.UUID              `json:"owner_id" db:"owner_id"`
	CooperativeID         uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	RegistrationDocuments map[string]interface{} `json:"registration_documents" db:"registration_documents"`
	ApprovalStatus        string                 `json:"approval_status" db:"approval_status"`
	BusinessImage         *string                `json:"business_image" db:"business_image"`
	IsActive              bool                   `json:"is_active" db:"is_active"`
	CreatedAt             time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt             time.Time              `json:"updated_at" db:"updated_at"`
}

type CreateBusinessRequest struct {
	Name                  string                 `json:"name" validate:"required,min=2,max=255"`
	BusinessType          string                 `json:"business_type" validate:"required,max=100"`
	Description           string                 `json:"description"`
	OwnerID               uuid.UUID              `json:"owner_id" validate:"required"`
	CooperativeID         uuid.UUID              `json:"cooperative_id" validate:"required"`
	RegistrationDocuments map[string]interface{} `json:"registration_documents"`
	BusinessImage         *string                `json:"business_image" validate:"omitempty,url,max=500"`
}

type UpdateBusinessRequest struct {
	Name                  string                 `json:"name" validate:"min=2,max=255"`
	BusinessType          string                 `json:"business_type" validate:"max=100"`
	Description           string                 `json:"description"`
	RegistrationDocuments map[string]interface{} `json:"registration_documents"`
	BusinessImage         *string                `json:"business_image" validate:"omitempty,url,max=500"`
}
