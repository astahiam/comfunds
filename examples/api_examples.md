# ComFunds API Usage Examples

This document provides comprehensive examples of how to use the ComFunds API with role-based access control.

## Authentication

### 1. Register a New User

```bash
# Register as a Cooperative Member and Investor (FR-010: Multiple Roles)
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "investor@example.com",
    "name": "John Investor",
    "password": "SecurePass123!",
    "phone": "+1234567890",
    "address": "123 Investment St",
    "roles": ["member", "investor"]
  }'
```

```bash
# Register as a Business Owner
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "business@example.com",
    "name": "Sarah Business",
    "password": "BusinessPass456!",
    "phone": "+1234567891",
    "address": "456 Business Ave",
    "roles": ["member", "business_owner"]
  }'
```

### 2. Login

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "investor@example.com",
    "password": "SecurePass123!"
  }'
```

**Response:**
```json
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "email": "investor@example.com",
      "name": "John Investor",
      "roles": ["member", "investor"]
    },
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "Bearer"
  }
}
```

## Role Management

### 3. Get User Roles and Permissions

```bash
curl -X GET http://localhost:8080/api/v1/user/roles \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Response:**
```json
{
  "status": "success",
  "message": "User roles retrieved successfully",
  "data": {
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "roles": ["member", "investor"],
    "role_descriptions": {
      "member": "Can view all projects within their cooperative",
      "investor": "Can invest in approved projects and view portfolio"
    },
    "permissions": [
      "view_public_projects",
      "view_cooperative_projects",
      "invest_in_projects",
      "view_portfolio",
      "manage_profile"
    ],
    "can_invest": true,
    "can_create_business": false,
    "can_create_project": false,
    "can_approve_projects": false,
    "can_access_cooperative": true
  }
}
```

### 4. Update User Roles (FR-010: Multiple Roles)

```bash
# Add business_owner role to existing member/investor
curl -X PUT http://localhost:8080/api/v1/user/roles \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "roles": ["member", "investor", "business_owner"]
  }'
```

### 5. Get Role Information (Public)

```bash
curl -X GET http://localhost:8080/api/v1/roles/info
```

## Project Viewing (Role-Based Access)

### 6. View Public Projects (FR-006: Guest Users)

```bash
# No authentication required - accessible to everyone
curl -X GET http://localhost:8080/api/v1/public/projects?page=1&limit=10
```

**Response:**
```json
{
  "status": "success",
  "message": "Public projects retrieved successfully",
  "data": {
    "projects": [
      {
        "id": "987fcdeb-51a2-43d1-9f4e-123456789abc",
        "title": "Tech Startup Funding",
        "description": "Innovative tech startup seeking investment",
        "target_amount": 100000,
        "raised_amount": 25000,
        "status": "active",
        "category": "Technology"
      }
    ],
    "page": 1,
    "limit": 10,
    "total": 2,
    "access_level": "public"
  }
}
```

### 7. View Cooperative Projects (FR-007: Cooperative Members)

```bash
# Requires member role or higher
curl -X GET http://localhost:8080/api/v1/cooperative/projects \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Response:**
```json
{
  "status": "success",
  "message": "Cooperative projects retrieved successfully",
  "data": {
    "projects": [
      {
        "id": "456def78-9abc-12de-f345-678901234567",
        "title": "Local Bakery Expansion",
        "description": "Expanding bakery to serve more members",
        "target_amount": 75000,
        "raised_amount": 45000,
        "status": "active",
        "cooperative_id": "coop-123-456-789"
      }
    ],
    "access_level": "cooperative",
    "user_roles": ["member", "investor"]
  }
}
```

## Project Management (Business Owners)

### 8. Create Project (FR-008: Business Owners)

```bash
# Requires business_owner role
curl -X POST http://localhost:8080/api/v1/projects \
  -H "Authorization: Bearer YOUR_BUSINESS_OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Restaurant Chain Expansion",
    "description": "Expanding restaurant business to new locations",
    "target_amount": 150000,
    "min_investment": 1000,
    "category": "Food & Beverage",
    "risk_level": "Medium",
    "investment_period": 24,
    "expected_return": "8-12% annually",
    "business_id": "business-123-456-789"
  }'
```

**Response:**
```json
{
  "status": "success",
  "message": "Project created successfully",
  "data": {
    "project": {
      "id": "new-project-123-456",
      "title": "Restaurant Chain Expansion",
      "status": "pending_approval",
      "owner_id": "business-owner-id",
      "message": "Project created and pending cooperative approval"
    }
  }
}
```

### 9. View Own Projects (FR-008: Business Owners)

```bash
# Requires business_owner role
curl -X GET http://localhost:8080/api/v1/user/projects \
  -H "Authorization: Bearer YOUR_BUSINESS_OWNER_TOKEN"
```

## Investment Opportunities (Investors)

### 10. View Investment Opportunities (FR-009: Investors)

```bash
# Requires investor role
curl -X GET http://localhost:8080/api/v1/investments/opportunities?category=Technology \
  -H "Authorization: Bearer YOUR_INVESTOR_TOKEN"
```

**Response:**
```json
{
  "status": "success",
  "message": "Investment opportunities retrieved successfully",
  "data": {
    "opportunities": [
      {
        "id": "invest-opp-123",
        "title": "Halal Food Processing Plant",
        "target_amount": 500000,
        "raised_amount": 200000,
        "min_investment": 1000,
        "expected_return": "8-12% annually",
        "investment_period": "24 months",
        "status": "approved",
        "risk_level": "Medium",
        "sharia_compliant": true
      }
    ],
    "user_roles": ["member", "investor"]
  }
}
```

## Admin Functions

### 11. Get Users by Role (Admin Only)

```bash
# Requires admin role
curl -X GET http://localhost:8080/api/v1/admin/users/role/investor?page=1&limit=20 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

## Error Handling Examples

### 12. Insufficient Permissions

```bash
# Guest trying to access cooperative projects
curl -X GET http://localhost:8080/api/v1/cooperative/projects
```

**Response:**
```json
{
  "status": "error",
  "message": "Authorization header required",
  "error": null
}
```

### 13. Role Restriction

```bash
# Member trying to create project (requires business_owner)
curl -X POST http://localhost:8080/api/v1/projects \
  -H "Authorization: Bearer YOUR_MEMBER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Project"}'
```

**Response:**
```json
{
  "status": "error",
  "message": "Insufficient permissions",
  "error": null
}
```

## Role-Based Access Summary

| Role | Can View Public | Can View Cooperative | Can Create Project | Can Invest | Can Approve |
|------|----------------|---------------------|-------------------|------------|-------------|
| **Guest** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Member** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Business Owner** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Investor** | ✅ | ✅ | ❌ | ✅ | ❌ |
| **Admin** | ✅ | ✅ | ❌ | ❌ | ✅ |

### Multiple Role Benefits (FR-010)
- **Member + Investor**: Can view cooperative projects AND invest
- **Member + Business Owner**: Can view cooperative projects AND create projects
- **Member + Business Owner + Investor**: Can do all of the above

## Authentication Flow

1. **Register** → Get access & refresh tokens
2. **Login** → Get fresh tokens
3. **Use Access Token** → Make authenticated requests
4. **Refresh Token** → Get new access token when expired
5. **Check Roles** → Verify permissions for specific actions
