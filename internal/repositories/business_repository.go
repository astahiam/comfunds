package repositories

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"comfunds/internal/database"
	"comfunds/internal/entities"

	"github.com/google/uuid"
)

type BusinessRepository interface {
	Create(ctx context.Context, business *entities.BusinessExtended) (*entities.BusinessExtended, error)
	GetByID(ctx context.Context, id uuid.UUID) (*entities.BusinessExtended, error)
	GetPendingBusinesses(ctx context.Context, cooperativeID *uuid.UUID, limit, offset int) ([]*entities.BusinessExtended, int, error)
	GetByOwner(ctx context.Context, ownerID uuid.UUID, limit, offset int) ([]*entities.BusinessExtended, int, error)
	ApproveBusiness(ctx context.Context, businessID uuid.UUID) error
	RejectBusiness(ctx context.Context, businessID uuid.UUID, reason string) error
	GetAll(ctx context.Context, limit, offset int) ([]*entities.BusinessExtended, int, error)
}

type businessRepository struct {
	shardMgr *database.ShardManager
}

func NewBusinessRepository(shardMgr *database.ShardManager) BusinessRepository {
	return &businessRepository{shardMgr: shardMgr}
}

// Helper function to scan a business row with all fields
func scanBusinessRow(rows *sql.Rows) (*entities.BusinessExtended, error) {
	fmt.Printf("DEBUG: scanBusinessRow called with updated function\n")
	var business entities.BusinessExtended
	var scannedDocumentsJSON, metadataJSON, performanceMetricsJSON, complianceStatusJSON []byte
	var approvedBy, approvedAt, rejectionReason sql.NullString

	var businessImage sql.NullString
	err := rows.Scan(
		&business.ID, &business.Name, &business.Type, &business.Description,
		&business.OwnerID, &business.CooperativeID, &business.RegistrationNumber,
		&business.TaxID, &business.LegalStructure, &business.Industry,
		&business.Sector, &business.Address, &business.Phone,
		&business.Email, &business.Website, &business.EstablishedDate,
		&business.EmployeeCount, &business.AnnualRevenue, &business.Currency,
		&business.BankAccount, &business.BusinessLicense, &businessImage,
		&scannedDocumentsJSON, &business.Status, &business.ApprovalStatus, &approvedBy, &approvedAt, &rejectionReason,
		&metadataJSON, &performanceMetricsJSON, &complianceStatusJSON,
		&business.IsActive, &business.CreatedAt, &business.UpdatedAt,
	)
	if businessImage.Valid {
		business.BusinessImage = &businessImage.String
	}
	if err != nil {
		return nil, err
	}

	// Handle JSON fields
	if len(scannedDocumentsJSON) > 0 {
		json.Unmarshal(scannedDocumentsJSON, &business.Documents)
	}
	if len(metadataJSON) > 0 {
		json.Unmarshal(metadataJSON, &business.Metadata)
	}
	if len(performanceMetricsJSON) > 0 {
		json.Unmarshal(performanceMetricsJSON, &business.PerformanceMetrics)
	}
	if len(complianceStatusJSON) > 0 {
		json.Unmarshal(complianceStatusJSON, &business.ComplianceStatus)
	}

	// Handle nullable UUID and timestamp fields
	if approvedBy.Valid {
		parsedUUID, _ := uuid.Parse(approvedBy.String)
		business.ApprovedBy = &parsedUUID
	}
	if approvedAt.Valid {
		parsedTime, _ := time.Parse(time.RFC3339, approvedAt.String)
		business.ApprovedAt = &parsedTime
	}
	business.RejectionReason = rejectionReason.String

	return &business, nil
}

// Standard SELECT query for all business fields
const businessSelectQuery = `
	SELECT id, name, business_type, description, owner_id, cooperative_id,
	       registration_number, tax_id, legal_structure, industry, sector,
	       address, phone, email, website, established_date, employee_count,
	       annual_revenue, currency, bank_account, business_license, business_image, documents,
	       status, approval_status, approved_by, approved_at, rejection_reason,
	       metadata, performance_metrics, compliance_status, is_active, created_at, updated_at
	FROM businesses`

