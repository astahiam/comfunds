package utils

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

type TestStruct struct {
	Email    string `validate:"required,email"`
	Name     string `validate:"required,min=2,max=50"`
	Age      int    `validate:"required,min=1,max=120"`
	Password string `validate:"required,min=6"`
}

func TestValidateStruct_ValidData(t *testing.T) {
	validStruct := TestStruct{
		Email:    "test@example.com",
		Name:     "John Doe",
		Age:      25,
		Password: "password123",
	}

	err := ValidateStruct(validStruct)

	assert.NoError(t, err)
}

func TestValidateStruct_MissingRequiredField(t *testing.T) {
	invalidStruct := TestStruct{
		Email:    "test@example.com",
		Name:     "", // Missing required field
		Age:      25,
		Password: "password123",
	}

	err := ValidateStruct(invalidStruct)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "Name is required")
}

func TestValidateStruct_InvalidEmail(t *testing.T) {
	invalidStruct := TestStruct{
		Email:    "invalid-email", // Invalid email format
		Name:     "John Doe",
		Age:      25,
		Password: "password123",
	}

	err := ValidateStruct(invalidStruct)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "Email is email")
}

func TestValidateStruct_MinLengthViolation(t *testing.T) {
	invalidStruct := TestStruct{
		Email:    "test@example.com",
		Name:     "J", // Too short (min=2)
		Age:      25,
		Password: "password123",
	}

	err := ValidateStruct(invalidStruct)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "Name is min")
}

func TestValidateStruct_MaxLengthViolation(t *testing.T) {
	longName := ""
	for i := 0; i < 60; i++ { // Exceed max=50
		longName += "a"
	}

	invalidStruct := TestStruct{
		Email:    "test@example.com",
		Name:     longName,
		Age:      25,
		Password: "password123",
	}

	err := ValidateStruct(invalidStruct)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "Name is max")
}

func TestValidateStruct_NumericMinViolation(t *testing.T) {
	invalidStruct := TestStruct{
		Email:    "test@example.com",
		Name:     "John Doe",
		Age:      0, // Below min=1
		Password: "password123",
	}

	err := ValidateStruct(invalidStruct)

	assert.Error(t, err)
	// For numeric fields with value 0 and min validation, it shows as "required" instead of "min"
	assert.True(t, strings.Contains(err.Error(), "Age is min") || strings.Contains(err.Error(), "Age is required"))
}

func TestValidateStruct_NumericMaxViolation(t *testing.T) {
	invalidStruct := TestStruct{
		Email:    "test@example.com",
		Name:     "John Doe",
		Age:      150, // Above max=120
		Password: "password123",
	}

	err := ValidateStruct(invalidStruct)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "Age is max")
}

func TestValidateStruct_PasswordTooShort(t *testing.T) {
	invalidStruct := TestStruct{
		Email:    "test@example.com",
		Name:     "John Doe",
		Age:      25,
		Password: "123", // Too short (min=6)
	}

	err := ValidateStruct(invalidStruct)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "Password is min")
}

func TestValidateStruct_MultipleErrors(t *testing.T) {
	invalidStruct := TestStruct{
		Email:    "invalid-email", // Invalid email
		Name:     "J",             // Too short
		Age:      0,               // Below minimum
		Password: "123",           // Too short
	}

	err := ValidateStruct(invalidStruct)

	assert.Error(t, err)
	errorMsg := err.Error()
	assert.Contains(t, errorMsg, "Email is email")
	assert.Contains(t, errorMsg, "Name is min")
	// For numeric fields with value 0, it might show as "required" instead of "min"
	assert.True(t, strings.Contains(errorMsg, "Age is min") || strings.Contains(errorMsg, "Age is required"))
	assert.Contains(t, errorMsg, "Password is min")
}

func TestValidateStruct_NilPointer(t *testing.T) {
	err := ValidateStruct(nil)

	assert.Error(t, err)
}
