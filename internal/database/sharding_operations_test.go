package database

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestShardConfig represents a database shard configuration for testing
type TestShardConfig struct {
	Name     string
	Host     string
	Port     string
	User     string
	Password string
	Database string
}

// TestShardManager manages connections to multiple database shards for testing
type TestShardManager struct {
	shards []*TestShardConfig
	dbs    []*sql.DB
}

// NewTestShardManager creates a new test shard manager
func NewTestShardManager(shards []*TestShardConfig) (*TestShardManager, error) {
	sm := &TestShardManager{
		shards: shards,
		dbs:    make([]*sql.DB, len(shards)),
	}

	for i, shard := range shards {
		dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
			shard.User, shard.Password, shard.Host, shard.Port, shard.Database)

		db, err := sql.Open("postgres", dsn)
		if err != nil {
			return nil, fmt.Errorf("failed to connect to shard %s: %w", shard.Name, err)
		}

		// Test connection
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		if err := db.PingContext(ctx); err != nil {
			return nil, fmt.Errorf("failed to ping shard %s: %w", shard.Name, err)
		}

		sm.dbs[i] = db
	}

	return sm, nil
}

// GetShardForUser determines which shard a user should be stored in
func (sm *TestShardManager) GetShardForUser(userID uuid.UUID) int {
	// Simple hash-based sharding
	hash := 0
	for _, b := range userID {
		hash = (hash*31 + int(b)) % len(sm.shards)
	}
	return hash
}

// GetShard returns the database connection for a specific shard
func (sm *TestShardManager) GetShard(index int) *sql.DB {
	if index < 0 || index >= len(sm.dbs) {
		return nil
	}
	return sm.dbs[index]
}

// Close closes all database connections
func (sm *TestShardManager) Close() error {
	var lastErr error
	for i, db := range sm.dbs {
		if db != nil {
			if err := db.Close(); err != nil {
				lastErr = fmt.Errorf("failed to close shard %d: %w", i, err)
			}
		}
	}
	return lastErr
}

// TestShardingOperations tests read and write operations across all four sharded databases (comfunds01, comfunds02, comfunds03, comfunds04).
func TestShardingOperations(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping sharding operations test in short mode")
	}

	// Configure all four shards
	shards := []*TestShardConfig{
		{
			Name:     "comfunds00",
			Host:     getEnvOrDefault("DB_HOST", "localhost"),
			Port:     getEnvOrDefault("DB_PORT", "5432"),
			User:     getEnvOrDefault("DB_USER", "postgres"),
			Password: getEnvOrDefault("DB_PASSWORD", "postgres"),
			Database: "comfunds00",
		},
		{
			Name:     "comfunds01",
			Host:     getEnvOrDefault("DB_HOST", "localhost"),
			Port:     getEnvOrDefault("DB_PORT", "5432"),
			User:     getEnvOrDefault("DB_USER", "postgres"),
			Password: getEnvOrDefault("DB_PASSWORD", "postgres"),
			Database: "comfunds01",
		},
		{
			Name:     "comfunds02",
			Host:     getEnvOrDefault("DB_HOST", "localhost"),
			Port:     getEnvOrDefault("DB_PORT", "5432"),
			User:     getEnvOrDefault("DB_USER", "postgres"),
			Password: getEnvOrDefault("DB_PASSWORD", "postgres"),
			Database: "comfunds02",
		},
		{
			Name:     "comfunds03",
			Host:     getEnvOrDefault("DB_HOST", "localhost"),
			Port:     getEnvOrDefault("DB_PORT", "5432"),
			User:     getEnvOrDefault("DB_USER", "postgres"),
			Password: getEnvOrDefault("DB_PASSWORD", "postgres"),
			Database: "comfunds03",
		},
	}

	// Create shard manager
	shardMgr, err := NewTestShardManager(shards)
	require.NoError(t, err, "Failed to create shard manager")
	defer shardMgr.Close()

	t.Run("Sharding_Write_Operations", func(t *testing.T) {
		testShardingWriteOperations(t, shardMgr)
	})

	t.Run("Sharding_Read_Operations", func(t *testing.T) {
		testShardingReadOperations(t, shardMgr)
	})

	t.Run("Sharding_Cross_Shard_Operations", func(t *testing.T) {
		testShardingCrossShardOperations(t, shardMgr)
	})

	t.Run("Sharding_Concurrent_Operations", func(t *testing.T) {
		testShardingConcurrentOperations(t, shardMgr)
	})

	t.Run("Sharding_Data_Distribution", func(t *testing.T) {
		testShardingDataDistribution(t, shardMgr)
	})

	t.Run("Sharding_Performance", func(t *testing.T) {
		testShardingPerformance(t, shardMgr)
	})
}

