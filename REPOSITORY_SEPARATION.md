# Repository Separation Documentation

## Overview
The ComFunds project has been successfully separated into two independent repositories to enable better team collaboration and separation of concerns between backend and frontend development.

## Repository Structure

### 1. Main Repository (Backend + Mobile)
**Repository**: [https://github.com/astahiam/comfunds.git](https://github.com/astahiam/comfunds.git)
**Focus**: Backend API, Mobile Applications, Infrastructure

**Contents**:
- Go Backend API (`internal/`, `main.go`)
- Database migrations (`migrations/`)
- Mobile applications (`mobile/`)
- Docker configurations (`Dockerfile`, `docker-compose.yml`)
- Documentation (`README.md`, `PRD.md`)
- Tests and utilities

### 2. Web Repository (Frontend)
**Repository**: [https://github.com/astahiam/comfunds-web.git](https://github.com/astahiam/comfunds-web.git)
**Focus**: Flutter Web Application

**Contents**:
- Flutter Web Application (`lib/`)
- Web-specific Docker configurations
- Comprehensive test suite (`test/`)
- Web documentation and README

## Separation Details

### What Was Moved
✅ **Flutter Web Application**:
- Complete Flutter web codebase (`lib/`)
- Web-specific Docker files (`Dockerfile`, `Dockerfile.dev`)
- Nginx configuration (`nginx.conf`)
- Flutter dependencies (`pubspec.yaml`)
- Comprehensive test suite (`test/`)

### What Remains in Main Repository
✅ **Backend & Infrastructure**:
- Go API backend (`internal/`, `main.go`)
- Database migrations (`migrations/`)
- Mobile applications (`mobile/`)
- Docker Compose configurations
- Documentation and PRD
- Backend tests

### Configuration Updates Made

#### Docker Compose Files
- **Production** (`docker-compose.yml`): Removed `frontend` service
- **Development** (`docker-compose.dev.yml`): Removed `frontend-dev` service
- **Nginx**: Updated to only proxy backend services

#### Makefile
- Removed web-related commands (`frontend-logs`)
- Updated service URLs to reflect backend-only setup
- Maintained mobile build commands

## Team Collaboration

### Backend Team
- **Repository**: `comfunds` (main)
- **Focus**: API development, database, mobile apps
- **Access**: Full access to backend codebase
- **Deployment**: Backend services and mobile apps

### Frontend Team
- **Repository**: `comfunds-web`
- **Focus**: Flutter web application
- **Access**: Full access to web codebase
- **Deployment**: Web application

## Development Workflow

### Backend Development
```bash
# Clone main repository
git clone https://github.com/astahiam/comfunds.git
cd comfunds

# Start development environment
make dev

# Access services
# Backend API: http://localhost:8081
# Database Admin: http://localhost:8082
# Redis: localhost:6380
```

### Frontend Development
```bash
# Clone web repository
git clone https://github.com/astahiam/comfunds-web.git
cd comfunds-web

# Install dependencies
flutter pub get

# Run development server
flutter run -d chrome

# Run tests
flutter test
```

### Integration Testing
Both teams can test integration by:
1. Backend team runs API on `localhost:8080`
2. Frontend team configures API endpoint in web app
3. Test complete user workflows

## API Integration

### Frontend Configuration
The web application should be configured to connect to the backend API:

```dart
// In web application configuration
const String apiBaseUrl = 'http://localhost:8080/api/v1';
```

### CORS Configuration
Backend API should include CORS headers for web application:

```go
// In main.go
router.Use(cors.New(cors.Config{
    AllowOrigins:     []string{"http://localhost:3000", "http://localhost:80"},
    AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
    AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
    AllowCredentials: true,
}))
```

## Deployment Strategy

### Backend Deployment
- Deploy Go API to production server
- Deploy PostgreSQL database
- Deploy Redis for caching
- Configure Nginx reverse proxy

### Frontend Deployment
- Build Flutter web application
- Deploy to web server or CDN
- Configure API endpoint for production

## Benefits of Separation

### 1. **Team Independence**
- Backend and frontend teams can work independently
- No merge conflicts between different codebases
- Separate release cycles

### 2. **Technology Focus**
- Backend team focuses on Go, PostgreSQL, APIs
- Frontend team focuses on Flutter, UI/UX, web optimization

### 3. **Scalability**
- Independent scaling of frontend and backend
- Different deployment strategies
- Separate monitoring and logging

### 4. **Security**
- Isolated access controls
- Separate security reviews
- Different vulnerability management

## Migration Checklist

### ✅ Completed
- [x] Create new web repository
- [x] Move all web-related files
- [x] Update Docker configurations
- [x] Update Makefile
- [x] Commit and push changes
- [x] Clean up main repository

### 🔄 Next Steps
- [ ] Update CI/CD pipelines
- [ ] Configure team access permissions
- [ ] Set up integration testing
- [ ] Update documentation links
- [ ] Configure production deployment

## Communication

### Repository Links
- **Main Repository**: https://github.com/astahiam/comfunds.git
- **Web Repository**: https://github.com/astahiam/comfunds-web.git

### Team Coordination
- Use GitHub Issues for cross-team coordination
- Maintain API documentation for integration
- Regular sync meetings for integration testing

## Support

For questions or issues related to the separation:
1. Check this documentation
2. Review repository README files
3. Create GitHub Issues for specific problems
4. Coordinate with team leads for complex issues

---

**Last Updated**: August 29, 2024
**Status**: ✅ Complete
**Version**: 1.0
