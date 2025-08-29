package services

import (
	"context"
	"fmt"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
)

type ProjectManagementService interface {
	// FR-032: Project Creation
	CreateProject(ctx context.Context, req *entities.CreateProjectExtendedRequest, ownerID uuid.UUID) (*entities.ProjectExtended, error)
	ValidateProjectCreation(ctx context.Context, req *entities.CreateProjectExtendedRequest, ownerID uuid.UUID) (bool, []string, error)
	
	// FR-033: Project Profile Management
	GetProject(ctx context.Context, projectID uuid.UUID) (*entities.ProjectExtended, error)
	UpdateProject(ctx context.Context, projectID uuid.UUID, req *entities.UpdateProjectExtendedRequest, updaterID uuid.UUID) (*entities.ProjectExtended, error)
	
	// FR-034: Intended Use of Funds
	ValidateIntendedUseOfFunds(ctx context.Context, intendedUse string, detailedUse map[string]interface{}) (bool, []string, error)
	UpdateIntendedUseOfFunds(ctx context.Context, projectID uuid.UUID, intendedUse string, detailedUse map[string]interface{}, updaterID uuid.UUID) error
	
	// FR-035: Profit-Sharing Projections
	CalculateProfitSharingProjection(ctx context.Context, projectID uuid.UUID) (*entities.ProfitSharingProjection, error)
	GetProfitSharingProjection(ctx context.Context, projectID uuid.UUID) (*entities.ProfitSharingProjection, error)
	UpdateProfitSharingTerms(ctx context.Context, projectID uuid.UUID, terms *entities.ProfitSharingTerms, updaterID uuid.UUID) error
	
	// FR-036: Project CRUD Operations
	GetOwnerProjects(ctx context.Context, ownerID uuid.UUID, page, limit int) ([]*entities.ProjectExtended, int, error)
	GetCooperativeProjects(ctx context.Context, cooperativeID uuid.UUID, status string, page, limit int) ([]*entities.ProjectExtended, int, error)
	SearchProjects(ctx context.Context, filter *entities.ProjectFilter) ([]*entities.ProjectExtended, int, error)
	DeleteProject(ctx context.Context, projectID, deleterID uuid.UUID, reason string) error
	
	// FR-037: Project Lifecycle Management
	SubmitProjectForApproval(ctx context.Context, projectID, submitterID uuid.UUID) error
	ApproveProject(ctx context.Context, req *entities.ProjectExtendedApprovalRequest, approverID uuid.UUID) error
	RejectProject(ctx context.Context, req *entities.ProjectRejectionRequest, approverID uuid.UUID) error
	ActivateProject(ctx context.Context, projectID, activatorID uuid.UUID) error
	CloseProject(ctx context.Context, projectID, closerID uuid.UUID, reason string) error
	CancelProject(ctx context.Context, projectID, cancellerID uuid.UUID, reason string) error
	
	// FR-038: Cooperative Approval Workflow
	GetPendingProjectApprovals(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.ProjectExtended, int, error)
	ValidateProjectForInvestment(ctx context.Context, projectID uuid.UUID) (bool, []string, error)
	
	// FR-039: Funding Deadlines and Requirements
	CheckFundingDeadline(ctx context.Context, projectID uuid.UUID) (bool, error)
	ValidateMinimumFunding(ctx context.Context, projectID uuid.UUID, currentFunding float64) (bool, error)
	UpdateFundingProgress(ctx context.Context, projectID uuid.UUID, newFunding float64) error
	MarkProjectAsFunded(ctx context.Context, projectID uuid.UUID, fundedAt time.Time) error
	
	// FR-040: Project Progress and Milestones
	CreateMilestone(ctx context.Context, projectID uuid.UUID, req *entities.CreateMilestoneRequest, creatorID uuid.UUID) (*entities.ProjectMilestone, error)
	UpdateMilestone(ctx context.Context, milestoneID uuid.UUID, req *entities.UpdateMilestoneRequest, updaterID uuid.UUID) (*entities.ProjectMilestone, error)
	GetProjectMilestones(ctx context.Context, projectID uuid.UUID) ([]*entities.ProjectMilestone, error)
	CompleteMilestone(ctx context.Context, milestoneID uuid.UUID, completedAt time.Time, completerID uuid.UUID) error
	
	// Progress Tracking
	CreateProgressReport(ctx context.Context, projectID uuid.UUID, req *entities.CreateProgressReportRequest, reporterID uuid.UUID) (*entities.ProjectProgress, error)
	GetProjectProgress(ctx context.Context, projectID uuid.UUID, startDate, endDate time.Time) ([]*entities.ProjectProgress, error)
	GetProjectProgressSummary(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error)
	
	// Analytics and reporting
	GetProjectAnalytics(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error)
	GetProjectTimeline(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error)
	GenerateProjectReport(ctx context.Context, projectID uuid.UUID, reportType string) (map[string]interface{}, error)
}

