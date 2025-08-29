package services

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"comfunds/internal/entities"
	"comfunds/internal/repositories"
)

type ImageService struct {
	imageRepo *repositories.ImageRepository
}

func NewImageService(imageRepo *repositories.ImageRepository) *ImageService {
	return &ImageService{
		imageRepo: imageRepo,
	}
}

func (s *ImageService) CreateImage(req *entities.CreateImageRequest) (*entities.Image, error) {
	image := &entities.Image{
		ID:        uuid.New(),
		ImageURL:  req.ImageURL,
		ImageName: req.ImageName,
		UsedBy:    req.UsedBy,
		ImageSize: req.ImageSize,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	err := s.imageRepo.Create(image)
	if err != nil {
		return nil, err
	}

	return image, nil
}

func (s *ImageService) GetImageByID(id uuid.UUID) (*entities.Image, error) {
	return s.imageRepo.GetByID(id)
}

func (s *ImageService) GetImagesByUsedBy(usedBy string, limit, offset int) ([]*entities.Image, error) {
	// Validate usedBy parameter
	validUsedBy := map[string]bool{
		entities.ImageUsedByProjects:     true,
		entities.ImageUsedByUsers:        true,
		entities.ImageUsedByCooperatives: true,
		entities.ImageUsedByBusinesses:   true,
	}

	if !validUsedBy[usedBy] {
		return nil, fmt.Errorf("invalid used_by value: %s", usedBy)
	}

	return s.imageRepo.GetByUsedBy(usedBy, limit, offset)
}

func (s *ImageService) UpdateImage(id uuid.UUID, req *entities.UpdateImageRequest) (*entities.Image, error) {
	// Check if image exists
	existingImage, err := s.imageRepo.GetByID(id)
	if err != nil {
		return nil, err
	}
	if existingImage == nil {
		return nil, fmt.Errorf("image not found")
	}

	err = s.imageRepo.Update(id, req)
	if err != nil {
		return nil, err
	}

	// Return updated image
	return s.imageRepo.GetByID(id)
}

func (s *ImageService) DeleteImage(id uuid.UUID) error {
	// Check if image exists
	existingImage, err := s.imageRepo.GetByID(id)
	if err != nil {
		return err
	}
	if existingImage == nil {
		return fmt.Errorf("image not found")
	}

	return s.imageRepo.Delete(id)
}

func (s *ImageService) GetAllImages(limit, offset int) ([]*entities.Image, error) {
	return s.imageRepo.GetAll(limit, offset)
}
