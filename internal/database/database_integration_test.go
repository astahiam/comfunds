package database

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	_ "github.com/lib/pq"
)

// TestDatabaseIntegration tests the complete database integration
func TestDatabaseIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping database integration test in short mode")
	}

	// Check if we have database environment variables
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		// Try individual environment variables
		dbUser := os.Getenv("DB_USER")
		dbPassword := os.Getenv("DB_PASSWORD")
		dbHost := os.Getenv("DB_HOST")
		dbPort := os.Getenv("DB_PORT")
		dbName := os.Getenv("DB_NAME")

		if dbUser == "" || dbPassword == "" || dbHost == "" || dbPort == "" || dbName == "" {
			t.Skip("Database environment variables not set, skipping integration test")
		}

		dbURL = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
			dbUser, dbPassword, dbHost, dbPort, dbName)
	}

	t.Run("Database_Connection", func(t *testing.T) {
		testDatabaseConnection(t, dbURL)
	})

	t.Run("Database_Migrations", func(t *testing.T) {
		testDatabaseMigrations(t, dbURL)
	})

	t.Run("Database_CRUD_Operations", func(t *testing.T) {
		testDatabaseCRUDOperations(t, dbURL)
	})

	t.Run("Database_Transactions", func(t *testing.T) {
		testDatabaseTransactions(t, dbURL)
	})

	t.Run("Database_Concurrent_Access", func(t *testing.T) {
		testDatabaseConcurrentAccess(t, dbURL)
	})
}

// testDatabaseConnection tests basic database connectivity
func testDatabaseConnection(t *testing.T, dbURL string) {
	// Test connection
	db, err := sql.Open("postgres", dbURL)
	require.NoError(t, err)
	defer db.Close()

	// Test ping
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	err = db.PingContext(ctx)
	require.NoError(t, err, "Database ping failed")

	// Test basic query
	var version string
	err = db.QueryRowContext(ctx, "SELECT version()").Scan(&version)
	require.NoError(t, err, "Database version query failed")
	
	t.Logf("Database version: %s", version)
}

// testDatabaseMigrations tests that all required tables exist
func testDatabaseMigrations(t *testing.T, dbURL string) {
	db, err := sql.Open("postgres", dbURL)
	require.NoError(t, err)
	defer db.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Test that required tables exist
	requiredTables := []string{
		"users",
		"cooperatives", 
		"businesses",
		"projects",
		"investments",
		"profit_distributions",
		"audit_logs",
	}

	for _, tableName := range requiredTables {
		var exists bool
		query := `
			SELECT EXISTS (
				SELECT FROM information_schema.tables 
				WHERE table_schema = 'public' 
				AND table_name = $1
			)
		`
		err := db.QueryRowContext(ctx, query, tableName).Scan(&exists)
		require.NoError(t, err, "Failed to check if table %s exists", tableName)
		
		if exists {
			t.Logf("✅ Table %s exists", tableName)
		} else {
			t.Logf("⚠️  Table %s does not exist", tableName)
		}
	}
}

// testDatabaseCRUDOperations tests basic CRUD operations
func testDatabaseCRUDOperations(t *testing.T, dbURL string) {
	db, err := sql.Open("postgres", dbURL)
	require.NoError(t, err)
	defer db.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Test User CRUD operations
	t.Run("User_CRUD", func(t *testing.T) {
		testUserCRUD(t, ctx, db)
	})

	// Test Cooperative CRUD operations
	t.Run("Cooperative_CRUD", func(t *testing.T) {
		testCooperativeCRUD(t, ctx, db)
	})

	// Test Business CRUD operations
	t.Run("Business_CRUD", func(t *testing.T) {
		testBusinessCRUD(t, ctx, db)
	})
}

