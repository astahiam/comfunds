package entities

import (
	"time"

	"github.com/google/uuid"
)

// BusinessExtended represents comprehensive business management (FR-024 to FR-031)
type BusinessExtended struct {
	ID                 uuid.UUID              `json:"id" db:"id"`
	Name               string                 `json:"name" db:"name"`
	Type               string                 `json:"type" db:"type"`
	Description        string                 `json:"description" db:"description"`
	OwnerID            uuid.UUID              `json:"owner_id" db:"owner_id"`
	CooperativeID      uuid.UUID              `json:"cooperative_id" db:"cooperative_id"`
	RegistrationNumber string                 `json:"registration_number" db:"registration_number"`
	TaxID              string                 `json:"tax_id" db:"tax_id"`
	LegalStructure     string                 `json:"legal_structure" db:"legal_structure"`
	Industry           string                 `json:"industry" db:"industry"`
	Sector             string                 `json:"sector" db:"sector"`
	Address            string                 `json:"address" db:"address"`
	Phone              string                 `json:"phone" db:"phone"`
	Email              string                 `json:"email" db:"email"`
	Website            string                 `json:"website" db:"website"`
	EstablishedDate    time.Time              `json:"established_date" db:"established_date"`
	EmployeeCount      int                    `json:"employee_count" db:"employee_count"`
	AnnualRevenue      float64                `json:"annual_revenue" db:"annual_revenue"`
	Currency           string                 `json:"currency" db:"currency"`
	BankAccount        string                 `json:"bank_account" db:"bank_account"`
	BusinessLicense    string                 `json:"business_license" db:"business_license"`
	Documents          []string               `json:"documents" db:"documents"`
	Status             string                 `json:"status" db:"status"` // draft, pending_approval, approved, rejected, suspended, active, inactive
	ApprovalStatus     string                 `json:"approval_status" db:"approval_status"`
	ApprovedBy         *uuid.UUID             `json:"approved_by" db:"approved_by"`
	ApprovedAt         *time.Time             `json:"approved_at" db:"approved_at"`
	RejectionReason    string                 `json:"rejection_reason" db:"rejection_reason"`
	Metadata           map[string]interface{} `json:"metadata" db:"metadata"`
	PerformanceMetrics map[string]interface{} `json:"performance_metrics" db:"performance_metrics"`
	ComplianceStatus   map[string]interface{} `json:"compliance_status" db:"compliance_status"`
	IsActive           bool                   `json:"is_active" db:"is_active"`
	CreatedAt          time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt          time.Time              `json:"updated_at" db:"updated_at"`
}

// BusinessPerformanceMetrics tracks business performance (FR-030)
type BusinessPerformanceMetrics struct {
	ID                   uuid.UUID              `json:"id" db:"id"`
	BusinessID           uuid.UUID              `json:"business_id" db:"business_id"`
	MetricType           string                 `json:"metric_type" db:"metric_type"` // revenue, profit, growth, efficiency
	Period               string                 `json:"period" db:"period"`           // monthly, quarterly, yearly
	PeriodStart          time.Time              `json:"period_start" db:"period_start"`
	PeriodEnd            time.Time              `json:"period_end" db:"period_end"`
	Revenue              float64                `json:"revenue" db:"revenue"`
	Expenses             float64                `json:"expenses" db:"expenses"`
	NetProfit            float64                `json:"net_profit" db:"net_profit"`
	GrossMargin          float64                `json:"gross_margin" db:"gross_margin"`
	OperatingMargin      float64                `json:"operating_margin" db:"operating_margin"`
	CustomerCount        int                    `json:"customer_count" db:"customer_count"`
	OrderCount           int                    `json:"order_count" db:"order_count"`
	AverageOrderValue    float64                `json:"average_order_value" db:"average_order_value"`
	CustomerAcquisition  int                    `json:"customer_acquisition" db:"customer_acquisition"`
	CustomerRetention    float64                `json:"customer_retention" db:"customer_retention"`
	MarketShare          float64                `json:"market_share" db:"market_share"`
	GrowthRate           float64                `json:"growth_rate" db:"growth_rate"`
	EmployeeProductivity float64                `json:"employee_productivity" db:"employee_productivity"`
	KPIs                 map[string]interface{} `json:"kpis" db:"kpis"`
	Benchmarks           map[string]interface{} `json:"benchmarks" db:"benchmarks"`
	Goals                map[string]interface{} `json:"goals" db:"goals"`
	Notes                string                 `json:"notes" db:"notes"`
	RecordedBy           uuid.UUID              `json:"recorded_by" db:"recorded_by"`
	CreatedAt            time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt            time.Time              `json:"updated_at" db:"updated_at"`
}

