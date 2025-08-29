package entities

import (
	"time"

	"github.com/google/uuid"
)

// AuditLog represents an audit trail entry for tracking all system operations
type AuditLog struct {
	ID         uuid.UUID `json:"id" db:"id"`
	EntityType string    `json:"entity_type" db:"entity_type"` // user, cooperative, project, etc.
	EntityID   uuid.UUID `json:"entity_id" db:"entity_id"`     // ID of the affected entity
	Operation  string    `json:"operation" db:"operation"`     // CREATE, READ, UPDATE, DELETE
	UserID     uuid.UUID `json:"user_id" db:"user_id"`         // User who performed the operation
	IPAddress  string    `json:"ip_address" db:"ip_address"`   // IP address of the user
	UserAgent  string    `json:"user_agent" db:"user_agent"`   // Browser/client information
	Changes    string    `json:"changes" db:"changes"`         // JSON of what changed
	OldValues  string    `json:"old_values" db:"old_values"`   // JSON of previous values
	NewValues  string    `json:"new_values" db:"new_values"`   // JSON of new values
	Reason     string    `json:"reason" db:"reason"`           // Optional reason for the change
	Status     string    `json:"status" db:"status"`           // SUCCESS, FAILED, UNAUTHORIZED
	ErrorMsg   string    `json:"error_msg" db:"error_msg"`     // Error message if status is FAILED
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
}

// AuditOperation constants
const (
	AuditOperationCreate = "CREATE"
	AuditOperationRead   = "READ"
	AuditOperationUpdate = "UPDATE"
	AuditOperationDelete = "DELETE"
	AuditOperationLogin  = "LOGIN"
	AuditOperationLogout = "LOGOUT"
)

// AuditEntityType constants
const (
	AuditEntityUser        = "user"
	AuditEntityCooperative = "cooperative"
	AuditEntityBusiness    = "business"
	AuditEntityProject     = "project"
	AuditEntityInvestment  = "investment"
)

// AuditStatus constants
const (
	AuditStatusSuccess      = "SUCCESS"
	AuditStatusFailed       = "FAILED"
	AuditStatusUnauthorized = "UNAUTHORIZED"
)

// CreateAuditLogRequest for manual audit log creation
type CreateAuditLogRequest struct {
	EntityType string    `json:"entity_type" validate:"required"`
	EntityID   uuid.UUID `json:"entity_id" validate:"required"`
	Operation  string    `json:"operation" validate:"required,oneof=CREATE READ UPDATE DELETE LOGIN LOGOUT"`
	Changes    string    `json:"changes"`
	OldValues  string    `json:"old_values"`
	NewValues  string    `json:"new_values"`
	Reason     string    `json:"reason"`
}

// AuditLogFilter for querying audit logs
type AuditLogFilter struct {
	EntityType string     `json:"entity_type"`
	EntityID   *uuid.UUID `json:"entity_id"`
	UserID     *uuid.UUID `json:"user_id"`
	Operation  string     `json:"operation"`
	Status     string     `json:"status"`
	StartDate  *time.Time `json:"start_date"`
	EndDate    *time.Time `json:"end_date"`
	Page       int        `json:"page"`
	Limit      int        `json:"limit"`
}
