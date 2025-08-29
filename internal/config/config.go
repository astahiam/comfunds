package config

import "os"

type Config struct {
	DatabaseURL string
	Port        string
	Environment string
	JWTSecret   string
}

func Load() *Config {
	return &Config{
		DatabaseURL: getEnv("DATABASE_URL", ""),
		Port:        getEnv("PORT", "8080"),
		Environment: getEnv("ENVIRONMENT", "development"),
		JWTSecret:   getEnv("JWT_SECRET", "your-super-secret-jwt-key"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}