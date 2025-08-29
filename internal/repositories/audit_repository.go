package repositories

import (
	"context"
	"fmt"
	"strings"

	"comfunds/internal/database"
	"comfunds/internal/entities"
)

type AuditRepository interface {
	Create(ctx context.Context, auditLog *entities.AuditLog) error
	GetByFilter(ctx context.Context, filter *entities.AuditLogFilter) ([]*entities.AuditLog, int, error)
	GetByID(ctx context.Context, id string) (*entities.AuditLog, error)
	DeleteOlderThan(ctx context.Context, days int) (int, error)
}

type auditRepository struct {
	shardMgr *database.ShardManager
}

func NewAuditRepository(shardMgr *database.ShardManager) AuditRepository {
	return &auditRepository{shardMgr: shardMgr}
}

func (r *auditRepository) Create(ctx context.Context, auditLog *entities.AuditLog) error {
	// Determine shard based on entity ID
	_, shardIndex, err := r.shardMgr.GetShardByID(auditLog.EntityID.String())
	if err != nil {
		return fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		INSERT INTO audit_logs (id, entity_type, entity_id, operation, user_id, ip_address, user_agent, 
		                       changes, old_values, new_values, reason, status, error_msg, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
	`

	_, err = r.shardMgr.ExecuteOnShard(ctx, shardIndex, query,
		auditLog.ID, auditLog.EntityType, auditLog.EntityID, auditLog.Operation,
		auditLog.UserID, auditLog.IPAddress, auditLog.UserAgent,
		auditLog.Changes, auditLog.OldValues, auditLog.NewValues,
		auditLog.Reason, auditLog.Status, auditLog.ErrorMsg, auditLog.CreatedAt)

	if err != nil {
		return fmt.Errorf("failed to create audit log: %w", err)
	}

	return nil
}

func (r *auditRepository) GetByFilter(ctx context.Context, filter *entities.AuditLogFilter) ([]*entities.AuditLog, int, error) {
	// Build query with filters
	whereConditions := []string{}
	args := []interface{}{}
	argCount := 0

	if filter.EntityType != "" {
		argCount++
		whereConditions = append(whereConditions, fmt.Sprintf("entity_type = $%d", argCount))
		args = append(args, filter.EntityType)
	}

	if filter.EntityID != nil {
		argCount++
		whereConditions = append(whereConditions, fmt.Sprintf("entity_id = $%d", argCount))
		args = append(args, *filter.EntityID)
	}

	if filter.UserID != nil {
		argCount++
		whereConditions = append(whereConditions, fmt.Sprintf("user_id = $%d", argCount))
		args = append(args, *filter.UserID)
	}

	if filter.Operation != "" {
		argCount++
		whereConditions = append(whereConditions, fmt.Sprintf("operation = $%d", argCount))
		args = append(args, filter.Operation)
	}

	if filter.Status != "" {
		argCount++
		whereConditions = append(whereConditions, fmt.Sprintf("status = $%d", argCount))
		args = append(args, filter.Status)
	}

	if filter.StartDate != nil {
		argCount++
		whereConditions = append(whereConditions, fmt.Sprintf("created_at >= $%d", argCount))
		args = append(args, *filter.StartDate)
	}

	if filter.EndDate != nil {
		argCount++
		whereConditions = append(whereConditions, fmt.Sprintf("created_at <= $%d", argCount))
		args = append(args, *filter.EndDate)
	}

	whereClause := ""
	if len(whereConditions) > 0 {
		whereClause = "WHERE " + strings.Join(whereConditions, " AND ")
	}

	// Calculate offset
	offset := (filter.Page - 1) * filter.Limit

	// Query for audit logs
	query := fmt.Sprintf(`
		SELECT id, entity_type, entity_id, operation, user_id, ip_address, user_agent,
		       changes, old_values, new_values, reason, status, error_msg, created_at
		FROM audit_logs
		%s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, argCount+1, argCount+2)

	args = append(args, filter.Limit, offset)

	// Count query
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM audit_logs
		%s
	`, whereClause)

	// Query all shards and combine results
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get shards: %w", err)
	}

	var allAuditLogs []*entities.AuditLog
	totalCount := 0

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		// Get audit logs from this shard
		rows, err := shard.QueryContext(ctx, query, args...)
		if err != nil {
			continue // Try next shard
		}

		for rows.Next() {
			auditLog := &entities.AuditLog{}
			err = rows.Scan(
				&auditLog.ID, &auditLog.EntityType, &auditLog.EntityID, &auditLog.Operation,
				&auditLog.UserID, &auditLog.IPAddress, &auditLog.UserAgent,
				&auditLog.Changes, &auditLog.OldValues, &auditLog.NewValues,
				&auditLog.Reason, &auditLog.Status, &auditLog.ErrorMsg, &auditLog.CreatedAt,
			)
			if err != nil {
				continue
			}
			allAuditLogs = append(allAuditLogs, auditLog)
		}
		rows.Close()

		// Get count from this shard
		var shardCount int
		err = shard.QueryRowContext(ctx, countQuery, args[:argCount]...).Scan(&shardCount)
		if err == nil {
			totalCount += shardCount
		}
	}

	return allAuditLogs, totalCount, nil
}

func (r *auditRepository) GetByID(ctx context.Context, id string) (*entities.AuditLog, error) {
	// Query all shards to find the audit log
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, entity_type, entity_id, operation, user_id, ip_address, user_agent,
		       changes, old_values, new_values, reason, status, error_msg, created_at
		FROM audit_logs
		WHERE id = $1
	`

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		auditLog := &entities.AuditLog{}
		err = shard.QueryRowContext(ctx, query, id).Scan(
			&auditLog.ID, &auditLog.EntityType, &auditLog.EntityID, &auditLog.Operation,
			&auditLog.UserID, &auditLog.IPAddress, &auditLog.UserAgent,
			&auditLog.Changes, &auditLog.OldValues, &auditLog.NewValues,
			&auditLog.Reason, &auditLog.Status, &auditLog.ErrorMsg, &auditLog.CreatedAt,
		)

		if err == nil {
			return auditLog, nil
		}
	}

	return nil, fmt.Errorf("audit log not found")
}

func (r *auditRepository) DeleteOlderThan(ctx context.Context, days int) (int, error) {
	// Delete audit logs older than specified days from all shards
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return 0, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		DELETE FROM audit_logs
		WHERE created_at < NOW() - INTERVAL '%d days'
	`

	totalDeleted := 0
	for _, shard := range shards {
		if shard == nil {
			continue
		}

		result, err := shard.ExecContext(ctx, fmt.Sprintf(query, days))
		if err == nil {
			if rowsAffected, err := result.RowsAffected(); err == nil {
				totalDeleted += int(rowsAffected)
			}
		}
	}

	return totalDeleted, nil
}
