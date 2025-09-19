package handlers

import (
	"hajifund-frontend/models"
	"hajifund-frontend/utils"

	"github.com/gofiber/fiber/v2"
)

type Handler struct{}

func NewDashboardHandler() *Handler {
	return &Handler{}
}

func NewAdminHandler() *Handler {
	return &Handler{}
}

func NewCooperativeHandler() *Handler {
	return &Handler{}
}

func NewProjectHandler() *Handler {
	return &Handler{}
}

func NewInvestmentHandler() *Handler {
	return &Handler{}
}

// Common helper methods
func (h *Handler) getUserFromContext(c *fiber.Ctx) *models.User {
	if user := c.Locals("user"); user != nil {
		if u, ok := user.(*models.User); ok {
			return u
		}
	}
	return nil
}

func (h *Handler) getAuthToken(c *fiber.Ctx) string {
	return c.Cookies("auth_token")
}

func (h *Handler) makeAuthenticatedRequest(method, endpoint string, body interface{}, c *fiber.Ctx) (*utils.APIResponse, error) {
	token := h.getAuthToken(c)
	headers := utils.GetAuthHeaders(token)
	return utils.MakeAPIRequest(method, endpoint, body, headers)
}
