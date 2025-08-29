package database

import (
	"context"
	"database/sql"
	"fmt"
	"hash/crc32"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
)

const (
	ShardCount = 4
	MaxRetries = 3
)

type ShardManager struct {
	shards     []*sql.DB
	shardNames []string
	mu         sync.RWMutex
}

type ShardConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	SSLMode  string
}

func NewShardManager(config ShardConfig) (*ShardManager, error) {
	sm := &ShardManager{
		shards:     make([]*sql.DB, ShardCount),
		shardNames: make([]string, ShardCount),
	}

	// Initialize connections to all shards
	for i := 0; i < ShardCount; i++ {
		dbName := fmt.Sprintf("comfunds%02d", i)
		sm.shardNames[i] = dbName

		dsn := fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s",
			config.Username, config.Password, config.Host, config.Port, dbName, config.SSLMode)

		db, err := sql.Open("postgres", dsn)
		if err != nil {
			return nil, fmt.Errorf("failed to connect to shard %s: %w", dbName, err)
		}

		// Configure connection pool
		db.SetMaxOpenConns(25)
		db.SetMaxIdleConns(10)
		db.SetConnMaxLifetime(5 * time.Minute)

		// Test connection
		if err := db.Ping(); err != nil {
			return nil, fmt.Errorf("failed to ping shard %s: %w", dbName, err)
		}

		sm.shards[i] = db
		log.Printf("Connected to shard: %s", dbName)
	}

	return sm, nil
}

// GetShardByID determines which shard to use based on ID
func (sm *ShardManager) GetShardByID(id string) (*sql.DB, int, error) {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	// Parse UUID to get consistent sharding
	parsedID, err := uuid.Parse(id)
	if err != nil {
		return nil, 0, fmt.Errorf("invalid UUID: %w", err)
	}

	// Use CRC32 hash of UUID bytes for consistent sharding
	hash := crc32.ChecksumIEEE(parsedID[:])
	shardIndex := int(hash % ShardCount)

	if sm.shards[shardIndex] == nil {
		return nil, 0, fmt.Errorf("shard %d is not available", shardIndex)
	}

	return sm.shards[shardIndex], shardIndex, nil
}

// GetShardByCooperativeID determines shard based on cooperative ID for data locality
func (sm *ShardManager) GetShardByCooperativeID(cooperativeID string) (*sql.DB, int, error) {
	return sm.GetShardByID(cooperativeID)
}

// GetAllShards returns all shard connections for operations that need to query all shards
func (sm *ShardManager) GetAllShards() ([]*sql.DB, error) {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	shards := make([]*sql.DB, len(sm.shards))
	copy(shards, sm.shards)
	return shards, nil
}

// ExecuteOnShard executes a query on a specific shard with retries
func (sm *ShardManager) ExecuteOnShard(ctx context.Context, shardIndex int, query string, args ...interface{}) (*sql.Rows, error) {
	sm.mu.RLock()
	shard := sm.shards[shardIndex]
	sm.mu.RUnlock()

	if shard == nil {
		return nil, fmt.Errorf("shard %d is not available", shardIndex)
	}

	var rows *sql.Rows
	var err error

	for attempt := 0; attempt < MaxRetries; attempt++ {
		rows, err = shard.QueryContext(ctx, query, args...)
		if err == nil {
			return rows, nil
		}

		log.Printf("Attempt %d failed for shard %d: %v", attempt+1, shardIndex, err)
		time.Sleep(time.Duration(attempt+1) * 100 * time.Millisecond)
	}

	return nil, fmt.Errorf("failed to execute query on shard %d after %d attempts: %w", shardIndex, MaxRetries, err)
}

// BeginTxOnShard starts a transaction on a specific shard
func (sm *ShardManager) BeginTxOnShard(ctx context.Context, shardIndex int) (*sql.Tx, error) {
	sm.mu.RLock()
	shard := sm.shards[shardIndex]
	sm.mu.RUnlock()

	if shard == nil {
		return nil, fmt.Errorf("shard %d is not available", shardIndex)
	}

	return shard.BeginTx(ctx, &sql.TxOptions{
		Isolation: sql.LevelReadCommitted,
	})
}

// ExecuteOnAllShards executes a query on all shards (for schema changes, etc.)
func (sm *ShardManager) ExecuteOnAllShards(ctx context.Context, query string, args ...interface{}) error {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	var wg sync.WaitGroup
	errChan := make(chan error, ShardCount)

	for i, shard := range sm.shards {
		if shard == nil {
			errChan <- fmt.Errorf("shard %d is not available", i)
			continue
		}

		wg.Add(1)
		go func(shardIndex int, db *sql.DB) {
			defer wg.Done()
			_, err := db.ExecContext(ctx, query, args...)
			if err != nil {
				errChan <- fmt.Errorf("shard %d: %w", shardIndex, err)
			}
		}(i, shard)
	}

	wg.Wait()
	close(errChan)

	// Check for errors
	for err := range errChan {
		if err != nil {
			return err
		}
	}

	return nil
}

// HealthCheck checks the health of all shards
func (sm *ShardManager) HealthCheck() map[string]bool {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	health := make(map[string]bool)
	for i, shard := range sm.shards {
		shardName := sm.shardNames[i]
		if shard == nil {
			health[shardName] = false
			continue
		}

		err := shard.Ping()
		health[shardName] = err == nil
	}

	return health
}

// Close closes all shard connections
func (sm *ShardManager) Close() error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	var lastErr error
	for i, shard := range sm.shards {
		if shard != nil {
			if err := shard.Close(); err != nil {
				log.Printf("Error closing shard %d: %v", i, err)
				lastErr = err
			}
		}
	}

	return lastErr
}

// GetShardName returns the name of a shard by index
func (sm *ShardManager) GetShardName(index int) string {
	if index >= 0 && index < len(sm.shardNames) {
		return sm.shardNames[index]
	}
	return ""
}
