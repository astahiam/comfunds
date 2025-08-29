package services

import (
	"context"
	"fmt"
	"time"

	"comfunds/internal/entities"
	"comfunds/internal/repositories"

	"github.com/google/uuid"
)

type MemberRegistryService interface {
	// FR-022: Cooperative Member Registry Management
	AddMemberToCooperative(ctx context.Context, cooperativeID, userID, adderID uuid.UUID, membershipType string) error
	RemoveMemberFromCooperative(ctx context.Context, cooperativeID, userID, removerID uuid.UUID, reason string) error
	UpdateMemberStatus(ctx context.Context, cooperativeID, userID, updaterID uuid.UUID, status string) error
	UpdateMembershipType(ctx context.Context, cooperativeID, userID, updaterID uuid.UUID, membershipType string) error

	// Member queries
	GetCooperativeMembers(ctx context.Context, cooperativeID uuid.UUID, status string, page, limit int) ([]*entities.User, int, error)
	GetMembershipHistory(ctx context.Context, cooperativeID, userID uuid.UUID) ([]*MembershipHistory, error)
	GetMemberStatistics(ctx context.Context, cooperativeID uuid.UUID) (map[string]interface{}, error)
	SearchMembers(ctx context.Context, cooperativeID uuid.UUID, query string, page, limit int) ([]*entities.User, int, error)

	// Member verification and validation
	VerifyMemberEligibility(ctx context.Context, userID uuid.UUID, cooperativeID uuid.UUID) (bool, []string, error)
	ValidateMembershipRequirements(ctx context.Context, userID uuid.UUID, membershipType string) (bool, []string, error)
	CheckMemberActiveStatus(ctx context.Context, cooperativeID, userID uuid.UUID) (bool, error)

	// Member roles and permissions within cooperative
	AssignMemberRole(ctx context.Context, cooperativeID, userID, assignerID uuid.UUID, role string) error
	RemoveMemberRole(ctx context.Context, cooperativeID, userID, removerID uuid.UUID, role string) error
	GetMemberRoles(ctx context.Context, cooperativeID, userID uuid.UUID) ([]string, error)

	// Member benefits and contributions
	RecordMemberContribution(ctx context.Context, cooperativeID, userID uuid.UUID, contribution *MemberContribution) error
	GetMemberContributions(ctx context.Context, cooperativeID, userID uuid.UUID, startDate, endDate time.Time) ([]*MemberContribution, error)
	CalculateMemberBenefits(ctx context.Context, cooperativeID, userID uuid.UUID, period string) (map[string]interface{}, error)

	// Notifications and communications
	NotifyMemberStatusChange(ctx context.Context, cooperativeID, userID uuid.UUID, oldStatus, newStatus string) error
	SendMembershipWelcome(ctx context.Context, cooperativeID, userID uuid.UUID) error
	SendMembershipReminder(ctx context.Context, cooperativeID uuid.UUID, reminderType string) (int, error)
}

type memberRegistryService struct {
	userRepo        repositories.UserRepositorySharded
	cooperativeRepo repositories.CooperativeRepository
	auditService    AuditService
}

func NewMemberRegistryService(
	userRepo repositories.UserRepositorySharded,
	cooperativeRepo repositories.CooperativeRepository,
	auditService AuditService,
) MemberRegistryService {
	return &memberRegistryService{
		userRepo:        userRepo,
		cooperativeRepo: cooperativeRepo,
		auditService:    auditService,
	}
}

