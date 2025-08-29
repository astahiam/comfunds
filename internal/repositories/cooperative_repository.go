package repositories

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"comfunds/internal/database"
	"comfunds/internal/entities"

	"github.com/google/uuid"
)

type CooperativeRepository interface {
	Create(ctx context.Context, cooperative *entities.Cooperative) (*entities.Cooperative, error)
	GetByID(ctx context.Context, id uuid.UUID) (*entities.Cooperative, error)
	GetByRegistrationNumber(ctx context.Context, regNumber string) (*entities.Cooperative, error)
	GetAll(ctx context.Context, limit, offset int) ([]*entities.Cooperative, error)
	Update(ctx context.Context, id uuid.UUID, cooperative *entities.Cooperative) (*entities.Cooperative, error)
	Delete(ctx context.Context, id uuid.UUID) error
	Count(ctx context.Context) (int, error)
}

type cooperativeRepository struct {
	shardMgr *database.ShardManager
}

func NewCooperativeRepository(shardMgr *database.ShardManager) CooperativeRepository {
	return &cooperativeRepository{shardMgr: shardMgr}
}

func (r *cooperativeRepository) Create(ctx context.Context, cooperative *entities.Cooperative) (*entities.Cooperative, error) {
	// Generate UUID if not provided
	if cooperative.ID == uuid.Nil {
		cooperative.ID = uuid.New()
	}

	// Determine shard based on cooperative ID
	_, shardIndex, err := r.shardMgr.GetShardByID(cooperative.ID.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		INSERT INTO cooperatives (id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING created_at, updated_at
	`

	now := time.Now()
	cooperative.IsActive = true
	cooperative.CreatedAt = now
	cooperative.UpdatedAt = now

	// Convert profit sharing policy to JSON
	policyJSON, err := json.Marshal(cooperative.ProfitSharingPolicy)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal profit sharing policy: %w", err)
	}

	rows, err := r.shardMgr.ExecuteOnShard(ctx, shardIndex, query,
		cooperative.ID, cooperative.Name, cooperative.RegistrationNumber, cooperative.Address,
		cooperative.Phone, cooperative.Email, cooperative.BankAccount, policyJSON,
		cooperative.IsActive, cooperative.CreatedAt, cooperative.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create cooperative: %w", err)
	}
	defer rows.Close()

	if rows.Next() {
		err = rows.Scan(&cooperative.CreatedAt, &cooperative.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan timestamps: %w", err)
		}
	}

	return cooperative, nil
}

func (r *cooperativeRepository) GetByID(ctx context.Context, id uuid.UUID) (*entities.Cooperative, error) {
	// Determine shard based on cooperative ID
	_, shardIndex, err := r.shardMgr.GetShardByID(id.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		SELECT id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at
		FROM cooperatives
		WHERE id = $1 AND is_active = true
	`

	rows, err := r.shardMgr.ExecuteOnShard(ctx, shardIndex, query, id)
	if err != nil {
		return nil, fmt.Errorf("failed to query cooperative: %w", err)
	}
	defer rows.Close()

	if !rows.Next() {
		return nil, fmt.Errorf("cooperative not found")
	}

	cooperative := &entities.Cooperative{}
	var policyJSON []byte

	err = rows.Scan(
		&cooperative.ID, &cooperative.Name, &cooperative.RegistrationNumber, &cooperative.Address,
		&cooperative.Phone, &cooperative.Email, &cooperative.BankAccount, &policyJSON,
		&cooperative.IsActive, &cooperative.CreatedAt, &cooperative.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to scan cooperative: %w", err)
	}

	// Parse profit sharing policy JSON
	if len(policyJSON) > 0 {
		if err := json.Unmarshal(policyJSON, &cooperative.ProfitSharingPolicy); err != nil {
			return nil, fmt.Errorf("failed to unmarshal profit sharing policy: %w", err)
		}
	}

	return cooperative, nil
}

func (r *cooperativeRepository) GetByRegistrationNumber(ctx context.Context, regNumber string) (*entities.Cooperative, error) {
	// Since we don't know which shard contains the cooperative, search all shards
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at
		FROM cooperatives
		WHERE registration_number = $1 AND is_active = true
	`

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		rows, err := shard.QueryContext(ctx, query, regNumber)
		if err != nil {
			continue // Try next shard
		}

		if rows.Next() {
			cooperative := &entities.Cooperative{}
			var policyJSON []byte

			err = rows.Scan(
				&cooperative.ID, &cooperative.Name, &cooperative.RegistrationNumber, &cooperative.Address,
				&cooperative.Phone, &cooperative.Email, &cooperative.BankAccount, &policyJSON,
				&cooperative.IsActive, &cooperative.CreatedAt, &cooperative.UpdatedAt,
			)
			rows.Close()

			if err != nil {
				continue // Try next shard
			}

			// Parse profit sharing policy JSON
			if len(policyJSON) > 0 {
				if err := json.Unmarshal(policyJSON, &cooperative.ProfitSharingPolicy); err != nil {
					continue // Try next shard
				}
			}

			return cooperative, nil
		}
		rows.Close()
	}

	return nil, fmt.Errorf("cooperative not found")
}

func (r *cooperativeRepository) GetAll(ctx context.Context, limit, offset int) ([]*entities.Cooperative, error) {
	// Query all shards and combine results
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at
		FROM cooperatives
		WHERE is_active = true
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`

	var allCooperatives []*entities.Cooperative

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		rows, err := shard.QueryContext(ctx, query, limit, offset)
		if err != nil {
			continue // Try next shard
		}

		for rows.Next() {
			cooperative := &entities.Cooperative{}
			var policyJSON []byte

			err = rows.Scan(
				&cooperative.ID, &cooperative.Name, &cooperative.RegistrationNumber, &cooperative.Address,
				&cooperative.Phone, &cooperative.Email, &cooperative.BankAccount, &policyJSON,
				&cooperative.IsActive, &cooperative.CreatedAt, &cooperative.UpdatedAt,
			)
			if err != nil {
				continue
			}

			// Parse profit sharing policy JSON
			if len(policyJSON) > 0 {
				if err := json.Unmarshal(policyJSON, &cooperative.ProfitSharingPolicy); err != nil {
					continue
				}
			}

			allCooperatives = append(allCooperatives, cooperative)
		}
		rows.Close()
	}

	return allCooperatives, nil
}

func (r *cooperativeRepository) Update(ctx context.Context, id uuid.UUID, cooperative *entities.Cooperative) (*entities.Cooperative, error) {
	// Determine shard based on cooperative ID
	_, shardIndex, err := r.shardMgr.GetShardByID(id.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		UPDATE cooperatives
		SET name = $2, address = $3, phone = $4, email = $5, bank_account = $6, profit_sharing_policy = $7, updated_at = $8
		WHERE id = $1 AND is_active = true
		RETURNING id, name, registration_number, address, phone, email, bank_account, profit_sharing_policy, is_active, created_at, updated_at
	`

	cooperative.UpdatedAt = time.Now()

	// Convert profit sharing policy to JSON
	policyJSON, err := json.Marshal(cooperative.ProfitSharingPolicy)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal profit sharing policy: %w", err)
	}

	rows, err := r.shardMgr.ExecuteOnShard(ctx, shardIndex, query,
		id, cooperative.Name, cooperative.Address, cooperative.Phone, cooperative.Email,
		cooperative.BankAccount, policyJSON, cooperative.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to update cooperative: %w", err)
	}
	defer rows.Close()

	if !rows.Next() {
		return nil, fmt.Errorf("cooperative not found")
	}

	var policyJSONResult []byte
	err = rows.Scan(
		&cooperative.ID, &cooperative.Name, &cooperative.RegistrationNumber, &cooperative.Address,
		&cooperative.Phone, &cooperative.Email, &cooperative.BankAccount, &policyJSONResult,
		&cooperative.IsActive, &cooperative.CreatedAt, &cooperative.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to scan updated cooperative: %w", err)
	}

	// Parse profit sharing policy JSON
	if len(policyJSONResult) > 0 {
		if err := json.Unmarshal(policyJSONResult, &cooperative.ProfitSharingPolicy); err != nil {
			return nil, fmt.Errorf("failed to unmarshal profit sharing policy: %w", err)
		}
	}

	return cooperative, nil
}

func (r *cooperativeRepository) Delete(ctx context.Context, id uuid.UUID) error {
	// Determine shard based on cooperative ID
	_, shardIndex, err := r.shardMgr.GetShardByID(id.String())
	if err != nil {
		return fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		UPDATE cooperatives
		SET is_active = false, updated_at = $2
		WHERE id = $1 AND is_active = true
	`

	tx, err := r.shardMgr.BeginTxOnShard(ctx, shardIndex)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	result, err := tx.ExecContext(ctx, query, id, time.Now())
	if err != nil {
		return fmt.Errorf("failed to delete cooperative: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get affected rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("cooperative not found")
	}

	return tx.Commit()
}

func (r *cooperativeRepository) Count(ctx context.Context) (int, error) {
	// Count across all shards
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return 0, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `SELECT COUNT(*) FROM cooperatives WHERE is_active = true`

	totalCount := 0
	for _, shard := range shards {
		if shard == nil {
			continue
		}

		var count int
		err := shard.QueryRowContext(ctx, query).Scan(&count)
		if err == nil {
			totalCount += count
		}
	}

	return totalCount, nil
}
