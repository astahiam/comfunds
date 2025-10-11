package handlers

import (
	"hajifund-frontend/models"

	"github.com/gofiber/fiber/v2"
)

// AboutPage renders the about us page with founder information
func AboutPage(c *fiber.Ctx) error {
	// Optional current user (set by OptionalAuth middleware)
	var currentUser *models.User
	if u := c.Locals("user"); u != nil {
		if usr, ok := u.(*models.User); ok {
			currentUser = usr
		}
	}

	// Founder information
	founders := []map[string]string{
		{
			"name":        "Dr(c). Ir. Nandra D Dwaputra, M.M",
			"title":       "Co-Founder & CEO",
			"description": "Ahli di bidang teknologi dan manajemen dengan pengalaman luas dalam pengembangan platform digital syariah.",
			"image":       "/static/images/founders/pak-nandra.jpg",
		},
		{
			"name":        "Dr(c). Ryan K Rakhmat, S.Kom. M.M",
			"title":       "Co-Founder & CTO", 
			"description": "Spesialis teknologi informasi dan sistem keuangan syariah dengan fokus pada inovasi fintech Islami.",
			"image":       "/static/images/founders/pak-ryan.jpg",
		},
	}

	return c.Render("about", fiber.Map{
		"Title":    "Tentang Kami - HajiFund",
		"Founders": founders,
		"User":     currentUser,
	}, "base")
}
