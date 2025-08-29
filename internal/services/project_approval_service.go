package services

import (
	"context"
	"fmt"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
)

type ProjectApprovalService interface {
	// FR-020: Project Approval/Rejection
	SubmitProjectForApproval(ctx context.Context, req *entities.SubmitProjectApprovalRequest, submitterID uuid.UUID) (*entities.ProjectApproval, error)
	ReviewProjectApproval(ctx context.Context, approvalID uuid.UUID, req *entities.ReviewProjectApprovalRequest, reviewerID uuid.UUID) (*entities.ProjectApproval, error)
	UpdateProjectApproval(ctx context.Context, approvalID uuid.UUID, req *entities.UpdateProjectApprovalRequest, updaterID uuid.UUID) (*entities.ProjectApproval, error)
	WithdrawProjectApproval(ctx context.Context, approvalID, submitterID uuid.UUID) error

	// Query and reporting
	GetProjectApproval(ctx context.Context, approvalID uuid.UUID) (*entities.ProjectApproval, error)
	GetProjectApprovals(ctx context.Context, filter *entities.ProjectApprovalFilter) ([]*entities.ProjectApproval, int, error)
	GetPendingApprovals(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.ProjectApproval, int, error)
	GetApprovalHistory(ctx context.Context, approvalID uuid.UUID) ([]*entities.ProjectApprovalHistory, error)

	// Committee and voting
	SubmitCommitteeVote(ctx context.Context, approvalID, memberID uuid.UUID, vote string, comments string) error
	GetCommitteeVotes(ctx context.Context, approvalID uuid.UUID) ([]entities.CommitteeVote, error)
	CalculateApprovalScore(ctx context.Context, approvalID uuid.UUID) (*entities.EvaluationCriteria, error)

	// Notifications and deadlines
	GetExpiringApprovals(ctx context.Context, cooperativeID uuid.UUID, days int) ([]*entities.ProjectApproval, error)
	SendApprovalNotifications(ctx context.Context, approvalID uuid.UUID) error
}

type projectApprovalService struct {
	auditService AuditService
}

func NewProjectApprovalService(auditService AuditService) ProjectApprovalService {
	return &projectApprovalService{
		auditService: auditService,
	}
}

func (s *projectApprovalService) SubmitProjectForApproval(ctx context.Context, req *entities.SubmitProjectApprovalRequest, submitterID uuid.UUID) (*entities.ProjectApproval, error) {
	// Validate project exists and submitter is authorized
	// project, err := s.projectRepo.GetByID(ctx, req.ProjectID)

	approval := &entities.ProjectApproval{
		ID:              uuid.New(),
		ProjectID:       req.ProjectID,
		CooperativeID:   uuid.New(), // Would get from project
		SubmittedBy:     submitterID,
		Status:          entities.ApprovalStatusPending,
		Priority:        req.Priority,
		SubmissionNotes: req.SubmissionNotes,
		Documents:       req.Documents,
		SubmittedAt:     time.Now(),
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	// Set due date based on priority
	dueDate := s.calculateDueDate(req.Priority, req.RequestedDate)
	approval.DueDate = &dueDate

	// In real implementation, save to repository
	// createdApproval, err := s.approvalRepo.Create(ctx, approval)

	// Create history entry
	s.createHistoryEntry(ctx, approval.ID, submitterID, "", entities.ApprovalStatusPending, "Project submitted for approval", req.Metadata)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   req.ProjectID,
		Operation:  entities.AuditOperationCreate,
		UserID:     submitterID,
		Changes:    map[string]interface{}{"action": "submit_for_approval", "approval_id": approval.ID},
		NewValues:  approval,
		Status:     entities.AuditStatusSuccess,
	})

	return approval, nil
}