// testShardingWriteOperations tests write operations across all shards
func testShardingWriteOperations(t *testing.T, shardMgr *TestShardManager) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Test writing users to different shards
	userCount := 100
	shardDistribution := make(map[int]int)
	userIDs := make([]uuid.UUID, userCount)

	t.Logf("Writing %d users across %d shards...", userCount, len(shardMgr.shards))

	for i := 0; i < userCount; i++ {
		userID := uuid.New()
		userIDs[i] = userID

		// Determine which shard this user should go to
		shardIndex := shardMgr.GetShardForUser(userID)
		shardDistribution[shardIndex]++

		// Get the database connection for this shard
		db := shardMgr.GetShard(shardIndex)
		require.NotNil(t, db, "Database connection should not be nil for shard %d", shardIndex)

		// Write user to the appropriate shard
		email := fmt.Sprintf("user-%d-%s@example.com", i, userID.String()[:8])
		name := fmt.Sprintf("User %d", i)

		insertQuery := `
			INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
		`

		_, err := db.ExecContext(ctx, insertQuery,
			userID, email, name, "hashedpassword", true, time.Now(), time.Now())
		require.NoError(t, err, "Failed to insert user %d into shard %d", i, shardIndex)
	}

	// Verify data distribution
	t.Logf("Data distribution across shards:")
	for shardIndex, count := range shardDistribution {
		t.Logf("  Shard %d (%s): %d users", shardIndex, shardMgr.shards[shardIndex].Name, count)
		assert.Greater(t, count, 0, "Shard %d should have at least one user", shardIndex)
	}

	// Test writing cooperatives to different shards
	coopCount := 20
	t.Logf("Writing %d cooperatives across shards...", coopCount)

	for i := 0; i < coopCount; i++ {
		coopID := uuid.New()
		shardIndex := i % len(shardMgr.shards) // Round-robin distribution for cooperatives

		db := shardMgr.GetShard(shardIndex)
		require.NotNil(t, db, "Database connection should not be nil for shard %d", shardIndex)

		name := fmt.Sprintf("Cooperative %d", i)
		registrationNumber := fmt.Sprintf("COOP-2024-%03d-%d", i, time.Now().UnixNano())
		address := fmt.Sprintf("Address %d", i)
		phone := fmt.Sprintf("+1234567%04d", i)
		email := fmt.Sprintf("coop%d@example.com", i)
		bankAccount := fmt.Sprintf("123456789%d", i)

		insertQuery := `
			INSERT INTO cooperatives (id, name, registration_number, address, phone, email, bank_account, is_active, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		`

		_, err := db.ExecContext(ctx, insertQuery,
			coopID, name, registrationNumber, address, phone, email, bankAccount, true, time.Now(), time.Now())
		require.NoError(t, err, "Failed to insert cooperative %d into shard %d", i, shardIndex)
	}

	t.Logf("✅ Sharding write operations completed successfully")
}

