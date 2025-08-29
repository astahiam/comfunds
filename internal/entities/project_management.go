package entities

import (
	"time"

	"github.com/google/uuid"
)

// ProjectExtended represents comprehensive project management (FR-032 to FR-040)
type ProjectExtended struct {
	ID                    uuid.UUID              `json:"id" db:"id"`
	Title                 string                 `json:"title" db:"title"`
	Description           string                 `json:"description" db:"description"`
	BusinessID            uuid.UUID              `json:"business_id" db:"business_id"`
	CooperativeID         uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	OwnerID               uuid.UUID              `json:"owner_id" db:"owner_id"`
	Category              string                 `json:"category" db:"category"` // startup, expansion, equipment, research
	FundingGoal           float64                `json:"funding_goal" db:"funding_goal"`
	Currency              string                 `json:"currency" db:"currency"`
	CurrentFunding        float64                `json:"current_funding" db:"current_funding"`
	FundingProgress       float64                `json:"funding_progress" db:"funding_progress"` // percentage
	MinFundingRequired    float64                `json:"min_funding_required" db:"min_funding_required"`
	StartDate             time.Time              `json:"start_date" db:"start_date"`
	EndDate               time.Time              `json:"end_date" db:"end_date"`
	Duration              int                    `json:"duration" db:"duration"` // in days
	Timeline              []ProjectMilestone     `json:"timeline" db:"timeline"`
	ProfitSharingTerms    *ProfitSharingTerms    `json:"profit_sharing_terms" db:"profit_sharing_terms"`
	IntendedUseOfFunds    string                 `json:"intended_use_of_funds" db:"intended_use_of_funds"`
	DetailedUseOfFunds    map[string]interface{} `json:"detailed_use_of_funds" db:"detailed_use_of_funds"`
	RiskLevel             string                 `json:"risk_level" db:"risk_level"` // low, medium, high
	ExpectedReturn        float64                `json:"expected_return" db:"expected_return"` // percentage
	ExpectedReturnPeriod  int                    `json:"expected_return_period" db:"expected_return_period"` // in months
	ShariaCompliant       bool                   `json:"sharia_compliant" db:"sharia_compliant"`
	ComplianceNotes       string                 `json:"compliance_notes" db:"compliance_notes"`
	Status                string                 `json:"status" db:"status"` // draft, submitted, approved, active, closed, cancelled
	ApprovalStatus        string                 `json:"approval_status" db:"approval_status"`
	ApprovedBy            *uuid.UUID             `json:"approved_by" db:"approved_by"`
	ApprovedAt            *time.Time             `json:"approved_at" db:"approved_at"`
	RejectionReason       string                 `json:"rejection_reason" db:"rejection_reason"`
	FundingDeadline       time.Time              `json:"funding_deadline" db:"funding_deadline"`
	IsFunded              bool                   `json:"is_funded" db:"is_funded"`
	FundedAt              *time.Time             `json:"funded_at" db:"funded_at"`
	InvestorCount         int                    `json:"investor_count" db:"investor_count"`
	Documents             []string               `json:"documents" db:"documents"`
	Attachments           []string               `json:"attachments" db:"attachments"`
	Tags                  []string               `json:"tags" db:"tags"`
	Metadata              map[string]interface{} `json:"metadata" db:"metadata"`
	IsActive              bool                   `json:"is_active" db:"is_active"`
	CreatedAt             time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt             time.Time              `json:"updated_at" db:"updated_at"`
}

// ProjectMilestone represents project milestones (FR-040)
type ProjectMilestone struct {
	ID          uuid.UUID              `json:"id" db:"id"`
	ProjectID   uuid.UUID              `json:"project_id" db:"project_id"`
	Title       string                 `json:"title" db:"title"`
	Description string                 `json:"description" db:"description"`
	Type        string                 `json:"type" db:"type"` // planning, development, testing, launch, completion
	DueDate     time.Time              `json:"due_date" db:"due_date"`
	CompletedAt *time.Time             `json:"completed_at" db:"completed_at"`
	Status      string                 `json:"status" db:"status"` // pending, in_progress, completed, delayed, cancelled
	Progress    float64                `json:"progress" db:"progress"` // percentage
	Budget      float64                `json:"budget" db:"budget"`
	Spent       float64                `json:"spent" db:"spent"`
	Deliverables []string              `json:"deliverables" db:"deliverables"`
	Notes       string                 `json:"notes" db:"notes"`
	AssignedTo  *uuid.UUID             `json:"assigned_to" db:"assigned_to"`
	Metadata    map[string]interface{} `json:"metadata" db:"metadata"`
	CreatedAt   time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at" db:"updated_at"`
}

