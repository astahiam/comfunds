package repositories

import (
	"context"
	"fmt"

	"comfunds/internal/database"
	"comfunds/internal/entities"

	"github.com/google/uuid"
)

type ProjectRepository interface {
	Create(ctx context.Context, project *entities.Project) (*entities.Project, error)
	GetByID(ctx context.Context, id uuid.UUID) (*entities.Project, error)
	GetAll(ctx context.Context, limit, offset int) ([]*entities.Project, error)
	GetByOwnerID(ctx context.Context, ownerID uuid.UUID, limit, offset int) ([]*entities.Project, error)
	GetByApprovalStatus(ctx context.Context, status string, limit, offset int) ([]*entities.Project, error)
	Update(ctx context.Context, id uuid.UUID, project *entities.Project) (*entities.Project, error)
	Delete(ctx context.Context, id uuid.UUID) error
	Count(ctx context.Context) (int, error)
}

type projectRepository struct {
	shardMgr *database.ShardManager
}

func NewProjectRepository(shardMgr *database.ShardManager) ProjectRepository {
	return &projectRepository{shardMgr: shardMgr}
}

func (r *projectRepository) Create(ctx context.Context, project *entities.Project) (*entities.Project, error) {
	shard, _, err := r.shardMgr.GetShardByID(project.OwnerID.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		INSERT INTO projects (
			id, title, description, target_amount, raised_amount, min_investment, category,
			status, approval_status, risk_level, investment_period, expected_return,
			business_id, owner_id, cooperative_id, start_date, end_date,
			project_image_1, project_image_2, project_image_3, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
		) RETURNING id, created_at, updated_at
	`

	err = shard.QueryRowContext(ctx, query,
		project.ID, project.Title, project.Description, project.TargetAmount, project.RaisedAmount,
		project.MinInvestment, project.Category, project.Status, project.ApprovalStatus,
		project.RiskLevel, project.InvestmentPeriod, project.ExpectedReturn,
		project.BusinessID, project.OwnerID, project.CooperativeID, project.StartDate, project.EndDate,
		project.ProjectImage1, project.ProjectImage2, project.ProjectImage3,
	).Scan(&project.ID, &project.CreatedAt, &project.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create project: %w", err)
	}

	return project, nil
}

func (r *projectRepository) GetByID(ctx context.Context, id uuid.UUID) (*entities.Project, error) {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, title, description, target_amount, raised_amount, min_investment, category,
			status, approval_status, risk_level, investment_period, expected_return,
			business_id, owner_id, cooperative_id, approved_by, approved_at,
			rejected_by, rejected_at, rejection_reason, reviewer_comments,
			start_date, end_date, project_image_1, project_image_2, project_image_3,
			created_at, updated_at
		FROM projects
		WHERE id = $1
	`

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		project := &entities.Project{}
		err := shard.QueryRowContext(ctx, query, id).Scan(
			&project.ID, &project.Title, &project.Description, &project.TargetAmount, &project.RaisedAmount,
			&project.MinInvestment, &project.Category, &project.Status, &project.ApprovalStatus,
			&project.RiskLevel, &project.InvestmentPeriod, &project.ExpectedReturn,
			&project.BusinessID, &project.OwnerID, &project.CooperativeID, &project.ApprovedBy, &project.ApprovedAt,
			&project.RejectedBy, &project.RejectedAt, &project.RejectionReason, &project.ReviewerComments,
			&project.StartDate, &project.EndDate, &project.ProjectImage1, &project.ProjectImage2, &project.ProjectImage3,
			&project.CreatedAt, &project.UpdatedAt,
		)

		if err == nil {
			return project, nil
		}
	}

	return nil, fmt.Errorf("project not found")
}