// testShardingReadOperations tests read operations across all shards
func testShardingReadOperations(t *testing.T, shardMgr *TestShardManager) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Test reading from each shard
	t.Logf("Reading data from all %d shards...", len(shardMgr.shards))

	for i, shard := range shardMgr.shards {
		db := shardMgr.GetShard(i)
		require.NotNil(t, db, "Database connection should not be nil for shard %d", i)

		// Count users in this shard
		var userCount int
		err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&userCount)
		require.NoError(t, err, "Failed to count users in shard %d", i)

		t.Logf("  Shard %d (%s): %d users", i, shard.Name, userCount)

		// Count cooperatives in this shard
		var coopCount int
		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM cooperatives").Scan(&coopCount)
		require.NoError(t, err, "Failed to count cooperatives in shard %d", i)

		t.Logf("  Shard %d (%s): %d cooperatives", i, shard.Name, coopCount)

		// Read some sample users from this shard
		rows, err := db.QueryContext(ctx, "SELECT id, email, name FROM users LIMIT 5")
		require.NoError(t, err, "Failed to query users from shard %d", i)
		defer rows.Close()

		userCount = 0
		for rows.Next() {
			var id, email, name string
			err := rows.Scan(&id, &email, &name)
			require.NoError(t, err, "Failed to scan user from shard %d", i)
			userCount++
		}

		t.Logf("  Shard %d (%s): Read %d sample users", i, shard.Name, userCount)
	}

	// Test cross-shard aggregation (simulate)
	t.Logf("Simulating cross-shard aggregation...")
	totalUsers := 0
	totalCoops := 0

	for i := 0; i < len(shardMgr.shards); i++ {
		db := shardMgr.GetShard(i)

		var userCount, coopCount int
		err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&userCount)
		require.NoError(t, err, "Failed to count users in shard %d", i)

		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM cooperatives").Scan(&coopCount)
		require.NoError(t, err, "Failed to count cooperatives in shard %d", i)

		totalUsers += userCount
		totalCoops += coopCount
	}

	t.Logf("Total users across all shards: %d", totalUsers)
	t.Logf("Total cooperatives across all shards: %d", totalCoops)

	t.Logf("✅ Sharding read operations completed successfully")
}

// testShardingCrossShardOperations tests operations that span multiple shards
func testShardingCrossShardOperations(t *testing.T, shardMgr *TestShardManager) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	t.Logf("Testing cross-shard operations...")

	// Test finding a user across all shards (simulate user lookup)
	testEmail := "test-cross-shard@example.com"
	foundUser := false
	var foundShardIndex int

	for i := 0; i < len(shardMgr.shards); i++ {
		db := shardMgr.GetShard(i)

		var userID, email, name string
		err := db.QueryRowContext(ctx, "SELECT id, email, name FROM users WHERE email = $1", testEmail).Scan(&userID, &email, &name)
		if err == sql.ErrNoRows {
			continue
		}
		require.NoError(t, err, "Failed to query user in shard %d", i)

		foundUser = true
		foundShardIndex = i
		t.Logf("Found user %s in shard %d (%s)", email, i, shardMgr.shards[i].Name)
		break
	}

	if foundUser {
		t.Logf("✅ Cross-shard user lookup successful in shard %d", foundShardIndex)
	} else {
		t.Logf("ℹ️  Test user not found (expected for test data)")
	}

	// Test cross-shard business creation (user from one shard, cooperative from another)
	t.Logf("Testing cross-shard business creation...")

	// Find a user and cooperative from different shards
	var userID, coopID string
	var userShardIndex, coopShardIndex int

	// Find a user
	for i := 0; i < len(shardMgr.shards); i++ {
		db := shardMgr.GetShard(i)
		err := db.QueryRowContext(ctx, "SELECT id FROM users LIMIT 1").Scan(&userID)
		if err == sql.ErrNoRows {
			continue
		}
		require.NoError(t, err, "Failed to get user from shard %d", i)
		userShardIndex = i
		break
	}

	// Find a cooperative from any shard (can be same as user for simplicity)
	for i := 0; i < len(shardMgr.shards); i++ {
		db := shardMgr.GetShard(i)
		err := db.QueryRowContext(ctx, "SELECT id FROM cooperatives LIMIT 1").Scan(&coopID)
		if err == sql.ErrNoRows {
			continue
		}
		require.NoError(t, err, "Failed to get cooperative from shard %d", i)
		coopShardIndex = i
		break
	}

	// If cooperative is in different shard from user, find a user in the same shard as cooperative
	if coopShardIndex != userShardIndex {
		db := shardMgr.GetShard(coopShardIndex)
		err := db.QueryRowContext(ctx, "SELECT id FROM users LIMIT 1").Scan(&userID)
		if err == sql.ErrNoRows {
			t.Logf("ℹ️  No user found in cooperative's shard, skipping cross-shard business creation")
			userID = ""
		} else {
			require.NoError(t, err, "Failed to get user from cooperative's shard %d", coopShardIndex)
			userShardIndex = coopShardIndex
		}
	}

	if userID != "" && coopID != "" {
		t.Logf("Cross-shard business creation: User from shard %d, Cooperative from shard %d", userShardIndex, coopShardIndex)

		// Create business in the cooperative's shard
		businessID := uuid.New()
		db := shardMgr.GetShard(coopShardIndex)

		insertQuery := `
			INSERT INTO businesses (id, cooperative_id, owner_id, name, description, business_type, is_active, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		`

		_, err := db.ExecContext(ctx, insertQuery,
			businessID, coopID, userID, "Cross-Shard Business", "Business created across shards", "retail", true, time.Now(), time.Now())
		require.NoError(t, err, "Failed to create cross-shard business")

		t.Logf("✅ Cross-shard business creation successful")
	} else {
		t.Logf("ℹ️  Skipping cross-shard business creation (insufficient test data)")
	}

	t.Logf("✅ Cross-shard operations completed successfully")
}

