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
				fieldName := err.Field()
				tag := err.Tag()
				param := err.Param()
				
				// Create user-friendly error messages
				var msg string
				switch tag {
				case "required":
					msg = fmt.Sprintf("%s is required", fieldName)
				case "min":
					msg = fmt.Sprintf("%s must be at least %s characters", fieldName, param)
				case "max":
					msg = fmt.Sprintf("%s must be at most %s characters", fieldName, param)
				case "email":
					msg = fmt.Sprintf("%s must be a valid email address", fieldName)
				case "len":
					msg = fmt.Sprintf("%s must be exactly %s characters", fieldName, param)
				case "oneof":
					msg = fmt.Sprintf("%s must be one of: %s", fieldName, param)
				default:
					msg = fmt.Sprintf("%s is invalid (%s)", fieldName, tag)
				}
				errorMessages = append(errorMessages, msg)
			}
			return fmt.Errorf("validation failed: %s", strings.Join(errorMessages, "; "))
		}
		// Handle other types of validation errors
		return fmt.Errorf("validation failed: %s", err.Error())
	}
	return nil
}
