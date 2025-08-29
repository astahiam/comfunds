package controllers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"comfunds/internal/auth"
	"comfunds/internal/entities"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func setupRoleController() (*RoleController, *MockUserServiceAuth) {
	mockService := new(MockUserServiceAuth)
	controller := NewRoleController(mockService)
	return controller, mockService
}

func TestRoleController_GetUserRoles(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupRoleController()

	userID := uuid.New()
	userRoles := []string{auth.RoleMember, auth.RoleInvestor}

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/user/roles", nil)
	c.Set("user_id", userID)
	c.Set("user_roles", userRoles)

	controller.GetUserRoles(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, "success", response["status"])
	data := response["data"].(map[string]interface{})
	assert.Equal(t, userID.String(), data["user_id"])
	
	// Check roles
	returnedRoles := data["roles"].([]interface{})
	assert.Len(t, returnedRoles, 2)
	assert.Contains(t, returnedRoles, auth.RoleMember)
	assert.Contains(t, returnedRoles, auth.RoleInvestor)

	// Check capabilities
	assert.Equal(t, true, data["can_invest"])
	assert.Equal(t, false, data["can_create_business"])
	assert.Equal(t, true, data["can_access_cooperative"])
}

func TestRoleController_GetUserRoles_Unauthenticated(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupRoleController()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/user/roles", nil)
	// No user_id or user_roles set

	controller.GetUserRoles(c)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestRoleController_UpdateUserRoles_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, mockService := setupRoleController()

	userID := uuid.New()
	newRoles := []string{auth.RoleMember, auth.RoleBusinessOwner}

	updatedUser := &entities.User{
		ID:    userID,
		Email: "test@example.com",
		Name:  "Test User",
		Roles: newRoles,
	}

	mockService.On("UpdateUser", mock.Anything, userID, mock.AnythingOfType("*entities.UpdateUserRequest")).Return(updatedUser, nil)

	reqBody := map[string]interface{}{
		"roles": newRoles,
	}
	jsonBody, _ := json.Marshal(reqBody)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("PUT", "/user/roles", bytes.NewBuffer(jsonBody))
	c.Request.Header.Set("Content-Type", "application/json")
	c.Set("user_id", userID)

	controller.UpdateUserRoles(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, "success", response["status"])
	data := response["data"].(map[string]interface{})
	assert.Contains(t, data, "user")
	assert.Contains(t, data, "permissions")

	mockService.AssertExpectations(t)
}

func TestRoleController_UpdateUserRoles_AdminRestriction(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupRoleController()

	userID := uuid.New()
	// Try to assign admin role
	newRoles := []string{auth.RoleMember, auth.RoleAdmin}

	reqBody := map[string]interface{}{
		"roles": newRoles,
	}
	jsonBody, _ := json.Marshal(reqBody)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("PUT", "/user/roles", bytes.NewBuffer(jsonBody))
	c.Request.Header.Set("Content-Type", "application/json")
	c.Set("user_id", userID)

	controller.UpdateUserRoles(c)

	assert.Equal(t, http.StatusForbidden, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, "error", response["status"])
	assert.Contains(t, response["message"], "Cannot assign admin role")
}

func TestRoleController_UpdateUserRoles_InvalidRoles(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupRoleController()

	userID := uuid.New()
	// Try to assign invalid role
	newRoles := []string{"invalid_role"}

	reqBody := map[string]interface{}{
		"roles": newRoles,
	}
	jsonBody, _ := json.Marshal(reqBody)

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("PUT", "/user/roles", bytes.NewBuffer(jsonBody))
	c.Request.Header.Set("Content-Type", "application/json")
	c.Set("user_id", userID)

	controller.UpdateUserRoles(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestRoleController_GetRoleInfo(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupRoleController()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/roles/info", nil)

	controller.GetRoleInfo(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, "success", response["status"])
	data := response["data"].(map[string]interface{})
	
	// Check that all expected fields are present
	assert.Contains(t, data, "available_roles")
	assert.Contains(t, data, "role_descriptions")
	assert.Contains(t, data, "role_permissions")
	assert.Contains(t, data, "role_hierarchy")

	// Check available roles
	availableRoles := data["available_roles"].([]interface{})
	assert.Contains(t, availableRoles, auth.RoleGuest)
	assert.Contains(t, availableRoles, auth.RoleMember)
	assert.Contains(t, availableRoles, auth.RoleBusinessOwner)
	assert.Contains(t, availableRoles, auth.RoleInvestor)
	assert.Contains(t, availableRoles, auth.RoleAdmin)
}

func TestRoleController_GetUsersByRole(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupRoleController()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/admin/users/role/investor", nil)
	c.Params = []gin.Param{
		{Key: "role", Value: auth.RoleInvestor},
	}

	controller.GetUsersByRole(c)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)

	assert.Equal(t, "success", response["status"])
	data := response["data"].(map[string]interface{})
	assert.Equal(t, auth.RoleInvestor, data["role"])
	assert.Contains(t, data, "users")
	assert.Contains(t, data, "total")
}

func TestRoleController_GetUsersByRole_InvalidRole(t *testing.T) {
	gin.SetMode(gin.TestMode)
	controller, _ := setupRoleController()

	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest("GET", "/admin/users/role/invalid", nil)
	c.Params = []gin.Param{
		{Key: "role", Value: "invalid_role"},
	}

	controller.GetUsersByRole(c)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}