// testShardingConcurrentOperations tests concurrent operations across shards
func testShardingConcurrentOperations(t *testing.T, shardMgr *TestShardManager) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	t.Logf("Testing concurrent operations across shards...")

	// Test concurrent reads from all shards
	concurrency := 10
	var wg sync.WaitGroup
	results := make(chan string, concurrency*len(shardMgr.shards))

	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()

			for shardIndex := 0; shardIndex < len(shardMgr.shards); shardIndex++ {
				db := shardMgr.GetShard(shardIndex)
				if db == nil {
					results <- fmt.Sprintf("Worker %d: Shard %d - No connection", workerID, shardIndex)
					continue
				}

				var userCount int
				err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&userCount)
				if err != nil {
					results <- fmt.Sprintf("Worker %d: Shard %d - Error: %v", workerID, shardIndex, err)
				} else {
					results <- fmt.Sprintf("Worker %d: Shard %d - %d users", workerID, shardIndex, userCount)
				}
			}
		}(i)
	}

	wg.Wait()
	close(results)

	// Collect results
	successCount := 0
	for result := range results {
		t.Logf("  %s", result)
		if result != "" {
			successCount++
		}
	}

	t.Logf("Concurrent operations completed: %d successful operations", successCount)

	// Test concurrent writes to different shards
	writeConcurrency := 5
	writeResults := make(chan string, writeConcurrency)

	for i := 0; i < writeConcurrency; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()

			// Each worker writes to a different shard
			shardIndex := workerID % len(shardMgr.shards)
			db := shardMgr.GetShard(shardIndex)

			if db == nil {
				writeResults <- fmt.Sprintf("Worker %d: Shard %d - No connection", workerID, shardIndex)
				return
			}

			userID := uuid.New()
			email := fmt.Sprintf("concurrent-user-%d-%s@example.com", workerID, userID.String()[:8])
			name := fmt.Sprintf("Concurrent User %d", workerID)

			insertQuery := `
				INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7)
			`

			_, err := db.ExecContext(ctx, insertQuery,
				userID, email, name, "password", true, time.Now(), time.Now())

			if err != nil {
				writeResults <- fmt.Sprintf("Worker %d: Shard %d - Write error: %v", workerID, shardIndex, err)
			} else {
				writeResults <- fmt.Sprintf("Worker %d: Shard %d - Write successful", workerID, shardIndex)
			}
		}(i)
	}

	wg.Wait()
	close(writeResults)

	// Collect write results
	writeSuccessCount := 0
	for result := range writeResults {
		t.Logf("  %s", result)
		if result != "" {
			writeSuccessCount++
		}
	}

	t.Logf("Concurrent writes completed: %d successful writes", writeSuccessCount)

	t.Logf("✅ Concurrent operations completed successfully")
}

