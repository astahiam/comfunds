#!/bin/bash

# Fix Landing Handler Errors
# This script fixes the missing getStringValue function in landing handler

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step "Fixing Landing Handler Errors"

# 1. Stop services to prevent further issues
print_step "1. Stopping services to prevent further issues..."

systemctl stop hajifund-frontend
systemctl stop hajifund-backend

print_status "Services stopped"

# 2. Fix landing handler
print_step "2. Fixing landing handler..."

if [ -f "/var/www/hajifund/frontend/handlers/landing.go" ]; then
    print_info "Backing up current landing.go..."
    cp /var/www/hajifund/frontend/handlers/landing.go /var/www/hajifund/frontend/handlers/landing.go.backup
    
    print_info "Fixing landing handler to include getStringValue function..."
    
    # Create a fixed version of landing.go
    cat > /tmp/landing_fixed.go << 'EOF'
package handlers

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gofiber/fiber/v2"
)

type LandingHandler struct{}

// getStringValue safely extracts string value from map
func getStringValue(data map[string]interface{}, key string) string {
	if value, exists := data[key]; exists {
		if str, ok := value.(string); ok {
			return str
		}
	}
	return ""
}

// getStringSliceValue safely extracts string slice from map
func getStringSliceValue(data map[string]interface{}, key string) []string {
	if value, exists := data[key]; exists {
		if slice, ok := value.([]interface{}); ok {
			result := make([]string, len(slice))
			for i, v := range slice {
				if str, ok := v.(string); ok {
					result[i] = str
				}
			}
			return result
		}
	}
	return []string{}
}

// getMapValue safely extracts map value from map
func getMapValue(data map[string]interface{}, key string) map[string]interface{} {
	if value, exists := data[key]; exists {
		if m, ok := value.(map[string]interface{}); ok {
			return m
		}
	}
	return map[string]interface{}{}
}

// LandingPage renders the landing page
func (h *LandingHandler) LandingPage(c *fiber.Ctx) error {
	// Fetch hero data from backend
	heroData, err := h.fetchHeroData()
	if err != nil {
		log.Printf("Failed to fetch hero data: %v", err)
		// Use default data if backend is unavailable
		heroData = h.getDefaultHeroData()
	}

	// Extract hero content
	heroContent := getMapValue(heroData, "hero_content")
	
	// Extract title and subtitle
	title := getStringValue(heroContent, "title")
	subtitle := getStringValue(heroContent, "subtitle")
	
	// Extract CTA buttons
	ctaButtons := getStringSliceValue(heroContent, "cta_buttons")
	
	// Extract hero image
	heroImage := getMapValue(heroContent, "hero_image")
	heroImageURL := getStringValue(heroImage, "url")
	heroImageAlt := getStringValue(heroImage, "alt")

	return c.Render("landing", fiber.Map{
		"Title":         "HajiFund - Platform Investasi Syariah",
		"HeroTitle":     title,
		"HeroSubtitle":  subtitle,
		"CTAButtons":    ctaButtons,
		"HeroImageURL":  heroImageURL,
		"HeroImageAlt":  heroImageAlt,
	}, "base")
}

// fetchHeroData fetches hero data from backend
func (h *LandingHandler) fetchHeroData() (map[string]interface{}, error) {
	backendURL := "http://103.103.20.68:8080/api/v1/public/hero"
	
	resp, err := http.Get(backendURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var responseData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&responseData); err != nil {
		return nil, err
	}

	if responseData["status"] == "success" {
		return getMapValue(responseData, "data"), nil
	}

	return nil, fiber.NewError(500, "Failed to fetch hero data")
}

// getDefaultHeroData returns default hero data
func (h *LandingHandler) getDefaultHeroData() map[string]interface{} {
	return map[string]interface{}{
		"hero_content": map[string]interface{}{
			"title":    "HajiFund - Platform Investasi Syariah",
			"subtitle": "Investasi yang aman, halal, dan menguntungkan untuk masa depan Anda",
			"cta_buttons": []string{
				"Mulai Investasi",
				"Pelajari Lebih Lanjut",
			},
			"hero_image": map[string]interface{}{
				"url":  "/static/images/hero-image.jpg",
				"alt":  "HajiFund Hero Image",
			},
		},
	}
}
EOF
    
    # Replace the original file
    mv /tmp/landing_fixed.go /var/www/hajifund/frontend/handlers/landing.go
    print_status "Landing handler updated with getStringValue function"
else
    print_error "Landing handler not found"
fi

# 3. Create missing landing template
print_step "3. Creating missing landing template..."

# Create landing template
print_info "Creating landing template..."
cat > /var/www/hajifund/frontend/views/landing.html << 'EOF'
{{define "landing"}}
<div class="hero-section">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-lg-6">
                <h1 class="hero-title">{{.HeroTitle}}</h1>
                <p class="hero-subtitle">{{.HeroSubtitle}}</p>
                <div class="d-flex flex-wrap gap-3 mb-4">
                    <a href="/register" class="btn btn-success btn-lg px-4">Mulai Investasi</a>
                    <a href="/about" class="btn btn-outline-success btn-lg px-4">Pelajari Lebih Lanjut</a>
                </div>
            </div>
            <div class="col-lg-6">
                <div class="hero-image-container">
                    <img src="{{.HeroImageURL}}" alt="{{.HeroImageAlt}}" class="img-fluid">
                </div>
            </div>
        </div>
    </div>