func (r *businessRepository) Create(ctx context.Context, business *entities.BusinessExtended) (*entities.BusinessExtended, error) {
	// Generate UUID if not provided
	if business.ID == uuid.Nil {
		business.ID = uuid.New()
	}

	// Determine shard based on business ID
	_, shardIndex, err := r.shardMgr.GetShardByID(business.ID.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard: %w", err)
	}

	query := `
		INSERT INTO businesses (
			id, name, business_type, description, owner_id, cooperative_id,
			registration_number, tax_id, legal_structure, industry, sector,
			address, phone, email, website, established_date, employee_count,
			annual_revenue, currency, bank_account, business_license, business_image, documents,
			status, approval_status, metadata, performance_metrics, compliance_status,
			is_active, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17,
			$18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31
		) RETURNING created_at, updated_at
	`

	now := time.Now()
	business.IsActive = true
	business.CreatedAt = now
	business.UpdatedAt = now

	// Set defaults for nullable fields
	if business.RegistrationNumber == "" {
		business.RegistrationNumber = fmt.Sprintf("REG-%d", now.Unix())
	}
	if business.LegalStructure == "" {
		business.LegalStructure = "PT"
	}
	if business.Industry == "" {
		business.Industry = "Other"
	}
	if business.Currency == "" {
		business.Currency = "IDR"
	}
	if business.Status == "" {
		business.Status = "pending_approval"
	}
	if business.ApprovalStatus == "" {
		business.ApprovalStatus = "pending"
	}
	if business.EstablishedDate.IsZero() {
		business.EstablishedDate = now
	}

	// Convert complex fields to JSON
	documentsJSON, _ := json.Marshal(business.Documents)
	metadataJSON, _ := json.Marshal(business.Metadata)
	performanceMetricsJSON, _ := json.Marshal(business.PerformanceMetrics)
	complianceStatusJSON, _ := json.Marshal(business.ComplianceStatus)

	rows, err := r.shardMgr.ExecuteOnShard(ctx, shardIndex, query,
		business.ID, business.Name, business.Type, business.Description,
		business.OwnerID, business.CooperativeID, business.RegistrationNumber,
		business.TaxID, business.LegalStructure, business.Industry, business.Sector,
		business.Address, business.Phone, business.Email, business.Website,
		business.EstablishedDate, business.EmployeeCount, business.AnnualRevenue,
		business.Currency, business.BankAccount, business.BusinessLicense,
		business.BusinessImage, documentsJSON, business.Status, business.ApprovalStatus,
		metadataJSON, performanceMetricsJSON, complianceStatusJSON,
		business.IsActive, business.CreatedAt, business.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create business: %w", err)
	}
	defer rows.Close()

	if rows.Next() {
		err = rows.Scan(&business.CreatedAt, &business.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan timestamps: %w", err)
		}
	}

	return business, nil
}

func (r *businessRepository) GetByID(ctx context.Context, id uuid.UUID) (*entities.BusinessExtended, error) {
	fmt.Printf("DEBUG: GetByID called for business ID: %s\n", id.String())
	_, shardIndex, err := r.shardMgr.GetShardByID(id.String())
	if err != nil {
		return nil, fmt.Errorf("failed to get shard for business ID %s: %w", id.String(), err)
	}

	query := businessSelectQuery + ` WHERE id = $1 AND is_active = true`

	rows, err := r.shardMgr.ExecuteOnShard(ctx, shardIndex, query, id)
	if err != nil {
		return nil, fmt.Errorf("failed to query business: %w", err)
	}
	defer rows.Close()

	if !rows.Next() {
		return nil, fmt.Errorf("business not found")
	}

	business, err := scanBusinessRow(rows)
	if err != nil {
		return nil, fmt.Errorf("failed to scan business: %w", err)
	}

	return business, nil
}

// GetPendingBusinesses scans all shards for businesses with approval_status = 'pending'.
func (r *businessRepository) GetPendingBusinesses(ctx context.Context, cooperativeID *uuid.UUID, limit, offset int) ([]*entities.BusinessExtended, int, error) {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get shards: %w", err)
	}

	baseQuery := businessSelectQuery + ` WHERE approval_status = 'pending' AND is_active = TRUE`

	var results []*entities.BusinessExtended
	for _, shard := range shards {
		if shard == nil {
			continue
		}

		query := baseQuery
		var rowsArgs []interface{}
		if cooperativeID != nil {
			query += " AND cooperative_id = $1"
			rowsArgs = append(rowsArgs, *cooperativeID)
		}

		query += " ORDER BY created_at DESC"

		rows, err := shard.QueryContext(ctx, query, rowsArgs...)
		if err != nil {
			continue // skip shard on error
		}

		for rows.Next() {
			business, err := scanBusinessRow(rows)
			if err != nil {
				continue // Skip invalid rows
			}
			results = append(results, business)
		}
		rows.Close()
	}

	total := len(results)
	// apply offset/limit in-memory across combined shards
	start := offset
	if start < 0 {
		start = 0
	}
	end := start + limit
	if limit <= 0 {
		end = total
	}
	if start > total {
		return []*entities.BusinessExtended{}, total, nil
	}
	if end > total {
		end = total
	}
	return results[start:end], total, nil
}

