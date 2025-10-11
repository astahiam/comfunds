package handlers

import (
	"hajifund-frontend/models"

	"github.com/gofiber/fiber/v2"
)

// InfoPembiayaanPage renders the financing information page
func InfoPembiayaanPage(c *fiber.Ctx) error {
	// Optional current user (set by OptionalAuth middleware)
	var currentUser *models.User
	if u := c.Locals("user"); u != nil {
		if usr, ok := u.(*models.User); ok {
			currentUser = usr
		}
	}

	return c.Render("info-pembiayaan", fiber.Map{
		"Title": "Info Pembiayaan - HajiFund",
		"User":  currentUser,
	}, "base")
}

// AjukanPembiayaanPage renders the funding application page
func AjukanPembiayaanPage(c *fiber.Ctx) error {
	// Optional current user (set by OptionalAuth middleware)
	var currentUser *models.User
	if u := c.Locals("user"); u != nil {
		if usr, ok := u.(*models.User); ok {
			currentUser = usr
		}
	}

	return c.Render("ajukan-pembiayaan", fiber.Map{
		"Title": "Ajukan Pembiayaan - HajiFund",
		"User":  currentUser,
	}, "base")
}

// KisahSuksesPage renders the success stories page
func KisahSuksesPage(c *fiber.Ctx) error {
	// Optional current user (set by OptionalAuth middleware)
	var currentUser *models.User
	if u := c.Locals("user"); u != nil {
		if usr, ok := u.(*models.User); ok {
			currentUser = usr
		}
	}

	// Success stories data
	successStories := []map[string]string{
		{
			"title":       "Warung Makan Al-Falah",
			"description": "Berhasil mengembangkan warung makan tradisional menjadi restoran halal dengan 3 cabang di Jakarta",
			"amount":      "Rp 500.000.000",
			"duration":    "18 bulan",
			"return":      "15% per tahun",
		},
		{
			"title":       "Toko Baju Muslimah Zahra",
			"description": "Ekspansi bisnis fashion muslimah dengan sistem online dan offline yang terintegrasi",
			"amount":      "Rp 300.000.000",
			"duration":    "12 bulan",
			"return":      "18% per tahun",
		},
		{
			"title":       "Kedai Kopi Syariah",
			"description": "Membuka kedai kopi halal dengan konsep syariah di kawasan bisnis Jakarta Selatan",
			"amount":      "Rp 200.000.000",
			"duration":    "15 bulan",
			"return":      "20% per tahun",
		},
	}

	return c.Render("kisah-sukses", fiber.Map{
		"Title":          "Kisah Sukses - HajiFund",
		"SuccessStories": successStories,
		"User":           currentUser,
	}, "base")
}

// SyaratKetentuanPage renders the terms and conditions page
func SyaratKetentuanPage(c *fiber.Ctx) error {
	// Optional current user (set by OptionalAuth middleware)
	var currentUser *models.User
	if u := c.Locals("user"); u != nil {
		if usr, ok := u.(*models.User); ok {
			currentUser = usr
		}
	}

	return c.Render("syarat-ketentuan", fiber.Map{
		"Title": "Syarat dan Ketentuan - HajiFund",
		"User":  currentUser,
	}, "base")
}

// KebijakanPrivasiPage renders the privacy policy page
func KebijakanPrivasiPage(c *fiber.Ctx) error {
	// Optional current user (set by OptionalAuth middleware)
	var currentUser *models.User
	if u := c.Locals("user"); u != nil {
		if usr, ok := u.(*models.User); ok {
			currentUser = usr
		}
	}

	return c.Render("kebijakan-privasi", fiber.Map{
		"Title": "Kebijakan Privasi - HajiFund",
		"User":  currentUser,
	}, "base")
}
