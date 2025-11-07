# Flutter Web & Android Development Environment
FROM ghcr.io/cirruslabs/flutter:stable

# Install dependencies for Web and Android
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    default-jdk \
  && rm -rf /var/lib/apt/lists/*

# Enable web and android platforms
RUN flutter config --enable-web \
  && flutter config --no-enable-ios \
  && flutter config --no-enable-macos \
  && flutter config --no-enable-linux

# Accept Android licenses
RUN yes | flutter doctor --android-licenses || true

WORKDIR /app

# Copy dependency files
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN flutter pub get

# Copy the rest of the project
COPY . .

# Build web version
RUN flutter build web --release

EXPOSE 8080

# Default command - serve web app
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]