// GetByOwner scans all shards for businesses belonging to an owner.
func (r *businessRepository) GetByOwner(ctx context.Context, ownerID uuid.UUID, limit, offset int) ([]*entities.BusinessExtended, int, error) {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get shards: %w", err)
	}

	query := businessSelectQuery + ` WHERE owner_id = $1 AND is_active = TRUE ORDER BY created_at DESC`

	var results []*entities.BusinessExtended
	for _, shard := range shards {
		if shard == nil {
			continue
		}
		rows, err := shard.QueryContext(ctx, query, ownerID)
		if err != nil {
			continue
		}
		for rows.Next() {
			business, err := scanBusinessRow(rows)
			if err != nil {
				continue // Skip invalid rows
			}
			results = append(results, business)
		}
		rows.Close()
	}

	total := len(results)
	start := offset
	if start < 0 {
		start = 0
	}
	end := start + limit
	if limit <= 0 {
		end = total
	}
	if start > total {
		return []*entities.BusinessExtended{}, total, nil
	}
	if end > total {
		end = total
	}
	return results[start:end], total, nil
}

// GetAll returns all active businesses across shards (any approval_status)
func (r *businessRepository) GetAll(ctx context.Context, limit, offset int) ([]*entities.BusinessExtended, int, error) {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get shards: %w", err)
	}
	query := `
        SELECT id, name, business_type, description, owner_id, cooperative_id, approval_status, is_active, created_at, updated_at
        FROM businesses
        WHERE is_active = TRUE
        ORDER BY created_at DESC`

	var results []*entities.BusinessExtended
	for _, shard := range shards {
		if shard == nil {
			continue
		}
		rows, err := shard.QueryContext(ctx, query)
		if err != nil {
			continue
		}
		for rows.Next() {
			var (
				id        uuid.UUID
				name      string
				btype     string
				desc      string
				owner     uuid.UUID
				coop      uuid.UUID
				approval  string
				isActive  bool
				createdAt time.Time
				updatedAt time.Time
			)
			if err := rows.Scan(&id, &name, &btype, &desc, &owner, &coop, &approval, &isActive, &createdAt, &updatedAt); err != nil {
				continue
			}
			results = append(results, &entities.BusinessExtended{
				ID:             id,
				Name:           name,
				Type:           btype,
				Description:    desc,
				OwnerID:        owner,
				CooperativeID:  coop,
				ApprovalStatus: approval,
				IsActive:       isActive,
				CreatedAt:      createdAt,
				UpdatedAt:      updatedAt,
			})
		}
		rows.Close()
	}

	total := len(results)
	start := offset
	if start < 0 {
		start = 0
	}
	end := start + limit
	if limit <= 0 {
		end = total
	}
	if start > total {
		return []*entities.BusinessExtended{}, total, nil
	}
	if end > total {
		end = total
	}
	return results[start:end], total, nil
}

// ApproveBusiness sets approval_status to 'approved' and updates updated_at.
func (r *businessRepository) ApproveBusiness(ctx context.Context, businessID uuid.UUID) error {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return fmt.Errorf("failed to get shards: %w", err)
	}
	query := `UPDATE businesses SET approval_status='approved', updated_at=$2 WHERE id=$1`
	now := time.Now()
	for _, shard := range shards {
		if shard == nil {
			continue
		}
		res, err := shard.ExecContext(ctx, query, businessID, now)
		if err != nil {
			continue
		}
		if rows, _ := res.RowsAffected(); rows > 0 {
			return nil
		}
	}
	return fmt.Errorf("business not found")
}

// RejectBusiness sets approval_status to 'rejected' and updates updated_at.
func (r *businessRepository) RejectBusiness(ctx context.Context, businessID uuid.UUID, reason string) error {
	shards, err := r.shardMgr.GetAllShards()
	if err != nil {
		return fmt.Errorf("failed to get shards: %w", err)
	}
	query := `UPDATE businesses SET approval_status='rejected', updated_at=$2 WHERE id=$1`
	now := time.Now()
	for _, shard := range shards {
		if shard == nil {
			continue
		}
		res, err := shard.ExecContext(ctx, query, businessID, now)
		if err != nil {
			continue
		}
		if rows, _ := res.RowsAffected(); rows > 0 {
			return nil
		}
	}
	return fmt.Errorf("business not found")
}
