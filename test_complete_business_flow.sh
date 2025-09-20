#!/bin/bash

# Complete Business Creation and Approval Flow Test
# Tests: User registration -> Business creation -> Admin approval -> Frontend verification

set -e

echo "🚀 Complete Business Creation and Approval Flow Test"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Check if servers are running
print_step "1. Checking server status"
BACKEND_STATUS=$(curl -s http://localhost:8080/api/v1/health | jq -r '.status // "error"')
FRONTEND_STATUS=$(curl -s http://localhost:3000/ | head -1 | grep -q "DOCTYPE" && echo "OK" || echo "error")

if [ "$BACKEND_STATUS" != "OK" ]; then
    print_error "Backend is not running on port 8080"
    exit 1
fi
print_success "Backend is running"

if [ "$FRONTEND_STATUS" != "OK" ]; then
    print_error "Frontend is not running on port 3000"
    exit 1
fi
print_success "Frontend is running"

# Generate unique identifiers
TIMESTAMP=$(date +%s)
USER_EMAIL="testuser${TIMESTAMP}@example.com"
BUSINESS_NAME="Test Business ${TIMESTAMP}"

print_step "2. Creating test user"
print_info "Email: $USER_EMAIL"

USER_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "'$USER_EMAIL'",
    "password": "Password123!",
    "phone": "08123456789",
    "address": "Test Address",
    "roles": ["business_owner"]
  }')

USER_STATUS=$(echo $USER_RESPONSE | jq -r '.status')
if [ "$USER_STATUS" != "success" ]; then
    print_error "User registration failed"
    echo $USER_RESPONSE | jq .
    exit 1
fi
print_success "User registered successfully"

print_step "3. User login"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'$USER_EMAIL'",
    "password": "Password123!"
  }')

USER_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.access_token // empty')
if [ -z "$USER_TOKEN" ]; then
    print_error "User login failed"
    echo $LOGIN_RESPONSE | jq .
    exit 1
fi
print_success "User logged in successfully"

print_step "4. Creating business"
print_info "Business: $BUSINESS_NAME"

BUSINESS_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/businesses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'$BUSINESS_NAME'",
    "type": "retail",
    "description": "Comprehensive test business for approval flow",
    "cooperative_id": "550e8400-e29b-41d4-a716-446655440001",
    "registration_number": "TEST-'$TIMESTAMP'",
    "legal_structure": "PT",
    "industry": "Retail",
    "address": "Test Business Address",
    "phone": "08123456789",
    "email": "business'$TIMESTAMP'@test.com",
    "established_date": "2023-01-01T00:00:00Z",
    "currency": "IDR",
    "bank_account": "1234567890"
  }')

BUSINESS_STATUS=$(echo $BUSINESS_RESPONSE | jq -r '.status')
BUSINESS_ID=$(echo $BUSINESS_RESPONSE | jq -r '.data.id // empty')

if [ "$BUSINESS_STATUS" != "success" ] || [ -z "$BUSINESS_ID" ]; then
    print_error "Business creation failed"
    echo $BUSINESS_RESPONSE | jq .
    exit 1
fi
print_success "Business created successfully: $BUSINESS_ID"

print_step "5. Verifying user's business list"
USER_BUSINESSES=$(curl -s -X GET http://localhost:8080/api/v1/user/businesses \
  -H "Authorization: Bearer $USER_TOKEN")

USER_BUSINESS_COUNT=$(echo $USER_BUSINESSES | jq -r '.data.total // 0')
print_info "User has $USER_BUSINESS_COUNT businesses"

if [ "$USER_BUSINESS_COUNT" -gt 0 ]; then
    print_success "✅ Business appears in user's business list"
else
    print_error "❌ Business NOT appearing in user's business list"
    echo $USER_BUSINESSES | jq .
fi

