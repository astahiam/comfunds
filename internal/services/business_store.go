package services

import (
	"sync"

	"comfunds/internal/entities"

	"github.com/google/uuid"
)

// Global business store for testing
var (
	GlobalBusinessStore = NewBusinessStore()
)

type BusinessStore struct {
	businesses []*entities.BusinessExtended
	mutex      sync.RWMutex
}

func NewBusinessStore() *BusinessStore {
	return &BusinessStore{
		businesses: make([]*entities.BusinessExtended, 0),
	}
}

func (s *BusinessStore) AddBusiness(business *entities.BusinessExtended) {
	s.mutex.Lock()
	defer s.mutex.Unlock()
	s.businesses = append(s.businesses, business)
}

func (s *BusinessStore) GetBusinessByID(id uuid.UUID) *entities.BusinessExtended {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	for _, business := range s.businesses {
		if business.ID == id {
			return business
		}
	}
	return nil
}

func (s *BusinessStore) GetBusinessesByOwner(ownerID uuid.UUID) []*entities.BusinessExtended {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	var result []*entities.BusinessExtended
	for _, business := range s.businesses {
		if business.OwnerID == ownerID {
			result = append(result, business)
		}
	}
	return result
}

func (s *BusinessStore) GetPendingBusinesses(cooperativeID *uuid.UUID) []*entities.BusinessExtended {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	var result []*entities.BusinessExtended
	for _, business := range s.businesses {
		if business.ApprovalStatus == "pending" {
			if cooperativeID == nil || (business.CooperativeID != uuid.Nil && business.CooperativeID == *cooperativeID) {
				result = append(result, business)
			}
		}
	}
	return result
}

func (s *BusinessStore) UpdateBusinessStatus(businessID uuid.UUID, status string) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	for _, business := range s.businesses {
		if business.ID == businessID {
			business.ApprovalStatus = status
			break
		}
	}
}

func (s *BusinessStore) GetAllBusinesses() []*entities.BusinessExtended {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	// Return a copy to avoid race conditions
	result := make([]*entities.BusinessExtended, len(s.businesses))
	copy(result, s.businesses)
	return result
}
