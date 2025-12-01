# Registration File Upload Testing

This document describes how to test the registration page with file uploads.

## Test Files

1. **test_registration_file_upload.go** - Go integration tests for file upload functionality
2. **test_registration_file_upload.sh** - Shell script for manual testing with a running server

## Running Go Integration Tests

The Go tests test the registration endpoint with various file types (PDF, JPG, PNG) and validate:
- File upload success with valid file types
- File rejection for invalid file types
- File storage on disk
- Registration success with file uploads

### Prerequisites

1. PostgreSQL database running with test databases configured
2. Environment variables set (or `.env.test` file):
   - `TEST_DB_HOST` (default: localhost)
   - `TEST_DB_USER` (default: postgres)
   - `TEST_DB_PASSWORD`
   - `TEST_DB_SSLMODE` (default: disable)

### Run Tests

```bash
# Set environment variable to enable integration tests
export TEST_INTEGRATION=1

# Run the specific test file
go test -v ./test_registration_file_upload.go

# Or run all tests
go test -v -run TestRegistrationFileUploadSuite
```

## Running Manual Tests (Shell Script)

The shell script can be used to test against a running server (backend or frontend).

### Prerequisites

1. Backend server running on `http://localhost:8080` (or set `API_BASE_URL`)
2. Optional: Frontend server running on `http://localhost:3000` (or set `FRONTEND_URL`)

### Run Manual Tests

```bash
# Make script executable
chmod +x test_registration_file_upload.sh

# Run tests
./test_registration_file_upload.sh

# Or with custom URLs
API_BASE_URL=http://localhost:8080 FRONTEND_URL=http://localhost:3000 ./test_registration_file_upload.sh
```

### What the Script Tests

1. **PDF File Upload** - Tests registration with a PDF payment proof
2. **JPG File Upload** - Tests registration with a JPG image
3. **PNG File Upload** - Tests registration with a PNG image
4. **Invalid File Type** - Tests rejection of unsupported file types (e.g., TXT)
5. **Frontend Endpoint** - Tests registration via frontend proxy (if frontend is running)

## Expected Behavior

### Valid File Types
- **PDF** (.pdf) - Accepted
- **JPEG** (.jpg, .jpeg) - Accepted
- **PNG** (.png) - Accepted
- **File Size Limit** - Maximum 10MB
- Files are saved to `uploads/documents/register/` directory
- File URLs are stored in the user's `membership_payment_proof` field

### Invalid File Types
- Any file type not listed above should be rejected with a 400 error
- Error message: "Invalid file type. Allowed: PDF, JPG, PNG"

### File Storage
- Files are stored with unique names: `payment_proof_{timestamp}_{uuid}.{ext}`
- Files are accessible at: `/uploads/documents/register/{filename}`

## Test Results

After running tests, check:
1. **Upload Directory** - Verify files exist in `uploads/documents/register/`
2. **Database** - Verify user records have `membership_payment_proof` field set
3. **API Response** - Verify response includes file URL in user data

## Troubleshooting

### Tests Skip with "Test database not available"
- Ensure PostgreSQL is running
- Check database connection settings in `.env.test`
- Verify test databases exist (comfunds00, comfunds01, etc.)

### File Upload Fails
- Check upload directory permissions: `chmod -R 755 uploads/`
- Verify disk space is available
- Check server logs for detailed error messages

### Invalid File Type Not Rejected
- Verify file extension validation in `auth_controller.go`
- Check that `allowedExtensions` array includes only PDF, JPG, PNG

## Sample cURL Commands

You can also test manually using cURL:

```bash
# Register with PDF file
curl -X POST http://localhost:8080/api/v1/auth/register \
  -F "name=Test User" \
  -F "email=test@example.com" \
  -F "password=TestPass123!" \
  -F "phone=+628123456789" \
  -F "address=Test Address" \
  -F "cooperative_id=550e8400-e29b-41d4-a716-446655440001" \
  -F "roles=investor" \
  -F "roles=member" \
  -F "payment_proof=@/path/to/payment_proof.pdf"

# Register with JPG file
curl -X POST http://localhost:8080/api/v1/auth/register \
  -F "name=Test User" \
  -F "email=test2@example.com" \
  -F "password=TestPass123!" \
  -F "phone=+628123456789" \
  -F "address=Test Address" \
  -F "cooperative_id=550e8400-e29b-41d4-a716-446655440001" \
  -F "roles=investor" \
  -F "roles=member" \
  -F "payment_proof=@/path/to/payment_proof.jpg"
```

## Notes

- Test files are automatically cleaned up after tests complete
- Uploaded files may be kept for verification (check test code)
- Users created during tests are automatically deleted in TearDownSuite
- The frontend form requires the file field, but the backend accepts registration without files (file is optional)

