package services

import (
	"context"
	"fmt"
	"strings"

	"comfunds/internal/auth"
	"comfunds/internal/entities"
	"comfunds/internal/repositories"
	"comfunds/internal/utils"

	"github.com/google/uuid"
)

type UserServiceAuth interface {
	Register(ctx context.Context, req *entities.CreateUserRequest) (*entities.User, string, string, error)
	Login(ctx context.Context, email, password string) (*entities.User, string, string, error)
	RefreshToken(ctx context.Context, refreshToken string) (string, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (*entities.User, error)
	GetUserByEmail(ctx context.Context, email string) (*entities.User, error)
	GetAllUsers(ctx context.Context, page, limit int) ([]*entities.User, int, error)
	UpdateUser(ctx context.Context, id uuid.UUID, req *entities.UpdateUserRequest) (*entities.User, error)
	DeleteUser(ctx context.Context, id uuid.UUID) error
	VerifyCooperativeMembership(ctx context.Context, userID, cooperativeID uuid.UUID) (bool, error)
}

type userServiceAuth struct {
	userRepo         repositories.UserRepositorySharded
	cooperativeRepo  repositories.CooperativeRepository
	jwtManager       *auth.JWTManager
}

func NewUserServiceAuth(
	userRepo repositories.UserRepositorySharded,
	cooperativeRepo repositories.CooperativeRepository,
	jwtManager *auth.JWTManager,
) UserServiceAuth {
	return &userServiceAuth{
		userRepo:        userRepo,
		cooperativeRepo: cooperativeRepo,
		jwtManager:      jwtManager,
	}
}

func (s *userServiceAuth) Register(ctx context.Context, req *entities.CreateUserRequest) (*entities.User, string, string, error) {
	// FR-002: Validate mandatory fields
	if err := s.validateMandatoryFields(req); err != nil {
		return nil, "", "", fmt.Errorf("validation failed: %w", err)
	}

	// Check if user already exists
	existingUser, _ := s.userRepo.GetByEmail(ctx, req.Email)
	if existingUser != nil {
		return nil, "", "", fmt.Errorf("user with email %s already exists", req.Email)
	}

	// FR-003: Verify cooperative membership before granting member roles
	if req.CooperativeID != nil && s.requiresCooperativeVerification(req.Roles) {
		cooperative, err := s.cooperativeRepo.GetByID(ctx, *req.CooperativeID)
		if err != nil {
			return nil, "", "", fmt.Errorf("invalid cooperative: %w", err)
		}
		if !cooperative.IsActive {
			return nil, "", "", fmt.Errorf("cooperative is not active")
		}
	}

	// FR-005: Enforce password complexity
	if err := s.validatePasswordComplexity(req.Password); err != nil {
		return nil, "", "", fmt.Errorf("password validation failed: %w", err)
	}

	// Hash password
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user entity
	user := &entities.User{
		ID:            uuid.New(),
		Email:         req.Email,
		Name:          req.Name,
		Password:      hashedPassword,
		Phone:         req.Phone,
		Address:       req.Address,
		CooperativeID: req.CooperativeID,
		Roles:         req.Roles,
		KYCStatus:     "pending",
		IsActive:      true,
	}

	// Create user in database
	createdUser, err := s.userRepo.Create(ctx, user)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to create user: %w", err)
	}

	// FR-004: Generate JWT tokens
	accessToken, err := s.jwtManager.Generate(createdUser.ID, createdUser.Email, createdUser.Roles, createdUser.CooperativeID)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := s.jwtManager.GenerateRefreshToken(createdUser.ID)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return createdUser, accessToken, refreshToken, nil
}

func (s *userServiceAuth) Login(ctx context.Context, email, password string) (*entities.User, string, string, error) {
	// Get user by email
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return nil, "", "", fmt.Errorf("invalid credentials")
	}

	// Check if user is active
	if !user.IsActive {
		return nil, "", "", fmt.Errorf("user account is not active")
	}

	// Verify password
	if err := utils.CheckPassword(user.Password, password); err != nil {
		return nil, "", "", fmt.Errorf("invalid credentials")
	}

	// Generate JWT tokens
	accessToken, err := s.jwtManager.Generate(user.ID, user.Email, user.Roles, user.CooperativeID)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := s.jwtManager.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, "", "", fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return user, accessToken, refreshToken, nil
}

