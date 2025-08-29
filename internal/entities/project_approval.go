package entities

import (
	"time"

	"github.com/google/uuid"
)

// ProjectApproval represents the approval workflow for projects (FR-020)
type ProjectApproval struct {
	ID               uuid.UUID              `json:"id" db:"id"`
	ProjectID        uuid.UUID              `json:"project_id" db:"project_id"`
	CooperativeID    uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	SubmittedBy      uuid.UUID              `json:"submitted_by" db:"submitted_by"`      // Business Owner
	ReviewedBy       *uuid.UUID             `json:"reviewed_by" db:"reviewed_by"`       // Admin/Committee Member
	Status           string                 `json:"status" db:"status"`                 // pending, under_review, approved, rejected, revision_required
	Priority         string                 `json:"priority" db:"priority"`             // low, medium, high, urgent
	SubmissionNotes  string                 `json:"submission_notes" db:"submission_notes"`
	ReviewNotes      string                 `json:"review_notes" db:"review_notes"`
	ApprovalComments string                 `json:"approval_comments" db:"approval_comments"`
	RejectionReason  string                 `json:"rejection_reason" db:"rejection_reason"`
	RequiredChanges  string                 `json:"required_changes" db:"required_changes"`
	Documents        []string               `json:"documents" db:"documents"`           // Document URLs/IDs
	Criteria         map[string]interface{} `json:"criteria" db:"criteria"`             // Evaluation criteria scores
	CommitteeVotes   map[string]interface{} `json:"committee_votes" db:"committee_votes"` // Committee member votes
	DueDate          *time.Time             `json:"due_date" db:"due_date"`
	SubmittedAt      time.Time              `json:"submitted_at" db:"submitted_at"`
	ReviewStartedAt  *time.Time             `json:"review_started_at" db:"review_started_at"`
	ReviewedAt       *time.Time             `json:"reviewed_at" db:"reviewed_at"`
	CreatedAt        time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time              `json:"updated_at" db:"updated_at"`
}

// ProjectApprovalHistory tracks all changes in approval process
type ProjectApprovalHistory struct {
	ID           uuid.UUID              `json:"id" db:"id"`
	ApprovalID   uuid.UUID              `json:"approval_id" db:"approval_id"`
	ChangedBy    uuid.UUID              `json:"changed_by" db:"changed_by"`
	OldStatus    string                 `json:"old_status" db:"old_status"`
	NewStatus    string                 `json:"new_status" db:"new_status"`
	Comments     string                 `json:"comments" db:"comments"`
	Changes      map[string]interface{} `json:"changes" db:"changes"`
	Timestamp    time.Time              `json:"timestamp" db:"timestamp"`
	IPAddress    string                 `json:"ip_address" db:"ip_address"`
	UserAgent    string                 `json:"user_agent" db:"user_agent"`
}

// ProjectApprovalConstants
const (
	ApprovalStatusPending          = "pending"
	ApprovalStatusUnderReview      = "under_review"
	ApprovalStatusApproved         = "approved"
	ApprovalStatusRejected         = "rejected"
	ApprovalStatusRevisionRequired = "revision_required"
	ApprovalStatusWithdrawn        = "withdrawn"
	ApprovalStatusExpired          = "expired"

	ApprovalPriorityLow    = "low"
	ApprovalPriorityMedium = "medium"
	ApprovalPriorityHigh   = "high"
	ApprovalPriorityUrgent = "urgent"
)

// SubmitProjectApprovalRequest for FR-020
type SubmitProjectApprovalRequest struct {
	ProjectID       uuid.UUID              `json:"project_id" validate:"required"`
	SubmissionNotes string                 `json:"submission_notes" validate:"max=1000"`
	Documents       []string               `json:"documents"`
	Priority        string                 `json:"priority" validate:"oneof=low medium high urgent"`
	RequestedDate   *time.Time             `json:"requested_date"`
	Metadata        map[string]interface{} `json:"metadata"`
}

// ReviewProjectApprovalRequest for FR-020
type ReviewProjectApprovalRequest struct {
	Status           string                 `json:"status" validate:"required,oneof=under_review approved rejected revision_required"`
	ReviewNotes      string                 `json:"review_notes" validate:"max=1000"`
	ApprovalComments string                 `json:"approval_comments" validate:"max=500"`
	RejectionReason  string                 `json:"rejection_reason" validate:"max=500"`
	RequiredChanges  string                 `json:"required_changes" validate:"max=1000"`
	Criteria         map[string]interface{} `json:"criteria"`
	CommitteeVotes   map[string]interface{} `json:"committee_votes"`
	DueDate          *time.Time             `json:"due_date"`
}

// UpdateProjectApprovalRequest for updating approval details
type UpdateProjectApprovalRequest struct {
	Priority        string     `json:"priority" validate:"oneof=low medium high urgent"`
	SubmissionNotes string     `json:"submission_notes" validate:"max=1000"`
	Documents       []string   `json:"documents"`
	DueDate         *time.Time `json:"due_date"`
}

// ProjectApprovalFilter for querying approvals
type ProjectApprovalFilter struct {
	CooperativeID *uuid.UUID `json:"cooperative_id"`
	ProjectID     *uuid.UUID `json:"project_id"`
	SubmittedBy   *uuid.UUID `json:"submitted_by"`
	ReviewedBy    *uuid.UUID `json:"reviewed_by"`
	Status        string     `json:"status"`
	Priority      string     `json:"priority"`
	StartDate     *time.Time `json:"start_date"`
	EndDate       *time.Time `json:"end_date"`
	Page          int        `json:"page"`
	Limit         int        `json:"limit"`
	SortBy        string     `json:"sort_by"` // created_at, updated_at, due_date, priority
	SortOrder     string     `json:"sort_order"` // asc, desc
}

// Committee member vote structure
type CommitteeVote struct {
	MemberID    uuid.UUID `json:"member_id"`
	MemberName  string    `json:"member_name"`
	Vote        string    `json:"vote"`        // approve, reject, abstain
	Comments    string    `json:"comments"`
	VotedAt     time.Time `json:"voted_at"`
	Weight      float64   `json:"weight"`      // Vote weight (1.0 = normal)
}

// Evaluation criteria structure
type EvaluationCriteria struct {
	FinancialViability  float64 `json:"financial_viability"`   // 0-10 score
	MarketPotential     float64 `json:"market_potential"`      // 0-10 score
	TeamCapability      float64 `json:"team_capability"`       // 0-10 score
	ShariaCompliance    float64 `json:"sharia_compliance"`     // 0-10 score
	RiskAssessment      float64 `json:"risk_assessment"`       // 0-10 score
	SocialImpact        float64 `json:"social_impact"`         // 0-10 score
	EnvironmentalImpact float64 `json:"environmental_impact"`  // 0-10 score
	Innovation          float64 `json:"innovation"`            // 0-10 score
	OverallScore        float64 `json:"overall_score"`         // Calculated average
	Recommendation      string  `json:"recommendation"`        // approve, reject, conditional
}
