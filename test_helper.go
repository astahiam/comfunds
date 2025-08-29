package main

import (
	"database/sql"
	"log"
	"os"
	"testing"

	"comfunds/internal/database"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

var testDB *database.DB

func TestMain(m *testing.M) {
	// Load test environment variables
	if err := godotenv.Load(".env.test"); err != nil {
		log.Println("No .env.test file found, using default test configuration")
	}

	// Setup test database
	testDatabaseURL := os.Getenv("TEST_DATABASE_URL")
	if testDatabaseURL == "" {
		testDatabaseURL = "postgres://localhost/comfunds_test?sslmode=disable"
	}

	var err error
	testDB, err = database.NewConnection(testDatabaseURL)
	if err != nil {
		log.Printf("Failed to connect to test database: %v", err)
		log.Println("Skipping database integration tests")
	}

	// Run tests
	code := m.Run()

	// Cleanup
	if testDB != nil {
		testDB.Close()
	}

	os.Exit(code)
}

func setupTestDB(t *testing.T) *sql.DB {
	if testDB == nil {
		t.Skip("Test database not available")
	}
	return testDB.DB
}

func cleanupTestDB(t *testing.T, db *sql.DB) {
	if db == nil {
		return
	}

	// Clean up test data
	tables := []string{"merchants", "users"}
	for _, table := range tables {
		_, err := db.Exec("TRUNCATE TABLE " + table + " RESTART IDENTITY CASCADE")
		if err != nil {
			t.Logf("Failed to cleanup table %s: %v", table, err)
		}
	}
}