func (s *memberRegistryService) AddMemberToCooperative(ctx context.Context, cooperativeID, userID, adderID uuid.UUID, membershipType string) error {
	// Verify cooperative exists
	_, err := s.cooperativeRepo.GetByID(ctx, cooperativeID)
	if err != nil {
		return fmt.Errorf("cooperative not found: %w", err)
	}

	// Verify user exists
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return fmt.Errorf("user not found: %w", err)
	}

	// Check if user is already a member
	if user.CooperativeID != nil && *user.CooperativeID == cooperativeID {
		return fmt.Errorf("user is already a member of this cooperative")
	}

	// Verify member eligibility
	eligible, violations, err := s.VerifyMemberEligibility(ctx, userID, cooperativeID)
	if err != nil {
		return fmt.Errorf("failed to verify eligibility: %w", err)
	}
	if !eligible {
		return fmt.Errorf("user is not eligible for membership: %v", violations)
	}

	// Update user's cooperative membership
	user.CooperativeID = &cooperativeID

	// Add member role if not already present
	hasMemberRole := false
	for _, role := range user.Roles {
		if role == "member" {
			hasMemberRole = true
			break
		}
	}
	if !hasMemberRole {
		user.Roles = append(user.Roles, "member")
	}

	// Update user in repository
	_, err = s.userRepo.Update(ctx, userID, user)
	if err != nil {
		return fmt.Errorf("failed to update user membership: %w", err)
	}

	// Create membership history entry
	s.createMembershipHistoryEntry(ctx, cooperativeID, userID, adderID, "added", membershipType, "Member added to cooperative")

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityUser,
		EntityID:   userID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     adderID,
		Changes:    map[string]interface{}{"action": "add_to_cooperative", "cooperative_id": cooperativeID, "membership_type": membershipType},
		NewValues:  map[string]interface{}{"cooperative_id": cooperativeID, "roles": user.Roles},
		Status:     entities.AuditStatusSuccess,
	})

	// Send welcome notification
	s.SendMembershipWelcome(ctx, cooperativeID, userID)

	return nil
}

func (s *memberRegistryService) RemoveMemberFromCooperative(ctx context.Context, cooperativeID, userID, removerID uuid.UUID, reason string) error {
	// Verify user exists and is a member
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return fmt.Errorf("user not found: %w", err)
	}

	if user.CooperativeID == nil || *user.CooperativeID != cooperativeID {
		return fmt.Errorf("user is not a member of this cooperative")
	}

	// Store old values for audit
	oldCooperativeID := user.CooperativeID
	oldRoles := make([]string, len(user.Roles))
	copy(oldRoles, user.Roles)

	// Remove cooperative association
	user.CooperativeID = nil

	// Remove member role
	newRoles := []string{}
	for _, role := range user.Roles {
		if role != "member" {
			newRoles = append(newRoles, role)
		}
	}
	user.Roles = newRoles

	// Update user in repository
	_, err = s.userRepo.Update(ctx, userID, user)
	if err != nil {
		return fmt.Errorf("failed to update user membership: %w", err)
	}

	// Create membership history entry
	s.createMembershipHistoryEntry(ctx, cooperativeID, userID, removerID, "removed", "", reason)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityUser,
		EntityID:   userID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     removerID,
		Changes:    map[string]interface{}{"action": "remove_from_cooperative", "reason": reason},
		OldValues:  map[string]interface{}{"cooperative_id": oldCooperativeID, "roles": oldRoles},
		NewValues:  map[string]interface{}{"cooperative_id": nil, "roles": user.Roles},
		Status:     entities.AuditStatusSuccess,
	})

	// Notify about status change
	s.NotifyMemberStatusChange(ctx, cooperativeID, userID, "active", "removed")

	return nil
}

func (s *memberRegistryService) GetCooperativeMembers(ctx context.Context, cooperativeID uuid.UUID, status string, page, limit int) ([]*entities.User, int, error) {
	// Get members from repository
	members, err := s.userRepo.GetByCooperativeID(ctx, cooperativeID, limit, (page-1)*limit)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to get cooperative members: %w", err)
	}

	// Filter by status if specified
	if status != "" {
		filteredMembers := []*entities.User{}
		for _, member := range members {
			// In real implementation, check member status from membership table
			// For now, assume all active members
			if status == "active" && member.IsActive {
				filteredMembers = append(filteredMembers, member)
			}
		}
		members = filteredMembers
	}

	return members, len(members), nil
}

