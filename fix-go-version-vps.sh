#!/bin/bash

# Fix Go Version on VPS
# This script updates Go to version 1.21+ on the VPS

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
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

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_header "Fix Go Version on VPS"

# Check current Go version
print_step "1. Checking current Go version..."

if command -v go &> /dev/null; then
    CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    print_info "Current Go version: $CURRENT_VERSION"
    
    # Extract major.minor version
    MAJOR_MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f1,2)
    
    if [ "$(printf '%s\n' "1.21" "$MAJOR_MINOR" | sort -V | head -n1)" = "1.21" ]; then
        print_status "Go version is 1.21 or higher. No update needed."
        exit 0
    else
        print_warning "Go version is below 1.21. Need to update."
    fi
else
    print_warning "Go is not installed."
fi

# Install/Update Go
print_step "2. Installing/Updating Go 1.21.5..."

GO_VERSION="1.21.5"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TAR}"

# Download Go
print_info "Downloading Go ${GO_VERSION}..."
cd /tmp
wget -q "$GO_URL" || curl -L -o "$GO_TAR" "$GO_URL"

# Remove old Go installation
print_info "Removing old Go installation..."
sudo rm -rf /usr/local/go

# Extract Go
print_info "Extracting Go..."
sudo tar -C /usr/local -xzf "$GO_TAR"

# Clean up
rm -f "$GO_TAR"

# Update PATH
print_step "3. Updating PATH..."

# Add to .bashrc if not already there
if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export GOBIN=$GOPATH/bin' >> ~/.bashrc
fi

# Add to current session
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin

# Verify installation
print_step "4. Verifying Go installation..."

NEW_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
print_info "New Go version: $NEW_VERSION"

if [ "$(printf '%s\n' "1.21" "$(echo $NEW_VERSION | cut -d. -f1,2)" | sort -V | head -n1)" = "1.21" ]; then
    print_status "✅ Go updated successfully!"
    print_info "Run 'source ~/.bashrc' or reconnect SSH to use new Go version"
else
    print_error "Go update failed"
    exit 1
fi

print_header "Go Version Fix Complete"

print_info "To use the new Go version in current session:"
echo "  source ~/.bashrc"
echo ""
print_info "Or reconnect SSH session"
echo ""