// ProfitSharingTerms for project profit distribution (FR-035)
type ProfitSharingTerms struct {
	InvestorShare       float64                `json:"investor_share"`       // Percentage for investors
	BusinessOwnerShare  float64                `json:"business_owner_share"` // Percentage for business owner
	CooperativeShare    float64                `json:"cooperative_share"`    // Percentage for cooperative
	DistributionMethod  string                 `json:"distribution_method"`  // monthly, quarterly, yearly, on_completion
	MinProfitThreshold  float64                `json:"min_profit_threshold"` // Minimum profit before distribution
	FirstDistribution   int                    `json:"first_distribution"`   // Months after project completion
	RiskAdjustment      float64                `json:"risk_adjustment"`      // Risk-based adjustment factor
	CustomTerms         map[string]interface{} `json:"custom_terms"`
}

// ProjectProgress represents project progress tracking (FR-040)
type ProjectProgress struct {
	ID                uuid.UUID              `json:"id" db:"id"`
	ProjectID         uuid.UUID              `json:"project_id" db:"project_id"`
	ReportDate        time.Time              `json:"report_date" db:"report_date"`
	OverallProgress   float64                `json:"overall_progress" db:"overall_progress"` // percentage
	MilestoneProgress map[string]float64     `json:"milestone_progress" db:"milestone_progress"`
	BudgetUtilization float64                `json:"budget_utilization" db:"budget_utilization"` // percentage
	TimelineStatus    string                 `json:"timeline_status" db:"timeline_status"` // on_track, ahead, behind, delayed
	KeyAchievements   []string               `json:"key_achievements" db:"key_achievements"`
	Challenges        []string               `json:"challenges" db:"challenges"`
	NextSteps         []string               `json:"next_steps" db:"next_steps"`
	FinancialStatus   map[string]interface{} `json:"financial_status" db:"financial_status"`
	RiskAssessment    map[string]interface{} `json:"risk_assessment" db:"risk_assessment"`
	QualityMetrics    map[string]interface{} `json:"quality_metrics" db:"quality_metrics"`
	ReportedBy        uuid.UUID              `json:"reported_by" db:"reported_by"`
	Notes             string                 `json:"notes" db:"notes"`
	CreatedAt         time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time              `json:"updated_at" db:"updated_at"`
}

// ProjectExtended status constants
const (
	ProjectExtendedStatusDraft     = "draft"
	ProjectExtendedStatusSubmitted = "submitted"
	ProjectExtendedStatusApproved  = "approved"
	ProjectExtendedStatusActive    = "active"
	ProjectExtendedStatusClosed    = "closed"
	ProjectExtendedStatusCancelled = "cancelled"

	ProjectCategoryStartup    = "startup"
	ProjectCategoryExpansion  = "expansion"
	ProjectCategoryEquipment  = "equipment"
	ProjectCategoryResearch   = "research"
	ProjectCategoryTechnology = "technology"
	ProjectCategoryAgriculture = "agriculture"
	ProjectCategoryManufacturing = "manufacturing"
	ProjectCategoryServices   = "services"
	ProjectCategoryOther      = "other"

	ProjectRiskLevelLow    = "low"
	ProjectRiskLevelMedium = "medium"
	ProjectRiskLevelHigh   = "high"

	MilestoneStatusPending     = "pending"
	MilestoneStatusInProgress  = "in_progress"
	MilestoneStatusCompleted   = "completed"
	MilestoneStatusDelayed     = "delayed"
	MilestoneStatusCancelled   = "cancelled"

	TimelineStatusOnTrack = "on_track"
	TimelineStatusAhead   = "ahead"
	TimelineStatusBehind  = "behind"
	TimelineStatusDelayed = "delayed"
)

