package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"comfunds/internal/entities"
)

type UserRepository interface {
	Create(user *entities.User) (*entities.User, error)
	GetByID(id int) (*entities.User, error)
	GetByEmail(email string) (*entities.User, error)
	GetAll(limit, offset int) ([]*entities.User, error)
	Update(id int, user *entities.User) (*entities.User, error)
	Delete(id int) error
	Count() (int, error)
}

type userRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(user *entities.User) (*entities.User, error) {
	query := `
		INSERT INTO users (email, name, password, phone, address, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at, updated_at
	`
	
	now := time.Now()
	user.IsActive = true
	user.CreatedAt = now
	user.UpdatedAt = now

	err := r.db.QueryRow(
		query,
		user.Email,
		user.Name,
		user.Password,
		user.Phone,
		user.Address,
		user.IsActive,
		user.CreatedAt,
		user.UpdatedAt,
	).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return user, nil
}

func (r *userRepository) GetByID(id int) (*entities.User, error) {
	query := `
		SELECT id, email, name, password, phone, address, is_active, created_at, updated_at
		FROM users
		WHERE id = $1 AND is_active = true
	`

	user := &entities.User{}
	err := r.db.QueryRow(query, id).Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&user.Password,
		&user.Phone,
		&user.Address,
		&user.IsActive,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return user, nil
}

func (r *userRepository) GetByEmail(email string) (*entities.User, error) {
	query := `
		SELECT id, email, name, password, phone, address, is_active, created_at, updated_at
		FROM users
		WHERE email = $1 AND is_active = true
	`

	user := &entities.User{}
	err := r.db.QueryRow(query, email).Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&user.Password,
		&user.Phone,
		&user.Address,
		&user.IsActive,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return user, nil
}

func (r *userRepository) GetAll(limit, offset int) ([]*entities.User, error) {
	query := `
		SELECT id, email, name, password, phone, address, is_active, created_at, updated_at
		FROM users
		WHERE is_active = true
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`

	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get users: %w", err)
	}
	defer rows.Close()

	var users []*entities.User
	for rows.Next() {
		user := &entities.User{}
		err := rows.Scan(
			&user.ID,
			&user.Email,
			&user.Name,
			&user.Password,
			&user.Phone,
			&user.Address,
			&user.IsActive,
			&user.CreatedAt,
			&user.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	return users, nil
}

func (r *userRepository) Update(id int, user *entities.User) (*entities.User, error) {
	query := `
		UPDATE users
		SET name = $2, phone = $3, address = $4, updated_at = $5
		WHERE id = $1 AND is_active = true
		RETURNING id, email, name, phone, address, is_active, created_at, updated_at
	`

	user.UpdatedAt = time.Now()
	
	err := r.db.QueryRow(
		query,
		id,
		user.Name,
		user.Phone,
		user.Address,
		user.UpdatedAt,
	).Scan(
		&user.ID,
		&user.Email,
		&user.Name,
		&user.Phone,
		&user.Address,
		&user.IsActive,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	return user, nil
}

func (r *userRepository) Delete(id int) error {
	query := `
		UPDATE users
		SET is_active = false, updated_at = $2
		WHERE id = $1 AND is_active = true
	`

	result, err := r.db.Exec(query, id, time.Now())
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get affected rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	return nil
}

func (r *userRepository) Count() (int, error) {
	query := `SELECT COUNT(*) FROM users WHERE is_active = true`
	
	var count int
	err := r.db.QueryRow(query).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count users: %w", err)
	}

	return count, nil
}
