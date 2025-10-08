// HajiFund Frontend JavaScript

// Utility functions
function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    const toastBody = document.getElementById('toast-body');
    
    toastBody.textContent = message;
    toast.className = `toast toast-${type}`;
    
    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0
    }).format(amount);
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('id-ID', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// Authentication functions
async function login(email, password) {
    try {
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Login berhasil!', 'success');
            setTimeout(() => {
                window.location.href = data.redirect || '/dashboard';
            }, 1000);
        } else {
            showToast(data.message || 'Login gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat login', 'error');
        console.error('Login error:', error);
    }
}

// Logout function
async function logout() {
    try {
        const response = await fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            }
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Logout berhasil!', 'success');
            setTimeout(() => {
                window.location.href = '/';
            }, 1000);
        } else {
            showToast('Logout gagal', 'error');
        }
    } catch (error) {
        console.error('Logout error:', error);
        showToast('Terjadi kesalahan saat logout', 'error');
    }
}

// Check authentication status
function checkAuthStatus() {
    // Check if auth token cookie exists
    const authToken = document.cookie
        .split('; ')
        .find(row => row.startsWith('auth_token='));
    
    return authToken && authToken.split('=')[1] !== '';
}

// Redirect to login if not authenticated (for protected pages)
function requireAuth() {
    if (!checkAuthStatus()) {
        window.location.href = '/login';
        return false;
    }
    return true;
}

async function register(formData) {
    try {
        const response = await fetch('/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(formData)
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Registrasi berhasil!', 'success');
            setTimeout(() => {
                window.location.href = data.redirect || '/dashboard';
            }, 1000);
        } else {
            showToast(data.message || 'Registrasi gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat registrasi', 'error');
        console.error('Register error:', error);
    }
}

async function logout() {
    try {
        const response = await fetch('/api/auth/logout', {
            method: 'POST'
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Logout berhasil!', 'success');
            setTimeout(() => {
                window.location.href = data.redirect || '/';
            }, 1000);
        }
    } catch (error) {
        console.error('Logout error:', error);
        // Force redirect even if API call fails
        window.location.href = '/';
    }
}

// Form handlers
function handleLoginForm(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const email = formData.get('email');
    const password = formData.get('password');
    
    if (!email || !password) {
        showToast('Email dan password harus diisi', 'error');
        return;
    }
    
    login(email, password);
}

function handleRegisterForm(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const registerData = {
        name: formData.get('name'),
        email: formData.get('email'),
        password: formData.get('password'),
        phone: formData.get('phone'),
        address: formData.get('address'),
        cooperative_id: formData.get('cooperative_id') || null,
        roles: [formData.get('role')]
    };
    
    // Validation
    if (!registerData.name || !registerData.email || !registerData.password) {
        showToast('Nama, email, dan password harus diisi', 'error');
        return;
    }
    
    if (registerData.password.length < 6) {
        showToast('Password minimal 6 karakter', 'error');
        return;
    }
    
    register(registerData);
}

// Investment functions
async function investInProject(projectId, amount) {
    try {
        const response = await fetch(`/api/projects/${projectId}/invest`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ amount })
        });

        const data = await response.json();

        if (data.status === 'success') {
            showToast('Investasi berhasil!', 'success');
            setTimeout(() => {
                window.location.reload();
            }, 1000);
        } else {
            showToast(data.message || 'Investasi gagal', 'error');
        }
    } catch (error) {
        showToast('Terjadi kesalahan saat investasi', 'error');
        console.error('Investment error:', error);
    }
}

// Project progress calculation
function calculateProgress(raised, target) {
    if (target === 0) return 0;
    return Math.min((raised / target) * 100, 100);
}

// Real-time updates using WebSocket (placeholder)
function initWebSocket() {
    // This would connect to a WebSocket for real-time updates
    // For now, we'll use polling
    setInterval(updateProjectProgress, 30000); // Update every 30 seconds
}

