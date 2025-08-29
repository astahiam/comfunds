# Multi-stage build for Flutter Web
FROM debian:latest AS base

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Set up environment variables
ENV FLUTTER_HOME="/opt/flutter"
ENV PATH="$FLUTTER_HOME/bin:$PATH"

# Download and install Flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Set up Flutter doctor
RUN flutter doctor

# Copy Flutter app
WORKDIR /app
COPY . .

# Get Flutter dependencies
RUN flutter pub get

# Build Flutter web app
RUN flutter build web --release

# Production stage with nginx
FROM nginx:alpine

# Copy built web app to nginx
COPY --from=base /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80 || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
