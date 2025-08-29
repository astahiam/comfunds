package services

import (
	"context"
	"testing"
	"time"

	"comfunds/internal/entities"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// Using MockAuditService from mocks_test.go

func TestProjectManagementService_CreateProject(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()

	// Test data
	ownerID := uuid.New()
	req := &entities.CreateProjectExtendedRequest{
		Title:                 "Test Project",
		Description:           "A comprehensive test project for funding",
		Category:              "technology",
		FundingGoal:           50000.0,
		Currency:              "USD",
		MinFundingRequired:    5000.0,
		StartDate:             time.Now(),
		EndDate:               time.Now().AddDate(0, 6, 0),
		IntendedUseOfFunds:    "Equipment purchase and marketing campaigns",
		RiskLevel:             "medium",
		ExpectedReturn:        15.0,
		ExpectedReturnPeriod:  12,
		ShariaCompliant:       true,
		FundingDeadline:       time.Now().AddDate(0, 1, 0),
		Documents:             []string{"business_plan.pdf", "financial_projection.xlsx"},
		Tags:                  []string{"tech", "startup", "innovation"},
		Metadata:              map[string]interface{}{"industry": "software"},
	}

	// Mock audit service
	mockAuditService.On("LogOperation", ctx, mock.AnythingOfType("*services.LogOperationRequest")).Return(nil)

	// Execute
	project, err := service.CreateProject(ctx, req, ownerID)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, project)
	assert.Equal(t, req.Title, project.Title)
	assert.Equal(t, req.Description, project.Description)
	assert.Equal(t, req.Category, project.Category)
	assert.Equal(t, req.FundingGoal, project.FundingGoal)
	assert.Equal(t, req.Currency, project.Currency)
	assert.Equal(t, ownerID, project.OwnerID)
	assert.Equal(t, entities.ProjectExtendedStatusDraft, project.Status)
	assert.Equal(t, 0.0, project.CurrentFunding)
	assert.Equal(t, 0.0, project.FundingProgress)
	assert.False(t, project.IsFunded)
	assert.True(t, project.IsActive)
	assert.NotNil(t, project.ProfitSharingTerms)
	assert.Equal(t, 60.0, project.ProfitSharingTerms.InvestorShare)
	assert.Equal(t, 30.0, project.ProfitSharingTerms.BusinessOwnerShare)
	assert.Equal(t, 10.0, project.ProfitSharingTerms.CooperativeShare)

	// Verify audit was called
	mockAuditService.AssertExpectations(t)
}