function updateProjectProgress() {
    // Update project progress bars and funding amounts
    const progressBars = document.querySelectorAll('.project-progress');
    progressBars.forEach(bar => {
        const projectId = bar.dataset.projectId;
        // Fetch updated progress from API
        fetch(`/api/projects/${projectId}/progress`)
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    const progress = calculateProgress(data.data.raised_amount, data.data.target_amount);
                    bar.style.width = `${progress}%`;
                    
                    // Update raised amount display
                    const raisedElement = document.querySelector(`[data-project="${projectId}"] .raised-amount`);
                    if (raisedElement) {
                        raisedElement.textContent = formatCurrency(data.data.raised_amount);
                    }
                }
            })
            .catch(error => console.error('Progress update error:', error));
    });
}

// File upload helper (for cloud storage links)
function handleFileUpload(file, callback) {
    // This would integrate with cloud storage services
    // For now, we'll show a placeholder
    showToast('Fitur upload file akan segera tersedia', 'info');
    callback('https://example.com/placeholder-file.pdf');
}

// Hero section data fetching
async function fetchHeroData() {
    try {
        const response = await fetch('http://localhost:8080/api/v1/public/hero');
        const data = await response.json();
        
        if (data.status === 'success') {
            updateHeroContent(data.data);
        }
    } catch (error) {
        console.error('Hero data fetch error:', error);
    }
}

function updateHeroContent(heroData) {
    // Update hero title
    const titleElement = document.querySelector('.hero-title');
    if (titleElement && heroData.hero_content?.title) {
        titleElement.textContent = heroData.hero_content.title;
    }
    
    // Update hero subtitle
    const subtitleElement = document.querySelector('.hero-subtitle');
    if (subtitleElement && heroData.hero_content?.subtitle) {
        subtitleElement.textContent = heroData.hero_content.subtitle;
    }
    
    // Update CTA buttons
    const ctaContainer = document.querySelector('.d-flex.flex-wrap.gap-3.mb-4');
    if (ctaContainer && heroData.hero_content?.cta_buttons) {
        ctaContainer.innerHTML = '';
        heroData.hero_content.cta_buttons.forEach(button => {
            const buttonElement = document.createElement('a');
            buttonElement.href = button.url;
            buttonElement.textContent = button.text;
            buttonElement.className = button.type === 'outline' 
                ? 'btn btn-outline-success btn-lg px-4' 
                : 'btn btn-success btn-lg px-4';
            ctaContainer.appendChild(buttonElement);
        });
    }
    
    // Update hero image
    const heroImage = document.querySelector('.hero-person-image img');
    if (heroImage && heroData.hero_content?.hero_image?.url) {
        heroImage.src = heroData.hero_content.hero_image.url;
        heroImage.alt = heroData.hero_content.hero_image.alt;
    }
}

// Dashboard statistics
function updateDashboardStats() {
    // Dashboard stats will be loaded from server-side rendering
    // No need for additional API call
    console.log('Dashboard stats loaded from server');
}

function updateStatCards(stats) {
    const statElements = {
        'total-investments': stats.total_investments || 0,
        'total-projects': stats.total_projects || 0,
        'total-returns': stats.total_returns || 0,
        'active-projects': stats.active_projects || 0
    };
    
    Object.entries(statElements).forEach(([id, value]) => {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = formatCurrency(value);
        }
    });
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Initialize WebSocket for real-time updates
    initWebSocket();

    // Update dashboard stats if on dashboard page
    if (window.location.pathname === '/dashboard') {
        updateDashboardStats();
    }
    
    // Fetch hero data if on landing page
    if (window.location.pathname === '/') {
        fetchHeroData();
    }

    // Handle form submissions
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLoginForm);
    }

    const registerForm = document.getElementById('registerForm');
    if (registerForm) {
        registerForm.addEventListener('submit', handleRegisterForm);
    }

    // Handle investment buttons
    const investButtons = document.querySelectorAll('.invest-btn');
    investButtons.forEach(button => {
        button.addEventListener('click', function() {
            const projectId = this.dataset.projectId;
            const amount = prompt('Masukkan jumlah investasi (Rp):');
            
            if (amount && !isNaN(amount) && parseFloat(amount) > 0) {
                investInProject(projectId, parseFloat(amount));
            }
        });
    });
});

// Export functions for global access
window.HajiFund = {
    login,
    register,
    logout,
    showToast,
    formatCurrency,
    formatDate,
    investInProject,
    handleFileUpload
};