// CreateProjectExtendedRequest for FR-032 and FR-033
type CreateProjectExtendedRequest struct {
	Title                 string                 `json:"title" validate:"required,min=5,max=200"`
	Description           string                 `json:"description" validate:"required,min=20,max=2000"`
	Category              string                 `json:"category" validate:"required,oneof=startup expansion equipment research technology agriculture manufacturing services other"`
	FundingGoal           float64                `json:"funding_goal" validate:"required,min=1000"`
	Currency              string                 `json:"currency" validate:"required,len=3"`
	MinFundingRequired    float64                `json:"min_funding_required" validate:"required,min=100"`
	StartDate             time.Time              `json:"start_date" validate:"required"`
	EndDate               time.Time              `json:"end_date" validate:"required"`
	IntendedUseOfFunds    string                 `json:"intended_use_of_funds" validate:"required,min=10,max=500"`
	DetailedUseOfFunds    map[string]interface{} `json:"detailed_use_of_funds"`
	RiskLevel             string                 `json:"risk_level" validate:"required,oneof=low medium high"`
	ExpectedReturn        float64                `json:"expected_return" validate:"required,min=0,max=100"`
	ExpectedReturnPeriod  int                    `json:"expected_return_period" validate:"required,min=1,max=60"`
	ShariaCompliant       bool                   `json:"sharia_compliant"`
	ComplianceNotes       string                 `json:"compliance_notes" validate:"max=1000"`
	FundingDeadline       time.Time              `json:"funding_deadline" validate:"required"`
	Documents             []string               `json:"documents"`
	Tags                  []string               `json:"tags"`
	Metadata              map[string]interface{} `json:"metadata"`
}

// UpdateProjectExtendedRequest for FR-036
type UpdateProjectExtendedRequest struct {
	Title                 string                 `json:"title" validate:"min=5,max=200"`
	Description           string                 `json:"description" validate:"min=20,max=2000"`
	Category              string                 `json:"category" validate:"oneof=startup expansion equipment research technology agriculture manufacturing services other"`
	FundingGoal           float64                `json:"funding_goal" validate:"min=1000"`
	MinFundingRequired    float64                `json:"min_funding_required" validate:"min=100"`
	EndDate               time.Time              `json:"end_date"`
	IntendedUseOfFunds    string                 `json:"intended_use_of_funds" validate:"min=10,max=500"`
	DetailedUseOfFunds    map[string]interface{} `json:"detailed_use_of_funds"`
	RiskLevel             string                 `json:"risk_level" validate:"oneof=low medium high"`
	ExpectedReturn        float64                `json:"expected_return" validate:"min=0,max=100"`
	ExpectedReturnPeriod  int                    `json:"expected_return_period" validate:"min=1,max=60"`
	ComplianceNotes       string                 `json:"compliance_notes" validate:"max=1000"`
	FundingDeadline       time.Time              `json:"funding_deadline"`
	Documents             []string               `json:"documents"`
	Tags                  []string               `json:"tags"`
	Metadata              map[string]interface{} `json:"metadata"`
}

// CreateMilestoneRequest for FR-040
type CreateMilestoneRequest struct {
	Title        string                 `json:"title" validate:"required,min=3,max=100"`
	Description  string                 `json:"description" validate:"required,min=10,max=500"`
	Type         string                 `json:"type" validate:"required,oneof=planning development testing launch completion"`
	DueDate      time.Time              `json:"due_date" validate:"required"`
	Budget       float64                `json:"budget" validate:"min=0"`
	Deliverables []string               `json:"deliverables"`
	Notes        string                 `json:"notes" validate:"max=1000"`
	AssignedTo   *uuid.UUID             `json:"assigned_to"`
	Metadata     map[string]interface{} `json:"metadata"`
}