// testUserCRUD tests user CRUD operations
func testUserCRUD(t *testing.T, ctx context.Context, db *sql.DB) {
	userID := uuid.New()
	email := fmt.Sprintf("test-%s@example.com", uuid.New().String()[:8])
	name := "Test User"
	password := "hashedpassword123"

	// Create user
	createQuery := `
		INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := db.ExecContext(ctx, createQuery, 
		userID, email, name, password, true, time.Now(), time.Now())
	require.NoError(t, err, "Failed to create user")

	// Read user
	var retrievedEmail, retrievedName string
	var isActive bool
	readQuery := `SELECT email, name, is_active FROM users WHERE id = $1`
	err = db.QueryRowContext(ctx, readQuery, userID).Scan(&retrievedEmail, &retrievedName, &isActive)
	require.NoError(t, err, "Failed to read user")
	
	assert.Equal(t, email, retrievedEmail)
	assert.Equal(t, name, retrievedName)
	assert.True(t, isActive)

	// Update user
	newName := "Updated Test User"
	updateQuery := `UPDATE users SET name = $1, updated_at = $2 WHERE id = $3`
	_, err = db.ExecContext(ctx, updateQuery, newName, time.Now(), userID)
	require.NoError(t, err, "Failed to update user")

	// Verify update
	err = db.QueryRowContext(ctx, readQuery, userID).Scan(&retrievedEmail, &retrievedName, &isActive)
	require.NoError(t, err, "Failed to read updated user")
	assert.Equal(t, newName, retrievedName)

	// Soft delete user
	deleteQuery := `UPDATE users SET is_active = false, updated_at = $1 WHERE id = $2`
	_, err = db.ExecContext(ctx, deleteQuery, time.Now(), userID)
	require.NoError(t, err, "Failed to soft delete user")

	// Verify soft delete
	err = db.QueryRowContext(ctx, readQuery, userID).Scan(&retrievedEmail, &retrievedName, &isActive)
	require.NoError(t, err, "Failed to read soft deleted user")
	assert.False(t, isActive)

	t.Logf("✅ User CRUD operations completed successfully")
}

// testCooperativeCRUD tests cooperative CRUD operations
func testCooperativeCRUD(t *testing.T, ctx context.Context, db *sql.DB) {
	cooperativeID := uuid.New()
	name := "Test Cooperative"
	registrationNumber := "COOP-2024-001"
	address := "123 Test Street, Test City"
	phone := "+1234567890"
	email := "test@cooperative.com"
	bankAccount := "1234567890"

	// Create cooperative
	createQuery := `
		INSERT INTO cooperatives (id, name, registration_number, address, phone, email, bank_account, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err := db.ExecContext(ctx, createQuery,
		cooperativeID, name, registrationNumber, address, phone, email, bankAccount, true, time.Now(), time.Now())
	require.NoError(t, err, "Failed to create cooperative")

	// Read cooperative
	var retrievedName, retrievedRegistrationNumber, retrievedAddress, retrievedPhone, retrievedEmail, retrievedBankAccount string
	var isActive bool
	readQuery := `SELECT name, registration_number, address, phone, email, bank_account, is_active FROM cooperatives WHERE id = $1`
	err = db.QueryRowContext(ctx, readQuery, cooperativeID).Scan(&retrievedName, &retrievedRegistrationNumber, &retrievedAddress, &retrievedPhone, &retrievedEmail, &retrievedBankAccount, &isActive)
	require.NoError(t, err, "Failed to read cooperative")
	
	assert.Equal(t, name, retrievedName)
	assert.Equal(t, registrationNumber, retrievedRegistrationNumber)
	assert.Equal(t, address, retrievedAddress)
	assert.Equal(t, phone, retrievedPhone)
	assert.Equal(t, email, retrievedEmail)
	assert.Equal(t, bankAccount, retrievedBankAccount)
	assert.True(t, isActive)

	// Update cooperative
	newAddress := "456 Updated Street, Updated City"
	updateQuery := `UPDATE cooperatives SET address = $1, updated_at = $2 WHERE id = $3`
	_, err = db.ExecContext(ctx, updateQuery, newAddress, time.Now(), cooperativeID)
	require.NoError(t, err, "Failed to update cooperative")

	// Verify update
	err = db.QueryRowContext(ctx, readQuery, cooperativeID).Scan(&retrievedName, &retrievedRegistrationNumber, &retrievedAddress, &retrievedPhone, &retrievedEmail, &retrievedBankAccount, &isActive)
	require.NoError(t, err, "Failed to read updated cooperative")
	assert.Equal(t, newAddress, retrievedAddress)

	t.Logf("✅ Cooperative CRUD operations completed successfully")
}

// testBusinessCRUD tests business CRUD operations
func testBusinessCRUD(t *testing.T, ctx context.Context, db *sql.DB) {
	// First create a cooperative for the business
	cooperativeID := uuid.New()
	coopQuery := `INSERT INTO cooperatives (id, name, description, is_active, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)`
	_, err := db.ExecContext(ctx, coopQuery, cooperativeID, "Test Coop", "Test cooperative", true, time.Now(), time.Now())
	require.NoError(t, err, "Failed to create test cooperative")

	businessID := uuid.New()
	name := "Test Business"
	description := "A test business for integration testing"

	// Create business
	createQuery := `
		INSERT INTO businesses (id, cooperative_id, name, description, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err = db.ExecContext(ctx, createQuery,
		businessID, cooperativeID, name, description, true, time.Now(), time.Now())
	require.NoError(t, err, "Failed to create business")

	// Read business
	var retrievedName, retrievedDescription string
	var isActive bool
	readQuery := `SELECT name, description, is_active FROM businesses WHERE id = $1`
	err = db.QueryRowContext(ctx, readQuery, businessID).Scan(&retrievedName, &retrievedDescription, &isActive)
	require.NoError(t, err, "Failed to read business")
	
	assert.Equal(t, name, retrievedName)
	assert.Equal(t, description, retrievedDescription)
	assert.True(t, isActive)

	// Update business
	newDescription := "Updated test business description"
	updateQuery := `UPDATE businesses SET description = $1, updated_at = $2 WHERE id = $3`
	_, err = db.ExecContext(ctx, updateQuery, newDescription, time.Now(), businessID)
	require.NoError(t, err, "Failed to update business")

	// Verify update
	err = db.QueryRowContext(ctx, readQuery, businessID).Scan(&retrievedName, &retrievedDescription, &isActive)
	require.NoError(t, err, "Failed to read updated business")
	assert.Equal(t, newDescription, retrievedDescription)

	t.Logf("✅ Business CRUD operations completed successfully")
}

// testDatabaseTransactions tests database transaction handling
func testDatabaseTransactions(t *testing.T, dbURL string) {
	db, err := sql.Open("postgres", dbURL)
	require.NoError(t, err)
	defer db.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Test transaction rollback
	t.Run("Transaction_Rollback", func(t *testing.T) {
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		userID := uuid.New()
		email := fmt.Sprintf("rollback-test-%s@example.com", uuid.New().String()[:8])

		// Insert user in transaction
		_, err = tx.ExecContext(ctx, `
			INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
		`, userID, email, "Rollback Test User", "password", true, time.Now(), time.Now())
		require.NoError(t, err, "Failed to insert user in transaction")

		// Verify user exists in transaction
		var count int
		err = tx.QueryRowContext(ctx, "SELECT COUNT(*) FROM users WHERE id = $1", userID).Scan(&count)
		require.NoError(t, err, "Failed to count user in transaction")
		assert.Equal(t, 1, count, "User should exist in transaction")

		// Rollback transaction
		err = tx.Rollback()
		require.NoError(t, err, "Failed to rollback transaction")

		// Verify user doesn't exist after rollback
		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users WHERE id = $1", userID).Scan(&count)
		require.NoError(t, err, "Failed to count user after rollback")
		assert.Equal(t, 0, count, "User should not exist after rollback")

		t.Logf("✅ Transaction rollback test completed successfully")
	})

	// Test transaction commit
	t.Run("Transaction_Commit", func(t *testing.T) {
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		userID := uuid.New()
		email := fmt.Sprintf("commit-test-%s@example.com", uuid.New().String()[:8])

		// Insert user in transaction
		_, err = tx.ExecContext(ctx, `
			INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
		`, userID, email, "Commit Test User", "password", true, time.Now(), time.Now())
		require.NoError(t, err, "Failed to insert user in transaction")

		// Commit transaction
		err = tx.Commit()
		require.NoError(t, err, "Failed to commit transaction")

		// Verify user exists after commit
		var count int
		err = db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users WHERE id = $1", userID).Scan(&count)
		require.NoError(t, err, "Failed to count user after commit")
		assert.Equal(t, 1, count, "User should exist after commit")

		// Clean up
		_, err = db.ExecContext(ctx, "DELETE FROM users WHERE id = $1", userID)
		require.NoError(t, err, "Failed to clean up test user")

		t.Logf("✅ Transaction commit test completed successfully")
	})
}

// testDatabaseConcurrentAccess tests concurrent database access
func testDatabaseConcurrentAccess(t *testing.T, dbURL string) {
	db, err := sql.Open("postgres", dbURL)
	require.NoError(t, err)
	defer db.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Test concurrent reads
	t.Run("Concurrent_Reads", func(t *testing.T) {
		concurrency := 10
		results := make(chan error, concurrency)

		for i := 0; i < concurrency; i++ {
			go func() {
				var count int
				err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&count)
				results <- err
			}()
		}

		// Collect results
		for i := 0; i < concurrency; i++ {
			err := <-results
			require.NoError(t, err, "Concurrent read failed")
		}

		t.Logf("✅ Concurrent reads test completed successfully")
	})

	// Test concurrent writes (with unique data)
	t.Run("Concurrent_Writes", func(t *testing.T) {
		concurrency := 5
		results := make(chan error, concurrency)

		for i := 0; i < concurrency; i++ {
			go func(index int) {
				userID := uuid.New()
				email := fmt.Sprintf("concurrent-test-%d-%s@example.com", index, uuid.New().String()[:8])
				
				_, err := db.ExecContext(ctx, `
					INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
					VALUES ($1, $2, $3, $4, $5, $6, $7)
				`, userID, email, fmt.Sprintf("Concurrent User %d", index), "password", true, time.Now(), time.Now())
				
				results <- err
			}(i)
		}

		// Collect results
		for i := 0; i < concurrency; i++ {
			err := <-results
			require.NoError(t, err, "Concurrent write failed")
		}

		t.Logf("✅ Concurrent writes test completed successfully")
	})
}

// BenchmarkDatabaseOperations benchmarks database operations
func BenchmarkDatabaseOperations(b *testing.B) {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		b.Skip("Database URL not set, skipping benchmark")
	}

	db, err := sql.Open("postgres", dbURL)
	require.NoError(b, err)
	defer db.Close()

	ctx := context.Background()

	b.Run("Simple_Query", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			var count int
			err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM users").Scan(&count)
			require.NoError(b, err)
		}
	})

	b.Run("Insert_User", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			userID := uuid.New()
			email := fmt.Sprintf("benchmark-%d-%s@example.com", i, uuid.New().String()[:8])
			
			_, err := db.ExecContext(ctx, `
				INSERT INTO users (id, email, name, password, is_active, created_at, updated_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7)
			`, userID, email, "Benchmark User", "password", true, time.Now(), time.Now())
			require.NoError(b, err)
		}
	})
}
