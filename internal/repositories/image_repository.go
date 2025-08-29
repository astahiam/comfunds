package repositories

import (
	"database/sql"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"comfunds/internal/entities"
)

type ImageRepository struct {
	db *sqlx.DB
}

func NewImageRepository(db *sqlx.DB) *ImageRepository {
	return &ImageRepository{db: db}
}

func (r *ImageRepository) Create(image *entities.Image) error {
	query := `
		INSERT INTO images (id, image_url, image_name, used_by, image_size, created_at, updated_at)
		VALUES (:id, :image_url, :image_name, :used_by, :image_size, :created_at, :updated_at)
	`
	_, err := r.db.NamedExec(query, image)
	return err
}

func (r *ImageRepository) GetByID(id uuid.UUID) (*entities.Image, error) {
	var image entities.Image
	query := `SELECT * FROM images WHERE id = $1`
	err := r.db.Get(&image, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &image, nil
}

func (r *ImageRepository) GetByUsedBy(usedBy string, limit, offset int) ([]*entities.Image, error) {
	var images []*entities.Image
	query := `
		SELECT * FROM images 
		WHERE used_by = $1 
		ORDER BY created_at DESC 
		LIMIT $2 OFFSET $3
	`
	err := r.db.Select(&images, query, usedBy, limit, offset)
	return images, err
}

func (r *ImageRepository) Update(id uuid.UUID, req *entities.UpdateImageRequest) error {
	setParts := []string{}
	args := []interface{}{}
	argIndex := 1

	if req.ImageURL != "" {
		setParts = append(setParts, fmt.Sprintf("image_url = $%d", argIndex))
		args = append(args, req.ImageURL)
		argIndex++
	}

	if req.ImageName != "" {
		setParts = append(setParts, fmt.Sprintf("image_name = $%d", argIndex))
		args = append(args, req.ImageName)
		argIndex++
	}

	if req.ImageSize != nil {
		setParts = append(setParts, fmt.Sprintf("image_size = $%d", argIndex))
		args = append(args, req.ImageSize)
		argIndex++
	}

	if len(setParts) == 0 {
		return fmt.Errorf("no fields to update")
	}

	setParts = append(setParts, fmt.Sprintf("updated_at = CURRENT_TIMESTAMP"))
	args = append(args, id)

	query := fmt.Sprintf("UPDATE images SET %s WHERE id = $%d", 
		fmt.Sprintf("%s", setParts[0:len(setParts)-1]), argIndex)
	
	for i := 1; i < len(setParts)-1; i++ {
		query = fmt.Sprintf("%s, %s", query, setParts[i])
	}
	query = fmt.Sprintf("%s, %s WHERE id = $%d", query, setParts[len(setParts)-1], argIndex)

	_, err := r.db.Exec(query, args...)
	return err
}

func (r *ImageRepository) Delete(id uuid.UUID) error {
	query := `DELETE FROM images WHERE id = $1`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return fmt.Errorf("image not found")
	}

	return nil
}

func (r *ImageRepository) GetAll(limit, offset int) ([]*entities.Image, error) {
	var images []*entities.Image
	query := `
		SELECT * FROM images 
		ORDER BY created_at DESC 
		LIMIT $1 OFFSET $2
	`
	err := r.db.Select(&images, query, limit, offset)
	return images, err
}