type projectManagementService struct {
	auditService AuditService
}

func NewProjectManagementService(auditService AuditService) ProjectManagementService {
	return &projectManagementService{
		auditService: auditService,
	}
}

func (s *projectManagementService) CreateProject(ctx context.Context, req *entities.CreateProjectExtendedRequest, ownerID uuid.UUID) (*entities.ProjectExtended, error) {
	// FR-033: Validate required fields
	if err := s.validateProjectCreationData(req); err != nil {
		return nil, err
	}

	// FR-034: Validate intended use of funds
	valid, violations, err := s.ValidateIntendedUseOfFunds(ctx, req.IntendedUseOfFunds, req.DetailedUseOfFunds)
	if err != nil {
		return nil, fmt.Errorf("failed to validate intended use of funds: %w", err)
	}
	if !valid {
		return nil, fmt.Errorf("intended use of funds validation failed: %v", violations)
	}

	// Calculate project duration
	duration := int(req.EndDate.Sub(req.StartDate).Hours() / 24)

	// Calculate default profit sharing terms
	profitSharingTerms := &entities.ProfitSharingTerms{
		InvestorShare:       60.0, // 60% for investors
		BusinessOwnerShare:  30.0, // 30% for business owner
		CooperativeShare:    10.0, // 10% for cooperative
		DistributionMethod:  "quarterly",
		MinProfitThreshold:  1000.0,
		FirstDistribution:   3, // 3 months after completion
		RiskAdjustment:      1.0,
		CustomTerms:         make(map[string]interface{}),
	}

	project := &entities.ProjectExtended{
		ID:                    uuid.New(),
		Title:                 req.Title,
		Description:           req.Description,
		BusinessID:            uuid.New(), // Would get from owner's business
		CooperativeID:         uuid.New(), // Would get from owner's cooperative
		OwnerID:               ownerID,
		Category:              req.Category,
		FundingGoal:           req.FundingGoal,
		Currency:              req.Currency,
		CurrentFunding:        0.0,
		FundingProgress:       0.0,
		MinFundingRequired:    req.MinFundingRequired,
		StartDate:             req.StartDate,
		EndDate:               req.EndDate,
		Duration:              duration,
		Timeline:              []entities.ProjectMilestone{},
		ProfitSharingTerms:    profitSharingTerms,
		IntendedUseOfFunds:    req.IntendedUseOfFunds,
		DetailedUseOfFunds:    req.DetailedUseOfFunds,
		RiskLevel:             req.RiskLevel,
		ExpectedReturn:        req.ExpectedReturn,
		ExpectedReturnPeriod:  req.ExpectedReturnPeriod,
		ShariaCompliant:       req.ShariaCompliant,
		ComplianceNotes:       req.ComplianceNotes,
		Status:                entities.ProjectExtendedStatusDraft,
		ApprovalStatus:        "pending",
		FundingDeadline:       req.FundingDeadline,
		IsFunded:              false,
		InvestorCount:         0,
		Documents:             req.Documents,
		Tags:                  req.Tags,
		Metadata:              req.Metadata,
		IsActive:              true,
		CreatedAt:             time.Now(),
		UpdatedAt:             time.Now(),
	}

	// In real implementation, save to repository
	// createdProject, err := s.projectRepo.Create(ctx, project)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   project.ID,
		Operation:  entities.AuditOperationCreate,
		UserID:     ownerID,
		Changes:    map[string]interface{}{"action": "create_project", "title": req.Title, "category": req.Category},
		NewValues:  project,
		Status:     entities.AuditStatusSuccess,
	})

	return project, nil
}