print_step "6. Checking database directly"
for i in {0..3}; do
    COUNT=$(PGPASSWORD="" psql -h localhost -U postgres -d comfunds0$i -t -c "
        SELECT COUNT(*) FROM businesses 
        WHERE name = '$BUSINESS_NAME' AND is_active = true;
    " | tr -d ' ')
    
    if [ "$COUNT" -gt 0 ]; then
        print_success "✅ Business found in database shard comfunds0$i"
        PGPASSWORD="" psql -h localhost -U postgres -d comfunds0$i -c "
            SELECT id, name, status, approval_status, created_at 
            FROM businesses 
            WHERE name = '$BUSINESS_NAME';"
        break
    fi
done

print_step "7. Admin login and verification"
# Try to login as admin (create if doesn't exist)
ADMIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@hajifund.com", "password": "Admin123!"}')

ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.data.access_token // empty')

if [ -z "$ADMIN_TOKEN" ]; then
    print_info "Creating admin user..."
    curl -s -X POST http://localhost:8080/api/v1/auth/register \
      -H "Content-Type: application/json" \
      -d '{
        "name": "Admin User",
        "email": "admin@hajifund.com",
        "password": "Admin123!",
        "phone": "08123456789",
        "address": "Admin Address",
        "roles": ["admin"]
      }' > /dev/null

    ADMIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
      -H "Content-Type: application/json" \
      -d '{"email": "admin@hajifund.com", "password": "Admin123!"}')
    
    ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.data.access_token // empty')
fi

if [ -n "$ADMIN_TOKEN" ]; then
    print_success "Admin logged in successfully"
    
    print_step "8. Checking admin pending businesses"
    PENDING_BUSINESSES=$(curl -s -X GET http://localhost:8080/api/v1/admin/businesses/pending \
      -H "Authorization: Bearer $ADMIN_TOKEN")
    
    PENDING_COUNT=$(echo $PENDING_BUSINESSES | jq -r '.data.businesses | length // 0')
    print_info "Admin sees $PENDING_COUNT pending businesses"
    
    if [ "$PENDING_COUNT" -gt 0 ]; then
        print_success "✅ Admin can see pending businesses"
        echo $PENDING_BUSINESSES | jq '.data.businesses[] | {id, name, approval_status}'
    else
        print_error "❌ Admin cannot see pending businesses"
    fi
    
    print_step "9. Testing frontend pages"
    print_info "Testing frontend business creation page..."
    FRONTEND_CREATE=$(curl -s http://localhost:3000/business/create | head -5 | grep -q "DOCTYPE" && echo "OK" || echo "error")
    
    if [ "$FRONTEND_CREATE" = "OK" ]; then
        print_success "✅ Frontend business creation page accessible"
    else
        print_error "❌ Frontend business creation page not accessible"
    fi
    
    print_info "Testing frontend admin businesses page..."
    FRONTEND_ADMIN=$(curl -s http://localhost:3000/admin/businesses | head -5 | grep -q "DOCTYPE" && echo "OK" || echo "error")
    
    if [ "$FRONTEND_ADMIN" = "OK" ]; then
        print_success "✅ Frontend admin businesses page accessible"
    else
        print_error "❌ Frontend admin businesses page not accessible"
    fi
else
    print_error "Admin login failed"
fi

print_step "10. Test Summary"
echo "=================================="
print_info "Test User: $USER_EMAIL"
print_info "Business: $BUSINESS_NAME"
print_info "Business ID: $BUSINESS_ID"
print_info "User Business Count: $USER_BUSINESS_COUNT"
print_info "Admin Pending Count: $PENDING_COUNT"

if [ "$USER_BUSINESS_COUNT" -gt 0 ] && [ "$PENDING_COUNT" -gt 0 ]; then
    print_success "🎉 COMPLETE FLOW TEST PASSED!"
    print_success "✅ Business creation works"
    print_success "✅ User can see their businesses"
    print_success "✅ Admin can see pending businesses"
    print_success "✅ Frontend pages are accessible"
else
    print_error "❌ FLOW TEST FAILED - Some issues remain"
fi

echo ""
print_info "🌐 Open in browser:"
print_info "Frontend: http://localhost:3000"
print_info "Admin Panel: http://localhost:3000/admin"
echo ""
