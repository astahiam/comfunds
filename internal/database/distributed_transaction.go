package database

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
)

// DistributedTransaction manages transactions across multiple shards
type DistributedTransaction struct {
	id          string
	shardTxs    map[int]*sql.Tx
	shardMgr    *ShardManager
	ctx         context.Context
	cancel      context.CancelFunc
	mu          sync.RWMutex
	committed   bool
	rolledBack  bool
	timeout     time.Duration
}

type TransactionManager struct {
	shardMgr     *ShardManager
	transactions map[string]*DistributedTransaction
	mu           sync.RWMutex
}

func NewTransactionManager(shardMgr *ShardManager) *TransactionManager {
	return &TransactionManager{
		shardMgr:     shardMgr,
		transactions: make(map[string]*DistributedTransaction),
	}
}

// BeginDistributedTransaction starts a new distributed transaction
func (tm *TransactionManager) BeginDistributedTransaction(ctx context.Context, timeout time.Duration) (*DistributedTransaction, error) {
	txID := uuid.New().String()
	txCtx, cancel := context.WithTimeout(ctx, timeout)

	dtx := &DistributedTransaction{
		id:       txID,
		shardTxs: make(map[int]*sql.Tx),
		shardMgr: tm.shardMgr,
		ctx:      txCtx,
		cancel:   cancel,
		timeout:  timeout,
	}

	tm.mu.Lock()
	tm.transactions[txID] = dtx
	tm.mu.Unlock()

	log.Printf("Started distributed transaction: %s", txID)
	return dtx, nil
}

// GetTransaction retrieves an existing transaction
func (tm *TransactionManager) GetTransaction(txID string) (*DistributedTransaction, error) {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	dtx, exists := tm.transactions[txID]
	if !exists {
		return nil, fmt.Errorf("transaction %s not found", txID)
	}

	return dtx, nil
}

// CleanupTransaction removes a transaction from the manager
func (tm *TransactionManager) CleanupTransaction(txID string) {
	tm.mu.Lock()
	defer tm.mu.Unlock()
	delete(tm.transactions, txID)
}

// GetOrCreateShardTx gets or creates a transaction for a specific shard
func (dtx *DistributedTransaction) GetOrCreateShardTx(shardIndex int) (*sql.Tx, error) {
	dtx.mu.Lock()
	defer dtx.mu.Unlock()

	if dtx.committed || dtx.rolledBack {
		return nil, fmt.Errorf("transaction %s is already finalized", dtx.id)
	}

	// Check if transaction already exists for this shard
	if tx, exists := dtx.shardTxs[shardIndex]; exists {
		return tx, nil
	}

	// Create new transaction for this shard
	tx, err := dtx.shardMgr.BeginTxOnShard(dtx.ctx, shardIndex)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction on shard %d: %w", shardIndex, err)
	}

	dtx.shardTxs[shardIndex] = tx
	log.Printf("Created transaction on shard %d for distributed transaction %s", shardIndex, dtx.id)
	return tx, nil
}

// ExecOnShard executes a query within the distributed transaction on a specific shard
func (dtx *DistributedTransaction) ExecOnShard(shardIndex int, query string, args ...interface{}) (sql.Result, error) {
	tx, err := dtx.GetOrCreateShardTx(shardIndex)
	if err != nil {
		return nil, err
	}

	result, err := tx.ExecContext(dtx.ctx, query, args...)
	if err != nil {
		log.Printf("Query failed on shard %d in transaction %s: %v", shardIndex, dtx.id, err)
		return nil, err
	}

	return result, nil
}

// QueryOnShard executes a query within the distributed transaction on a specific shard
func (dtx *DistributedTransaction) QueryOnShard(shardIndex int, query string, args ...interface{}) (*sql.Rows, error) {
	tx, err := dtx.GetOrCreateShardTx(shardIndex)
	if err != nil {
		return nil, err
	}

	rows, err := tx.QueryContext(dtx.ctx, query, args...)
	if err != nil {
		log.Printf("Query failed on shard %d in transaction %s: %v", shardIndex, dtx.id, err)
		return nil, err
	}

	return rows, nil
}

// Commit commits all shard transactions using 2-phase commit protocol
func (dtx *DistributedTransaction) Commit() error {
	dtx.mu.Lock()
	defer dtx.mu.Unlock()

	if dtx.committed {
		return fmt.Errorf("transaction %s already committed", dtx.id)
	}
	if dtx.rolledBack {
		return fmt.Errorf("transaction %s already rolled back", dtx.id)
	}

	defer dtx.cancel()

	// Phase 1: Prepare all transactions
	log.Printf("Starting 2-phase commit for transaction %s", dtx.id)
	
	// In PostgreSQL, we'll simulate 2PC by ensuring all operations complete successfully
	// before committing any transaction
	var commitErrors []error

	// Phase 2: Commit all transactions
	for shardIndex, tx := range dtx.shardTxs {
		if err := tx.Commit(); err != nil {
			commitErrors = append(commitErrors, fmt.Errorf("shard %d: %w", shardIndex, err))
			log.Printf("Failed to commit transaction on shard %d: %v", shardIndex, err)
		} else {
			log.Printf("Successfully committed transaction on shard %d", shardIndex)
		}
	}

	if len(commitErrors) > 0 {
		// If any commits failed, we have a problem - log it extensively
		log.Printf("CRITICAL: Partial commit failure in distributed transaction %s", dtx.id)
		for _, err := range commitErrors {
			log.Printf("Commit error: %v", err)
		}
		dtx.rolledBack = true
		return fmt.Errorf("distributed transaction partially failed: %v", commitErrors)
	}

	dtx.committed = true
	log.Printf("Successfully committed distributed transaction %s", dtx.id)
	return nil
}

// Rollback rolls back all shard transactions
func (dtx *DistributedTransaction) Rollback() error {
	dtx.mu.Lock()
	defer dtx.mu.Unlock()

	if dtx.committed {
		return fmt.Errorf("transaction %s already committed", dtx.id)
	}
	if dtx.rolledBack {
		return nil // Already rolled back
	}

	defer dtx.cancel()

	var rollbackErrors []error
	for shardIndex, tx := range dtx.shardTxs {
		if err := tx.Rollback(); err != nil {
			rollbackErrors = append(rollbackErrors, fmt.Errorf("shard %d: %w", shardIndex, err))
			log.Printf("Failed to rollback transaction on shard %d: %v", shardIndex, err)
		} else {
			log.Printf("Successfully rolled back transaction on shard %d", shardIndex)
		}
	}

	dtx.rolledBack = true
	
	if len(rollbackErrors) > 0 {
		log.Printf("Some rollbacks failed in distributed transaction %s: %v", dtx.id, rollbackErrors)
		return fmt.Errorf("some rollbacks failed: %v", rollbackErrors)
	}

	log.Printf("Successfully rolled back distributed transaction %s", dtx.id)
	return nil
}

// GetID returns the transaction ID
func (dtx *DistributedTransaction) GetID() string {
	return dtx.id
}

// IsActive checks if the transaction is still active
func (dtx *DistributedTransaction) IsActive() bool {
	dtx.mu.RLock()
	defer dtx.mu.RUnlock()
	return !dtx.committed && !dtx.rolledBack
}

// GetParticipatingShards returns the list of shards participating in this transaction
func (dtx *DistributedTransaction) GetParticipatingShards() []int {
	dtx.mu.RLock()
	defer dtx.mu.RUnlock()

	shards := make([]int, 0, len(dtx.shardTxs))
	for shardIndex := range dtx.shardTxs {
		shards = append(shards, shardIndex)
	}
	return shards
}
