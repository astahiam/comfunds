#!/bin/bash

# HajiFund Startup Script
# This script starts both backend and frontend servers

echo "🚀 Starting HajiFund Platform..."
echo "================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${BLUE}Port $port is already in use${NC}"
        return 0
    else
        echo -e "${BLUE}Port $port is available${NC}"
        return 1
    fi
}

# Function to kill process on port
kill_port() {
    local port=$1
    echo -e "${BLUE}Killing process on port $port...${NC}"
    lsof -ti:$port | xargs kill -9 2>/dev/null || true
    sleep 2
}

# Check and kill existing processes
echo "Checking for existing processes..."
if check_port 8080; then
    kill_port 8080
fi

if check_port 3000; then
    kill_port 3000
fi

# Start backend server
echo ""
echo -e "${GREEN}Starting Backend Server (port 8080)...${NC}"
cd /Users/alkha/Documents/project/comfunds
go run main.go &
BACKEND_PID=$!

# Wait for backend to start
sleep 3

# Check if backend is running
if curl -s http://localhost:8080/api/v1/health > /dev/null; then
    echo -e "${GREEN}✅ Backend server started successfully${NC}"
else
    echo -e "${RED}❌ Backend server failed to start${NC}"
    exit 1
fi

# Start frontend server
echo ""
echo -e "${GREEN}Starting Frontend Server (port 3000)...${NC}"
cd /Users/alkha/Documents/project/comfunds/frontend
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production go run main.go &
FRONTEND_PID=$!

# Wait for frontend to start
sleep 3

# Check if frontend is running
if curl -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✅ Frontend server started successfully${NC}"
else
    echo -e "${RED}❌ Frontend server failed to start${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 HajiFund Platform is now running!${NC}"
echo "================================"
echo ""
echo "🌐 Website URLs:"
echo "  • Landing Page: http://localhost:3000"
echo "  • Login Page: http://localhost:3000/login"
echo "  • Register Page: http://localhost:3000/register"
echo "  • Admin Dashboard: http://localhost:3000/admin"
echo ""
echo "🔑 Demo Accounts:"
echo "  • Admin: admin@hajifund.com / AdminPassword123!"
echo "  • Register new business owners at /register"
echo ""
echo "🧪 Test Commands:"
echo "  • Run full test: ./test_business_flow.sh"
echo "  • Stop servers: pkill -f 'go run main.go'"
echo ""
echo "📊 Server Status:"
echo "  • Backend: http://localhost:8080/api/v1/health"
echo "  • Frontend: http://localhost:3000"
echo ""

# Open browser if on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}Opening browser...${NC}"
    open http://localhost:3000
fi

echo "Press Ctrl+C to stop servers"
echo ""

# Wait for user to stop
wait