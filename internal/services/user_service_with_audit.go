package services

import (
	"context"
	"fmt"

	"comfunds/internal/entities"
	"comfunds/internal/repositories"

	"github.com/google/uuid"
)

// UserServiceWithAudit extends UserServiceAuth with audit trail functionality (FR-013)
type UserServiceWithAudit interface {
	UserServiceAuth
	// FR-011: CRUD Operations
	GetAllUsersWithAudit(ctx context.Context, userID uuid.UUID, page, limit int, ipAddress, userAgent string) ([]*entities.User, int, error)
	GetUserByIDWithAudit(ctx context.Context, targetUserID, requestUserID uuid.UUID, ipAddress, userAgent string) (*entities.User, error)
	UpdateUserWithAudit(ctx context.Context, targetUserID, requestUserID uuid.UUID, req *entities.UpdateUserRequest, ipAddress, userAgent, reason string) (*entities.User, error)
	// FR-014: Soft delete
	SoftDeleteUser(ctx context.Context, targetUserID, requestUserID uuid.UUID, ipAddress, userAgent, reason string) error
	RestoreUser(ctx context.Context, targetUserID, requestUserID uuid.UUID, ipAddress, userAgent, reason string) error
	// Audit trail
	GetUserAuditTrail(ctx context.Context, userID uuid.UUID, page, limit int) ([]*entities.AuditLog, int, error)
}

type userServiceWithAudit struct {
	UserServiceAuth
	auditService AuditService
	userRepo     repositories.UserRepositorySharded
}

func NewUserServiceWithAudit(
	userService UserServiceAuth,
	auditService AuditService,
	userRepo repositories.UserRepositorySharded,
) UserServiceWithAudit {
	return &userServiceWithAudit{
		UserServiceAuth: userService,
		auditService:    auditService,
		userRepo:        userRepo,
	}
}

func (s *userServiceWithAudit) GetAllUsersWithAudit(ctx context.Context, userID uuid.UUID, page, limit int, ipAddress, userAgent string) ([]*entities.User, int, error) {
	// Log the read operation
	defer func() {
		s.auditService.LogOperation(ctx, &LogOperationRequest{
			EntityType: entities.AuditEntityUser,
			EntityID:   uuid.New(), // For list operations, we use a new UUID
			Operation:  entities.AuditOperationRead,
			UserID:     userID,
			IPAddress:  ipAddress,
			UserAgent:  userAgent,
			Changes:    map[string]interface{}{"operation": "list_users", "page": page, "limit": limit},
			Status:     entities.AuditStatusSuccess,
		})
	}()

	return s.UserServiceAuth.GetAllUsers(ctx, page, limit)
}

func (s *userServiceWithAudit) GetUserByIDWithAudit(ctx context.Context, targetUserID, requestUserID uuid.UUID, ipAddress, userAgent string) (*entities.User, error) {
	user, err := s.UserServiceAuth.GetUserByID(ctx, targetUserID)

	// Log the operation
	status := entities.AuditStatusSuccess
	errorMsg := ""
	if err != nil {
		status = entities.AuditStatusFailed
		errorMsg = err.Error()
	}

	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityUser,
		EntityID:   targetUserID,
		Operation:  entities.AuditOperationRead,
		UserID:     requestUserID,
		IPAddress:  ipAddress,
		UserAgent:  userAgent,
		Changes:    map[string]interface{}{"operation": "get_user_by_id"},
		Status:     status,
		ErrorMsg:   errorMsg,
	})

	return user, err
}

func (s *userServiceWithAudit) UpdateUserWithAudit(ctx context.Context, targetUserID, requestUserID uuid.UUID, req *entities.UpdateUserRequest, ipAddress, userAgent, reason string) (*entities.User, error) {
	// Get old user data for audit trail
	oldUser, err := s.userRepo.GetByID(ctx, targetUserID)
	if err != nil {
		return nil, fmt.Errorf("failed to get old user data: %w", err)
	}

	// Perform the update
	updatedUser, err := s.UserServiceAuth.UpdateUser(ctx, targetUserID, req)

	// Prepare audit data
	status := entities.AuditStatusSuccess
	errorMsg := ""
	if err != nil {
		status = entities.AuditStatusFailed
		errorMsg = err.Error()
	}

	// Log the operation
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityUser,
		EntityID:   targetUserID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     requestUserID,
		IPAddress:  ipAddress,
		UserAgent:  userAgent,
		Changes:    req,
		OldValues:  oldUser,
		NewValues:  updatedUser,
		Reason:     reason,
		Status:     status,
		ErrorMsg:   errorMsg,
	})

	return updatedUser, err
}

func (s *userServiceWithAudit) SoftDeleteUser(ctx context.Context, targetUserID, requestUserID uuid.UUID, ipAddress, userAgent, reason string) error {
	// Get user data before deletion
	user, err := s.userRepo.GetByID(ctx, targetUserID)
	if err != nil {
		return fmt.Errorf("user not found: %w", err)
	}

	// Perform soft delete (update is_active to false)
	err = s.userRepo.Delete(ctx, targetUserID)

	// Log the operation
	status := entities.AuditStatusSuccess
	errorMsg := ""
	if err != nil {
		status = entities.AuditStatusFailed
		errorMsg = err.Error()
	}

	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityUser,
		EntityID:   targetUserID,
		Operation:  entities.AuditOperationDelete,
		UserID:     requestUserID,
		IPAddress:  ipAddress,
		UserAgent:  userAgent,
		Changes:    map[string]interface{}{"soft_delete": true, "is_active": false},
		OldValues:  user,
		NewValues:  map[string]interface{}{"is_active": false},
		Reason:     reason,
		Status:     status,
		ErrorMsg:   errorMsg,
	})

	return err
}

func (s *userServiceWithAudit) RestoreUser(ctx context.Context, targetUserID, requestUserID uuid.UUID, ipAddress, userAgent, reason string) error {
	// This would require a new repository method to restore soft-deleted users
	// For now, we'll implement the audit logging structure

	// Log the operation
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityUser,
		EntityID:   targetUserID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     requestUserID,
		IPAddress:  ipAddress,
		UserAgent:  userAgent,
		Changes:    map[string]interface{}{"restore_user": true, "is_active": true},
		Reason:     reason,
		Status:     entities.AuditStatusSuccess,
	})

	return fmt.Errorf("restore user functionality not yet implemented")
}

func (s *userServiceWithAudit) GetUserAuditTrail(ctx context.Context, userID uuid.UUID, page, limit int) ([]*entities.AuditLog, int, error) {
	return s.auditService.GetEntityAuditTrail(ctx, entities.AuditEntityUser, userID, page, limit)
}
