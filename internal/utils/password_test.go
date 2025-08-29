package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHashPassword(t *testing.T) {
	password := "testpassword123"
	
	hashedPassword, err := HashPassword(password)
	
	assert.NoError(t, err)
	assert.NotEmpty(t, hashedPassword)
	assert.NotEqual(t, password, hashedPassword)
}

func TestCheckPassword_ValidPassword(t *testing.T) {
	password := "testpassword123"
	hashedPassword, err := HashPassword(password)
	assert.NoError(t, err)
	
	err = CheckPassword(hashedPassword, password)
	assert.NoError(t, err)
}

func TestCheckPassword_InvalidPassword(t *testing.T) {
	password := "testpassword123"
	wrongPassword := "wrongpassword"
	hashedPassword, err := HashPassword(password)
	assert.NoError(t, err)
	
	err = CheckPassword(hashedPassword, wrongPassword)
	assert.Error(t, err)
}

func TestCheckPassword_EmptyPassword(t *testing.T) {
	password := "testpassword123"
	hashedPassword, err := HashPassword(password)
	assert.NoError(t, err)
	
	err = CheckPassword(hashedPassword, "")
	assert.Error(t, err)
}