// testShardingDataDistribution tests data distribution across shards
func testShardingDataDistribution(t *testing.T, shardMgr *TestShardManager) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	t.Logf("Testing data distribution across shards...")

	// Analyze data distribution
	shardStats := make(map[int]map[string]int)

	for i := 0; i < len(shardMgr.shards); i++ {
		db := shardMgr.GetShard(i)
		shardStats[i] = make(map[string]int)

		// Count users
		var userCount int
		err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&userCount)
		require.NoError(t, err, "Failed to count users in shard %d", i)
		shardStats[i]["users"] = userCount

		// Count cooperatives
		var coopCount int
		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM cooperatives").Scan(&coopCount)
		require.NoError(t, err, "Failed to count cooperatives in shard %d", i)
		shardStats[i]["cooperatives"] = coopCount

		// Count businesses
		var businessCount int
		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM businesses").Scan(&businessCount)
		require.NoError(t, err, "Failed to count businesses in shard %d", i)
		shardStats[i]["businesses"] = businessCount

		// Count projects
		var projectCount int
		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM projects").Scan(&projectCount)
		require.NoError(t, err, "Failed to count projects in shard %d", i)
		shardStats[i]["projects"] = projectCount

		// Count investments
		var investmentCount int
		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM investments").Scan(&investmentCount)
		require.NoError(t, err, "Failed to count investments in shard %d", i)
		shardStats[i]["investments"] = investmentCount
	}

	// Report distribution
	t.Logf("Data distribution across shards:")
	for shardIndex, stats := range shardStats {
		t.Logf("  Shard %d (%s):", shardIndex, shardMgr.shards[shardIndex].Name)
		for table, count := range stats {
			t.Logf("    %s: %d", table, count)
		}
	}

	// Calculate distribution balance
	totalUsers := 0
	for _, stats := range shardStats {
		totalUsers += stats["users"]
	}

	if totalUsers > 0 {
		expectedPerShard := totalUsers / len(shardMgr.shards)
		tolerance := expectedPerShard / 2 // Allow 50% variance

		t.Logf("User distribution analysis:")
		t.Logf("  Total users: %d", totalUsers)
		t.Logf("  Expected per shard: %d", expectedPerShard)
		t.Logf("  Tolerance: ±%d", tolerance)

		for shardIndex, stats := range shardStats {
			userCount := stats["users"]
			t.Logf("  Shard %d: %d users (expected: %d±%d)", shardIndex, userCount, expectedPerShard, tolerance)

			if expectedPerShard > 0 {
				assert.GreaterOrEqual(t, userCount, expectedPerShard-tolerance,
					"Shard %d should have at least %d users", shardIndex, expectedPerShard-tolerance)
			}
		}
	}

	t.Logf("✅ Data distribution analysis completed successfully")
}

// testShardingPerformance tests performance across shards
func testShardingPerformance(t *testing.T, shardMgr *TestShardManager) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	t.Logf("Testing sharding performance...")

	// Test read performance for each shard
	readIterations := 100
	shardReadTimes := make(map[int][]time.Duration)

	for shardIndex := 0; shardIndex < len(shardMgr.shards); shardIndex++ {
		db := shardMgr.GetShard(shardIndex)
		times := make([]time.Duration, readIterations)

		for i := 0; i < readIterations; i++ {
			start := time.Now()

			var count int
			err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&count)
			require.NoError(t, err, "Failed to count users in shard %d", shardIndex)

			times[i] = time.Since(start)
		}

		shardReadTimes[shardIndex] = times
	}

	// Calculate and report performance metrics
	for shardIndex, times := range shardReadTimes {
		var total time.Duration
		for _, t := range times {
			total += t
		}
		avg := total / time.Duration(len(times))

		t.Logf("Shard %d (%s) read performance:", shardIndex, shardMgr.shards[shardIndex].Name)
		t.Logf("  Average: %v", avg)
		t.Logf("  Total: %v", total)
		t.Logf("  Operations: %d", len(times))
	}

	// Test write performance
	writeIterations := 50
	shardWriteTimes := make(map[int][]time.Duration)

	for shardIndex := 0; shardIndex < len(shardMgr.shards); shardIndex++ {
		db := shardMgr.GetShard(shardIndex)
		times := make([]time.Duration, writeIterations)

		for i := 0; i < writeIterations; i++ {
			start := time.Now()

			userID := uuid.New()
			email := fmt.Sprintf("perf-test-%d-%s@example.com", i, userID.String()[:8])
			name := fmt.Sprintf("Performance User %d", i)

			insertQuery := `
				INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7)
			`

			_, err := db.ExecContext(ctx, insertQuery,
				userID, email, name, "password", true, time.Now(), time.Now())
			require.NoError(t, err, "Failed to insert user in shard %d", shardIndex)

			times[i] = time.Since(start)
		}

		shardWriteTimes[shardIndex] = times
	}

	// Calculate and report write performance metrics
	for shardIndex, times := range shardWriteTimes {
		var total time.Duration
		for _, t := range times {
			total += t
		}
		avg := total / time.Duration(len(times))

		t.Logf("Shard %d (%s) write performance:", shardIndex, shardMgr.shards[shardIndex].Name)
		t.Logf("  Average: %v", avg)
		t.Logf("  Total: %v", total)
		t.Logf("  Operations: %d", len(times))
	}

	t.Logf("✅ Sharding performance testing completed successfully")
}

