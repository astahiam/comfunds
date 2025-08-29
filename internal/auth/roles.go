package auth

import (
	"errors"
	"fmt"
)

// Role definitions as per PRD FR-006 to FR-010
const (
	RoleGuest         = "guest"
	RoleMember        = "member"
	RoleBusinessOwner = "business_owner"
	RoleInvestor      = "investor"
	RoleAdmin         = "admin" // For cooperative administrators
)

// Permission definitions
const (
	// Project permissions
	PermissionViewPublicProjects     = "view_public_projects"
	PermissionViewCooperativeProjects = "view_cooperative_projects"
	PermissionCreateProject          = "create_project"
	PermissionManageOwnProjects      = "manage_own_projects"
	PermissionApproveProjects        = "approve_projects"
	
	// Investment permissions
	PermissionInvestInProjects       = "invest_in_projects"
	PermissionViewOwnInvestments     = "view_own_investments"
	PermissionViewPortfolio          = "view_portfolio"
	
	// Business permissions
	PermissionCreateBusiness         = "create_business"
	PermissionManageOwnBusiness      = "manage_own_business"
	
	// Cooperative permissions
	PermissionManageCooperative      = "manage_cooperative"
	PermissionViewCooperativeMembers = "view_cooperative_members"
	
	// User permissions
	PermissionManageProfile          = "manage_profile"
	PermissionViewOwnData            = "view_own_data"
)

// RolePermissions maps roles to their allowed permissions
var RolePermissions = map[string][]string{
	RoleGuest: {
		PermissionViewPublicProjects,
	},
	RoleMember: {
		PermissionViewPublicProjects,
		PermissionViewCooperativeProjects,
		PermissionManageProfile,
		PermissionViewOwnData,
	},
	RoleBusinessOwner: {
		PermissionViewPublicProjects,
		PermissionViewCooperativeProjects,
		PermissionCreateProject,
		PermissionManageOwnProjects,
		PermissionCreateBusiness,
		PermissionManageOwnBusiness,
		PermissionManageProfile,
		PermissionViewOwnData,
	},
	RoleInvestor: {
		PermissionViewPublicProjects,
		PermissionViewCooperativeProjects,
		PermissionInvestInProjects,
		PermissionViewOwnInvestments,
		PermissionViewPortfolio,
		PermissionManageProfile,
		PermissionViewOwnData,
	},
	RoleAdmin: {
		PermissionViewPublicProjects,
		PermissionViewCooperativeProjects,
		PermissionApproveProjects,
		PermissionManageCooperative,
		PermissionViewCooperativeMembers,
		PermissionManageProfile,
		PermissionViewOwnData,
	},
}

// ValidRoles contains all valid role names
var ValidRoles = []string{
	RoleGuest,
	RoleMember,
	RoleBusinessOwner,
	RoleInvestor,
	RoleAdmin,
}

// RoleValidator provides role validation and permission checking
type RoleValidator struct{}

// NewRoleValidator creates a new role validator
func NewRoleValidator() *RoleValidator {
	return &RoleValidator{}
}

// ValidateRoles checks if all provided roles are valid
func (rv *RoleValidator) ValidateRoles(roles []string) error {
	if len(roles) == 0 {
		return errors.New("at least one role is required")
	}

	validRoleMap := make(map[string]bool)
	for _, role := range ValidRoles {
		validRoleMap[role] = true
	}

	for _, role := range roles {
		if !validRoleMap[role] {
			return fmt.Errorf("invalid role: %s", role)
		}
	}

	return nil
}

// HasRole checks if a user has a specific role
func (rv *RoleValidator) HasRole(userRoles []string, requiredRole string) bool {
	for _, role := range userRoles {
		if role == requiredRole {
			return true
		}
	}
	return false
}

// HasAnyRole checks if a user has any of the required roles
func (rv *RoleValidator) HasAnyRole(userRoles []string, requiredRoles []string) bool {
	for _, userRole := range userRoles {
		for _, requiredRole := range requiredRoles {
			if userRole == requiredRole {
				return true
			}
		}
	}
	return false
}

// HasPermission checks if a user has a specific permission based on their roles
func (rv *RoleValidator) HasPermission(userRoles []string, requiredPermission string) bool {
	for _, role := range userRoles {
		permissions, exists := RolePermissions[role]
		if !exists {
			continue
		}
		
		for _, permission := range permissions {
			if permission == requiredPermission {
				return true
			}
		}
	}
	return false
}

// GetUserPermissions returns all permissions for a user based on their roles
func (rv *RoleValidator) GetUserPermissions(userRoles []string) []string {
	permissionSet := make(map[string]bool)
	
	for _, role := range userRoles {
		permissions, exists := RolePermissions[role]
		if !exists {
			continue
		}
		
		for _, permission := range permissions {
			permissionSet[permission] = true
		}
	}
	
	var allPermissions []string
	for permission := range permissionSet {
		allPermissions = append(allPermissions, permission)
	}
	
	return allPermissions
}

// CanUserAccessCooperativeData checks if user can access cooperative-specific data
func (rv *RoleValidator) CanUserAccessCooperativeData(userRoles []string) bool {
	// Only members, business owners, investors, and admins can access cooperative data
	allowedRoles := []string{RoleMember, RoleBusinessOwner, RoleInvestor, RoleAdmin}
	return rv.HasAnyRole(userRoles, allowedRoles)
}

// CanUserInvest checks if user can make investments
func (rv *RoleValidator) CanUserInvest(userRoles []string) bool {
	return rv.HasRole(userRoles, RoleInvestor)
}

// CanUserCreateBusiness checks if user can create/manage businesses
func (rv *RoleValidator) CanUserCreateBusiness(userRoles []string) bool {
	return rv.HasRole(userRoles, RoleBusinessOwner)
}

// CanUserCreateProject checks if user can create projects
func (rv *RoleValidator) CanUserCreateProject(userRoles []string) bool {
	return rv.HasRole(userRoles, RoleBusinessOwner)
}

// CanUserApproveProjects checks if user can approve projects
func (rv *RoleValidator) CanUserApproveProjects(userRoles []string) bool {
	return rv.HasRole(userRoles, RoleAdmin)
}

// GetRoleHierarchy returns roles in order of privilege (lowest to highest)
func (rv *RoleValidator) GetRoleHierarchy() []string {
	return []string{
		RoleGuest,
		RoleMember,
		RoleBusinessOwner,
		RoleInvestor,
		RoleAdmin,
	}
}

// RoleDescription provides human-readable descriptions of roles
var RoleDescriptions = map[string]string{
	RoleGuest: "Can view public project information only",
	RoleMember: "Can view all projects within their cooperative",
	RoleBusinessOwner: "Can create and manage their business projects",
	RoleInvestor: "Can invest in approved projects and view portfolio",
	RoleAdmin: "Can manage cooperative and approve projects",
}
