# ComFunds Mobile Application

This directory contains the Flutter mobile application for the ComFunds platform, supporting both iOS and Android.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for native development)
- Android SDK / iOS development tools

### Development

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run on Android:**
   ```bash
   flutter run -d android
   ```

3. **Run on iOS:**
   ```bash
   flutter run -d ios
   ```

4. **Run on connected device:**
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

### Docker Development

1. **Build Android APK:**
   ```bash
   cd ..
   make mobile-build
   ```

2. **Build Android App Bundle:**
   ```bash
   make mobile-bundle
   ```

## 📱 Platform Support

### Android

- **Minimum SDK**: API 21 (Android 5.0)
- **Target SDK**: API 33 (Android 13)
- **Architecture**: ARM64, x86_64

### iOS

- **Minimum Version**: iOS 12.0
- **Target Version**: iOS 16.0
- **Architecture**: ARM64

## 📁 Project Structure

```
mobile/
├── android/                   # Android-specific code
│   ├── app/
│   │   ├── src/
│   │   └── build.gradle
│   └── build.gradle
├── ios/                       # iOS-specific code
│   ├── Runner/
│   │   ├── Info.plist
│   │   └── Assets.xcassets
│   └── Runner.xcworkspace
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

### Android Configuration

Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        // ... other config
    }
}
```

### iOS Configuration

Update `ios/Runner/Info.plist`:

```xml
<key>MinimumOSVersion</key>
<string>12.0</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

### API Configuration

Update the API base URL in `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  // ... rest of the service
}
```

## 🎨 UI/UX Features

- **Material Design**: Follows Google's Material Design guidelines
- **Cupertino Design**: iOS-specific design elements
- **Dark/Light Theme**: Support for theme switching
- **Responsive Layout**: Adapts to different screen sizes
- **Accessibility**: WCAG 2.1 compliant
- **Biometric Authentication**: Fingerprint/Face ID support

## 📱 Features

- **User Authentication**: Login, registration, password reset
- **Project Management**: Create, view, and manage projects
- **Investment Management**: Browse and invest in projects
- **Profile Management**: User profile and settings
- **Image Upload**: Camera and gallery support
- **Push Notifications**: Real-time project updates
- **Offline Support**: Basic offline functionality
- **QR Code Scanner**: Scan project QR codes
- **Biometric Login**: Secure authentication

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

### Platform-Specific Tests

```bash
# Android
flutter test --platform android

# iOS
flutter test --platform ios
```

## 🚀 Building

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS Archive

```bash
flutter build ios --release
```

### Docker Builds

```bash
# Build Android APK
make mobile-build

# Build Android App Bundle
make mobile-bundle

# Build iOS (simulator)
docker build -f mobile/Dockerfile --target ios-builder ./mobile
```

## 📱 App Store Deployment

### Android (Google Play Store)

1. **Build App Bundle:**
   ```bash
   flutter build appbundle --release
   ```

2. **Sign the bundle:**
   ```bash
   jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore my-release-key.keystore app-release.aab alias_name
   ```

3. **Upload to Google Play Console**

### iOS (App Store)

1. **Build for distribution:**
   ```bash
   flutter build ios --release
   ```

2. **Archive in Xcode:**
   - Open `ios/Runner.xcworkspace`
   - Select "Any iOS Device" as target
   - Product → Archive

3. **Upload to App Store Connect**

## 🔒 Security

### Android Security

- **Network Security**: Configure network security config
- **Certificate Pinning**: Implement certificate pinning
- **ProGuard**: Enable code obfuscation
- **Permissions**: Request only necessary permissions

### iOS Security

- **App Transport Security**: Enable ATS
- **Keychain**: Secure storage for sensitive data
- **Code Signing**: Proper code signing
- **Permissions**: Request only necessary permissions

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

### Platform-Specific Dependencies

- `permission_handler`: Handle permissions
- `camera`: Camera functionality
- `qr_code_scanner`: QR code scanning

### Development Dependencies

- `flutter_test`: Testing framework
- `flutter_lints`: Code linting

## 🔧 Permissions

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

### iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes and take photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images</string>
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID for secure authentication</string>
```

## 🤝 Contributing

1. Follow Flutter coding conventions
2. Write tests for new features
3. Update documentation
4. Test on both platforms
5. Ensure accessibility compliance

## 📄 License

This mobile application is part of the ComFunds project and follows the same license terms.
