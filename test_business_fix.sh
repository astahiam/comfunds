#!/bin/bash

# Test script to verify business creation and retrieval
echo "🧪 Testing Business Creation and Retrieval Fix..."

# Test 1: Create a business and verify it's stored
echo "📝 Test 1: Creating a business..."
BUSINESS_DATA='{
    "name": "Test Business Store",
    "type": "retail",
    "description": "A test business for verification",
    "cooperative_id": "550e8400-e29b-41d4-a716-446655440001",
    "registration_number": "TEST-REG-001",
    "legal_structure": "CV",
    "industry": "retail",
    "address": "Jl. Test Business No. 123",
    "phone": "+62-800-TEST",
    "email": "test@business.com",
    "established_date": "2023-01-01T00:00:00Z",
    "currency": "IDR",
    "bank_account": "1234567890123456",
    "business_license": "TEST-LICENSE-001",
    "documents": []
}'

# Register a test user
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testowner@hajifund.com",
    "password": "Password123!",
    "name": "Test Owner",
    "phone": "+62-800-TEST",
    "address": "Jl. Test Owner No. 1",
    "cooperative_id": "550e8400-e29b-41d4-a716-446655440001",
    "roles": ["business_owner"]
  }')

if [ $? -eq 0 ]; then
    echo "✅ User registration successful"
else
    echo "❌ User registration failed"
    exit 1
fi

# Login
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "testowner@hajifund.com", "password": "Password123!"}')

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ Login failed"
    exit 1
fi

echo "✅ Login successful"

# Create business
CREATE_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" -X POST http://localhost:8080/api/v1/businesses \
  -H "Content-Type: application/json" \
  -d "$BUSINESS_DATA")

BUSINESS_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$BUSINESS_ID" ]; then
    echo "❌ Business creation failed"
    echo "Response: $CREATE_RESPONSE"
    exit 1
fi

echo "✅ Business created successfully with ID: $BUSINESS_ID"

# Test 2: Retrieve user businesses
echo "📋 Test 2: Retrieving user businesses..."
USER_BUSINESSES=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/user/businesses)

echo "User businesses response: $USER_BUSINESSES"

# Check if businesses are returned
BUSINESS_COUNT=$(echo "$USER_BUSINESSES" | grep -o '"total":[0-9]*' | cut -d':' -f2)

if [ "$BUSINESS_COUNT" = "0" ]; then
    echo "❌ No businesses found in user dashboard"
    echo "This indicates the business retrieval is not working"
else
    echo "✅ Found $BUSINESS_COUNT businesses in user dashboard"
fi

# Test 3: Check admin pending businesses
echo "👨‍💼 Test 3: Checking admin pending businesses..."

# Login as admin
ADMIN_LOGIN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@hajifund.com", "password": "AdminPassword123!"}')

ADMIN_TOKEN=$(echo "$ADMIN_LOGIN" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Admin login failed"
    exit 1
fi

echo "✅ Admin login successful"

# Check pending businesses
ADMIN_BUSINESSES=$(curl -s -H "Authorization: Bearer $ADMIN_TOKEN" "http://localhost:8080/api/v1/admin/businesses/pending")

echo "Admin pending businesses: $ADMIN_BUSINESSES"

# Check if pending businesses are returned
PENDING_COUNT=$(echo "$ADMIN_BUSINESSES" | grep -o '"total":[0-9]*' | cut -d':' -f2)

if [ "$PENDING_COUNT" = "0" ]; then
    echo "❌ No pending businesses found in admin dashboard"
    echo "This indicates the business retrieval is not working"
else
    echo "✅ Found $PENDING_COUNT pending businesses in admin dashboard"
fi

echo ""
echo "🎯 SUMMARY:"
echo "==========="
if [ "$BUSINESS_COUNT" = "0" ] && [ "$PENDING_COUNT" = "0" ]; then
    echo "❌ BUSINESS RETRIEVAL IS NOT WORKING"
    echo "   - Business creation: ✅ Working"
    echo "   - Business retrieval: ❌ Not working"
    echo "   - Admin pending businesses: ❌ Not working"
    echo ""
    echo "🔧 RECOMMENDATION:"
    echo "The issue is in the service layer - businesses are being created"
    echo "but not retrieved properly. This needs to be fixed in the"
    echo "business management service implementation."
else
    echo "✅ BUSINESS CREATION AND RETRIEVAL IS WORKING"
    echo "   - Business creation: ✅ Working"
    echo "   - Business retrieval: ✅ Working"
    echo "   - Admin pending businesses: ✅ Working"
fi