func (s *userServiceAuth) RefreshToken(ctx context.Context, refreshToken string) (string, error) {
	// Verify refresh token
	userID, err := s.jwtManager.VerifyRefreshToken(refreshToken)
	if err != nil {
		return "", fmt.Errorf("invalid refresh token: %w", err)
	}

	// Get user details
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return "", fmt.Errorf("user not found: %w", err)
	}

	if !user.IsActive {
		return "", fmt.Errorf("user account is not active")
	}

	// Generate new access token
	accessToken, err := s.jwtManager.Generate(user.ID, user.Email, user.Roles, user.CooperativeID)
	if err != nil {
		return "", fmt.Errorf("failed to generate access token: %w", err)
	}

	return accessToken, nil
}

func (s *userServiceAuth) GetUserByID(ctx context.Context, id uuid.UUID) (*entities.User, error) {
	return s.userRepo.GetByID(ctx, id)
}

func (s *userServiceAuth) GetUserByEmail(ctx context.Context, email string) (*entities.User, error) {
	return s.userRepo.GetByEmail(ctx, email)
}

func (s *userServiceAuth) GetAllUsers(ctx context.Context, page, limit int) ([]*entities.User, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	users, err := s.userRepo.GetAll(ctx, limit, offset)
	if err != nil {
		return nil, 0, err
	}

	total, err := s.userRepo.Count(ctx)
	if err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

func (s *userServiceAuth) UpdateUser(ctx context.Context, id uuid.UUID, req *entities.UpdateUserRequest) (*entities.User, error) {
	// Check if user exists
	existingUser, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	// Update only provided fields
	if req.Name != "" {
		existingUser.Name = req.Name
	}
	if req.Phone != "" {
		existingUser.Phone = req.Phone
	}
	if req.Address != "" {
		existingUser.Address = req.Address
	}
	if len(req.Roles) > 0 {
		// Verify cooperative membership for role changes
		if existingUser.CooperativeID != nil && s.requiresCooperativeVerification(req.Roles) {
			cooperative, err := s.cooperativeRepo.GetByID(ctx, *existingUser.CooperativeID)
			if err != nil {
				return nil, fmt.Errorf("invalid cooperative: %w", err)
			}
			if !cooperative.IsActive {
				return nil, fmt.Errorf("cooperative is not active")
			}
		}
		existingUser.Roles = req.Roles
	}

	return s.userRepo.Update(ctx, id, existingUser)
}

func (s *userServiceAuth) DeleteUser(ctx context.Context, id uuid.UUID) error {
	// Check if user exists
	_, err := s.userRepo.GetByID(ctx, id)
	if err != nil {
		return err
	}

	return s.userRepo.Delete(ctx, id)
}

func (s *userServiceAuth) VerifyCooperativeMembership(ctx context.Context, userID, cooperativeID uuid.UUID) (bool, error) {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return false, err
	}

	if user.CooperativeID == nil {
		return false, nil
	}

	return *user.CooperativeID == cooperativeID, nil
}

// Helper methods

func (s *userServiceAuth) validateMandatoryFields(req *entities.CreateUserRequest) error {
	if req.Email == "" {
		return fmt.Errorf("email is required")
	}
	if req.Name == "" {
		return fmt.Errorf("name is required")
	}
	if req.Phone == "" {
		return fmt.Errorf("phone is required")
	}
	if req.Address == "" {
		return fmt.Errorf("address is required")
	}
	if len(req.Roles) == 0 {
		return fmt.Errorf("at least one role is required")
	}
	return nil
}

func (s *userServiceAuth) requiresCooperativeVerification(roles []string) bool {
	verificationRequiredRoles := []string{"member", "business_owner", "investor"}
	
	for _, role := range roles {
		for _, reqRole := range verificationRequiredRoles {
			if role == reqRole {
				return true
			}
		}
	}
	return false
}

func (s *userServiceAuth) validatePasswordComplexity(password string) error {
	if len(password) < 8 {
		return fmt.Errorf("password must be at least 8 characters long")
	}
	
	hasUpper := false
	hasLower := false
	hasDigit := false
	hasSpecial := false
	
	for _, char := range password {
		switch {
		case 'A' <= char && char <= 'Z':
			hasUpper = true
		case 'a' <= char && char <= 'z':
			hasLower = true
		case '0' <= char && char <= '9':
			hasDigit = true
		case strings.ContainsRune("!@#$%^&*()_+-=[]{}|;:,.<>?", char):
			hasSpecial = true
		}
	}
	
	if !hasUpper {
		return fmt.Errorf("password must contain at least one uppercase letter")
	}
	if !hasLower {
		return fmt.Errorf("password must contain at least one lowercase letter")
	}
	if !hasDigit {
		return fmt.Errorf("password must contain at least one digit")
	}
	if !hasSpecial {
		return fmt.Errorf("password must contain at least one special character")
	}
	
	return nil
}