func (s *memberRegistryService) GetMemberStatistics(ctx context.Context, cooperativeID uuid.UUID) (map[string]interface{}, error) {
	// Get all members
	members, _, err := s.GetCooperativeMembers(ctx, cooperativeID, "", 1, 1000)
	if err != nil {
		return nil, err
	}

	// Calculate statistics
	stats := map[string]interface{}{
		"total_members":    len(members),
		"active_members":   0,
		"inactive_members": 0,
		"roles": map[string]int{
			"member":         0,
			"business_owner": 0,
			"investor":       0,
			"admin":          0,
		},
		"membership_duration": map[string]int{
			"new":     0, // < 3 months
			"regular": 0, // 3-12 months
			"veteran": 0, // > 12 months
		},
		"kyc_status": map[string]int{
			"pending":  0,
			"verified": 0,
			"rejected": 0,
		},
	}

	for _, member := range members {
		// Count active/inactive
		if member.IsActive {
			stats["active_members"] = stats["active_members"].(int) + 1
		} else {
			stats["inactive_members"] = stats["inactive_members"].(int) + 1
		}

		// Count roles
		rolesMap := stats["roles"].(map[string]int)
		for _, role := range member.Roles {
			if count, exists := rolesMap[role]; exists {
				rolesMap[role] = count + 1
			}
		}

		// Count KYC status
		kycMap := stats["kyc_status"].(map[string]int)
		if count, exists := kycMap[member.KYCStatus]; exists {
			kycMap[member.KYCStatus] = count + 1
		}

		// Calculate membership duration (mock)
		// In real implementation, get from membership history
		membershipDuration := stats["membership_duration"].(map[string]int)
		membershipDuration["regular"]++
	}

	return stats, nil
}

func (s *memberRegistryService) VerifyMemberEligibility(ctx context.Context, userID uuid.UUID, cooperativeID uuid.UUID) (bool, []string, error) {
	var violations []string

	// Get user
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return false, violations, err
	}

	// Check basic requirements
	if !user.IsActive {
		violations = append(violations, "User account is not active")
	}

	if user.KYCStatus != "verified" {
		violations = append(violations, "User KYC verification is required")
	}

	// Check if user is already a member of another cooperative
	if user.CooperativeID != nil && *user.CooperativeID != cooperativeID {
		violations = append(violations, "User is already a member of another cooperative")
	}

	// Additional checks could include:
	// - Age requirements
	// - Geographic restrictions
	// - Professional requirements
	// - Financial standing

	return len(violations) == 0, violations, nil
}

func (s *memberRegistryService) ValidateMembershipRequirements(ctx context.Context, userID uuid.UUID, membershipType string) (bool, []string, error) {
	var violations []string

	// Define requirements for different membership types
	requirements := map[string][]string{
		"basic":     {"kyc_verified", "active_account"},
		"premium":   {"kyc_verified", "active_account", "min_investment_history"},
		"corporate": {"kyc_verified", "active_account", "business_registration"},
	}

	membershipReqs, exists := requirements[membershipType]
	if !exists {
		violations = append(violations, "Invalid membership type")
		return false, violations, nil
	}

	// Check each requirement
	for _, req := range membershipReqs {
		switch req {
		case "kyc_verified":
			// Check KYC status
		case "active_account":
			// Check account status
		case "min_investment_history":
			// Check investment history
		case "business_registration":
			// Check business registration
		}
	}

	return len(violations) == 0, violations, nil
}

func (s *memberRegistryService) CheckMemberActiveStatus(ctx context.Context, cooperativeID, userID uuid.UUID) (bool, error) {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return false, err
	}

	if user.CooperativeID == nil || *user.CooperativeID != cooperativeID {
		return false, nil
	}

	return user.IsActive, nil
}

// Mock implementations for remaining interface methods
func (s *memberRegistryService) UpdateMemberStatus(ctx context.Context, cooperativeID, userID, updaterID uuid.UUID, status string) error {
	return fmt.Errorf("not implemented - requires membership status table")
}

func (s *memberRegistryService) UpdateMembershipType(ctx context.Context, cooperativeID, userID, updaterID uuid.UUID, membershipType string) error {
	return fmt.Errorf("not implemented - requires membership table")
}

func (s *memberRegistryService) GetMembershipHistory(ctx context.Context, cooperativeID, userID uuid.UUID) ([]*MembershipHistory, error) {
	return []*MembershipHistory{}, nil
}

