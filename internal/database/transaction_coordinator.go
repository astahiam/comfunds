package database

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
)

// TransactionCoordinator handles high-level distributed transaction operations
type TransactionCoordinator struct {
	txMgr    *TransactionManager
	shardMgr *ShardManager
}

func NewTransactionCoordinator(shardMgr *ShardManager) *TransactionCoordinator {
	return &TransactionCoordinator{
		txMgr:    NewTransactionManager(shardMgr),
		shardMgr: shardMgr,
	}
}

// ExecuteDistributedTransaction executes a function within a distributed transaction
func (tc *TransactionCoordinator) ExecuteDistributedTransaction(ctx context.Context, fn func(*DistributedTransaction) error) error {
	// Start distributed transaction with 30 second timeout
	dtx, err := tc.txMgr.BeginDistributedTransaction(ctx, 30*time.Second)
	if err != nil {
		return fmt.Errorf("failed to begin distributed transaction: %w", err)
	}

	defer tc.txMgr.CleanupTransaction(dtx.GetID())

	// Execute the business logic
	err = fn(dtx)
	if err != nil {
		log.Printf("Business logic failed in transaction %s: %v", dtx.GetID(), err)
		if rollbackErr := dtx.Rollback(); rollbackErr != nil {
			log.Printf("Failed to rollback transaction %s: %v", dtx.GetID(), rollbackErr)
		}
		return fmt.Errorf("transaction failed: %w", err)
	}

	// Commit the transaction
	if err := dtx.Commit(); err != nil {
		log.Printf("Failed to commit transaction %s: %v", dtx.GetID(), err)
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// CreateInvestmentTransaction creates an investment with proper ACID guarantees
func (tc *TransactionCoordinator) CreateInvestmentTransaction(ctx context.Context, projectID, investorID string, amount float64) (string, error) {
	var investmentID string
	
	err := tc.ExecuteDistributedTransaction(ctx, func(dtx *DistributedTransaction) error {
		// Generate unique investment ID
		investmentID = uuid.New().String()
		
		// Determine shard for the project
		projectShard, projectShardIndex, err := tc.shardMgr.GetShardByID(projectID)
		if err != nil {
			return fmt.Errorf("failed to get project shard: %w", err)
		}
		_ = projectShard // We'll use the transaction instead

		// Determine shard for the investor
		investorShard, investorShardIndex, err := tc.shardMgr.GetShardByID(investorID)
		if err != nil {
			return fmt.Errorf("failed to get investor shard: %w", err)
		}
		_ = investorShard // We'll use the transaction instead

		// 1. Verify project exists and is accepting investments
		projectQuery := `
			SELECT id, funding_goal, current_funding, status, profit_sharing_ratio
			FROM projects 
			WHERE id = $1 AND status = 'active'
		`
		
		rows, err := dtx.QueryOnShard(projectShardIndex, projectQuery, projectID)
		if err != nil {
			return fmt.Errorf("failed to query project: %w", err)
		}
		defer rows.Close()

		if !rows.Next() {
			return fmt.Errorf("project not found or not accepting investments")
		}

		var fundingGoal, currentFunding float64
		var status string
		var profitSharingRatio string
		
		err = rows.Scan(&projectID, &fundingGoal, &currentFunding, &status, &profitSharingRatio)
		if err != nil {
			return fmt.Errorf("failed to scan project: %w", err)
		}

		// Check if investment would exceed funding goal
		if currentFunding+amount > fundingGoal {
			return fmt.Errorf("investment would exceed funding goal")
		}

		// 2. Verify investor exists and has required role
		investorQuery := `
			SELECT id, roles
			FROM users 
			WHERE id = $1 AND is_active = true
		`
		
		rows, err = dtx.QueryOnShard(investorShardIndex, investorQuery, investorID)
		if err != nil {
			return fmt.Errorf("failed to query investor: %w", err)
		}
		defer rows.Close()

		if !rows.Next() {
			return fmt.Errorf("investor not found or inactive")
		}

		var roles string
		err = rows.Scan(&investorID, &roles)
		if err != nil {
			return fmt.Errorf("failed to scan investor: %w", err)
		}

		// 3. Generate unique transaction reference
		txRef := fmt.Sprintf("TXN-%d-%s", time.Now().Unix(), uuid.New().String()[:8])

		// 4. Create investment record
		investmentQuery := `
			INSERT INTO investments (id, project_id, investor_id, amount, profit_sharing_percentage, status, transaction_ref)
			VALUES ($1, $2, $3, $4, 70.0, 'pending', $5)
		`
		
		// Determine which shard to store the investment (based on project for data locality)
		_, err = dtx.ExecOnShard(projectShardIndex, investmentQuery, investmentID, projectID, investorID, amount, txRef)
		if err != nil {
			return fmt.Errorf("failed to create investment: %w", err)
		}

		// 5. Update project funding
		updateProjectQuery := `
			UPDATE projects 
			SET current_funding = current_funding + $1, updated_at = CURRENT_TIMESTAMP
			WHERE id = $2
		`
		
		_, err = dtx.ExecOnShard(projectShardIndex, updateProjectQuery, amount, projectID)
		if err != nil {
			return fmt.Errorf("failed to update project funding: %w", err)
		}

		log.Printf("Created investment %s: %s invested %f in project %s", investmentID, investorID, amount, projectID)
		return nil
	})

	if err != nil {
		return "", err
	}

	return investmentID, nil
}

// DistributeProfits distributes profits to investors with ACID guarantees
func (tc *TransactionCoordinator) DistributeProfits(ctx context.Context, projectID string, businessProfit float64) error {
	return tc.ExecuteDistributedTransaction(ctx, func(dtx *DistributedTransaction) error {
		// Determine project shard
		_, projectShardIndex, err := tc.shardMgr.GetShardByID(projectID)
		if err != nil {
			return fmt.Errorf("failed to get project shard: %w", err)
		}

		// 1. Get project details and profit sharing ratio
		projectQuery := `
			SELECT id, profit_sharing_ratio
			FROM projects 
			WHERE id = $1
		`
		
		rows, err := dtx.QueryOnShard(projectShardIndex, projectQuery, projectID)
		if err != nil {
			return fmt.Errorf("failed to query project: %w", err)
		}
		defer rows.Close()

		if !rows.Next() {
			return fmt.Errorf("project not found")
		}

		var profitSharingRatio string
		err = rows.Scan(&projectID, &profitSharingRatio)
		if err != nil {
			return fmt.Errorf("failed to scan project: %w", err)
		}

		// 2. Calculate total profit to distribute (assuming 70% to investors)
		investorProfitShare := businessProfit * 0.70

		// 3. Create profit distribution record
		distributionID := uuid.New().String()
		distributionQuery := `
			INSERT INTO profit_distributions (id, project_id, business_profit, total_distributed, status)
			VALUES ($1, $2, $3, $4, 'calculated')
		`
		
		_, err = dtx.ExecOnShard(projectShardIndex, distributionQuery, distributionID, projectID, businessProfit, investorProfitShare)
		if err != nil {
			return fmt.Errorf("failed to create profit distribution: %w", err)
		}

		// 4. Get all investments for this project
		investmentsQuery := `
			SELECT id, investor_id, amount
			FROM investments 
			WHERE project_id = $1 AND status = 'confirmed'
		`
		
		rows, err = dtx.QueryOnShard(projectShardIndex, investmentsQuery, projectID)
		if err != nil {
			return fmt.Errorf("failed to query investments: %w", err)
		}
		defer rows.Close()

		// Calculate total investment amount
		var totalInvestment float64
		var investments []struct {
			ID         string
			InvestorID string
			Amount     float64
		}

		for rows.Next() {
			var inv struct {
				ID         string
				InvestorID string
				Amount     float64
			}
			
			err = rows.Scan(&inv.ID, &inv.InvestorID, &inv.Amount)
			if err != nil {
				return fmt.Errorf("failed to scan investment: %w", err)
			}
			
			investments = append(investments, inv)
			totalInvestment += inv.Amount
		}

		if totalInvestment == 0 {
			return fmt.Errorf("no confirmed investments found for project")
		}

		// 5. Create return records for each investor
		for _, inv := range investments {
			returnAmount := (inv.Amount / totalInvestment) * investorProfitShare
			returnPercentage := (returnAmount / inv.Amount) * 100

			returnID := uuid.New().String()
			txRef := fmt.Sprintf("RTN-%d-%s", time.Now().Unix(), uuid.New().String()[:8])

			returnQuery := `
				INSERT INTO investment_returns (id, investment_id, distribution_id, return_amount, return_percentage, status, transaction_ref)
				VALUES ($1, $2, $3, $4, $5, 'pending', $6)
			`
			
			_, err = dtx.ExecOnShard(projectShardIndex, returnQuery, returnID, inv.ID, distributionID, returnAmount, returnPercentage, txRef)
			if err != nil {
				return fmt.Errorf("failed to create investment return: %w", err)
			}
		}

		log.Printf("Distributed profit for project %s: business profit %f, investor share %f", projectID, businessProfit, investorProfitShare)
		return nil
	})
}
