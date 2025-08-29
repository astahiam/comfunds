package services

import (
	"context"
	"encoding/json"
	"time"

	"comfunds/internal/entities"
	"comfunds/internal/repositories"

	"github.com/google/uuid"
)

type AuditService interface {
	LogOperation(ctx context.Context, req *LogOperationRequest) error
	GetAuditLogs(ctx context.Context, filter *entities.AuditLogFilter) ([]*entities.AuditLog, int, error)
	GetEntityAuditTrail(ctx context.Context, entityType string, entityID uuid.UUID, page, limit int) ([]*entities.AuditLog, int, error)
	GetUserActivity(ctx context.Context, userID uuid.UUID, page, limit int) ([]*entities.AuditLog, int, error)
}

type LogOperationRequest struct {
	EntityType string      `json:"entity_type"`
	EntityID   uuid.UUID   `json:"entity_id"`
	Operation  string      `json:"operation"`
	UserID     uuid.UUID   `json:"user_id"`
	IPAddress  string      `json:"ip_address"`
	UserAgent  string      `json:"user_agent"`
	Changes    interface{} `json:"changes"`
	OldValues  interface{} `json:"old_values"`
	NewValues  interface{} `json:"new_values"`
	Reason     string      `json:"reason"`
	Status     string      `json:"status"`
	ErrorMsg   string      `json:"error_msg"`
}

type auditService struct {
	auditRepo repositories.AuditRepository
}

func NewAuditService(auditRepo repositories.AuditRepository) AuditService {
	return &auditService{
		auditRepo: auditRepo,
	}
}

func (s *auditService) LogOperation(ctx context.Context, req *LogOperationRequest) error {
	auditLog := &entities.AuditLog{
		ID:         uuid.New(),
		EntityType: req.EntityType,
		EntityID:   req.EntityID,
		Operation:  req.Operation,
		UserID:     req.UserID,
		IPAddress:  req.IPAddress,
		UserAgent:  req.UserAgent,
		Reason:     req.Reason,
		Status:     req.Status,
		ErrorMsg:   req.ErrorMsg,
		CreatedAt:  time.Now(),
	}

	// Convert changes to JSON
	if req.Changes != nil {
		changesJSON, err := json.Marshal(req.Changes)
		if err == nil {
			auditLog.Changes = string(changesJSON)
		}
	}

	// Convert old values to JSON
	if req.OldValues != nil {
		oldValuesJSON, err := json.Marshal(req.OldValues)
		if err == nil {
			auditLog.OldValues = string(oldValuesJSON)
		}
	}

	// Convert new values to JSON
	if req.NewValues != nil {
		newValuesJSON, err := json.Marshal(req.NewValues)
		if err == nil {
			auditLog.NewValues = string(newValuesJSON)
		}
	}

	// Set default status if not provided
	if auditLog.Status == "" {
		auditLog.Status = entities.AuditStatusSuccess
	}

	return s.auditRepo.Create(ctx, auditLog)
}

func (s *auditService) GetAuditLogs(ctx context.Context, filter *entities.AuditLogFilter) ([]*entities.AuditLog, int, error) {
	// Set default pagination
	if filter.Page < 1 {
		filter.Page = 1
	}
	if filter.Limit < 1 || filter.Limit > 100 {
		filter.Limit = 20
	}

	return s.auditRepo.GetByFilter(ctx, filter)
}

func (s *auditService) GetEntityAuditTrail(ctx context.Context, entityType string, entityID uuid.UUID, page, limit int) ([]*entities.AuditLog, int, error) {
	filter := &entities.AuditLogFilter{
		EntityType: entityType,
		EntityID:   &entityID,
		Page:       page,
		Limit:      limit,
	}

	return s.GetAuditLogs(ctx, filter)
}

func (s *auditService) GetUserActivity(ctx context.Context, userID uuid.UUID, page, limit int) ([]*entities.AuditLog, int, error) {
	filter := &entities.AuditLogFilter{
		UserID: &userID,
		Page:   page,
		Limit:  limit,
	}

	return s.GetAuditLogs(ctx, filter)
}