func (s *memberRegistryService) SearchMembers(ctx context.Context, cooperativeID uuid.UUID, query string, page, limit int) ([]*entities.User, int, error) {
	return []*entities.User{}, 0, nil
}

func (s *memberRegistryService) AssignMemberRole(ctx context.Context, cooperativeID, userID, assignerID uuid.UUID, role string) error {
	return fmt.Errorf("not implemented - requires role management")
}

func (s *memberRegistryService) RemoveMemberRole(ctx context.Context, cooperativeID, userID, removerID uuid.UUID, role string) error {
	return fmt.Errorf("not implemented - requires role management")
}

func (s *memberRegistryService) GetMemberRoles(ctx context.Context, cooperativeID, userID uuid.UUID) ([]string, error) {
	return []string{}, nil
}

func (s *memberRegistryService) RecordMemberContribution(ctx context.Context, cooperativeID, userID uuid.UUID, contribution *MemberContribution) error {
	return fmt.Errorf("not implemented - requires contribution tracking")
}

func (s *memberRegistryService) GetMemberContributions(ctx context.Context, cooperativeID, userID uuid.UUID, startDate, endDate time.Time) ([]*MemberContribution, error) {
	return []*MemberContribution{}, nil
}

func (s *memberRegistryService) CalculateMemberBenefits(ctx context.Context, cooperativeID, userID uuid.UUID, period string) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (s *memberRegistryService) NotifyMemberStatusChange(ctx context.Context, cooperativeID, userID uuid.UUID, oldStatus, newStatus string) error {
	// Mock notification
	return nil
}

func (s *memberRegistryService) SendMembershipWelcome(ctx context.Context, cooperativeID, userID uuid.UUID) error {
	// Mock welcome notification
	return nil
}

func (s *memberRegistryService) SendMembershipReminder(ctx context.Context, cooperativeID uuid.UUID, reminderType string) (int, error) {
	return 0, nil
}

// Helper methods
func (s *memberRegistryService) createMembershipHistoryEntry(ctx context.Context, cooperativeID, userID, actionByID uuid.UUID, action, membershipType, notes string) {
	// In real implementation, create membership history entry
	history := map[string]interface{}{
		"cooperative_id":  cooperativeID,
		"user_id":         userID,
		"action":          action,
		"membership_type": membershipType,
		"action_by":       actionByID,
		"notes":           notes,
		"timestamp":       time.Now(),
	}

	// Log as audit entry for now
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: "membership_history",
		EntityID:   userID,
		Operation:  entities.AuditOperationCreate,
		UserID:     actionByID,
		Changes:    history,
		Status:     entities.AuditStatusSuccess,
	})
}

// Additional entity definitions that would be in separate files
type MembershipHistory struct {
	ID             uuid.UUID `json:"id" db:"id"`
	CooperativeID  uuid.UUID `json:"cooperative_id" db:"cooperative_id"`
	UserID         uuid.UUID `json:"user_id" db:"user_id"`
	Action         string    `json:"action" db:"action"` // added, removed, status_changed, role_assigned
	MembershipType string    `json:"membership_type" db:"membership_type"`
	OldStatus      string    `json:"old_status" db:"old_status"`
	NewStatus      string    `json:"new_status" db:"new_status"`
	ActionBy       uuid.UUID `json:"action_by" db:"action_by"`
	Notes          string    `json:"notes" db:"notes"`
	Timestamp      time.Time `json:"timestamp" db:"timestamp"`
}

type MemberContribution struct {
	ID               uuid.UUID `json:"id" db:"id"`
	CooperativeID    uuid.UUID `json:"cooperative_id" db:"cooperative_id"`
	UserID           uuid.UUID `json:"user_id" db:"user_id"`
	ContributionType string    `json:"contribution_type" db:"contribution_type"` // financial, volunteer, expertise
	Amount           float64   `json:"amount" db:"amount"`
	Currency         string    `json:"currency" db:"currency"`
	Description      string    `json:"description" db:"description"`
	Date             time.Time `json:"date" db:"date"`
	CreatedAt        time.Time `json:"created_at" db:"created_at"`
}
