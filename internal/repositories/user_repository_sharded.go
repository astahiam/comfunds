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

type UserRepositorySharded interface {
	Create(ctx context.Context, user *entities.User) (*entities.User, error)
	GetByID(ctx context.Context, id uuid.UUID) (*entities.User, error)
	GetByEmail(ctx context.Context, email string) (*entities.User, error)
	GetAll(ctx context.Context, limit, offset int) ([]*entities.User, error)
	Update(ctx context.Context, id uuid.UUID, user *entities.User) (*entities.User, error)
	Delete(ctx context.Context, id uuid.UUID) error
	Count(ctx context.Context) (int, error)
	GetByCooperativeID(ctx context.Context, cooperativeID uuid.UUID, limit, offset int) ([]*entities.User, error)
}

type userRepositorySharded struct {
	shardMgr *database.ShardManager
}

func NewUserRepositorySharded(shardMgr *database.ShardManager) UserRepositorySharded {
	return &userRepositorySharded{shardMgr: shardMgr}
}

func (r *userRepositorySharded) Create(ctx context.Context, user *entities.User) (*entities.User, error) {
	// Generate UUID if not provided
	if user.ID == uuid.Nil {
		user.ID = uuid.New()
	}

	// Determine shard based on user ID
	_, shardIndex, err := r.shardMgr.GetShardByID(user.ID.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		INSERT INTO users (id, email, name, password, phone, address, cooperative_id, roles, kyc_status, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING created_at, updated_at
	`

	now := time.Now()
	user.IsActive = true
	user.KYCStatus = "pending"
	user.CreatedAt = now
	user.UpdatedAt = now

	// Convert roles to PostgreSQL array
	rolesJSON, err := json.Marshal(user.Roles)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal roles: %w", err)
	}

	// Execute on the determined shard
	rows, err := r.shardMgr.ExecuteOnShard(ctx, shardIndex, query, 
		user.ID, user.Email, user.Name, user.Password, user.Phone, user.Address,
		user.CooperativeID, rolesJSON, user.KYCStatus, user.IsActive, user.CreatedAt, user.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}
	defer rows.Close()

	if rows.Next() {
		err = rows.Scan(&user.CreatedAt, &user.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan timestamps: %w", err)
		}
	}

	return user, nil
}

func (r *userRepositorySharded) GetByID(ctx context.Context, id uuid.UUID) (*entities.User, error) {
	// Determine shard based on user ID
	_, shardIndex, err := r.shardMgr.GetShardByID(id.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		SELECT id, email, name, password, phone, address, cooperative_id, roles, kyc_status, is_active, created_at, updated_at
		FROM users
		WHERE id = $1 AND is_active = true
	`

	rows, err := r.shardMgr.ExecuteOnShard(ctx, shardIndex, query, id)
	if err != nil {
		return nil, fmt.Errorf("failed to query user: %w", err)
	}
	defer rows.Close()

	if !rows.Next() {
		return nil, fmt.Errorf("user not found")
	}

	user := &entities.User{}
	var rolesJSON []byte

	err = rows.Scan(
		&user.ID, &user.Email, &user.Name, &user.Password, &user.Phone, &user.Address,
		&user.CooperativeID, &rolesJSON, &user.KYCStatus, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to scan user: %w", err)
	}

	// Parse roles JSON
	if err := json.Unmarshal(rolesJSON, &user.Roles); err != nil {
		return nil, fmt.Errorf("failed to unmarshal roles: %w", err)
	}

	return user, nil
}

func (r *userRepositorySharded) GetByEmail(ctx context.Context, email string) (*entities.User, error) {
	// Since we don't know which shard contains the user, we need to search all shards
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, email, name, password, phone, address, cooperative_id, roles, kyc_status, is_active, created_at, updated_at
		FROM users
		WHERE email = $1 AND is_active = true
	`

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		rows, err := shard.QueryContext(ctx, query, email)
		if err != nil {
			continue // Try next shard
		}

		if rows.Next() {
			user := &entities.User{}
			var rolesJSON []byte

			err = rows.Scan(
				&user.ID, &user.Email, &user.Name, &user.Password, &user.Phone, &user.Address,
				&user.CooperativeID, &rolesJSON, &user.KYCStatus, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
			)
			rows.Close()

			if err != nil {
				continue // Try next shard
			}

			// Parse roles JSON
			if err := json.Unmarshal(rolesJSON, &user.Roles); err != nil {
				continue // Try next shard
			}

			return user, nil
		}
		rows.Close()
	}

	return nil, fmt.Errorf("user not found")
}

func (r *userRepositorySharded) GetAll(ctx context.Context, limit, offset int) ([]*entities.User, error) {
	// Query all shards and combine results
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, email, name, password, phone, address, cooperative_id, roles, kyc_status, is_active, created_at, updated_at
		FROM users
		WHERE is_active = true
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`

	var allUsers []*entities.User

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		rows, err := shard.QueryContext(ctx, query, limit, offset)
		if err != nil {
			continue // Try next shard
		}

		for rows.Next() {
			user := &entities.User{}
			var rolesJSON []byte

			err = rows.Scan(
				&user.ID, &user.Email, &user.Name, &user.Password, &user.Phone, &user.Address,
				&user.CooperativeID, &rolesJSON, &user.KYCStatus, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
			)
			if err != nil {
				continue
			}

			// Parse roles JSON
			if err := json.Unmarshal(rolesJSON, &user.Roles); err != nil {
				continue
			}

			allUsers = append(allUsers, user)
		}
		rows.Close()
	}

	return allUsers, nil
}

func (r *userRepositorySharded) Update(ctx context.Context, id uuid.UUID, user *entities.User) (*entities.User, error) {
	// Determine shard based on user ID
	_, shardIndex, err := r.shardMgr.GetShardByID(id.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		UPDATE users
		SET name = $2, phone = $3, address = $4, roles = $5, updated_at = $6
		WHERE id = $1 AND is_active = true
		RETURNING id, email, name, phone, address, cooperative_id, roles, kyc_status, is_active, created_at, updated_at
	`

	user.UpdatedAt = time.Now()

	// Convert roles to PostgreSQL array
	rolesJSON, err := json.Marshal(user.Roles)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal roles: %w", err)
	}

	rows, err := r.shardMgr.ExecuteOnShard(ctx, shardIndex, query,
		id, user.Name, user.Phone, user.Address, rolesJSON, user.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}
	defer rows.Close()

	if !rows.Next() {
		return nil, fmt.Errorf("user not found")
	}

	var rolesJSONResult []byte
	err = rows.Scan(
		&user.ID, &user.Email, &user.Name, &user.Phone, &user.Address,
		&user.CooperativeID, &rolesJSONResult, &user.KYCStatus, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to scan updated user: %w", err)
	}

	// Parse roles JSON
	if err := json.Unmarshal(rolesJSONResult, &user.Roles); err != nil {
		return nil, fmt.Errorf("failed to unmarshal roles: %w", err)
	}

	return user, nil
}

func (r *userRepositorySharded) Delete(ctx context.Context, id uuid.UUID) error {
	// Determine shard based on user ID
	_, shardIndex, err := r.shardMgr.GetShardByID(id.String())
	if err != nil {
		return fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		UPDATE users
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
		return fmt.Errorf("failed to delete user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get affected rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	return tx.Commit()
}

func (r *userRepositorySharded) Count(ctx context.Context) (int, error) {
	// Count across all shards
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return 0, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `SELECT COUNT(*) FROM users WHERE is_active = true`

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

func (r *userRepositorySharded) GetByCooperativeID(ctx context.Context, cooperativeID uuid.UUID, limit, offset int) ([]*entities.User, error) {
	// Query all shards for users with the specified cooperative ID
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, email, name, password, phone, address, cooperative_id, roles, kyc_status, is_active, created_at, updated_at
		FROM users
		WHERE cooperative_id = $1 AND is_active = true
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	var allUsers []*entities.User

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		rows, err := shard.QueryContext(ctx, query, cooperativeID, limit, offset)
		if err != nil {
			continue // Try next shard
		}

		for rows.Next() {
			user := &entities.User{}
			var rolesJSON []byte

			err = rows.Scan(
				&user.ID, &user.Email, &user.Name, &user.Password, &user.Phone, &user.Address,
				&user.CooperativeID, &rolesJSON, &user.KYCStatus, &user.IsActive, &user.CreatedAt, &user.UpdatedAt,
			)
			if err != nil {
				continue
			}

			// Parse roles JSON
			if err := json.Unmarshal(rolesJSON, &user.Roles); err != nil {
				continue
			}

			allUsers = append(allUsers, user)
		}
		rows.Close()
	}

	return allUsers, nil
}