func (s *projectManagementService) ValidateIntendedUseOfFunds(ctx context.Context, intendedUse string, detailedUse map[string]interface{}) (bool, []string, error) {
	var violations []string

	// Validate intended use description
	if len(intendedUse) < 10 {
		violations = append(violations, "Intended use of funds must be at least 10 characters")
	}

	// Validate detailed use breakdown
	if detailedUse != nil {
		requiredCategories := []string{"equipment", "marketing", "operations", "development"}
		for _, category := range requiredCategories {
			if _, exists := detailedUse[category]; !exists {
				violations = append(violations, fmt.Sprintf("Missing required category: %s", category))
			}
		}
	}

	// Check for prohibited uses
	prohibitedTerms := []string{"gambling", "alcohol", "tobacco", "weapons", "illegal"}
	for _, term := range prohibitedTerms {
		if contains(intendedUse, term) {
			violations = append(violations, fmt.Sprintf("Prohibited use detected: %s", term))
		}
	}

	return len(violations) == 0, violations, nil
}

func (s *projectManagementService) CalculateProfitSharingProjection(ctx context.Context, projectID uuid.UUID) (*entities.ProfitSharingProjection, error) {
	// Mock calculation - in real implementation, would fetch project data
	projection := &entities.ProfitSharingProjection{
		ProjectID:          projectID,
		TotalInvestment:    100000.0,
		ExpectedProfit:     15000.0,
		ExpectedReturnRate: 15.0,
		InvestorShare:      9000.0,  // 60% of profit
		BusinessOwnerShare: 4500.0,  // 30% of profit
		CooperativeShare:   1500.0,  // 10% of profit
		DistributionSchedule: []entities.DistributionPeriod{
			{
				Period:     "Q1",
				Date:       time.Now().AddDate(0, 3, 0),
				Amount:     2250.0,
				Percentage: 25.0,
				Status:     "scheduled",
			},
			{
				Period:     "Q2",
				Date:       time.Now().AddDate(0, 6, 0),
				Amount:     2250.0,
				Percentage: 25.0,
				Status:     "scheduled",
			},
			{
				Period:     "Q3",
				Date:       time.Now().AddDate(0, 9, 0),
				Amount:     2250.0,
				Percentage: 25.0,
				Status:     "scheduled",
			},
			{
				Period:     "Q4",
				Date:       time.Now().AddDate(0, 12, 0),
				Amount:     2250.0,
				Percentage: 25.0,
				Status:     "scheduled",
			},
		},
		RiskFactors: map[string]interface{}{
			"market_risk":      "medium",
			"operational_risk": "low",
			"financial_risk":   "low",
		},
		CalculatedAt: time.Now(),
	}

	return projection, nil
}

func (s *projectManagementService) SubmitProjectForApproval(ctx context.Context, projectID, submitterID uuid.UUID) error {
	// Update project status
	// project.Status = entities.ProjectExtendedStatusSubmitted
	// project.UpdatedAt = time.Now()

	// In real implementation, update repository
	// s.projectRepo.Update(ctx, projectID, project)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   projectID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     submitterID,
		Changes:    map[string]interface{}{"action": "submit_for_approval", "status": entities.ProjectExtendedStatusSubmitted},
		Status:     entities.AuditStatusSuccess,
	})

	return nil
}

func (s *projectManagementService) ApproveProject(ctx context.Context, req *entities.ProjectExtendedApprovalRequest, approverID uuid.UUID) error {
	// Update project status
	now := time.Now()
	
	// In real implementation, update project
	// project.Status = entities.ProjectExtendedStatusApproved
	// project.ApprovedBy = &approverID
	// project.ApprovedAt = &now

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   req.ProjectID,
		Operation:  entities.AuditOperationUpdate,
		UserID:     approverID,
		Changes:    map[string]interface{}{"action": "approve_project", "comments": req.Comments, "approved_at": now},
		Status:     entities.AuditStatusSuccess,
	})

	return nil
}

