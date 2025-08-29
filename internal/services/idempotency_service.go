package services

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"comfunds/internal/entities"
	"comfunds/internal/repositories"
)

// IdempotencyService interface for idempotency operations
type IdempotencyService interface {
	// ProcessIdempotentRequest processes a request with idempotency support
	ProcessIdempotentRequest(ctx context.Context, req *entities.IdempotencyRequest, operation func() (interface{}, error)) (*entities.IdempotencyResponse, error)
	
	// GenerateIdempotencyKey generates a new idempotency key
	GenerateIdempotencyKey(ctx context.Context, tableName string) (string, error)
	
	// ValidateIdempotencyKey validates an idempotency key
	ValidateIdempotencyKey(key string) error
	
	// GetIdempotencyKey retrieves an idempotency key
	GetIdempotencyKey(ctx context.Context, id string) (*entities.IdempotencyKey, error)
	
	// CleanupExpiredKeys removes expired idempotency keys
	CleanupExpiredKeys(ctx context.Context) (int, error)
}

// idempotencyService implements IdempotencyService
type idempotencyService struct {
	idempotencyRepo repositories.IdempotencyRepository
	keyGenerator    *entities.IdempotencyKeyGenerator
}

// NewIdempotencyService creates a new idempotency service
func NewIdempotencyService(idempotencyRepo repositories.IdempotencyRepository) IdempotencyService {
	return &idempotencyService{
		idempotencyRepo: idempotencyRepo,
		keyGenerator:    entities.NewIdempotencyKeyGenerator(),
	}
}

