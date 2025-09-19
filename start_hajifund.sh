#!/bin/bash

# HajiFund Startup Script
# This script starts both the backend and frontend servers

echo "🚀 Starting HajiFund Islamic Crowdfunding Platform..."

# Kill any existing processes on ports 8080 and 3000
echo "🔧 Cleaning up existing processes..."
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# Wait a moment for processes to terminate
sleep 2

# Start backend server in background
echo "🔥 Starting Backend Server (Port 8080)..."
cd /Users/alkha/Documents/project/comfunds
go run main.go &
BACKEND_PID=$!

# Wait for backend to start
sleep 3

# Start frontend server in background
echo "🌐 Starting Frontend Server (Port 3000)..."
cd /Users/alkha/Documents/project/comfunds/frontend
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production go run main.go &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 3

echo ""
echo "✅ HajiFund Platform Started Successfully!"
echo ""
echo "🔗 Access URLs:"
echo "   📱 Frontend: http://localhost:3000"
echo "   🔧 Backend API: http://localhost:8080"
echo ""
echo "👥 Demo Accounts Available:"
echo "   🏢 Business Owner: demo-business@example.com (Password123!)"
echo "   💰 Investor: frontendtest@example.com (Password123!)"
echo ""
echo "🎯 Key Features Implemented:"
echo "   ✅ User Registration & Authentication (FR-001, FR-002)"
echo "   ✅ Role-Based Access Control (FR-005)"
echo "   ✅ Business Registration (FR-024-FR-031)"
echo "   ✅ Project Creation & Management (FR-032-FR-040)"
echo "   ✅ Investment Process (FR-041-FR-049)"
echo "   ✅ Public Project Viewing (FR-006)"
echo "   ✅ Cooperative Management (FR-015-FR-023)"
echo "   ✅ Role-Specific Dashboards"
echo ""
echo "🛑 To stop servers, press Ctrl+C or run:"
echo "   kill $BACKEND_PID $FRONTEND_PID"
echo ""

# Function to handle cleanup on script exit
cleanup() {
    echo ""
    echo "🛑 Stopping HajiFund servers..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true
    echo "✅ Servers stopped successfully!"
    exit 0
}

# Set trap for cleanup
trap cleanup SIGINT SIGTERM

# Keep script running
echo "⏳ Servers are running... Press Ctrl+C to stop"
wait