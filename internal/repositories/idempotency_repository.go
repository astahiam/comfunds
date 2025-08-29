package repositories

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"comfunds/internal/entities"

	"github.com/google/uuid"
)

// IdempotencyRepository interface for idempotency operations
type IdempotencyRepository interface {
	// Create creates a new idempotency key record
	Create(ctx context.Context, key *entities.IdempotencyKey) error
	
	// Get retrieves an idempotency key by ID
	Get(ctx context.Context, id string) (*entities.IdempotencyKey, error)
	
	// GetByUserAndEndpoint retrieves idempotency keys by user and endpoint
	GetByUserAndEndpoint(ctx context.Context, userID uuid.UUID, endpoint string) ([]*entities.IdempotencyKey, error)
	
	// UpdateStatus updates the status of an idempotency key
	UpdateStatus(ctx context.Context, id string, status string, responseData interface{}) error
	
	// DeleteExpired removes expired idempotency keys
	DeleteExpired(ctx context.Context) (int, error)
	
	// GetNextSequenceNumber gets the next sequence number for idempotency keys
	GetNextSequenceNumber(ctx context.Context) (int, error)
	
	// CheckDuplicate checks if a request with the same hash already exists
	CheckDuplicate(ctx context.Context, userID uuid.UUID, endpoint string, requestHash string) (*entities.IdempotencyKey, error)
}

// idempotencyRepository implements IdempotencyRepository
type idempotencyRepository struct {
	db *sql.DB
}

// NewIdempotencyRepository creates a new idempotency repository
func NewIdempotencyRepository(db *sql.DB) IdempotencyRepository {
	return &idempotencyRepository{
		db: db,
	}
}

// Create creates a new idempotency key record
func (r *idempotencyRepository) Create(ctx context.Context, key *entities.IdempotencyKey) error {
	query := `
		INSERT INTO idempotency_keys (
			id, user_id, endpoint, request_hash, response_data, status, 
			created_at, expires_at, sequence_number, table_name, random_suffix
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
		)
	`
	
	_, err := r.db.ExecContext(ctx, query,
		key.ID,
		key.UserID,
		key.Endpoint,
		key.RequestHash,
		key.ResponseData,
		key.Status,
		key.CreatedAt,
		key.ExpiresAt,
		key.SequenceNumber,
		key.TableName,
		key.RandomSuffix,
	)
	
	if err != nil {
		return fmt.Errorf("failed to create idempotency key: %w", err)
	}
	
	return nil
}

// Get retrieves an idempotency key by ID
func (r *idempotencyRepository) Get(ctx context.Context, id string) (*entities.IdempotencyKey, error) {
	query := `
		SELECT id, user_id, endpoint, request_hash, response_data, status,
			   created_at, expires_at, sequence_number, table_name, random_suffix
		FROM idempotency_keys
		WHERE id = $1 AND expires_at > NOW()
	`
	
	var key entities.IdempotencyKey
	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&key.ID,
		&key.UserID,
		&key.Endpoint,
		&key.RequestHash,
		&key.ResponseData,
		&key.Status,
		&key.CreatedAt,
		&key.ExpiresAt,
		&key.SequenceNumber,
		&key.TableName,
		&key.RandomSuffix,
	)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get idempotency key: %w", err)
	}
	
	return &key, nil
}

// GetByUserAndEndpoint retrieves idempotency keys by user and endpoint
func (r *idempotencyRepository) GetByUserAndEndpoint(ctx context.Context, userID uuid.UUID, endpoint string) ([]*entities.IdempotencyKey, error) {
	query := `
		SELECT id, user_id, endpoint, request_hash, response_data, status,
			   created_at, expires_at, sequence_number, table_name, random_suffix
		FROM idempotency_keys
		WHERE user_id = $1 AND endpoint = $2 AND expires_at > NOW()
		ORDER BY created_at DESC
	`
	
	rows, err := r.db.QueryContext(ctx, query, userID, endpoint)
	if err != nil {
		return nil, fmt.Errorf("failed to query idempotency keys: %w", err)
	}
	defer rows.Close()
	
	var keys []*entities.IdempotencyKey
	for rows.Next() {
		var key entities.IdempotencyKey
		err := rows.Scan(
			&key.ID,
			&key.UserID,
			&key.Endpoint,
			&key.RequestHash,
			&key.ResponseData,
			&key.Status,
			&key.CreatedAt,
			&key.ExpiresAt,
			&key.SequenceNumber,
			&key.TableName,
			&key.RandomSuffix,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan idempotency key: %w", err)
		}
		keys = append(keys, &key)
	}
	
	return keys, nil
}

// UpdateStatus updates the status of an idempotency key
func (r *idempotencyRepository) UpdateStatus(ctx context.Context, id string, status string, responseData interface{}) error {
	var responseJSON json.RawMessage
	if responseData != nil {
		jsonData, err := json.Marshal(responseData)
		if err != nil {
			return fmt.Errorf("failed to marshal response data: %w", err)
		}
		responseJSON = jsonData
	}
	
	query := `
		UPDATE idempotency_keys
		SET status = $1, response_data = $2, updated_at = NOW()
		WHERE id = $3
	`
	
	result, err := r.db.ExecContext(ctx, query, status, responseJSON, id)
	if err != nil {
		return fmt.Errorf("failed to update idempotency key status: %w", err)
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}
	
	if rowsAffected == 0 {
		return fmt.Errorf("idempotency key not found: %s", id)
	}
	
	return nil
}

// DeleteExpired removes expired idempotency keys
func (r *idempotencyRepository) DeleteExpired(ctx context.Context) (int, error) {
	query := `
		DELETE FROM idempotency_keys
		WHERE expires_at <= NOW()
	`
	
	result, err := r.db.ExecContext(ctx, query)
	if err != nil {
		return 0, fmt.Errorf("failed to delete expired idempotency keys: %w", err)
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return 0, fmt.Errorf("failed to get rows affected: %w", err)
	}
	
	return int(rowsAffected), nil
}

// GetNextSequenceNumber gets the next sequence number for idempotency keys
func (r *idempotencyRepository) GetNextSequenceNumber(ctx context.Context) (int, error) {
	query := `SELECT nextval('idempotency_sequence')`
	
	var sequence int
	err := r.db.QueryRowContext(ctx, query).Scan(&sequence)
	if err != nil {
		return 0, fmt.Errorf("failed to get next sequence number: %w", err)
	}
	
	return sequence, nil
}

// CheckDuplicate checks if a request with the same hash already exists
func (r *idempotencyRepository) CheckDuplicate(ctx context.Context, userID uuid.UUID, endpoint string, requestHash string) (*entities.IdempotencyKey, error) {
	query := `
		SELECT id, user_id, endpoint, request_hash, response_data, status,
			   created_at, expires_at, sequence_number, table_name, random_suffix
		FROM idempotency_keys
		WHERE user_id = $1 AND endpoint = $2 AND request_hash = $3 AND expires_at > NOW()
		ORDER BY created_at DESC
		LIMIT 1
	`
	
	var key entities.IdempotencyKey
	err := r.db.QueryRowContext(ctx, query, userID, endpoint, requestHash).Scan(
		&key.ID,
		&key.UserID,
		&key.Endpoint,
		&key.RequestHash,
		&key.ResponseData,
		&key.Status,
		&key.CreatedAt,
		&key.ExpiresAt,
		&key.SequenceNumber,
		&key.TableName,
		&key.RandomSuffix,
	)
	
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to check duplicate: %w", err)
	}
	
	return &key, nil
}
