package services

import (
	"fmt"

	"comfunds/internal/entities"
	"comfunds/internal/repositories"
	"comfunds/internal/utils"
)

type UserService interface {
	CreateUser(req *entities.CreateUserRequest) (*entities.User, error)
	GetUserByID(id int) (*entities.User, error)
	GetUserByEmail(email string) (*entities.User, error)
	GetAllUsers(page, limit int) ([]*entities.User, int, error)
	UpdateUser(id int, req *entities.UpdateUserRequest) (*entities.User, error)
	DeleteUser(id int) error
}

type userService struct {
	userRepo repositories.UserRepository
}

func NewUserService(userRepo repositories.UserRepository) UserService {
	return &userService{
		userRepo: userRepo,
	}
}

func (s *userService) CreateUser(req *entities.CreateUserRequest) (*entities.User, error) {
	// Check if user already exists
	existingUser, _ := s.userRepo.GetByEmail(req.Email)
	if existingUser != nil {
		return nil, fmt.Errorf("user with email %s already exists", req.Email)
	}

	// Hash password
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	user := &entities.User{
		Email:    req.Email,
		Name:     req.Name,
		Password: hashedPassword,
		Phone:    req.Phone,
		Address:  req.Address,
	}

	return s.userRepo.Create(user)
}

func (s *userService) GetUserByID(id int) (*entities.User, error) {
	return s.userRepo.GetByID(id)
}

func (s *userService) GetUserByEmail(email string) (*entities.User, error) {
	return s.userRepo.GetByEmail(email)
}

func (s *userService) GetAllUsers(page, limit int) ([]*entities.User, int, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 10
	}

	offset := (page - 1) * limit

	users, err := s.userRepo.GetAll(limit, offset)
	if err != nil {
		return nil, 0, err
	}

	total, err := s.userRepo.Count()
	if err != nil {
		return nil, 0, err
	}

	return users, total, nil
}

func (s *userService) UpdateUser(id int, req *entities.UpdateUserRequest) (*entities.User, error) {
	// Check if user exists
	existingUser, err := s.userRepo.GetByID(id)
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

	return s.userRepo.Update(id, existingUser)
}

func (s *userService) DeleteUser(id int) error {
	// Check if user exists
	_, err := s.userRepo.GetByID(id)
	if err != nil {
		return err
	}

	return s.userRepo.Delete(id)
}
