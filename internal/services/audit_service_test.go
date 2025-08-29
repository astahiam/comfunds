package services

import (
	"context"
	"testing"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// Mocks are now in mocks_test.go to avoid redeclaration

func TestAuditService_LogOperation(t *testing.T) {
	mockRepo := new(MockAuditRepository)
	auditService := NewAuditService(mockRepo)

	userID := uuid.New()
	entityID := uuid.New()

	req := &LogOperationRequest{
		EntityType: entities.AuditEntityUser,
		EntityID:   entityID,
		Operation:  entities.AuditOperationCreate,
		UserID:     userID,
		IPAddress:  "192.168.1.1",
		UserAgent:  "test-agent",
		Changes:    map[string]interface{}{"field": "value"},
		Status:     entities.AuditStatusSuccess,
	}

	mockRepo.On("Create", mock.Anything, mock.MatchedBy(func(auditLog *entities.AuditLog) bool {
		return auditLog.EntityType == entities.AuditEntityUser &&
			auditLog.EntityID == entityID &&
			auditLog.Operation == entities.AuditOperationCreate &&
			auditLog.UserID == userID &&
			auditLog.Status == entities.AuditStatusSuccess
	})).Return(nil)

	err := auditService.LogOperation(context.Background(), req)

	assert.NoError(t, err)
	mockRepo.AssertExpectations(t)
}

func TestAuditService_GetAuditLogs(t *testing.T) {
	mockRepo := new(MockAuditRepository)
	auditService := NewAuditService(mockRepo)

	userID := uuid.New()
	filter := &entities.AuditLogFilter{
		UserID: &userID,
		Page:   1,
		Limit:  20,
	}

	expectedLogs := []*entities.AuditLog{
		{
			ID:         uuid.New(),
			EntityType: entities.AuditEntityUser,
			EntityID:   uuid.New(),
			Operation:  entities.AuditOperationCreate,
			UserID:     userID,
			Status:     entities.AuditStatusSuccess,
			CreatedAt:  time.Now(),
		},
	}

	mockRepo.On("GetByFilter", mock.Anything, filter).Return(expectedLogs, 1, nil)

	logs, total, err := auditService.GetAuditLogs(context.Background(), filter)

	assert.NoError(t, err)
	assert.Equal(t, expectedLogs, logs)
	assert.Equal(t, 1, total)
	mockRepo.AssertExpectations(t)
}

func TestAuditService_GetEntityAuditTrail(t *testing.T) {
	mockRepo := new(MockAuditRepository)
	auditService := NewAuditService(mockRepo)

	entityID := uuid.New()
	entityType := entities.AuditEntityUser

	expectedFilter := &entities.AuditLogFilter{
		EntityType: entityType,
		EntityID:   &entityID,
		Page:       1,
		Limit:      10,
	}

	expectedLogs := []*entities.AuditLog{
		{
			ID:         uuid.New(),
			EntityType: entityType,
			EntityID:   entityID,
			Operation:  entities.AuditOperationUpdate,
			Status:     entities.AuditStatusSuccess,
			CreatedAt:  time.Now(),
		},
	}

	mockRepo.On("GetByFilter", mock.Anything, expectedFilter).Return(expectedLogs, 1, nil)

	logs, total, err := auditService.GetEntityAuditTrail(context.Background(), entityType, entityID, 1, 10)

	assert.NoError(t, err)
	assert.Equal(t, expectedLogs, logs)
	assert.Equal(t, 1, total)
	mockRepo.AssertExpectations(t)
}

func TestAuditService_GetUserActivity(t *testing.T) {
	mockRepo := new(MockAuditRepository)
	auditService := NewAuditService(mockRepo)

	userID := uuid.New()

	expectedFilter := &entities.AuditLogFilter{
		UserID: &userID,
		Page:   1,
		Limit:  10,
	}

	expectedLogs := []*entities.AuditLog{
		{
			ID:         uuid.New(),
			EntityType: entities.AuditEntityUser,
			EntityID:   uuid.New(),
			Operation:  entities.AuditOperationRead,
			UserID:     userID,
			Status:     entities.AuditStatusSuccess,
			CreatedAt:  time.Now(),
		},
	}

	mockRepo.On("GetByFilter", mock.Anything, expectedFilter).Return(expectedLogs, 1, nil)

	logs, total, err := auditService.GetUserActivity(context.Background(), userID, 1, 10)

	assert.NoError(t, err)
	assert.Equal(t, expectedLogs, logs)
	assert.Equal(t, 1, total)
	mockRepo.AssertExpectations(t)
}