// UpdateMilestoneRequest for FR-040
type UpdateMilestoneRequest struct {
	Title        string                 `json:"title" validate:"min=3,max=100"`
	Description  string                 `json:"description" validate:"min=10,max=500"`
	Type         string                 `json:"type" validate:"oneof=planning development testing launch completion"`
	DueDate      time.Time              `json:"due_date"`
	Status       string                 `json:"status" validate:"oneof=pending in_progress completed delayed cancelled"`
	Progress     float64                `json:"progress" validate:"min=0,max=100"`
	Budget       float64                `json:"budget" validate:"min=0"`
	Spent        float64                `json:"spent" validate:"min=0"`
	Deliverables []string               `json:"deliverables"`
	Notes        string                 `json:"notes" validate:"max=1000"`
	AssignedTo   *uuid.UUID             `json:"assigned_to"`
	Metadata     map[string]interface{} `json:"metadata"`
}

// CreateProgressReportRequest for FR-040
type CreateProgressReportRequest struct {
	ReportDate        time.Time              `json:"report_date" validate:"required"`
	OverallProgress   float64                `json:"overall_progress" validate:"required,min=0,max=100"`
	MilestoneProgress map[string]float64     `json:"milestone_progress"`
	BudgetUtilization float64                `json:"budget_utilization" validate:"min=0,max=100"`
	TimelineStatus    string                 `json:"timeline_status" validate:"required,oneof=on_track ahead behind delayed"`
	KeyAchievements   []string               `json:"key_achievements"`
	Challenges        []string               `json:"challenges"`
	NextSteps         []string               `json:"next_steps"`
	FinancialStatus   map[string]interface{} `json:"financial_status"`
	RiskAssessment    map[string]interface{} `json:"risk_assessment"`
	QualityMetrics    map[string]interface{} `json:"quality_metrics"`
	Notes             string                 `json:"notes" validate:"max=2000"`
}

// ProjectFilter for querying projects
type ProjectFilter struct {
	BusinessID       *uuid.UUID `json:"business_id"`
	CooperativeID    *uuid.UUID `json:"cooperative_id"`
	OwnerID          *uuid.UUID `json:"owner_id"`
	Category         string     `json:"category"`
	Status           string     `json:"status"`
	RiskLevel        string     `json:"risk_level"`
	MinFundingGoal   float64    `json:"min_funding_goal"`
	MaxFundingGoal   float64    `json:"max_funding_goal"`
	ShariaCompliant  *bool      `json:"sharia_compliant"`
	IsFunded         *bool      `json:"is_funded"`
	Page             int        `json:"page"`
	Limit            int        `json:"limit"`
	SortBy           string     `json:"sort_by"`    // title, created_at, funding_goal, end_date
	SortOrder        string     `json:"sort_order"` // asc, desc
}

// ProjectExtendedApprovalRequest for FR-038
type ProjectExtendedApprovalRequest struct {
	ProjectID uuid.UUID `json:"project_id" validate:"required"`
	Comments  string    `json:"comments" validate:"max=1000"`
	Conditions []string `json:"conditions"`
}

// ProjectRejectionRequest for FR-038
type ProjectRejectionRequest struct {
	ProjectID uuid.UUID `json:"project_id" validate:"required"`
	Reason    string    `json:"reason" validate:"required,min=10,max=1000"`
	Feedback  string    `json:"feedback" validate:"max=2000"`
}

// ProfitSharingProjection for FR-035
type ProfitSharingProjection struct {
	ProjectID           uuid.UUID              `json:"project_id"`
	TotalInvestment     float64                `json:"total_investment"`
	ExpectedProfit      float64                `json:"expected_profit"`
	ExpectedReturnRate  float64                `json:"expected_return_rate"`
	InvestorShare       float64                `json:"investor_share"`
	BusinessOwnerShare  float64                `json:"business_owner_share"`
	CooperativeShare    float64                `json:"cooperative_share"`
	DistributionSchedule []DistributionPeriod  `json:"distribution_schedule"`
	RiskFactors         map[string]interface{} `json:"risk_factors"`
	CalculatedAt        time.Time              `json:"calculated_at"`
}

// DistributionPeriod represents profit distribution periods
type DistributionPeriod struct {
	Period     string  `json:"period"`
	Date       time.Time `json:"date"`
	Amount     float64 `json:"amount"`
	Percentage float64 `json:"percentage"`
	Status     string  `json:"status"` // scheduled, completed, cancelled
}