// ProcessIdempotentRequest processes a request with idempotency support
func (s *idempotencyService) ProcessIdempotentRequest(ctx context.Context, req *entities.IdempotencyRequest, operation func() (interface{}, error)) (*entities.IdempotencyResponse, error) {
	// Generate request hash for duplicate detection
	requestHash, err := entities.GenerateRequestHash(req.Data)
	if err != nil {
		return nil, fmt.Errorf("failed to generate request hash: %w", err)
	}
	
	// Check for existing duplicate request
	existingKey, err := s.idempotencyRepo.CheckDuplicate(ctx, req.UserID, req.Endpoint, requestHash)
	if err != nil {
		return nil, fmt.Errorf("failed to check for duplicate request: %w", err)
	}
	
	// If duplicate found and completed, return cached response
	if existingKey != nil && existingKey.Status == entities.IdempotencyStatusCompleted {
		var responseData interface{}
		if existingKey.ResponseData != nil {
			if err := json.Unmarshal(existingKey.ResponseData, &responseData); err != nil {
				return nil, fmt.Errorf("failed to unmarshal cached response: %w", err)
			}
		}
		
		return &entities.IdempotencyResponse{
			ID:           existingKey.ID,
			Status:       existingKey.Status,
			ResponseData: existingKey.ResponseData,
			CreatedAt:    existingKey.CreatedAt,
			ExpiresAt:    existingKey.ExpiresAt,
			IsDuplicate:  true,
		}, nil
	}
	
	// Generate idempotency key if not provided
	idempotencyKey := req.IdempotencyKey
	if idempotencyKey == "" {
		idempotencyKey, err = s.GenerateIdempotencyKey(ctx, req.TableName)
		if err != nil {
			return nil, fmt.Errorf("failed to generate idempotency key: %w", err)
		}
	} else {
		// Validate provided key
		if err := s.ValidateIdempotencyKey(idempotencyKey); err != nil {
			return nil, fmt.Errorf("invalid idempotency key: %w", err)
		}
	}
	
	// Check if key already exists
	existingKey, err = s.idempotencyRepo.Get(ctx, idempotencyKey)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing idempotency key: %w", err)
	}
	
	// If key exists and is completed, return cached response
	if existingKey != nil && existingKey.Status == entities.IdempotencyStatusCompleted {
		var responseData interface{}
		if existingKey.ResponseData != nil {
			if err := json.Unmarshal(existingKey.ResponseData, &responseData); err != nil {
				return nil, fmt.Errorf("failed to unmarshal cached response: %w", err)
			}
		}
		
		return &entities.IdempotencyResponse{
			ID:           existingKey.ID,
			Status:       existingKey.Status,
			ResponseData: existingKey.ResponseData,
			CreatedAt:    existingKey.CreatedAt,
			ExpiresAt:    existingKey.ExpiresAt,
			IsDuplicate:  true,
		}, nil
	}
	
	// If key exists and is pending, this might be a concurrent request
	if existingKey != nil && existingKey.Status == entities.IdempotencyStatusPending {
		// Wait a bit and check again (simple retry mechanism)
		time.Sleep(100 * time.Millisecond)
		existingKey, err = s.idempotencyRepo.Get(ctx, idempotencyKey)
		if err != nil {
			return nil, fmt.Errorf("failed to recheck idempotency key: %w", err)
		}
		
		if existingKey != nil && existingKey.Status == entities.IdempotencyStatusCompleted {
			var responseData interface{}
			if existingKey.ResponseData != nil {
				if err := json.Unmarshal(existingKey.ResponseData, &responseData); err != nil {
					return nil, fmt.Errorf("failed to unmarshal cached response: %w", err)
				}
			}
			
			return &entities.IdempotencyResponse{
				ID:           existingKey.ID,
				Status:       existingKey.Status,
				ResponseData: existingKey.ResponseData,
				CreatedAt:    existingKey.CreatedAt,
				ExpiresAt:    existingKey.ExpiresAt,
				IsDuplicate:  true,
			}, nil
		}
	}
	
	// Create new idempotency key record
	now := time.Now()
	expiresAt := now.Add(entities.DefaultIdempotencyExpiration)
	
	// Get sequence number
	sequenceNumber, err := s.idempotencyRepo.GetNextSequenceNumber(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get sequence number: %w", err)
	}
	
	// Parse the idempotency key to extract components
	_, _, tableName, randomSuffix, err := entities.ParseIdempotencyKey(idempotencyKey)
	if err != nil {
		return nil, fmt.Errorf("failed to parse idempotency key: %w", err)
	}
	
	key := &entities.IdempotencyKey{
		ID:             idempotencyKey,
		UserID:         req.UserID,
		Endpoint:       req.Endpoint,
		RequestHash:    requestHash,
		Status:         entities.IdempotencyStatusPending,
		CreatedAt:      now,
		ExpiresAt:      expiresAt,
		SequenceNumber: sequenceNumber,
		TableName:      tableName,
		RandomSuffix:   randomSuffix,
	}
	
	// Create the idempotency key record
	err = s.idempotencyRepo.Create(ctx, key)
	if err != nil {
		return nil, fmt.Errorf("failed to create idempotency key: %w", err)
	}
	
	// Execute the operation
	result, err := operation()
	if err != nil {
		// Update status to failed
		updateErr := s.idempotencyRepo.UpdateStatus(ctx, idempotencyKey, entities.IdempotencyStatusFailed, nil)
		if updateErr != nil {
			// Log the error but don't fail the main operation
			fmt.Printf("Failed to update idempotency key status to failed: %v\n", updateErr)
		}
		return nil, fmt.Errorf("operation failed: %w", err)
	}
	
	// Update status to completed with response data
	err = s.idempotencyRepo.UpdateStatus(ctx, idempotencyKey, entities.IdempotencyStatusCompleted, result)
	if err != nil {
		return nil, fmt.Errorf("failed to update idempotency key status: %w", err)
	}
	
	// Marshal response data
	var responseData json.RawMessage
	if result != nil {
		jsonData, err := json.Marshal(result)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal response data: %w", err)
		}
		responseData = jsonData
	}
	
	return &entities.IdempotencyResponse{
		ID:           idempotencyKey,
		Status:       entities.IdempotencyStatusCompleted,
		ResponseData: responseData,
		CreatedAt:    now,
		ExpiresAt:    expiresAt,
		IsDuplicate:  false,
	}, nil
}

// GenerateIdempotencyKey generates a new idempotency key
func (s *idempotencyService) GenerateIdempotencyKey(ctx context.Context, tableName string) (string, error) {
	// Get sequence number
	sequenceNumber, err := s.idempotencyRepo.GetNextSequenceNumber(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to get sequence number: %w", err)
	}
	
	// Generate the idempotency key
	key := s.keyGenerator.GenerateIdempotencyKey(tableName, sequenceNumber)
	
	return key, nil
}

// ValidateIdempotencyKey validates an idempotency key
func (s *idempotencyService) ValidateIdempotencyKey(key string) error {
	return entities.ValidateIdempotencyKey(key)
}

// GetIdempotencyKey retrieves an idempotency key
func (s *idempotencyService) GetIdempotencyKey(ctx context.Context, id string) (*entities.IdempotencyKey, error) {
	return s.idempotencyRepo.Get(ctx, id)
}

// CleanupExpiredKeys removes expired idempotency keys
func (s *idempotencyService) CleanupExpiredKeys(ctx context.Context) (int, error) {
	return s.idempotencyRepo.DeleteExpired(ctx)
}
