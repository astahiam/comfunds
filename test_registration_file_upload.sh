#!/bin/bash

# Test Registration Page with File Uploads
# This script tests the registration endpoint with sample uploaded files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${API_BASE_URL:-http://localhost:8080}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
TEST_DIR="test_files"
UPLOAD_DIR="uploads/documents/register"

# Create test files directory
mkdir -p "$TEST_DIR"

echo -e "${GREEN}=== Registration File Upload Test ===${NC}\n"

# Function to create sample PDF file
create_sample_pdf() {
    local filename="$TEST_DIR/payment_proof.pdf"
    echo "%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/Resources <<
/Font <<
/F1 <<
/Type /Font
/Subtype /Type1
/BaseFont /Helvetica
>>
>>
>>
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj
4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
100 700 Td
(Sample Payment Proof) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000306 00000 n
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
390
%%EOF" > "$filename"
    echo "Created PDF: $filename"
}

# Function to create sample JPG file (minimal valid JPEG)
create_sample_jpg() {
    local filename="$TEST_DIR/payment_proof.jpg"
    # Create a minimal valid JPEG (1x1 pixel)
    printf "\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xDB\x00\x43\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\x09\x09\x08\x0A\x0C\x14\x0D\x0C\x0B\x0B\x0C\x19\x12\x13\x0F\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C\x20\x24\x2E\x27\x20\x22\x2C\x23\x1C\x1C\x28\x37\x29\x2C\x30\x31\x34\x34\x34\x1F\x27\x39\x3D\x38\x32\x3C\x2E\x33\x34\x32\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xFF\xC4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00\x3F\x00\x80\xFF\xD9" > "$filename"
    echo "Created JPG: $filename"
}

# Function to create sample PNG file (minimal valid PNG)
create_sample_png() {
    local filename="$TEST_DIR/payment_proof.png"
    # Create a minimal valid PNG (1x1 pixel, red)
    printf "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xDE\x00\x00\x00\x0C\x49\x44\x41\x54\x08\xD7\x63\xF8\xCF\xC0\x00\x00\x03\x01\x01\x00\x18\xDD\x8D\xB4\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82" > "$filename"
    echo "Created PNG: $filename"
}

# Function to create sample text file (should be rejected)
create_sample_txt() {
    local filename="$TEST_DIR/payment_proof.txt"
    echo "This is a sample payment proof text file" > "$filename"
    echo "Created TXT: $filename"
}

# Function to generate unique email
generate_email() {
    echo "test_$(date +%s)_$RANDOM@example.com"
}