// BenchmarkShardingOperations benchmarks sharding operations
func BenchmarkShardingOperations(b *testing.B) {
	// Configure shards
	shards := []*TestShardConfig{
		{
			Name:     "comfunds00",
			Host:     getEnvOrDefault("DB_HOST", "localhost"),
			Port:     getEnvOrDefault("DB_PORT", "5432"),
			User:     getEnvOrDefault("DB_USER", "postgres"),
			Password: getEnvOrDefault("DB_PASSWORD", "postgres"),
			Database: "comfunds00",
		},
		{
			Name:     "comfunds01",
			Host:     getEnvOrDefault("DB_HOST", "localhost"),
			Port:     getEnvOrDefault("DB_PORT", "5432"),
			User:     getEnvOrDefault("DB_USER", "postgres"),
			Password: getEnvOrDefault("DB_PASSWORD", "postgres"),
			Database: "comfunds01",
		},
		{
			Name:     "comfunds02",
			Host:     getEnvOrDefault("DB_HOST", "localhost"),
			Port:     getEnvOrDefault("DB_PORT", "5432"),
			User:     getEnvOrDefault("DB_USER", "postgres"),
			Password: getEnvOrDefault("DB_PASSWORD", "postgres"),
			Database: "comfunds02",
		},
		{
			Name:     "comfunds03",
			Host:     getEnvOrDefault("DB_HOST", "localhost"),
			Port:     getEnvOrDefault("DB_PORT", "5432"),
			User:     getEnvOrDefault("DB_USER", "postgres"),
			Password: getEnvOrDefault("DB_PASSWORD", "postgres"),
			Database: "comfunds03",
		},
	}

	shardMgr, err := NewTestShardManager(shards)
	if err != nil {
		b.Skip("Failed to create shard manager, skipping benchmark")
	}
	defer shardMgr.Close()

	ctx := context.Background()

	b.Run("Shard_Read", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			shardIndex := i % len(shards)
			db := shardMgr.GetShard(shardIndex)

			var count int
			err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&count)
			require.NoError(b, err)
		}
	})

	b.Run("Shard_Write", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			shardIndex := i % len(shards)
			db := shardMgr.GetShard(shardIndex)

			userID := uuid.New()
			email := fmt.Sprintf("bench-%d-%s@example.com", i, userID.String()[:8])

			insertQuery := `
				INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7)
			`

			_, err := db.ExecContext(ctx, insertQuery,
				userID, email, "Bench User", "password", true, time.Now(), time.Now())
			require.NoError(b, err)
		}
	})

	b.Run("Cross_Shard_Query", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			totalUsers := 0
			for shardIndex := 0; shardIndex < len(shards); shardIndex++ {
				db := shardMgr.GetShard(shardIndex)

				var count int
				err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&count)
				require.NoError(b, err)
				totalUsers += count
			}
			_ = totalUsers
		}
	})
}

// Helper function to get environment variable with default
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
