# Hajifund Mobile App

Sharia-Compliant Cooperative Crowdfunding Platform - React Native Mobile Application

## Overview

Hajifund Mobile is a React Native application for iOS and Android that enables cooperative members to invest in business projects through Sharia-compliant profit-sharing mechanisms.

## Features

- **Authentication**: Login and registration with role-based access
- **Project Browsing**: View and filter available funding projects
- **Investment Management**: Track investments and portfolio
- **Business Management**: Create and manage business profiles
- **Dashboard**: Overview of investments and project statistics

## Tech Stack

- React Native 0.72.6
- TypeScript
- React Navigation 6
- Axios for API calls
- AsyncStorage for local storage
- React Native Vector Icons

## Installation

### Prerequisites

- Node.js >= 18
- React Native CLI
- Xcode (for iOS development)
- Android Studio (for Android development)

### Setup

1. Install dependencies:
```bash
npm install
```

2. For iOS:
```bash
cd ios && pod install && cd ..
```

3. Run the app:
```bash
# iOS
npm run ios

# Android
npm run android
```

## Project Structure

```
mobile/
├── src/
│   ├── components/       # Reusable UI components
│   ├── screens/          # Screen components
│   ├── navigation/      # Navigation configuration
│   ├── services/        # API services
│   ├── context/         # React Context providers
│   ├── constants/       # App constants (colors, theme, config)
│   ├── types/           # TypeScript type definitions
│   └── assets/          # Images and static assets
├── App.tsx              # Root component
└── index.js             # Entry point
```

## Configuration

Update API base URL in `src/constants/Config.ts`:

```typescript
API_BASE_URL: 'http://your-backend-url/api/v1'
```

## Design System

The app uses the same design system as the web frontend:
- Primary Color: #00A86B (Green)
- Typography: Inter and Poppins fonts
- Components follow Material Design principles

## Features by Role

### Guest Users
- View public project information
- Register for an account

### Cooperative Members
- View all projects within their cooperative
- Invest in approved projects
- Track investment portfolio

### Business Owners
- Create and manage business profiles
- Create funding projects
- Track project funding progress

### Investors
- Browse and invest in projects
- View portfolio and returns
- Track profit distributions

## API Integration

The app integrates with the Hajifund backend API. Ensure the backend is running and accessible before testing the mobile app.

## Development

### Running in Development Mode

```bash
npm start
```

Then run on iOS or Android simulator/device.

### Building for Production

#### iOS
```bash
cd ios
xcodebuild -workspace Hajifund.xcworkspace -scheme Hajifund -configuration Release
```

#### Android
```bash
cd android
./gradlew assembleRelease
```

## License

Copyright © 2024 Hajifund. All rights reserved.

