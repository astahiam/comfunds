package auth

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestJWTManager_Generate(t *testing.T) {
	manager := NewJWTManager("test-secret", time.Hour)
	userID := uuid.New()
	email := "test@example.com"
	roles := []string{"member", "investor"}
	cooperativeID := uuid.New()

	token, err := manager.Generate(userID, email, roles, &cooperativeID)

	assert.NoError(t, err)
	assert.NotEmpty(t, token)
}

func TestJWTManager_Verify(t *testing.T) {
	manager := NewJWTManager("test-secret", time.Hour)
	userID := uuid.New()
	email := "test@example.com"
	roles := []string{"member", "investor"}
	cooperativeID := uuid.New()

	token, err := manager.Generate(userID, email, roles, &cooperativeID)
	assert.NoError(t, err)

	claims, err := manager.Verify(token)
	assert.NoError(t, err)
	assert.Equal(t, userID, claims.UserID)
	assert.Equal(t, email, claims.Email)
	assert.Equal(t, roles, claims.Roles)
	assert.Equal(t, cooperativeID, *claims.CooperativeID)
}

func TestJWTManager_VerifyInvalidToken(t *testing.T) {
	manager := NewJWTManager("test-secret", time.Hour)

	_, err := manager.Verify("invalid-token")
	assert.Error(t, err)
}

func TestJWTManager_VerifyExpiredToken(t *testing.T) {
	manager := NewJWTManager("test-secret", -time.Hour) // Expired token
	userID := uuid.New()
	email := "test@example.com"
	roles := []string{"member"}

	token, err := manager.Generate(userID, email, roles, nil)
	assert.NoError(t, err)

	// Sleep for a moment to ensure token is expired
	time.Sleep(time.Millisecond * 10)

	_, err = manager.Verify(token)
	assert.Error(t, err)
}

func TestJWTManager_GenerateRefreshToken(t *testing.T) {
	manager := NewJWTManager("test-secret", time.Hour)
	userID := uuid.New()

	token, err := manager.GenerateRefreshToken(userID)

	assert.NoError(t, err)
	assert.NotEmpty(t, token)
}

func TestJWTManager_VerifyRefreshToken(t *testing.T) {
	manager := NewJWTManager("test-secret", time.Hour)
	userID := uuid.New()

	token, err := manager.GenerateRefreshToken(userID)
	assert.NoError(t, err)

	verifiedUserID, err := manager.VerifyRefreshToken(token)
	assert.NoError(t, err)
	assert.Equal(t, userID, verifiedUserID)
}

func TestJWTManager_VerifyInvalidRefreshToken(t *testing.T) {
	manager := NewJWTManager("test-secret", time.Hour)

	_, err := manager.VerifyRefreshToken("invalid-refresh-token")
	assert.Error(t, err)
}
