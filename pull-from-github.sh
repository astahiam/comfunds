#!/bin/bash

# Pull Code from GitHub Master Branch to VPS
# This script pulls the latest code from GitHub master branch
# Run this script on your VPS

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

# Configuration - EDIT THESE VALUES BEFORE RUNNING
# ================================================
# Set your GitHub repository URL here:
GITHUB_REPO_URL="https://github.com/astahiam/comfunds.git"
# Or use SSH (if you have SSH keys set up on VPS):
# GITHUB_REPO_URL="git@github.com:YOUR_USERNAME/YOUR_REPO.git"

# Target directory where code will be pulled/cloned
TARGET_DIR="$HOME/sourcecode"

# Branch to pull (default: main)
BRANCH="main"

# Alternative: Use environment variables if set (useful for automation)
if [ -n "$GITHUB_REPO" ]; then
    GITHUB_REPO_URL="$GITHUB_REPO"
fi

if [ -n "$DEPLOY_DIR" ]; then
    TARGET_DIR="$DEPLOY_DIR"
fi

if [ -n "$GITHUB_BRANCH" ]; then
    BRANCH="$GITHUB_BRANCH"
fi

# Validate repository URL is set
if [ "$GITHUB_REPO_URL" = "https://github.com/astahiam/comfunds.git" ]; then
    print_error "Please edit this script and set GITHUB_REPO_URL to your actual repository URL"
    print_info "Or set it via environment variable: GITHUB_REPO=https://github.com/astahiam/comfunds.git ./pull-from-github.sh"
    exit 1
fi

print_step "Pulling Code from GitHub $BRANCH Branch"
echo ""
print_info "Configuration:"
print_info "  Repository: $GITHUB_REPO_URL"
print_info "  Target Directory: $TARGET_DIR"
print_info "  Branch: $BRANCH"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Installing git..."
    sudo apt-get update
    sudo apt-get install -y git
fi

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    print_step "Creating target directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    print_status "Directory created"
fi

# Navigate to target directory
cd "$TARGET_DIR"

# Check if it's already a git repository
if [ -d ".git" ]; then
    print_step "Git repository found. Pulling latest changes..."
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_warning "You have uncommitted changes in the repository."
        print_info "Stashing local changes before pulling..."
        git stash push -m "Auto-stash before pull on $(date '+%Y-%m-%d %H:%M:%S')"
        STASHED=true
    else
        STASHED=false
    fi
    
    # Check current branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    
    if [ -z "$CURRENT_BRANCH" ]; then
        print_warning "No branch checked out. Checking out $BRANCH..."
        git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
    elif [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
        print_info "Current branch is '$CURRENT_BRANCH'. Switching to '$BRANCH'..."
        git checkout "$BRANCH"
    fi
    
    # Fetch latest changes
    print_step "Fetching latest changes from origin..."
    git fetch origin
    
    # Pull latest changes
    print_step "Pulling latest changes from $BRANCH branch..."
    if git pull origin "$BRANCH"; then
        print_status "Successfully pulled latest changes"
        
        # Restore stashed changes if any
        if [ "$STASHED" = true ]; then
            print_info "Restoring stashed changes..."
            if git stash pop 2>/dev/null; then
                print_status "Stashed changes restored"
            else
                print_warning "Could not automatically restore stashed changes."
                print_info "You can restore them manually with: git stash pop"
            fi
        fi
    else
        print_error "Failed to pull changes. There might be conflicts."
        if [ "$STASHED" = true ]; then
            print_info "Your stashed changes are safe. View them with: git stash list"
        fi
        print_warning "You may need to resolve conflicts manually."
        exit 1
    fi
    
    # Show latest commit
    LATEST_COMMIT=$(git log -1 --oneline)
    print_info "Latest commit: $LATEST_COMMIT"
    
else
    print_step "Not a git repository. Cloning from GitHub..."
    
    # Clone the repository
    if git clone -b "$BRANCH" "$GITHUB_REPO_URL" .; then
        print_status "Successfully cloned repository"
    else
        print_error "Failed to clone repository"
        print_info "Please check:"
        print_info "  1. Repository URL is correct: $GITHUB_REPO_URL"
        print_info "  2. You have access to the repository"
        print_info "  3. Branch '$BRANCH' exists"
        exit 1
    fi
    
    # Show latest commit
    LATEST_COMMIT=$(git log -1 --oneline)
    print_info "Latest commit: $LATEST_COMMIT"
fi

# Show repository status
print_step "Repository Status:"
git status --short

# Show current branch and commit
print_info "Current branch: $(git branch --show-current)"
print_info "Current commit: $(git log -1 --oneline)"

print_status "Code pull completed successfully!"
print_info "Next steps:"
print_info "  1. Review the changes"
print_info "  2. Update environment variables if needed"
print_info "  3. Restart services if necessary"

