package utils

import (
	"fmt"
	"strings"

	"github.com/go-playground/validator/v10"
)

var validate *validator.Validate

func init() {
	validate = validator.New()
}

func ValidateStruct(s interface{}) error {
	err := validate.Struct(s)
	if err != nil {
		// Check if it's a validation error
		if validationErrors, ok := err.(validator.ValidationErrors); ok {
			var errorMessages []string
			for _, err := range validationErrors {
				errorMessages = append(errorMessages, fmt.Sprintf("%s is %s", err.Field(), err.Tag()))
			}
			return fmt.Errorf("validation failed: %s", strings.Join(errorMessages, ", "))
		}
		// Handle other types of validation errors
		return fmt.Errorf("validation failed: %s", err.Error())
	}
	return nil
}
