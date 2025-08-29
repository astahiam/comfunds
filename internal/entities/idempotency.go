package entities

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math/rand"
	"time"

	"github.com/google/uuid"
)

// IdempotencyKey represents an idempotency key record
type IdempotencyKey struct {
	ID             string          `json:"id" db:"id"`
	UserID         uuid.UUID       `json:"user_id" db:"user_id"`
	Endpoint       string          `json:"endpoint" db:"endpoint"`
	RequestHash    string          `json:"request_hash" db:"request_hash"`
	ResponseData   json.RawMessage `json:"response_data" db:"response_data"`
	Status         string          `json:"status" db:"status"`
	CreatedAt      time.Time       `json:"created_at" db:"created_at"`
	ExpiresAt      time.Time       `json:"expires_at" db:"expires_at"`
	SequenceNumber int             `json:"sequence_number" db:"sequence_number"`
	TableName      string          `json:"table_name" db:"table_name"`
	RandomSuffix   string          `json:"random_suffix" db:"random_suffix"`
}

// IdempotencyRequest represents a request with idempotency support
type IdempotencyRequest struct {
	IdempotencyKey string      `json:"idempotency_key,omitempty"`
	UserID         uuid.UUID   `json:"user_id"`
	Endpoint       string      `json:"endpoint"`
	TableName      string      `json:"table_name"`
	Data           interface{} `json:"data"`
}

// IdempotencyResponse represents the response from an idempotent operation
type IdempotencyResponse struct {
	ID             string          `json:"id"`
	Status         string          `json:"status"`
	ResponseData   json.RawMessage `json:"response_data,omitempty"`
	CreatedAt      time.Time       `json:"created_at"`
	ExpiresAt      time.Time       `json:"expires_at"`
	IsDuplicate    bool            `json:"is_duplicate"`
}

// IdempotencyKeyGenerator generates idempotency keys in the format: yyyymmddhhmm + sequence + table_name + 5_random_chars
type IdempotencyKeyGenerator struct {
	sequenceNumber int
}

// NewIdempotencyKeyGenerator creates a new idempotency key generator
func NewIdempotencyKeyGenerator() *IdempotencyKeyGenerator {
	return &IdempotencyKeyGenerator{
		sequenceNumber: 1,
	}
}

// GenerateIdempotencyKey generates a unique idempotency key
func (g *IdempotencyKeyGenerator) GenerateIdempotencyKey(tableName string, sequenceNumber int) string {
	// Format: yyyymmddhhmm + sequence_number + table_name + 5_random_chars
	now := time.Now()
	timeStr := now.Format("200601021504") // yyyymmddhhmm format
	
	// Generate 5 random alphanumeric characters
	randomSuffix := generateRandomSuffix(5)
	
	// Create the idempotency key
	key := fmt.Sprintf("%s%06d%s%s", timeStr, sequenceNumber, tableName, randomSuffix)
	
	return key
}

// generateRandomSuffix generates random alphanumeric characters
func generateRandomSuffix(length int) string {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	rand.Seed(time.Now().UnixNano())
	
	result := make([]byte, length)
	for i := range result {
		result[i] = charset[rand.Intn(len(charset))]
	}
	
	return string(result)
}

// GenerateRequestHash generates a hash of the request data for duplicate detection
func GenerateRequestHash(data interface{}) (string, error) {
	jsonData, err := json.Marshal(data)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request data: %w", err)
	}
	
	hash := sha256.Sum256(jsonData)
	return hex.EncodeToString(hash[:]), nil
}

// ValidateIdempotencyKey validates the format of an idempotency key
func ValidateIdempotencyKey(key string) error {
	if len(key) < 20 {
		return fmt.Errorf("idempotency key too short: %s", key)
	}
	
	// Check if it follows the expected format: yyyymmddhhmm + sequence + table_name + 5_random_chars
	// Minimum length: 12 (time) + 6 (sequence) + 1 (table_name) + 5 (random) = 24
	if len(key) < 24 {
		return fmt.Errorf("invalid idempotency key format: %s", key)
	}
	
	return nil
}

// ParseIdempotencyKey parses an idempotency key into its components
func ParseIdempotencyKey(key string) (time.Time, int, string, string, error) {
	if err := ValidateIdempotencyKey(key); err != nil {
		return time.Time{}, 0, "", "", err
	}
	
	// Extract time component (first 12 characters: yyyymmddhhmm)
	timeStr := key[:12]
	parsedTime, err := time.Parse("200601021504", timeStr)
	if err != nil {
		return time.Time{}, 0, "", "", fmt.Errorf("invalid time format in idempotency key: %w", err)
	}
	
	// Extract sequence number (next 6 characters)
	sequenceStr := key[12:18]
	var sequence int
	_, err = fmt.Sscanf(sequenceStr, "%06d", &sequence)
	if err != nil {
		return time.Time{}, 0, "", "", fmt.Errorf("invalid sequence number in idempotency key: %w", err)
	}
	
	// Extract table name (everything between sequence and last 5 characters)
	tableName := key[18 : len(key)-5]
	
	// Extract random suffix (last 5 characters)
	randomSuffix := key[len(key)-5:]
	
	return parsedTime, sequence, tableName, randomSuffix, nil
}

// Constants for idempotency status
const (
	IdempotencyStatusPending   = "pending"
	IdempotencyStatusCompleted = "completed"
	IdempotencyStatusFailed    = "failed"
	IdempotencyStatusExpired   = "expired"
)

// Default expiration time for idempotency keys (24 hours)
const DefaultIdempotencyExpiration = 24 * time.Hour
