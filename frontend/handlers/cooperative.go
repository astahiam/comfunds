package handlers

import (
	"github.com/gofiber/fiber/v2"
)

// CooperativeHandler methods
func (h *Handler) CooperativeDashboard(c *fiber.Ctx) error {
	return c.Render("cooperative/dashboard", fiber.Map{
		"Title": "Dashboard - Cooperative Admin",
	})
}

func (h *Handler) MembersPage(c *fiber.Ctx) error {
	return c.Render("cooperative/members", fiber.Map{
		"Title": "Members - Cooperative Admin",
	})
}

func (h *Handler) CooperativeProjectsPage(c *fiber.Ctx) error {
	return c.Render("cooperative/projects", fiber.Map{
		"Title": "Projects - Cooperative Admin",
	})
}

func (h *Handler) CooperativeBusinessesPage(c *fiber.Ctx) error {
	return c.Render("cooperative/businesses", fiber.Map{
		"Title": "Businesses - Cooperative Admin",
	})
}

func (h *Handler) ApproveMember(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Member approved",
	})
}

func (h *Handler) CooperativeApproveProject(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Project approved",
	})
}

func (h *Handler) CooperativeApproveBusiness(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Business approved",
	})
}

func (h *Handler) DisburseInvestment(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Investment disbursed",
	})
}