</div>

<div class="features-section py-5">
    <div class="container">
        <div class="row text-center">
            <div class="col-12">
                <h2 class="mb-5">Mengapa Memilih HajiFund?</h2>
            </div>
        </div>
        <div class="row">
            <div class="col-md-4">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <i class="fas fa-shield-alt fa-3x text-success mb-3"></i>
                        <h5 class="card-title">Aman & Terpercaya</h5>
                        <p class="card-text">Investasi yang aman dengan sistem keamanan berlapis</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <i class="fas fa-mosque fa-3x text-success mb-3"></i>
                        <h5 class="card-title">Prinsip Syariah</h5>
                        <p class="card-text">Semua investasi mengikuti prinsip syariah yang ketat</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <i class="fas fa-chart-line fa-3x text-success mb-3"></i>
                        <h5 class="card-title">Return Menguntungkan</h5>
                        <p class="card-text">Potensi return yang menarik dengan risiko terkendali</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="stats-section py-5 bg-light">
    <div class="container">
        <div class="row text-center">
            <div class="col-md-3">
                <div class="stat-item">
                    <h3 class="stat-number">1000+</h3>
                    <p class="stat-label">Investor Aktif</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-item">
                    <h3 class="stat-number">50+</h3>
                    <p class="stat-label">Proyek Berhasil</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-item">
                    <h3 class="stat-number">15%</h3>
                    <p class="stat-label">Return Rata-rata</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="stat-item">
                    <h3 class="stat-number">99%</h3>
                    <p class="stat-label">Tingkat Kepuasan</p>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="cta-section py-5">
    <div class="container text-center">
        <h2 class="mb-4">Siap Memulai Investasi Syariah?</h2>
        <p class="lead mb-4">Bergabunglah dengan ribuan investor yang telah mempercayai HajiFund</p>
        <a href="/register" class="btn btn-success btn-lg px-5">Daftar Sekarang</a>
    </div>
</div>

<style>
.hero-section {
    padding: 100px 0;
    background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
}

.hero-title {
    font-size: 3.5rem;
    font-weight: 700;
    color: #2c3e50;
    margin-bottom: 1.5rem;
}

.hero-subtitle {
    font-size: 1.25rem;
    color: #6c757d;
    margin-bottom: 2rem;
}

.hero-image-container {
    position: relative;
    z-index: 2;
}

.hero-image-container img {
    border-radius: 15px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
}

.features-section {
    background: #fff;
}

.stat-item {
    padding: 2rem 0;
}

.stat-number {
    font-size: 3rem;
    font-weight: 700;
    color: #28a745;
    margin-bottom: 0.5rem;
}

.stat-label {
    font-size: 1.1rem;
    color: #6c757d;
    margin-bottom: 0;
}

.cta-section {
    background: linear-gradient(135deg, #28a745 0%, #20c997 100%);
    color: white;
}

.cta-section h2 {
    color: white;
}

.cta-section .lead {
    color: rgba(255,255,255,0.9);
}

@media (max-width: 768px) {
    .hero-title {
        font-size: 2.5rem;
    }
    
    .hero-subtitle {
        font-size: 1.1rem;
    }
}
</style>
{{end}}
EOF

print_status "Landing template created"

# 4. Rebuild and restart services
print_step "4. Rebuilding and restarting services..."

# Reload systemd
systemctl daemon-reload

# Build applications
print_info "Building applications..."
cd /var/www/hajifund
go build -o hajifund-backend main.go
chown www-data:www-data hajifund-backend
chmod +x hajifund-backend

cd /var/www/hajifund/frontend
go build -o hajifund-frontend main.go
chown www-data:www-data hajifund-frontend
chmod +x hajifund-frontend
setcap 'cap_net_bind_service=+ep' hajifund-frontend

# Start services
print_info "Starting services..."
systemctl start hajifund-backend
systemctl start hajifund-frontend
print_status "Services restarted with landing handler fixes"

# 5. Test the fixes
print_step "5. Testing the fixes..."

sleep 5

# Test frontend
print_info "Testing frontend..."
if curl -s http://103.103.20.68/ | grep -q "HajiFund"; then
    print_status "Frontend is responding"
else
    print_warning "Frontend might not be responding"
fi

# Test backend
print_info "Testing backend..."
if curl -s http://103.103.20.68:8080/api/v1/health | grep -q "ok"; then
    print_status "Backend is responding"
else
    print_warning "Backend might not be responding"
fi

print_status "Landing handler errors fix completed!"
print_info "Issues addressed:"
print_info "1. Added getStringValue function"
print_info "2. Added getStringSliceValue function"
print_info "3. Added getMapValue function"
print_info "4. Created landing template"
print_info "5. Services rebuilt and restarted"

print_info "Key fixes:"
print_info "1. Safe string extraction from maps"
print_info "2. Safe slice extraction from maps"
print_info "3. Safe map extraction from maps"
print_info "4. Error handling for backend calls"
print_info "5. Default data fallback"

print_info "Test your application now:"
print_info "1. Check that services are running"
print_info "2. Test landing page"
print_info "3. Verify no compilation errors"
print_info "4. Check that landing page renders correctly"