func (s *projectManagementService) CreateMilestone(ctx context.Context, projectID uuid.UUID, req *entities.CreateMilestoneRequest, creatorID uuid.UUID) (*entities.ProjectMilestone, error) {
	milestone := &entities.ProjectMilestone{
		ID:          uuid.New(),
		ProjectID:   projectID,
		Title:       req.Title,
		Description: req.Description,
		Type:        req.Type,
		DueDate:     req.DueDate,
		Status:      entities.MilestoneStatusPending,
		Progress:    0.0,
		Budget:      req.Budget,
		Spent:       0.0,
		Deliverables: req.Deliverables,
		Notes:       req.Notes,
		AssignedTo:  req.AssignedTo,
		Metadata:    req.Metadata,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	// In real implementation, save to repository
	// createdMilestone, err := s.milestoneRepo.Create(ctx, milestone)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   projectID,
		Operation:  entities.AuditOperationCreate,
		UserID:     creatorID,
		Changes:    map[string]interface{}{"action": "create_milestone", "title": req.Title, "type": req.Type},
		NewValues:  milestone,
		Status:     entities.AuditStatusSuccess,
	})

	return milestone, nil
}

func (s *projectManagementService) CreateProgressReport(ctx context.Context, projectID uuid.UUID, req *entities.CreateProgressReportRequest, reporterID uuid.UUID) (*entities.ProjectProgress, error) {
	progress := &entities.ProjectProgress{
		ID:                uuid.New(),
		ProjectID:         projectID,
		ReportDate:        req.ReportDate,
		OverallProgress:   req.OverallProgress,
		MilestoneProgress: req.MilestoneProgress,
		BudgetUtilization: req.BudgetUtilization,
		TimelineStatus:    req.TimelineStatus,
		KeyAchievements:   req.KeyAchievements,
		Challenges:        req.Challenges,
		NextSteps:         req.NextSteps,
		FinancialStatus:   req.FinancialStatus,
		RiskAssessment:    req.RiskAssessment,
		QualityMetrics:    req.QualityMetrics,
		ReportedBy:        reporterID,
		Notes:             req.Notes,
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
	}

	// In real implementation, save to repository
	// createdProgress, err := s.progressRepo.Create(ctx, progress)

	// Log audit trail
	s.auditService.LogOperation(ctx, &LogOperationRequest{
		EntityType: entities.AuditEntityProject,
		EntityID:   projectID,
		Operation:  entities.AuditOperationCreate,
		UserID:     reporterID,
		Changes:    map[string]interface{}{"action": "create_progress_report", "overall_progress": req.OverallProgress, "timeline_status": req.TimelineStatus},
		NewValues:  progress,
		Status:     entities.AuditStatusSuccess,
	})

	return progress, nil
}

func (s *projectManagementService) GetProjectAnalytics(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error) {
	// Mock analytics data
	analytics := map[string]interface{}{
		"project_id": projectID,
		"funding": map[string]interface{}{
			"current_progress":    45.5,
			"days_remaining":      23,
			"funding_velocity":    2.1, // % per day
			"investor_engagement": 78.3,
		},
		"milestones": map[string]interface{}{
			"total_milestones":    8,
			"completed_milestones": 3,
			"on_track_milestones":  4,
			"delayed_milestones":   1,
		},
		"timeline": map[string]interface{}{
			"overall_progress":   37.5,
			"timeline_status":    "on_track",
			"days_ahead":         5,
			"risk_level":         "low",
		},
		"financial": map[string]interface{}{
			"budget_utilization": 42.3,
			"cost_efficiency":    1.15, // > 1 means under budget
			"roi_projection":     18.7,
		},
		"generated_at": time.Now(),
	}

	return analytics, nil
}

// Helper methods
func (s *projectManagementService) validateProjectCreationData(req *entities.CreateProjectExtendedRequest) error {
	if req.EndDate.Before(req.StartDate) {
		return fmt.Errorf("end date cannot be before start date")
	}

	if req.FundingDeadline.Before(time.Now()) {
		return fmt.Errorf("funding deadline cannot be in the past")
	}

	if req.MinFundingRequired > req.FundingGoal {
		return fmt.Errorf("minimum funding required cannot exceed funding goal")
	}

	if req.ExpectedReturn < 0 || req.ExpectedReturn > 100 {
		return fmt.Errorf("expected return must be between 0 and 100 percent")
	}

	return nil
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > len(substr) && (s[:len(substr)] == substr || s[len(s)-len(substr):] == substr || containsSubstring(s, substr)))
}

func containsSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// Mock implementations for interface compliance
func (s *projectManagementService) ValidateProjectCreation(ctx context.Context, req *entities.CreateProjectExtendedRequest, ownerID uuid.UUID) (bool, []string, error) {
	return true, []string{}, nil
}

func (s *projectManagementService) GetProject(ctx context.Context, projectID uuid.UUID) (*entities.ProjectExtended, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) UpdateProject(ctx context.Context, projectID uuid.UUID, req *entities.UpdateProjectExtendedRequest, updaterID uuid.UUID) (*entities.ProjectExtended, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) UpdateIntendedUseOfFunds(ctx context.Context, projectID uuid.UUID, intendedUse string, detailedUse map[string]interface{}, updaterID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) GetProfitSharingProjection(ctx context.Context, projectID uuid.UUID) (*entities.ProfitSharingProjection, error) {
	return s.CalculateProfitSharingProjection(ctx, projectID)
}

func (s *projectManagementService) UpdateProfitSharingTerms(ctx context.Context, projectID uuid.UUID, terms *entities.ProfitSharingTerms, updaterID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) GetOwnerProjects(ctx context.Context, ownerID uuid.UUID, page, limit int) ([]*entities.ProjectExtended, int, error) {
	return []*entities.ProjectExtended{}, 0, nil
}

func (s *projectManagementService) GetCooperativeProjects(ctx context.Context, cooperativeID uuid.UUID, status string, page, limit int) ([]*entities.ProjectExtended, int, error) {
	return []*entities.ProjectExtended{}, 0, nil
}

func (s *projectManagementService) SearchProjects(ctx context.Context, filter *entities.ProjectFilter) ([]*entities.ProjectExtended, int, error) {
	return []*entities.ProjectExtended{}, 0, nil
}

func (s *projectManagementService) DeleteProject(ctx context.Context, projectID, deleterID uuid.UUID, reason string) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) RejectProject(ctx context.Context, req *entities.ProjectRejectionRequest, approverID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) ActivateProject(ctx context.Context, projectID, activatorID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) CloseProject(ctx context.Context, projectID, closerID uuid.UUID, reason string) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) CancelProject(ctx context.Context, projectID, cancellerID uuid.UUID, reason string) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) GetPendingProjectApprovals(ctx context.Context, cooperativeID uuid.UUID, page, limit int) ([]*entities.ProjectExtended, int, error) {
	return []*entities.ProjectExtended{}, 0, nil
}

func (s *projectManagementService) ValidateProjectForInvestment(ctx context.Context, projectID uuid.UUID) (bool, []string, error) {
	return true, []string{}, nil
}

func (s *projectManagementService) CheckFundingDeadline(ctx context.Context, projectID uuid.UUID) (bool, error) {
	return true, nil
}

func (s *projectManagementService) ValidateMinimumFunding(ctx context.Context, projectID uuid.UUID, currentFunding float64) (bool, error) {
	return true, nil
}

func (s *projectManagementService) UpdateFundingProgress(ctx context.Context, projectID uuid.UUID, newFunding float64) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) MarkProjectAsFunded(ctx context.Context, projectID uuid.UUID, fundedAt time.Time) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) UpdateMilestone(ctx context.Context, milestoneID uuid.UUID, req *entities.UpdateMilestoneRequest, updaterID uuid.UUID) (*entities.ProjectMilestone, error) {
	return nil, fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) GetProjectMilestones(ctx context.Context, projectID uuid.UUID) ([]*entities.ProjectMilestone, error) {
	return []*entities.ProjectMilestone{}, nil
}

func (s *projectManagementService) CompleteMilestone(ctx context.Context, milestoneID uuid.UUID, completedAt time.Time, completerID uuid.UUID) error {
	return fmt.Errorf("not implemented - requires repository")
}

func (s *projectManagementService) GetProjectProgress(ctx context.Context, projectID uuid.UUID, startDate, endDate time.Time) ([]*entities.ProjectProgress, error) {
	return []*entities.ProjectProgress{}, nil
}

func (s *projectManagementService) GetProjectProgressSummary(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (s *projectManagementService) GetProjectTimeline(ctx context.Context, projectID uuid.UUID) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (s *projectManagementService) GenerateProjectReport(ctx context.Context, projectID uuid.UUID, reportType string) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}