func TestProjectManagementService_CreateProject_ValidationErrors(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()

	// Test cases
	testCases := []struct {
		name        string
		req         *entities.CreateProjectExtendedRequest
		expectedErr string
	}{
		{
			name: "End date before start date",
			req: &entities.CreateProjectExtendedRequest{
				Title:                 "Test Project",
				Description:           "A comprehensive test project",
				Category:              "technology",
				FundingGoal:           50000.0,
				Currency:              "USD",
				MinFundingRequired:    5000.0,
				StartDate:             time.Now().AddDate(0, 6, 0),
				EndDate:               time.Now(),
				IntendedUseOfFunds:    "Equipment purchase",
				RiskLevel:             "medium",
				ExpectedReturn:        15.0,
				ExpectedReturnPeriod:  12,
				FundingDeadline:       time.Now().AddDate(0, 1, 0),
			},
			expectedErr: "end date cannot be before start date",
		},
		{
			name: "Funding deadline in past",
			req: &entities.CreateProjectExtendedRequest{
				Title:                 "Test Project",
				Description:           "A comprehensive test project",
				Category:              "technology",
				FundingGoal:           50000.0,
				Currency:              "USD",
				MinFundingRequired:    5000.0,
				StartDate:             time.Now(),
				EndDate:               time.Now().AddDate(0, 6, 0),
				IntendedUseOfFunds:    "Equipment purchase",
				RiskLevel:             "medium",
				ExpectedReturn:        15.0,
				ExpectedReturnPeriod:  12,
				FundingDeadline:       time.Now().AddDate(0, -1, 0),
			},
			expectedErr: "funding deadline cannot be in the past",
		},
		{
			name: "Min funding exceeds goal",
			req: &entities.CreateProjectExtendedRequest{
				Title:                 "Test Project",
				Description:           "A comprehensive test project",
				Category:              "technology",
				FundingGoal:           50000.0,
				Currency:              "USD",
				MinFundingRequired:    60000.0,
				StartDate:             time.Now(),
				EndDate:               time.Now().AddDate(0, 6, 0),
				IntendedUseOfFunds:    "Equipment purchase",
				RiskLevel:             "medium",
				ExpectedReturn:        15.0,
				ExpectedReturnPeriod:  12,
				FundingDeadline:       time.Now().AddDate(0, 1, 0),
			},
			expectedErr: "minimum funding required cannot exceed funding goal",
		},
		{
			name: "Invalid expected return",
			req: &entities.CreateProjectExtendedRequest{
				Title:                 "Test Project",
				Description:           "A comprehensive test project",
				Category:              "technology",
				FundingGoal:           50000.0,
				Currency:              "USD",
				MinFundingRequired:    5000.0,
				StartDate:             time.Now(),
				EndDate:               time.Now().AddDate(0, 6, 0),
				IntendedUseOfFunds:    "Equipment purchase",
				RiskLevel:             "medium",
				ExpectedReturn:        150.0, // Invalid: > 100
				ExpectedReturnPeriod:  12,
				FundingDeadline:       time.Now().AddDate(0, 1, 0),
			},
			expectedErr: "expected return must be between 0 and 100 percent",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Execute
			project, err := service.CreateProject(ctx, tc.req, uuid.New())

			// Assert
			assert.Error(t, err)
			assert.Nil(t, project)
			assert.Contains(t, err.Error(), tc.expectedErr)
		})
	}
}

func TestProjectManagementService_ValidateIntendedUseOfFunds(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()

	// Test cases
	testCases := []struct {
		name           string
		intendedUse    string
		detailedUse    map[string]interface{}
		expectedValid  bool
		expectedErrors int
	}{
		{
			name:           "Valid intended use",
			intendedUse:    "Equipment purchase and marketing campaigns for business expansion",
			detailedUse: map[string]interface{}{
				"equipment":   "30% for machinery",
				"marketing":   "25% for campaigns",
				"operations":  "25% for operations",
				"development": "20% for R&D",
			},
			expectedValid:  true,
			expectedErrors: 0,
		},
		{
			name:           "Too short intended use",
			intendedUse:    "Short",
			detailedUse:    nil,
			expectedValid:  false,
			expectedErrors: 1,
		},
		{
			name:           "Missing required categories",
			intendedUse:    "Equipment purchase and marketing campaigns",
			detailedUse: map[string]interface{}{
				"equipment": "30% for machinery",
				// Missing marketing, operations, development
			},
			expectedValid:  false,
			expectedErrors: 3,
		},
		{
			name:           "Prohibited use detected",
			intendedUse:    "Gambling platform development and alcohol distribution",
			detailedUse:    nil,
			expectedValid:  false,
			expectedErrors: 2, // gambling, alcohol
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Execute
			valid, violations, err := service.ValidateIntendedUseOfFunds(ctx, tc.intendedUse, tc.detailedUse)

			// Assert
			assert.NoError(t, err)
			assert.Equal(t, tc.expectedValid, valid)
			assert.Len(t, violations, tc.expectedErrors)
		})
	}
}

