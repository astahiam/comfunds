package entities

import (
	"time"

	"github.com/google/uuid"
)

type Image struct {
	ID        uuid.UUID `json:"id" db:"id"`
	ImageURL  string    `json:"image_url" db:"image_url"`
	ImageName string    `json:"image_name" db:"image_name"`
	UsedBy    string    `json:"used_by" db:"used_by"` // 'projects', 'users', 'cooperatives', 'businesses'
	ImageSize *int64    `json:"image_size" db:"image_size"` // size in bytes
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

type CreateImageRequest struct {
	ImageURL  string `json:"image_url" validate:"required,url,max=500"`
	ImageName string `json:"image_name" validate:"required,max=255"`
	UsedBy    string `json:"used_by" validate:"required,oneof=projects users cooperatives businesses"`
	ImageSize *int64 `json:"image_size" validate:"omitempty,min=1"`
}

type UpdateImageRequest struct {
	ImageURL  string `json:"image_url" validate:"url,max=500"`
	ImageName string `json:"image_name" validate:"max=255"`
	ImageSize *int64 `json:"image_size" validate:"omitempty,min=1"`
}

// UsedBy constants
const (
	ImageUsedByProjects     = "projects"
	ImageUsedByUsers        = "users"
	ImageUsedByCooperatives = "cooperatives"
	ImageUsedByBusinesses   = "businesses"
)