// BusinessFinancialReport for investor reporting (FR-031)
type BusinessFinancialReport struct {
	ID               uuid.UUID              `json:"id" db:"id"`
	BusinessID       uuid.UUID              `json:"business_id" db:"business_id"`
	ReportType       string                 `json:"report_type" db:"report_type"` // monthly, quarterly, annual, custom
	ReportPeriod     string                 `json:"report_period" db:"report_period"`
	PeriodStart      time.Time              `json:"period_start" db:"period_start"`
	PeriodEnd        time.Time              `json:"period_end" db:"period_end"`
	Currency         string                 `json:"currency" db:"currency"`
	TotalRevenue     float64                `json:"total_revenue" db:"total_revenue"`
	TotalExpenses    float64                `json:"total_expenses" db:"total_expenses"`
	NetIncome        float64                `json:"net_income" db:"net_income"`
	GrossProfit      float64                `json:"gross_profit" db:"gross_profit"`
	OperatingIncome  float64                `json:"operating_income" db:"operating_income"`
	EBITDA           float64                `json:"ebitda" db:"ebitda"`
	Assets           float64                `json:"assets" db:"assets"`
	Liabilities      float64                `json:"liabilities" db:"liabilities"`
	Equity           float64                `json:"equity" db:"equity"`
	CashFlow         float64                `json:"cash_flow" db:"cash_flow"`
	ROI              float64                `json:"roi" db:"roi"`
	ROE              float64                `json:"roe" db:"roe"`
	DebtToEquity     float64                `json:"debt_to_equity" db:"debt_to_equity"`
	CurrentRatio     float64                `json:"current_ratio" db:"current_ratio"`
	FinancialDetails map[string]interface{} `json:"financial_details" db:"financial_details"`
	Attachments      []string               `json:"attachments" db:"attachments"`
	Summary          string                 `json:"summary" db:"summary"`
	Highlights       []string               `json:"highlights" db:"highlights"`
	Challenges       []string               `json:"challenges" db:"challenges"`
	Outlook          string                 `json:"outlook" db:"outlook"`
	ApprovalRequired bool                   `json:"approval_required" db:"approval_required"`
	ApprovedBy       *uuid.UUID             `json:"approved_by" db:"approved_by"`
	ApprovedAt       *time.Time             `json:"approved_at" db:"approved_at"`
	Status           string                 `json:"status" db:"status"` // draft, submitted, approved, published
	PublishedAt      *time.Time             `json:"published_at" db:"published_at"`
	GeneratedBy      uuid.UUID              `json:"generated_by" db:"generated_by"`
	CreatedAt        time.Time              `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time              `json:"updated_at" db:"updated_at"`
}

// Business status constants
const (
	BusinessStatusDraft           = "draft"
	BusinessStatusPendingApproval = "pending_approval"
	BusinessStatusApproved        = "approved"
	BusinessStatusRejected        = "rejected"
	BusinessStatusSuspended       = "suspended"
	BusinessStatusActive          = "active"
	BusinessStatusInactive        = "inactive"

	BusinessTypeManufacturing = "manufacturing"
	BusinessTypeRetail        = "retail"
	BusinessTypeServices      = "services"
	BusinessTypeTechnology    = "technology"
	BusinessTypeAgriculture   = "agriculture"
	BusinessTypeConstruction  = "construction"
	BusinessTypeHealthcare    = "healthcare"
	BusinessTypeEducation     = "education"
	BusinessTypeFinance       = "finance"
	BusinessTypeOther         = "other"

	ReportTypeMonthly   = "monthly"
	ReportTypeQuarterly = "quarterly"
	ReportTypeAnnual    = "annual"
	ReportTypeCustom    = "custom"
)

// CreateBusinessExtendedRequest for FR-024 and FR-025 (enhanced version)
type CreateBusinessExtendedRequest struct {
	Name               string                 `json:"name" validate:"required,min=2,max=200"`
	Type               string                 `json:"type" validate:"required,oneof=manufacturing retail services technology agriculture construction healthcare education finance other"`
	Description        string                 `json:"description" validate:"required,min=10,max=1000"`
	RegistrationNumber string                 `json:"registration_number" validate:"required"`
	TaxID              string                 `json:"tax_id"`
	LegalStructure     string                 `json:"legal_structure" validate:"required"`
	Industry           string                 `json:"industry" validate:"required"`
	Sector             string                 `json:"sector"`
	Address            string                 `json:"address" validate:"required"`
	Phone              string                 `json:"phone" validate:"required"`
	Email              string                 `json:"email" validate:"required,email"`
	Website            string                 `json:"website"`
	EstablishedDate    time.Time              `json:"established_date" validate:"required"`
	EmployeeCount      int                    `json:"employee_count" validate:"min=0"`
	AnnualRevenue      float64                `json:"annual_revenue" validate:"min=0"`
	Currency           string                 `json:"currency" validate:"required,len=3"`
	BankAccount        string                 `json:"bank_account" validate:"required"`
	BusinessLicense    string                 `json:"business_license"`
	Documents          []string               `json:"documents"`
	Metadata           map[string]interface{} `json:"metadata"`
}

// UpdateBusinessExtendedRequest for FR-028 (enhanced version)
type UpdateBusinessExtendedRequest struct {
	Name            string                 `json:"name" validate:"min=2,max=200"`
	Type            string                 `json:"type" validate:"oneof=manufacturing retail services technology agriculture construction healthcare education finance other"`
	Description     string                 `json:"description" validate:"min=10,max=1000"`
	Industry        string                 `json:"industry"`
	Sector          string                 `json:"sector"`
	Address         string                 `json:"address"`
	Phone           string                 `json:"phone"`
	Email           string                 `json:"email" validate:"email"`
	Website         string                 `json:"website"`
	EmployeeCount   int                    `json:"employee_count" validate:"min=0"`
	AnnualRevenue   float64                `json:"annual_revenue" validate:"min=0"`
	BankAccount     string                 `json:"bank_account"`
	BusinessLicense string                 `json:"business_license"`
	Documents       []string               `json:"documents"`
	Metadata        map[string]interface{} `json:"metadata"`
}

// CreatePerformanceMetricsRequest for FR-030
type CreatePerformanceMetricsRequest struct {
	MetricType           string                 `json:"metric_type" validate:"required,oneof=revenue profit growth efficiency"`
	Period               string                 `json:"period" validate:"required,oneof=monthly quarterly yearly"`
	PeriodStart          time.Time              `json:"period_start" validate:"required"`
	PeriodEnd            time.Time              `json:"period_end" validate:"required"`
	Revenue              float64                `json:"revenue" validate:"min=0"`
	Expenses             float64                `json:"expenses" validate:"min=0"`
	CustomerCount        int                    `json:"customer_count" validate:"min=0"`
	OrderCount           int                    `json:"order_count" validate:"min=0"`
	AverageOrderValue    float64                `json:"average_order_value" validate:"min=0"`
	CustomerAcquisition  int                    `json:"customer_acquisition" validate:"min=0"`
	CustomerRetention    float64                `json:"customer_retention" validate:"min=0,max=1"`
	MarketShare          float64                `json:"market_share" validate:"min=0,max=1"`
	GrowthRate           float64                `json:"growth_rate"`
	EmployeeProductivity float64                `json:"employee_productivity" validate:"min=0"`
	KPIs                 map[string]interface{} `json:"kpis"`
	Goals                map[string]interface{} `json:"goals"`
	Notes                string                 `json:"notes" validate:"max=1000"`
}

// CreateFinancialReportRequest for FR-031
type CreateFinancialReportRequest struct {
	ReportType       string                 `json:"report_type" validate:"required,oneof=monthly quarterly annual custom"`
	PeriodStart      time.Time              `json:"period_start" validate:"required"`
	PeriodEnd        time.Time              `json:"period_end" validate:"required"`
	Currency         string                 `json:"currency" validate:"required,len=3"`
	TotalRevenue     float64                `json:"total_revenue" validate:"required,min=0"`
	TotalExpenses    float64                `json:"total_expenses" validate:"required,min=0"`
	Assets           float64                `json:"assets" validate:"min=0"`
	Liabilities      float64                `json:"liabilities" validate:"min=0"`
	CashFlow         float64                `json:"cash_flow"`
	FinancialDetails map[string]interface{} `json:"financial_details"`
	Attachments      []string               `json:"attachments"`
	Summary          string                 `json:"summary" validate:"required,min=10,max=2000"`
	Highlights       []string               `json:"highlights"`
	Challenges       []string               `json:"challenges"`
	Outlook          string                 `json:"outlook" validate:"max=1000"`
}

// BusinessFilter for querying businesses
type BusinessFilter struct {
	OwnerID       *uuid.UUID `json:"owner_id"`
	CooperativeID *uuid.UUID `json:"cooperative_id"`
	Type          string     `json:"type"`
	Industry      string     `json:"industry"`
	Status        string     `json:"status"`
	MinRevenue    float64    `json:"min_revenue"`
	MaxRevenue    float64    `json:"max_revenue"`
	MinEmployees  int        `json:"min_employees"`
	MaxEmployees  int        `json:"max_employees"`
	Page          int        `json:"page"`
	Limit         int        `json:"limit"`
	SortBy        string     `json:"sort_by"`    // name, created_at, revenue, employees
	SortOrder     string     `json:"sort_order"` // asc, desc
}

// BusinessApprovalRequest for FR-027
type BusinessApprovalRequest struct {
	BusinessID uuid.UUID `json:"business_id" validate:"required"`
	Comments   string    `json:"comments" validate:"max=1000"`
	Conditions []string  `json:"conditions"`
}

// BusinessRejectionRequest for FR-027
type BusinessRejectionRequest struct {
	BusinessID uuid.UUID `json:"business_id" validate:"required"`
	Reason     string    `json:"reason" validate:"required,min=10,max=1000"`
	Feedback   string    `json:"feedback" validate:"max=2000"`
}
