#!/bin/bash

echo "🧪 Testing Demo Accounts..."

# Test demo account login
echo "Testing Business Owner login..."
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo-business@example.com",
    "password": "Password123!"
  }' \
  -s | jq '.status'

echo ""
echo "Testing Investor login..."
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "frontendtest@example.com",
    "password": "Password123!"
  }' \
  -s | jq '.status'

echo ""
echo "Testing Member login..."
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "member@hajifund.com",
    "password": "password123"
  }' \
  -s | jq '.status'

echo ""
echo "Testing Admin login..."
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@hajifund.com",
    "password": "admin123"
  }' \
  -s | jq '.status'

echo ""
echo "✅ Demo account testing completed!"
