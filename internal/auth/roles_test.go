package auth

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestRoleValidator_ValidateRoles(t *testing.T) {
	rv := NewRoleValidator()

	tests := []struct {
		name        string
		roles       []string
		expectError bool
		description string
	}{
		{
			name:        "Valid single role",
			roles:       []string{RoleGuest},
			expectError: false,
			description: "Should accept valid single role",
		},
		{
			name:        "Valid multiple roles",
			roles:       []string{RoleMember, RoleInvestor},
			expectError: false,
			description: "Should accept multiple valid roles",
		},
		{
			name:        "Invalid role",
			roles:       []string{"invalid_role"},
			expectError: true,
			description: "Should reject invalid role",
		},
		{
			name:        "Empty roles",
			roles:       []string{},
			expectError: true,
			description: "Should reject empty roles array",
		},
		{
			name:        "Mixed valid and invalid roles",
			roles:       []string{RoleGuest, "invalid_role"},
			expectError: true,
			description: "Should reject if any role is invalid",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := rv.ValidateRoles(tt.roles)
			if tt.expectError {
				assert.Error(t, err, tt.description)
			} else {
				assert.NoError(t, err, tt.description)
			}
		})
	}
}

func TestRoleValidator_HasRole(t *testing.T) {
	rv := NewRoleValidator()

	userRoles := []string{RoleMember, RoleInvestor}

	tests := []struct {
		name         string
		requiredRole string
		expected     bool
		description  string
	}{
		{
			name:         "User has required role",
			requiredRole: RoleInvestor,
			expected:     true,
			description:  "Should return true when user has the role",
		},
		{
			name:         "User doesn't have required role",
			requiredRole: RoleBusinessOwner,
			expected:     false,
			description:  "Should return false when user doesn't have the role",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := rv.HasRole(userRoles, tt.requiredRole)
			assert.Equal(t, tt.expected, result, tt.description)
		})
	}
}

func TestRoleValidator_HasAnyRole(t *testing.T) {
	rv := NewRoleValidator()

	userRoles := []string{RoleMember, RoleInvestor}

	tests := []struct {
		name          string
		requiredRoles []string
		expected      bool
		description   string
	}{
		{
			name:          "User has one of the required roles",
			requiredRoles: []string{RoleBusinessOwner, RoleInvestor},
			expected:      true,
			description:   "Should return true when user has any of the required roles",
		},
		{
			name:          "User has none of the required roles",
			requiredRoles: []string{RoleBusinessOwner, RoleAdmin},
			expected:      false,
			description:   "Should return false when user has none of the required roles",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := rv.HasAnyRole(userRoles, tt.requiredRoles)
			assert.Equal(t, tt.expected, result, tt.description)
		})
	}
}

func TestRoleValidator_HasPermission(t *testing.T) {
	rv := NewRoleValidator()

	tests := []struct {
		name               string
		userRoles          []string
		requiredPermission string
		expected           bool
		description        string
	}{
		{
			name:               "Guest can view public projects",
			userRoles:          []string{RoleGuest},
			requiredPermission: PermissionViewPublicProjects,
			expected:           true,
			description:        "Guest should be able to view public projects",
		},
		{
			name:               "Member can view cooperative projects",
			userRoles:          []string{RoleMember},
			requiredPermission: PermissionViewCooperativeProjects,
			expected:           true,
			description:        "Member should be able to view cooperative projects",
		},
		{
			name:               "Guest cannot create projects",
			userRoles:          []string{RoleGuest},
			requiredPermission: PermissionCreateProject,
			expected:           false,
			description:        "Guest should not be able to create projects",
		},
		{
			name:               "Business owner can create projects",
			userRoles:          []string{RoleBusinessOwner},
			requiredPermission: PermissionCreateProject,
			expected:           true,
			description:        "Business owner should be able to create projects",
		},
		{
			name:               "Investor can invest",
			userRoles:          []string{RoleInvestor},
			requiredPermission: PermissionInvestInProjects,
			expected:           true,
			description:        "Investor should be able to invest in projects",
		},
		{
			name:               "Multiple roles - has permission",
			userRoles:          []string{RoleMember, RoleInvestor},
			requiredPermission: PermissionInvestInProjects,
			expected:           true,
			description:        "User with multiple roles should have permissions from all roles",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := rv.HasPermission(tt.userRoles, tt.requiredPermission)
			assert.Equal(t, tt.expected, result, tt.description)
		})
	}
}

