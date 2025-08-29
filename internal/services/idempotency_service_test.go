package services

import (
	"context"
	"testing"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// MockIdempotencyRepository for testing
type MockIdempotencyRepository struct {
	keys map[string]*entities.IdempotencyKey
	sequence int
}

func NewMockIdempotencyRepository() *MockIdempotencyRepository {
	return &MockIdempotencyRepository{
		keys: make(map[string]*entities.IdempotencyKey),
		sequence: 1,
	}
}

func (m *MockIdempotencyRepository) Create(ctx context.Context, key *entities.IdempotencyKey) error {
	m.keys[key.ID] = key
	return nil
}

func (m *MockIdempotencyRepository) Get(ctx context.Context, id string) (*entities.IdempotencyKey, error) {
	if key, exists := m.keys[id]; exists {
		return key, nil
	}
	return nil, nil
}

func (m *MockIdempotencyRepository) GetByUserAndEndpoint(ctx context.Context, userID uuid.UUID, endpoint string) ([]*entities.IdempotencyKey, error) {
	var keys []*entities.IdempotencyKey
	for _, key := range m.keys {
		if key.UserID == userID && key.Endpoint == endpoint {
			keys = append(keys, key)
		}
	}
	return keys, nil
}

func (m *MockIdempotencyRepository) UpdateStatus(ctx context.Context, id string, status string, responseData interface{}) error {
	if key, exists := m.keys[id]; exists {
		key.Status = status
		return nil
	}
	return nil
}

func (m *MockIdempotencyRepository) DeleteExpired(ctx context.Context) (int, error) {
	count := 0
	for id, key := range m.keys {
		if key.ExpiresAt.Before(time.Now()) {
			delete(m.keys, id)
			count++
		}
	}
	return count, nil
}

func (m *MockIdempotencyRepository) GetNextSequenceNumber(ctx context.Context) (int, error) {
	m.sequence++
	return m.sequence, nil
}

func (m *MockIdempotencyRepository) CheckDuplicate(ctx context.Context, userID uuid.UUID, endpoint string, requestHash string) (*entities.IdempotencyKey, error) {
	for _, key := range m.keys {
		if key.UserID == userID && key.Endpoint == endpoint && key.RequestHash == requestHash {
			return key, nil
		}
	}
	return nil, nil
}

func TestIdempotencyKeyGeneration(t *testing.T) {
	generator := entities.NewIdempotencyKeyGenerator()
	
	key := generator.GenerateIdempotencyKey("investments", 123456)
	
	// Validate key format: yyyymmddhhmm + sequence + table_name + 5_random_chars
	assert.Len(t, key, 12+6+10+5) // 12 (time) + 6 (sequence) + 10 (table_name) + 5 (random)
	
	// Parse the key
	parsedTime, sequence, tableName, randomSuffix, err := entities.ParseIdempotencyKey(key)
	require.NoError(t, err)
	
	assert.Equal(t, 123456, sequence)
	assert.Equal(t, "investments", tableName)
	assert.Len(t, randomSuffix, 5)
	
	// Check that parsed time is close to current time
	now := time.Now()
	diff := now.Sub(parsedTime)
	assert.True(t, diff < time.Minute, "Parsed time should be close to current time")
}

func TestIdempotencyKeyValidation(t *testing.T) {
	// Valid key
	validKey := "202412291234000001investmentsABC12"
	err := entities.ValidateIdempotencyKey(validKey)
	assert.NoError(t, err)
	
	// Invalid keys
	invalidKeys := []string{
		"",                    // Empty
		"short",               // Too short
		"202412291234000001",  // Missing table name and random suffix
		"invalidformat",       // Invalid format
	}
	
	for _, key := range invalidKeys {
		err := entities.ValidateIdempotencyKey(key)
		assert.Error(t, err, "Key should be invalid: %s", key)
	}
}

func TestRequestHashGeneration(t *testing.T) {
	testData := map[string]interface{}{
		"amount": 1000.0,
		"project_id": "123e4567-e89b-12d3-a456-426614174000",
		"currency": "IDR",
	}
	
	hash1, err := entities.GenerateRequestHash(testData)
	require.NoError(t, err)
	assert.NotEmpty(t, hash1)
	
	// Same data should produce same hash
	hash2, err := entities.GenerateRequestHash(testData)
	require.NoError(t, err)
	assert.Equal(t, hash1, hash2)
	
	// Different data should produce different hash
	testData2 := map[string]interface{}{
		"amount": 2000.0,
		"project_id": "123e4567-e89b-12d3-a456-426614174000",
		"currency": "IDR",
	}
	
	hash3, err := entities.GenerateRequestHash(testData2)
	require.NoError(t, err)
	assert.NotEqual(t, hash1, hash3)
}

func TestIdempotencyService_ProcessIdempotentRequest(t *testing.T) {
	mockRepo := NewMockIdempotencyRepository()
	service := NewIdempotencyService(mockRepo)
	
	userID := uuid.New()
	req := &entities.IdempotencyRequest{
		UserID:    userID,
		Endpoint:  "/api/v1/investments",
		TableName: "investments",
		Data: map[string]interface{}{
			"amount": 1000.0,
			"project_id": "123e4567-e89b-12d3-a456-426614174000",
		},
	}
	
	// Test successful operation
	operation := func() (interface{}, error) {
		return map[string]interface{}{"investment_id": "test-123"}, nil
	}
	
	response, err := service.ProcessIdempotentRequest(context.Background(), req, operation)
	require.NoError(t, err)
	assert.NotNil(t, response)
	assert.Equal(t, entities.IdempotencyStatusCompleted, response.Status)
	assert.False(t, response.IsDuplicate)
	
	// Test duplicate request (same data)
	response2, err := service.ProcessIdempotentRequest(context.Background(), req, operation)
	require.NoError(t, err)
	assert.NotNil(t, response2)
	assert.True(t, response2.IsDuplicate)
	assert.Equal(t, response.ID, response2.ID)
}

func TestIdempotencyService_GenerateIdempotencyKey(t *testing.T) {
	mockRepo := NewMockIdempotencyRepository()
	service := NewIdempotencyService(mockRepo)
	
	key, err := service.GenerateIdempotencyKey(context.Background(), "investments")
	require.NoError(t, err)
	assert.NotEmpty(t, key)
	
	// Validate the generated key
	err = service.ValidateIdempotencyKey(key)
	assert.NoError(t, err)
	
	// Parse the key
	_, sequence, tableName, _, err := entities.ParseIdempotencyKey(key)
	require.NoError(t, err)
	assert.Equal(t, "investments", tableName)
	assert.Greater(t, sequence, 0)
}
