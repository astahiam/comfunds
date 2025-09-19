package utils

// HasRole checks if user has the required role
func HasRole(userRoles []string, requiredRole string) bool {
	for _, role := range userRoles {
		if role == requiredRole {
			return true
		}
	}
	return false
}