func TestProjectManagementService_CalculateProfitSharingProjection(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()
	projectID := uuid.New()

	// Execute
	projection, err := service.CalculateProfitSharingProjection(ctx, projectID)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, projection)
	assert.Equal(t, projectID, projection.ProjectID)
	assert.Equal(t, 100000.0, projection.TotalInvestment)
	assert.Equal(t, 15000.0, projection.ExpectedProfit)
	assert.Equal(t, 15.0, projection.ExpectedReturnRate)
	assert.Equal(t, 9000.0, projection.InvestorShare)
	assert.Equal(t, 4500.0, projection.BusinessOwnerShare)
	assert.Equal(t, 1500.0, projection.CooperativeShare)
	assert.Len(t, projection.DistributionSchedule, 4)
	assert.NotNil(t, projection.RiskFactors)
	assert.Equal(t, "medium", projection.RiskFactors["market_risk"])
	assert.Equal(t, "low", projection.RiskFactors["operational_risk"])
	assert.Equal(t, "low", projection.RiskFactors["financial_risk"])
}

func TestProjectManagementService_SubmitProjectForApproval(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()
	projectID := uuid.New()
	submitterID := uuid.New()

	// Mock audit service
	mockAuditService.On("LogOperation", ctx, mock.AnythingOfType("*services.LogOperationRequest")).Return(nil)

	// Execute
	err := service.SubmitProjectForApproval(ctx, projectID, submitterID)

	// Assert
	assert.NoError(t, err)
	mockAuditService.AssertExpectations(t)
}

func TestProjectManagementService_ApproveProject(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()
	projectID := uuid.New()
	approverID := uuid.New()

	req := &entities.ProjectExtendedApprovalRequest{
		ProjectID: projectID,
		Comments:  "Project meets all requirements and is approved",
		Conditions: []string{
			"Monthly progress reports required",
			"Quarterly financial reviews",
		},
	}

	// Mock audit service
	mockAuditService.On("LogOperation", ctx, mock.AnythingOfType("*services.LogOperationRequest")).Return(nil)

	// Execute
	err := service.ApproveProject(ctx, req, approverID)

	// Assert
	assert.NoError(t, err)
	mockAuditService.AssertExpectations(t)
}

func TestProjectManagementService_CreateMilestone(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()
	projectID := uuid.New()
	creatorID := uuid.New()

	req := &entities.CreateMilestoneRequest{
		Title:        "Project Planning Phase",
		Description:  "Complete initial project planning and requirements gathering",
		Type:         "planning",
		DueDate:      time.Now().AddDate(0, 1, 0),
		Budget:       5000.0,
		Deliverables: []string{"Project plan", "Requirements document", "Timeline"},
		Notes:        "Critical milestone for project success",
		Metadata:     map[string]interface{}{"priority": "high"},
	}

	// Mock audit service
	mockAuditService.On("LogOperation", ctx, mock.AnythingOfType("*services.LogOperationRequest")).Return(nil)

	// Execute
	milestone, err := service.CreateMilestone(ctx, projectID, req, creatorID)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, milestone)
	assert.Equal(t, projectID, milestone.ProjectID)
	assert.Equal(t, req.Title, milestone.Title)
	assert.Equal(t, req.Description, milestone.Description)
	assert.Equal(t, req.Type, milestone.Type)
	assert.Equal(t, req.DueDate, milestone.DueDate)
	assert.Equal(t, entities.MilestoneStatusPending, milestone.Status)
	assert.Equal(t, 0.0, milestone.Progress)
	assert.Equal(t, req.Budget, milestone.Budget)
	assert.Equal(t, 0.0, milestone.Spent)
	assert.Equal(t, req.Deliverables, milestone.Deliverables)
	assert.Equal(t, req.Notes, milestone.Notes)
	assert.Equal(t, req.Metadata, milestone.Metadata)
	assert.True(t, milestone.CreatedAt.After(time.Now().Add(-time.Second)))
	assert.True(t, milestone.UpdatedAt.After(time.Now().Add(-time.Second)))

	mockAuditService.AssertExpectations(t)
}