func (r *projectRepository) GetAll(ctx context.Context, limit, offset int) ([]*entities.Project, error) {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, title, description, target_amount, raised_amount, min_investment, category,
			status, approval_status, risk_level, investment_period, expected_return,
			business_id, owner_id, cooperative_id, approved_by, approved_at,
			rejected_by, rejected_at, rejection_reason, reviewer_comments,
			start_date, end_date, project_image_1, project_image_2, project_image_3,
			created_at, updated_at
		FROM projects
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`

	var allProjects []*entities.Project

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		rows, err := shard.QueryContext(ctx, query, limit, offset)
		if err != nil {
			continue
		}

		for rows.Next() {
			project := &entities.Project{}
			err = rows.Scan(
				&project.ID, &project.Title, &project.Description, &project.TargetAmount, &project.RaisedAmount,
				&project.MinInvestment, &project.Category, &project.Status, &project.ApprovalStatus,
				&project.RiskLevel, &project.InvestmentPeriod, &project.ExpectedReturn,
				&project.BusinessID, &project.OwnerID, &project.CooperativeID, &project.ApprovedBy, &project.ApprovedAt,
				&project.RejectedBy, &project.RejectedAt, &project.RejectionReason, &project.ReviewerComments,
				&project.StartDate, &project.EndDate, &project.ProjectImage1, &project.ProjectImage2, &project.ProjectImage3,
				&project.CreatedAt, &project.UpdatedAt,
			)
			if err != nil {
				continue
			}

			allProjects = append(allProjects, project)
		}
		rows.Close()
	}

	return allProjects, nil
}

func (r *projectRepository) GetByOwnerID(ctx context.Context, ownerID uuid.UUID, limit, offset int) ([]*entities.Project, error) {
	// Query ALL shards since projects can be distributed across any shard
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, title, description, target_amount, raised_amount, min_investment, category,
			status, approval_status, risk_level, investment_period, expected_return,
			business_id, owner_id, cooperative_id, approved_by, approved_at,
			rejected_by, rejected_at, rejection_reason, reviewer_comments,
			start_date, end_date, project_image_1, project_image_2, project_image_3,
			created_at, updated_at
		FROM projects
		WHERE owner_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	var allProjects []*entities.Project

	// Query each shard
	for _, shard := range shards {
		if shard == nil {
			continue
		}

		rows, err := shard.QueryContext(ctx, query, ownerID, limit, offset)
		if err != nil {
			continue // Try next shard
		}

		for rows.Next() {
			project := &entities.Project{}
			err = rows.Scan(
				&project.ID, &project.Title, &project.Description, &project.TargetAmount, &project.RaisedAmount,
				&project.MinInvestment, &project.Category, &project.Status, &project.ApprovalStatus,
				&project.RiskLevel, &project.InvestmentPeriod, &project.ExpectedReturn,
				&project.BusinessID, &project.OwnerID, &project.CooperativeID, &project.ApprovedBy, &project.ApprovedAt,
				&project.RejectedBy, &project.RejectedAt, &project.RejectionReason, &project.ReviewerComments,
				&project.StartDate, &project.EndDate, &project.ProjectImage1, &project.ProjectImage2, &project.ProjectImage3,
				&project.CreatedAt, &project.UpdatedAt,
			)
			if err != nil {
				continue
			}

			allProjects = append(allProjects, project)
		}
		rows.Close()
	}

	return allProjects, nil
}

func (r *projectRepository) GetByApprovalStatus(ctx context.Context, status string, limit, offset int) ([]*entities.Project, error) {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `
		SELECT id, title, description, target_amount, raised_amount, min_investment, category,
			status, approval_status, risk_level, investment_period, expected_return,
			business_id, owner_id, cooperative_id, approved_by, approved_at,
			rejected_by, rejected_at, rejection_reason, reviewer_comments,
			start_date, end_date, project_image_1, project_image_2, project_image_3,
			created_at, updated_at
		FROM projects
		WHERE approval_status = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	var allProjects []*entities.Project

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		rows, err := shard.QueryContext(ctx, query, status, limit, offset)
		if err != nil {
			continue
		}

		for rows.Next() {
			project := &entities.Project{}
			err = rows.Scan(
				&project.ID, &project.Title, &project.Description, &project.TargetAmount, &project.RaisedAmount,
				&project.MinInvestment, &project.Category, &project.Status, &project.ApprovalStatus,
				&project.RiskLevel, &project.InvestmentPeriod, &project.ExpectedReturn,
				&project.BusinessID, &project.OwnerID, &project.CooperativeID, &project.ApprovedBy, &project.ApprovedAt,
				&project.RejectedBy, &project.RejectedAt, &project.RejectionReason, &project.ReviewerComments,
				&project.StartDate, &project.EndDate, &project.ProjectImage1, &project.ProjectImage2, &project.ProjectImage3,
				&project.CreatedAt, &project.UpdatedAt,
			)
			if err != nil {
				continue
			}

			allProjects = append(allProjects, project)
		}
		rows.Close()
	}

	return allProjects, nil
}

func (r *projectRepository) Update(ctx context.Context, id uuid.UUID, project *entities.Project) (*entities.Project, error) {
	shard, _, err := r.shardMgr.GetShardByID(project.OwnerID.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		UPDATE projects SET
			title = $2, description = $3, target_amount = $4, raised_amount = $5, min_investment = $6,
			category = $7, status = $8, approval_status = $9, risk_level = $10, investment_period = $11,
			expected_return = $12, approved_by = $13, approved_at = $14,
			rejected_by = $15, rejected_at = $16, rejection_reason = $17, reviewer_comments = $18,
			start_date = $19, end_date = $20, updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
		RETURNING updated_at
	`

	err = shard.QueryRowContext(ctx, query,
		id, project.Title, project.Description, project.TargetAmount, project.RaisedAmount,
		project.MinInvestment, project.Category, project.Status, project.ApprovalStatus,
		project.RiskLevel, project.InvestmentPeriod, project.ExpectedReturn,
		project.ApprovedBy, project.ApprovedAt, project.RejectedBy, project.RejectedAt,
		project.RejectionReason, project.ReviewerComments, project.StartDate, project.EndDate,
	).Scan(&project.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to update project: %w", err)
	}

	return project, nil
}

func (r *projectRepository) Delete(ctx context.Context, id uuid.UUID) error {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return fmt.Errorf("failed to get shards: %w", err)
	}

	query := `DELETE FROM projects WHERE id = $1`

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		result, err := shard.ExecContext(ctx, query, id)
		if err != nil {
			continue
		}

		rowsAffected, err := result.RowsAffected()
		if err == nil && rowsAffected > 0 {
			return nil
		}
	}

	return fmt.Errorf("project not found")
}

func (r *projectRepository) Count(ctx context.Context) (int, error) {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return 0, fmt.Errorf("failed to get shards: %w", err)
	}

	query := `SELECT COUNT(*) FROM projects`
	total := 0

	for _, shard := range shards {
		if shard == nil {
			continue
		}

		var count int
		err := shard.QueryRowContext(ctx, query).Scan(&count)
		if err == nil {
			total += count
		}
	}

	return total, nil
}