func (s *projectApprovalService) ReviewProjectApproval(ctx context.Context, approvalID uuid.UUID, req *entities.ReviewProjectApprovalRequest, reviewerID uuid.UUID) (*entities.ProjectApproval, error) {
	// Get existing approval
	// approval, err := s.approvalRepo.GetByID(ctx, approvalID)

	// Mock approval for demonstration
	approval := &entities.ProjectApproval{
		ID:        approvalID,
		Status:    entities.ApprovalStatusUnderReview,
		UpdatedAt: time.Now(),
	}

	// Validate status transition
	if !s.isValidStatusTransition(approval.Status, req.Status) {
		return nil, fmt.Errorf("invalid status transition from %s to %s", approval.Status, req.Status)
	}

	// Update approval
	oldStatus := approval.Status
	approval.Status = req.Status
	approval.ReviewedBy = &reviewerID
	approval.ReviewNotes = req.ReviewNotes
	approval.ApprovalComments = req.ApprovalComments
	approval.RejectionReason = req.RejectionReason
	approval.RequiredChanges = req.RequiredChanges
	approval.Criteria = req.Criteria
	approval.CommitteeVotes = req.CommitteeVotes
	approval.DueDate = req.DueDate
	approval.UpdatedAt = time.Now()

	// Set review timestamps
	now := time.Now()
	if approval.ReviewStartedAt == nil && req.Status == entities.ApprovalStatusUnderReview {
		approval.ReviewStartedAt = &now
	}
	if req.Status == entities.ApprovalStatusApproved || req.Status == entities.ApprovalStatusRejected {
		approval.ReviewedAt = &now
	}

	// In real implementation, update repository
	// updatedApproval, err := s.approvalRepo.Update(ctx, approvalID, approval)

	// Create history entry
	s.createHistoryEntry(ctx, approvalID, reviewerID, oldStatus, req.Status, req.ReviewNotes, req.Criteria)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   approval.ProjectID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     reviewerID,
		Changes:    map[string]interface{}{"action": "review_approval", "old_status": oldStatus, "new_status": req.Status},
		OldValues:  map[string]interface{}{"status": oldStatus},
		NewValues:  approval,
		Status:     entities.AuditStatusSuccess,
	})

	return approval, nil
}

func (s *projectApprovalService) SubmitCommitteeVote(ctx context.Context, approvalID, memberID uuid.UUID, vote string, comments string) error {
	// Validate vote value
	if vote != "approve" && vote != "reject" && vote != "abstain" {
		return fmt.Errorf("invalid vote value: %s", vote)
	}

	// Get approval
	// approval, err := s.approvalRepo.GetByID(ctx, approvalID)

	// Add vote to committee votes
	_ = entities.CommitteeVote{
		MemberID: memberID,
		Vote:     vote,
		Comments: comments,
		VotedAt:  time.Now(),
		Weight:   1.0, // Default weight
	}

	// In real implementation, update the approval's committee_votes JSONB field
	// s.approvalRepo.AddCommitteeVote(ctx, approvalID, voteData)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   approvalID, // Using approval ID as entity ID
		Operation:  entities.AuditOperationUpdate,
		UserID:     memberID,
		Changes:    map[string]interface{}{"action": "committee_vote", "vote": vote, "comments": comments},
		Status:     entities.AuditStatusSuccess,
	})

	return nil
}

func (s *projectApprovalService) CalculateApprovalScore(ctx context.Context, approvalID uuid.UUID) (*entities.EvaluationCriteria, error) {
	// Get approval with criteria
	// approval, err := s.approvalRepo.GetByID(ctx, approvalID)

	// Mock evaluation criteria calculation
	criteria := &entities.EvaluationCriteria{
		FinancialViability:  8.5,
		MarketPotential:     7.8,
		TeamCapability:      8.0,
		ShariaCompliance:    9.2,
		RiskAssessment:      7.5,
		SocialImpact:        8.8,
		EnvironmentalImpact: 7.0,
		Innovation:          6.5,
	}

	// Calculate overall score (weighted average)
	criteria.OverallScore = (criteria.FinancialViability + criteria.MarketPotential +
		criteria.TeamCapability + criteria.ShariaCompliance + criteria.RiskAssessment +
		criteria.SocialImpact + criteria.EnvironmentalImpact + criteria.Innovation) / 8.0

	// Determine recommendation
	if criteria.OverallScore >= 8.0 {
		criteria.Recommendation = "approve"
	} else if criteria.OverallScore >= 6.0 {
		criteria.Recommendation = "conditional"
	} else {
		criteria.Recommendation = "reject"
	}

	return criteria, nil
}

