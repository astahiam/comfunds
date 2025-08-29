# ComFunds Web Application

This directory contains the Flutter web application for the ComFunds platform.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.0.0 or higher)
- Web browser (Chrome recommended)

### Development

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run in development mode:**
   ```bash
   flutter run -d chrome --web-port 3000
   ```

3. **Build for production:**
   ```bash
   flutter build web --release
   ```

### Docker Development

1. **Start with Docker:**
   ```bash
   cd ..
   make dev
   ```

2. **Access the application:**
   - Development: http://localhost:3000
   - Production: http://localhost:80

## 📁 Project Structure

```
web/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── app.dart               # App configuration
│   ├── models/                # Data models
│   ├── services/              # API services
│   ├── providers/             # State management
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable widgets
│   └── utils/                 # Utility functions
├── assets/
│   ├── images/                # Image assets
│   ├── icons/                 # Icon assets
│   └── fonts/                 # Font files
├── test/                      # Unit tests
├── pubspec.yaml               # Dependencies
└── README.md                  # This file
```

## 🔧 Configuration

### API Configuration

Update the API base URL in `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  // ... rest of the service
}
```

### Environment Variables

Create a `.env` file for environment-specific configuration:

```env
API_BASE_URL=http://localhost:8080/api/v1
ENVIRONMENT=development
```

## 🎨 UI/UX Features

- **Responsive Design**: Works on desktop, tablet, and mobile
- **Material Design**: Follows Google's Material Design guidelines
- **Dark/Light Theme**: Support for theme switching
- **Internationalization**: Multi-language support
- **Accessibility**: WCAG 2.1 compliant

## 📱 Features

- **User Authentication**: Login, registration, password reset
- **Project Management**: Create, view, and manage projects
- **Investment Management**: Browse and invest in projects
- **Profile Management**: User profile and settings
- **Image Upload**: Support for project and profile images
- **Real-time Updates**: Live project status updates

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Widget Tests

```bash
flutter test test/widget_test.dart
```

## 🚀 Deployment

### Production Build

```bash
flutter build web --release
```

### Docker Deployment

```bash
# Build production image
docker build -t comfunds-web .

# Run container
docker run -p 80:80 comfunds-web
```

### Static Hosting

The built web application can be deployed to any static hosting service:

- **Netlify**: Drag and drop the `build/web` folder
- **Vercel**: Connect your repository
- **Firebase Hosting**: Use Firebase CLI
- **AWS S3**: Upload to S3 bucket with CloudFront

## 🔒 Security

- **HTTPS**: Always use HTTPS in production
- **CORS**: Configure CORS headers for API access
- **Content Security Policy**: Implemented in nginx configuration
- **Input Validation**: Client-side and server-side validation

## 📚 Dependencies

### Core Dependencies

- `flutter`: Flutter framework
- `http`: HTTP client for API calls
- `provider`: State management
- `shared_preferences`: Local storage
- `flutter_secure_storage`: Secure storage
- `image_picker`: Image selection
- `cached_network_image`: Image caching
- `flutter_svg`: SVG support
- `intl`: Internationalization
- `url_launcher`: URL handling

### Development Dependencies

- `flutter_test`: Testing framework
- `flutter_lints`: Code linting

## 🤝 Contributing

1. Follow Flutter coding conventions
2. Write tests for new features
3. Update documentation
4. Ensure responsive design
5. Test on multiple browsers

## 📄 License

This web application is part of the ComFunds project and follows the same license terms.