func TestProjectManagementService_CreateProgressReport(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()
	projectID := uuid.New()
	reporterID := uuid.New()

	req := &entities.CreateProgressReportRequest{
		ReportDate:      time.Now(),
		OverallProgress: 45.5,
		MilestoneProgress: map[string]float64{
			"planning":    100.0,
			"development": 60.0,
			"testing":     0.0,
		},
		BudgetUtilization: 42.3,
		TimelineStatus:    "on_track",
		KeyAchievements:   []string{"Completed planning phase", "Started development"},
		Challenges:        []string{"Resource constraints", "Technical complexity"},
		NextSteps:         []string{"Complete development", "Begin testing phase"},
		FinancialStatus: map[string]interface{}{
			"budget_remaining": 28700.0,
			"spent_to_date":    21300.0,
		},
		RiskAssessment: map[string]interface{}{
			"technical_risk": "low",
			"schedule_risk":  "medium",
		},
		QualityMetrics: map[string]interface{}{
			"code_coverage": 85.0,
			"test_pass_rate": 92.0,
		},
		Notes: "Project is progressing well within budget and timeline",
	}

	// Mock audit service
	mockAuditService.On("LogOperation", ctx, mock.AnythingOfType("*services.LogOperationRequest")).Return(nil)

	// Execute
	progress, err := service.CreateProgressReport(ctx, projectID, req, reporterID)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, progress)
	assert.Equal(t, projectID, progress.ProjectID)
	assert.Equal(t, req.ReportDate, progress.ReportDate)
	assert.Equal(t, req.OverallProgress, progress.OverallProgress)
	assert.Equal(t, req.MilestoneProgress, progress.MilestoneProgress)
	assert.Equal(t, req.BudgetUtilization, progress.BudgetUtilization)
	assert.Equal(t, req.TimelineStatus, progress.TimelineStatus)
	assert.Equal(t, req.KeyAchievements, progress.KeyAchievements)
	assert.Equal(t, req.Challenges, progress.Challenges)
	assert.Equal(t, req.NextSteps, progress.NextSteps)
	assert.Equal(t, req.FinancialStatus, progress.FinancialStatus)
	assert.Equal(t, req.RiskAssessment, progress.RiskAssessment)
	assert.Equal(t, req.QualityMetrics, progress.QualityMetrics)
	assert.Equal(t, reporterID, progress.ReportedBy)
	assert.Equal(t, req.Notes, progress.Notes)
	assert.True(t, progress.CreatedAt.After(time.Now().Add(-time.Second)))
	assert.True(t, progress.UpdatedAt.After(time.Now().Add(-time.Second)))

	mockAuditService.AssertExpectations(t)
}

func TestProjectManagementService_GetProjectAnalytics(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()
	projectID := uuid.New()

	// Execute
	analytics, err := service.GetProjectAnalytics(ctx, projectID)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, analytics)
	assert.Equal(t, projectID, analytics["project_id"])
	
	// Check funding analytics
	funding, exists := analytics["funding"].(map[string]interface{})
	assert.True(t, exists)
	assert.Equal(t, 45.5, funding["current_progress"])
	assert.Equal(t, 23, funding["days_remaining"])
	assert.Equal(t, 2.1, funding["funding_velocity"])
	assert.Equal(t, 78.3, funding["investor_engagement"])

	// Check milestone analytics
	milestones, exists := analytics["milestones"].(map[string]interface{})
	assert.True(t, exists)
	assert.Equal(t, 8, milestones["total_milestones"])
	assert.Equal(t, 3, milestones["completed_milestones"])
	assert.Equal(t, 4, milestones["on_track_milestones"])
	assert.Equal(t, 1, milestones["delayed_milestones"])

	// Check timeline analytics
	timeline, exists := analytics["timeline"].(map[string]interface{})
	assert.True(t, exists)
	assert.Equal(t, 37.5, timeline["overall_progress"])
	assert.Equal(t, "on_track", timeline["timeline_status"])
	assert.Equal(t, 5, timeline["days_ahead"])
	assert.Equal(t, "low", timeline["risk_level"])

	// Check financial analytics
	financial, exists := analytics["financial"].(map[string]interface{})
	assert.True(t, exists)
	assert.Equal(t, 42.3, financial["budget_utilization"])
	assert.Equal(t, 1.15, financial["cost_efficiency"])
	assert.Equal(t, 18.7, financial["roi_projection"])

	// Check generated timestamp
	assert.True(t, analytics["generated_at"].(time.Time).After(time.Now().Add(-time.Second)))
}

