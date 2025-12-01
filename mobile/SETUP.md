# Hajifund Mobile App - Setup Guide

## Prerequisites

1. **Node.js** (v18 or higher)
   ```bash
   node --version
   ```

2. **React Native CLI**
   ```bash
   npm install -g react-native-cli
   ```

3. **For iOS Development:**
   - macOS
   - Xcode (latest version)
   - CocoaPods: `sudo gem install cocoapods`

4. **For Android Development:**
   - Android Studio
   - Android SDK
   - Java Development Kit (JDK 11 or higher)

## Installation Steps

### 1. Install Dependencies

```bash
cd mobile
npm install
```

### 2. Install iOS Dependencies (macOS only)

```bash
cd ios
pod install
cd ..
```

### 3. Configure Environment

Update `src/constants/Config.ts` with your backend API URL:

```typescript
API_BASE_URL: 'http://your-backend-url:8080/api/v1'
```

### 4. Run the App

#### iOS Simulator
```bash
npm run ios
```

#### Android Emulator
```bash
npm run android
```

#### Start Metro Bundler separately
```bash
npm start
```

## Project Structure

```
mobile/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   └── Input.tsx
│   ├── screens/            # Screen components
│   │   ├── auth/          # Authentication screens
│   │   ├── home/          # Home/Dashboard
│   │   ├── projects/      # Project management
│   │   ├── business/       # Business management
│   │   ├── investments/   # Investment portfolio
│   │   └── profile/       # User profile
│   ├── navigation/        # Navigation configuration
│   ├── services/          # API services
│   ├── context/          # React Context (Auth)
│   ├── constants/       # App constants
│   ├── types/            # TypeScript types
│   └── assets/           # Images and assets
├── App.tsx               # Root component
└── index.js              # Entry point
```

## Key Features Implemented

### ✅ Authentication
- Welcome screen with branding
- Login screen
- Registration screen
- JWT token management
- Role-based access control

### ✅ Main Screens
- Home/Dashboard with statistics
- Projects listing with filters
- Business management
- Investment portfolio
- User profile

### ✅ Design System
- Consistent color scheme (Hajifund green #00A86B)
- Typography (Inter & Poppins)
- Reusable components
- Material Design icons

### ✅ API Integration
- Centralized API service
- Authentication handling
- Error handling
- Request/response interceptors

## Next Steps

### To Complete the App:

1. **Add Missing Screens:**
   - Project detail screen
   - Business detail screen
   - Create/Edit business forms
   - Create project form
   - Investment detail screen
   - Investment flow

2. **Add Native Features:**
   - Image picker for document uploads
   - Push notifications
   - Biometric authentication
   - Offline support

3. **Testing:**
   - Unit tests
   - Integration tests
   - E2E tests

4. **Build Configuration:**
   - iOS app icons and splash screens
   - Android app icons and splash screens
   - App store configuration

## Troubleshooting

### Metro Bundler Issues
```bash
npm start -- --reset-cache
```

### iOS Build Issues
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Android Build Issues
```bash
cd android
./gradlew clean
cd ..
```

## Development Notes

- The app uses React Navigation 6 for navigation
- Authentication state is managed via React Context
- API calls use Axios with interceptors for token management
- All images should be placed in `src/assets/images/`
- Design follows the same color scheme as the web frontend

## Support

For issues or questions, refer to:
- React Native Documentation: https://reactnative.dev/docs/getting-started
- React Navigation: https://reactnavigation.org/docs/getting-started