func (s *projectApprovalService) GetExpiringApprovals(ctx context.Context, cooperativeID uuid.UUID, days int) ([]*entities.ProjectApproval, error) {
	// Calculate expiry date threshold
	_ = time.Now().AddDate(0, 0, days)

	// In real implementation, query repository
	// return s.approvalRepo.GetExpiringApprovals(ctx, cooperativeID, threshold)

	return []*entities.ProjectApproval{}, nil
}

// Mock implementations for interface compliance
func (s *projectApprovalService) UpdateProjectApproval(ctx context.Context, approvalID uuid.UUID, req *entities.UpdateProjectApprovalRequest, updaterID uuid.UUID) (*entities.ProjectApproval, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *projectApprovalService) WithdrawProjectApproval(ctx context.Context, approvalID, submitterID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectApprovalService) GetProjectApproval(ctx context.Context, approvalID uuid.UUID) (*entities.ProjectApproval, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *projectApprovalService) GetProjectApprovals(ctx context.Context, filter *entities.ProjectApprovalFilter) ([]*entities.ProjectApproval, int, error) {
	return []*entities.ProjectApproval{}, 0, nil
}

func (s *projectApprovalService) GetPendingApprovals(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.ProjectApproval, int, error) {
	return []*entities.ProjectApproval{}, 0, nil
}

func (s *projectApprovalService) GetApprovalHistory(ctx context.Context, approvalID uuid.UUID) ([]*entities.ProjectApprovalHistory, error) {
	return []*entities.ProjectApprovalHistory{}, nil
}

func (s *projectApprovalService) GetCommitteeVotes(ctx context.Context, approvalID uuid.UUID) ([]entities.CommitteeVote, error) {
	return []entities.CommitteeVote{}, nil
}

func (s *projectApprovalService) SendApprovalNotifications(ctx context.Context, approvalID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires notification service")
}

// Helper methods
func (s *projectApprovalService) calculateDueDate(priority string, requestedDate *time.Time) time.Time {
	if requestedDate != nil {
		return *requestedDate
	}

	now := time.Now()
	switch priority {
	case entities.ApprovalPriorityUrgent:
		return now.AddDate(0, 0, 3) // 3 days
	case entities.ApprovalPriorityHigh:
		return now.AddDate(0, 0, 7) // 1 week
	case entities.ApprovalPriorityMedium:
		return now.AddDate(0, 0, 14) // 2 weeks
	default: // low
		return now.AddDate(0, 0, 30) // 1 month
	}
}

func (s *projectApprovalService) isValidStatusTransition(currentStatus, newStatus string) bool {
	validTransitions := map[string][]string{
		entities.ApprovalStatusPending:          {entities.ApprovalStatusUnderReview, entities.ApprovalStatusWithdrawn},
		entities.ApprovalStatusUnderReview:      {entities.ApprovalStatusApproved, entities.ApprovalStatusRejected, entities.ApprovalStatusRevisionRequired},
		entities.ApprovalStatusRevisionRequired: {entities.ApprovalStatusPending, entities.ApprovalStatusWithdrawn},
	}

	allowedStatuses, exists := validTransitions[currentStatus]
	if !exists {
		return false
	}

	for _, status := range allowedStatuses {
		if status == newStatus {
			return true
		}
	}

	return false
}

func (s *projectApprovalService) createHistoryEntry(ctx context.Context, approvalID, userID uuid.UUID, oldStatus, newStatus, comments string, changes interface{}) {
	history := &entities.ProjectApprovalHistory{
		ID:         uuid.New(),
		ApprovalID: approvalID,
		ChangedBy:  userID,
		OldStatus:  oldStatus,
		NewStatus:  newStatus,
		Comments:   comments,
		Timestamp:  time.Now(),
	}

	if changes != nil {
		if changesMap, ok := changes.(map[string]interface{}); ok {
			history.Changes = changesMap
		}
	}

	// In real implementation, save to repository
	// s.historyRepo.Create(ctx, history)
}