// Integration test for complete project workflow
func TestProjectManagementService_CompleteWorkflow(t *testing.T) {
	// Setup
	mockAuditService := new(MockAuditService)
	service := NewProjectManagementService(mockAuditService)
	ctx := context.Background()
	ownerID := uuid.New()
	projectID := uuid.New()

	// Mock audit service for all operations
	mockAuditService.On("LogOperation", ctx, mock.AnythingOfType("*services.LogOperationRequest")).Return(nil)

	// Step 1: Create project
	createReq := &entities.CreateProjectExtendedRequest{
		Title:                 "Complete Workflow Test Project",
		Description:           "Testing the complete project workflow",
		Category:              "technology",
		FundingGoal:           100000.0,
		Currency:              "USD",
		MinFundingRequired:    10000.0,
		StartDate:             time.Now(),
		EndDate:               time.Now().AddDate(0, 12, 0),
		IntendedUseOfFunds:    "Development of new software platform and marketing",
		DetailedUseOfFunds: map[string]interface{}{
			"equipment":   "40% for development tools",
			"marketing":   "30% for marketing campaigns",
			"operations":  "20% for operational costs",
			"development": "10% for R&D",
		},
		RiskLevel:             "medium",
		ExpectedReturn:        20.0,
		ExpectedReturnPeriod:  18,
		ShariaCompliant:       true,
		FundingDeadline:       time.Now().AddDate(0, 2, 0),
	}

	project, err := service.CreateProject(ctx, createReq, ownerID)
	assert.NoError(t, err)
	assert.NotNil(t, project)

	// Step 2: Submit for approval
	err = service.SubmitProjectForApproval(ctx, project.ID, ownerID)
	assert.NoError(t, err)

	// Step 3: Approve project
	approveReq := &entities.ProjectExtendedApprovalRequest{
		ProjectID: project.ID,
		Comments:  "Project approved after thorough review",
		Conditions: []string{
			"Monthly progress reports",
			"Quarterly financial reviews",
		},
	}
	err = service.ApproveProject(ctx, approveReq, uuid.New())
	assert.NoError(t, err)

	// Step 4: Create milestone
	milestoneReq := &entities.CreateMilestoneRequest{
		Title:        "Project Planning",
		Description:  "Complete project planning phase",
		Type:         "planning",
		DueDate:      time.Now().AddDate(0, 1, 0),
		Budget:       10000.0,
		Deliverables: []string{"Project plan", "Requirements doc"},
	}
	milestone, err := service.CreateMilestone(ctx, project.ID, milestoneReq, ownerID)
	assert.NoError(t, err)
	assert.NotNil(t, milestone)

	// Step 5: Create progress report
	progressReq := &entities.CreateProgressReportRequest{
		ReportDate:      time.Now(),
		OverallProgress: 25.0,
		MilestoneProgress: map[string]float64{
			"planning": 100.0,
		},
		BudgetUtilization: 25.0,
		TimelineStatus:    "on_track",
		KeyAchievements:   []string{"Completed planning phase"},
		Challenges:        []string{"Resource allocation"},
		NextSteps:         []string{"Begin development phase"},
		Notes:             "Project is progressing as planned",
	}
	progress, err := service.CreateProgressReport(ctx, project.ID, progressReq, ownerID)
	assert.NoError(t, err)
	assert.NotNil(t, progress)

	// Step 6: Get profit sharing projection
	projection, err := service.CalculateProfitSharingProjection(ctx, project.ID)
	assert.NoError(t, err)
	assert.NotNil(t, projection)

	// Step 7: Get analytics
	analytics, err := service.GetProjectAnalytics(ctx, project.ID)
	assert.NoError(t, err)
	assert.NotNil(t, analytics)

	// Verify all audit operations were called
	mockAuditService.AssertExpectations(t)
	assert.Equal(t, 6, len(mockAuditService.Calls)) // Create project, submit, approve, create milestone, create progress, analytics
}
