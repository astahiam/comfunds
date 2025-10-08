package main

import (
	"context"
	"log"
	"os"

	"comfunds/internal/database"
	"comfunds/internal/entities"
	"comfunds/internal/repositories"
	"comfunds/internal/utils"

	"github.com/google/uuid"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	// Initialize shard manager
	shardConfig := database.ShardConfig{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     5432,
		Username: getEnv("DB_USER", "postgres"),
		Password: getEnv("DB_PASSWORD", ""),
		SSLMode:  getEnv("DB_SSLMODE", "disable"),
	}

	shardMgr, err := database.NewShardManager(shardConfig)
	if err != nil {
		log.Fatal("Failed to initialize shard manager:", err)
	}
	defer shardMgr.Close()

	// Initialize repositories
	userRepo := repositories.NewUserRepositorySharded(shardMgr)
	cooperativeRepo := repositories.NewCooperativeRepository(shardMgr)

	ctx := context.Background()

	// Create demo cooperatives first
	cooperatives := []entities.Cooperative{
		{
			ID:                 uuid.MustParse("550e8400-e29b-41d4-a716-446655440001"),
			Name:               "Koperasi Haji",
			RegistrationNumber: "KOP-HAJI-001",
			Address:            "Jl. Haji No. 1, Jakarta",
			Phone:              "+62-21-1234567",
			Email:              "info@koperasihaji.com",
			BankAccount:        "1234567890",
			IsActive:           true,
		},
		{
			ID:                 uuid.MustParse("550e8400-e29b-41d4-a716-446655440002"),
			Name:               "Koperasi SIDANA",
			RegistrationNumber: "KOP-SIDANA-001",
			Address:            "Jl. SIDANA No. 2, Jakarta",
			Phone:              "+62-21-2345678",
			Email:              "info@koperasisidana.com",
			BankAccount:        "0987654321",
			IsActive:           true,
		},
	}

	log.Println("Creating demo cooperatives...")
	for _, coop := range cooperatives {
		_, err := cooperativeRepo.Create(ctx, &coop)
		if err != nil {
			log.Printf("Failed to create cooperative %s: %v", coop.Name, err)
		} else {
			log.Printf("✅ Created cooperative: %s", coop.Name)
		}
	}

	// Create demo users
	demoUsers := []entities.User{
		{
			ID:            uuid.MustParse("123e4567-e89b-12d3-a456-426614174001"),
			Email:         "demo-business@example.com",
			Name:          "Demo Business Owner",
			Password:      hashPassword("Password123!"),
			Phone:         "+6281234567890",
			Address:       "Jl. Demo Business No. 123, Jakarta",
			CooperativeID: &cooperatives[0].ID, // Koperasi Haji
			Roles:         []string{"member", "business_owner", "investor"},
			KYCStatus:     "approved",
			IsActive:      true,
		},
		{
			ID:            uuid.MustParse("123e4567-e89b-12d3-a456-426614174002"),
			Email:         "frontendtest@example.com",
			Name:          "Demo Investor",
			Password:      hashPassword("Password123!"),
			Phone:         "+6281234567891",
			Address:       "Jl. Demo Investor No. 456, Jakarta",
			CooperativeID: &cooperatives[1].ID, // Koperasi SIDANA
			Roles:         []string{"member", "business_owner"},
			KYCStatus:     "approved",
			IsActive:      true,
		},
		{
			ID:            uuid.MustParse("123e4567-e89b-12d3-a456-426614174003"),
			Email:         "member@hajifund.com",
			Name:          "Demo Member",
			Password:      hashPassword("password123"),
			Phone:         "+6281234567892",
			Address:       "Jl. Demo Member No. 789, Jakarta",
			CooperativeID: &cooperatives[0].ID, // Koperasi Haji
			Roles:         []string{"member", "investor"},
			KYCStatus:     "approved",
			IsActive:      true,
		},
		{
			ID:            uuid.MustParse("123e4567-e89b-12d3-a456-426614174004"),
			Email:         "admin@hajifund.com",
			Name:          "Demo Admin",
			Password:      hashPassword("admin123"),
			Phone:         "+6281234567893",
			Address:       "Jl. Demo Admin No. 101, Jakarta",
			CooperativeID: &cooperatives[0].ID, // Koperasi Haji
			Roles:         []string{"member", "admin"},
			KYCStatus:     "approved",
			IsActive:      true,
		},
	}

	log.Println("Creating demo users...")
	for _, user := range demoUsers {
		_, err := userRepo.Create(ctx, &user)
		if err != nil {
			log.Printf("Failed to create user %s: %v", user.Email, err)
		} else {
			log.Printf("✅ Created user: %s (%s)", user.Name, user.Email)
		}
	}

	log.Println("🎉 Demo accounts created successfully!")
	log.Println("\n📋 Demo Account Summary:")
	log.Println("1. Business Owner: demo-business@example.com / Password123!")
	log.Println("2. Investor: frontendtest@example.com / Password123!")
	log.Println("3. Member: member@hajifund.com / password123")
	log.Println("4. Admin: admin@hajifund.com / admin123")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func hashPassword(password string) string {
	hashed, err := utils.HashPassword(password)
	if err != nil {
		log.Fatal("Failed to hash password:", err)
	}
	return hashed
}
