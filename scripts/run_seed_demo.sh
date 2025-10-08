#!/bin/bash

echo "🌱 Seeding Demo Accounts..."

# Navigate to project directory
cd "$(dirname "$0")/.."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go first."
    exit 1
fi

# Run the seed script
echo "📦 Running demo account seeder..."
go run scripts/seed_demo_accounts.go

echo "✅ Demo account seeding completed!"
echo ""
echo "📋 Available Demo Accounts:"
echo "1. Business Owner: demo-business@example.com / Password123!"
echo "2. Investor: frontendtest@example.com / Password123!"
echo "3. Member: member@hajifund.com / password123"
echo "4. Admin: admin@hajifund.com / admin123"
echo ""
echo "🚀 You can now test the demo accounts in the frontend!"