# Function to test registration with file
test_registration_with_file() {
    local file_path=$1
    local file_type=$2
    local email=$(generate_email)
    local name="Test User $RANDOM"
    local phone="+628123456789"
    local address="Test Address, Jakarta"
    local password="TestPass123!"
    local cooperative_id="550e8400-e29b-41d4-a716-446655440001"  # Koperasi Haji
    
    echo -e "\n${YELLOW}Testing registration with $file_type file...${NC}"
    echo "File: $file_path"
    echo "Email: $email"
    
    # Test via backend API directly
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/auth/register" \
        -F "name=$name" \
        -F "email=$email" \
        -F "password=$password" \
        -F "phone=$phone" \
        -F "address=$address" \
        -F "cooperative_id=$cooperative_id" \
        -F "roles=investor" \
        -F "roles=member" \
        -F "payment_proof=@$file_path")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "HTTP Status: $http_code"
    echo "Response: $body" | jq '.' 2>/dev/null || echo "$body"
    
    if [ "$http_code" -eq 201 ] || [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Registration with $file_type successful!${NC}"
        
        # Check if file was uploaded
        if [ -d "$UPLOAD_DIR" ]; then
            uploaded_file=$(ls -t "$UPLOAD_DIR" | head -n1)
            if [ -n "$uploaded_file" ]; then
                echo -e "${GREEN}✓ File uploaded successfully: $UPLOAD_DIR/$uploaded_file${NC}"
                echo "File size: $(stat -f%z "$UPLOAD_DIR/$uploaded_file" 2>/dev/null || stat -c%s "$UPLOAD_DIR/$uploaded_file" 2>/dev/null) bytes"
            else
                echo -e "${YELLOW}⚠ File directory exists but no file found${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ Upload directory not found: $UPLOAD_DIR${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}✗ Registration with $file_type failed!${NC}"
        return 1
    fi
}

# Function to test registration via frontend
test_registration_frontend() {
    local file_path=$1
    local file_type=$2
    local email=$(generate_email)
    local name="Test User Frontend $RANDOM"
    local phone="+628123456789"
    local address="Test Address, Jakarta"
    local password="TestPass123!"
    local cooperative_id="550e8400-e29b-41d4-a716-446655440001"
    
    echo -e "\n${YELLOW}Testing registration via frontend with $file_type file...${NC}"
    echo "File: $file_path"
    echo "Email: $email"
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$FRONTEND_URL/api/auth/register" \
        -F "name=$name" \
        -F "email=$email" \
        -F "password=$password" \
        -F "phone=$phone" \
        -F "address=$address" \
        -F "cooperative_id=$cooperative_id" \
        -F "roles=investor" \
        -F "roles=member" \
        -F "payment_proof=@$file_path")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "HTTP Status: $http_code"
    echo "Response: $body" | jq '.' 2>/dev/null || echo "$body"
    
    if [ "$http_code" -eq 201 ] || [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Frontend registration with $file_type successful!${NC}"
        return 0
    else
        echo -e "${RED}✗ Frontend registration with $file_type failed!${NC}"
        return 1
    fi
}

# Function to test invalid file type rejection
test_invalid_file_type() {
    local file_path=$1
    local email=$(generate_email)
    
    echo -e "\n${YELLOW}Testing rejection of invalid file type...${NC}"
    echo "File: $file_path"
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/auth/register" \
        -F "name=Test User" \
        -F "email=$email" \
        -F "password=TestPass123!" \
        -F "phone=+628123456789" \
        -F "address=Test Address" \
        -F "cooperative_id=550e8400-e29b-41d4-a716-446655440001" \
        -F "roles=investor" \
        -F "roles=member" \
        -F "payment_proof=@$file_path")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "HTTP Status: $http_code"
    echo "Response: $body" | jq '.' 2>/dev/null || echo "$body"
    
    if [ "$http_code" -eq 400 ]; then
        echo -e "${GREEN}✓ Invalid file type correctly rejected!${NC}"
        return 0
    else
        echo -e "${RED}✗ Invalid file type was not rejected!${NC}"
        return 1
    fi
}

# Function to check server health
check_server() {
    echo -e "${YELLOW}Checking server health...${NC}"
    
    if curl -s -f "$BASE_URL/api/v1/health" > /dev/null; then
        echo -e "${GREEN}✓ Backend server is running${NC}"
        return 0
    else
        echo -e "${RED}✗ Backend server is not responding at $BASE_URL${NC}"
        echo "Please make sure the server is running:"
        echo "  - Backend: $BASE_URL"
        echo "  - Frontend: $FRONTEND_URL"
        return 1
    fi
}

# Main test execution
main() {
    echo "Test Configuration:"
    echo "  Backend URL: $BASE_URL"
    echo "  Frontend URL: $FRONTEND_URL"
    echo "  Test Directory: $TEST_DIR"
    echo "  Upload Directory: $UPLOAD_DIR"
    echo ""
    
    # Check if server is running
    if ! check_server; then
        exit 1
    fi
    
    # Create sample files
    echo -e "\n${YELLOW}Creating sample test files...${NC}"
    create_sample_pdf
    create_sample_jpg
    create_sample_png
    create_sample_txt
    
    # Create upload directory if it doesn't exist
    mkdir -p "$UPLOAD_DIR"
    
    # Test results tracking
    success_count=0
    fail_count=0
    
    # Test 1: Registration with PDF file (backend)
    if test_registration_with_file "$TEST_DIR/payment_proof.pdf" "PDF"; then
        ((success_count++))
    else
        ((fail_count++))
    fi
    
    # Test 2: Registration with JPG file (backend)
    if test_registration_with_file "$TEST_DIR/payment_proof.jpg" "JPG"; then
        ((success_count++))
    else
        ((fail_count++))
    fi
    
    # Test 3: Registration with PNG file (backend)
    if test_registration_with_file "$TEST_DIR/payment_proof.png" "PNG"; then
        ((success_count++))
    else
        ((fail_count++))
    fi
    
    # Test 4: Invalid file type rejection
    if test_invalid_file_type "$TEST_DIR/payment_proof.txt"; then
        ((success_count++))
    else
        ((fail_count++))
    fi
    
    # Test 5: Registration via frontend (if frontend is running)
    if curl -s -f "$FRONTEND_URL" > /dev/null 2>&1; then
        echo -e "\n${YELLOW}Frontend is running, testing frontend endpoint...${NC}"
        if test_registration_frontend "$TEST_DIR/payment_proof.pdf" "PDF"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    else
        echo -e "\n${YELLOW}Frontend is not running, skipping frontend tests${NC}"
    fi
    
    # Summary
    echo -e "\n${GREEN}=== Test Summary ===${NC}"
    echo "Successful tests: $success_count"
    echo "Failed tests: $fail_count"
    echo "Total tests: $((success_count + fail_count))"
    
    if [ $fail_count -eq 0 ]; then
        echo -e "\n${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Run main function
main