func TestRoleValidator_GetUserPermissions(t *testing.T) {
	rv := NewRoleValidator()

	tests := []struct {
		name               string
		userRoles          []string
		expectedToContain  []string
		expectedNotContain []string
		description        string
	}{
		{
			name:               "Guest permissions",
			userRoles:          []string{RoleGuest},
			expectedToContain:  []string{PermissionViewPublicProjects},
			expectedNotContain: []string{PermissionCreateProject, PermissionInvestInProjects},
			description:        "Guest should only have basic viewing permissions",
		},
		{
			name:      "Multiple roles permissions",
			userRoles: []string{RoleMember, RoleInvestor},
			expectedToContain: []string{
				PermissionViewPublicProjects,
				PermissionViewCooperativeProjects,
				PermissionInvestInProjects,
				PermissionViewPortfolio,
			},
			expectedNotContain: []string{PermissionCreateProject, PermissionApproveProjects},
			description:        "User with multiple roles should have combined permissions",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			permissions := rv.GetUserPermissions(tt.userRoles)

			for _, expectedPerm := range tt.expectedToContain {
				assert.Contains(t, permissions, expectedPerm, "Should contain permission: %s", expectedPerm)
			}

			for _, notExpectedPerm := range tt.expectedNotContain {
				assert.NotContains(t, permissions, notExpectedPerm, "Should not contain permission: %s", notExpectedPerm)
			}
		})
	}
}

func TestRoleValidator_CanUserAccessCooperativeData(t *testing.T) {
	rv := NewRoleValidator()

	tests := []struct {
		name        string
		userRoles   []string
		expected    bool
		description string
	}{
		{
			name:        "Guest cannot access cooperative data",
			userRoles:   []string{RoleGuest},
			expected:    false,
			description: "Guest users should not access cooperative data",
		},
		{
			name:        "Member can access cooperative data",
			userRoles:   []string{RoleMember},
			expected:    true,
			description: "Cooperative members should access cooperative data",
		},
		{
			name:        "Business owner can access cooperative data",
			userRoles:   []string{RoleBusinessOwner},
			expected:    true,
			description: "Business owners should access cooperative data",
		},
		{
			name:        "Investor can access cooperative data",
			userRoles:   []string{RoleInvestor},
			expected:    true,
			description: "Investors should access cooperative data",
		},
		{
			name:        "Admin can access cooperative data",
			userRoles:   []string{RoleAdmin},
			expected:    true,
			description: "Admins should access cooperative data",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := rv.CanUserAccessCooperativeData(tt.userRoles)
			assert.Equal(t, tt.expected, result, tt.description)
		})
	}
}

func TestRoleValidator_SpecificRoleChecks(t *testing.T) {
	rv := NewRoleValidator()

	// Test CanUserInvest
	assert.True(t, rv.CanUserInvest([]string{RoleInvestor}))
	assert.False(t, rv.CanUserInvest([]string{RoleGuest}))

	// Test CanUserCreateBusiness
	assert.True(t, rv.CanUserCreateBusiness([]string{RoleBusinessOwner}))
	assert.False(t, rv.CanUserCreateBusiness([]string{RoleMember}))

	// Test CanUserCreateProject
	assert.True(t, rv.CanUserCreateProject([]string{RoleBusinessOwner}))
	assert.False(t, rv.CanUserCreateProject([]string{RoleInvestor}))

	// Test CanUserApproveProjects
	assert.True(t, rv.CanUserApproveProjects([]string{RoleAdmin}))
	assert.False(t, rv.CanUserApproveProjects([]string{RoleBusinessOwner}))
}

func TestRolePermissions_Completeness(t *testing.T) {
	// Ensure all roles have permissions defined
	for _, role := range ValidRoles {
		permissions, exists := RolePermissions[role]
		assert.True(t, exists, "Role %s should have permissions defined", role)
		assert.NotEmpty(t, permissions, "Role %s should have at least one permission", role)
	}

	// Ensure all roles have descriptions
	for _, role := range ValidRoles {
		description, exists := RoleDescriptions[role]
		assert.True(t, exists, "Role %s should have description defined", role)
		assert.NotEmpty(t, description, "Role %s should have non-empty description", role)
	}
}

func TestRoleHierarchy(t *testing.T) {
	rv := NewRoleValidator()
	hierarchy := rv.GetRoleHierarchy()

	expectedHierarchy := []string{RoleGuest, RoleMember, RoleBusinessOwner, RoleInvestor, RoleAdmin}
	assert.Equal(t, expectedHierarchy, hierarchy, "Role hierarchy should be in correct order")
}
