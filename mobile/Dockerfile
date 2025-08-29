# Multi-stage build for Flutter Mobile Development
FROM debian:latest AS base

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set up environment variables
ENV FLUTTER_HOME="/opt/flutter"
ENV ANDROID_HOME="/opt/android-sdk"
ENV PATH="$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Download and install Flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
RUN flutter channel stable
RUN flutter upgrade

# Download and install Android SDK
RUN mkdir -p $ANDROID_HOME
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O /tmp/commandlinetools.zip
RUN unzip /tmp/commandlinetools.zip -d $ANDROID_HOME
RUN mv $ANDROID_HOME/cmdline-tools $ANDROID_HOME/cmdline-tools/latest

# Accept Android licenses
RUN yes | sdkmanager --licenses

# Install Android SDK components
RUN sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Set up Flutter doctor
RUN flutter doctor

# Copy Flutter app
WORKDIR /app
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# Build stage for Android APK
FROM base AS android-builder

# Build Android APK
RUN flutter build apk --release

# Build stage for Android App Bundle
FROM base AS android-bundle

# Build Android App Bundle
RUN flutter build appbundle --release

# Build stage for iOS (simulator only - for CI/CD)
FROM base AS ios-builder

# Install iOS dependencies (simulator only)
RUN flutter build ios --release --no-codesign

# Final stage for development
FROM base AS development

# Expose ports for development
EXPOSE 8080 3000

# Set working directory
WORKDIR /app

# Copy built artifacts (optional - for CI/CD)
COPY --from=android-builder /app/build/app/outputs/flutter-apk/app-release.apk /app/build/
COPY --from=android-bundle /app/build/app/outputs/bundle/release/app-release.aab /app/build/

# Development command
CMD ["flutter", "run", "--web-port", "8080", "--web-hostname", "0.0.0.0"]
