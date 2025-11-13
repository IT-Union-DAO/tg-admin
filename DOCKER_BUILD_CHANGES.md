# Docker Build Implementation

## Summary

The deployment script has been updated to use Docker-based builds, eliminating the requirement for local Java installation. This makes the deployment process more portable and easier to run on any machine with Docker installed.

## Changes Made

### 1. Updated Dockerfile
- **Multi-stage build**: Added a two-stage Docker build process
- **Builder stage**: Uses `eclipse-temurin:21-jdk-alpine` to compile the application
- **Runtime stage**: Uses `eclipse-temurin:21-jre-alpine` for the final image
- **In-container build**: The Gradle build now happens inside the Docker container

### 2. Updated .dockerignore
- **Fixed exclusions**: Removed Gradle build files from exclusion list
- **Selective exclusion**: Only exclude `.gradle/` cache and `build/` directories
- **Keep necessary files**: Allow `gradlew`, `build.gradle.kts`, `settings.gradle.kts`, and `gradle/` directory

### 3. Enhanced deploy.sh
- **Prerequisites check**: Added validation for Docker and Docker Compose availability
- **Removed local build**: Eliminated the `./gradlew build` step that required local Java
- **Better error messages**: Clear instructions when Docker is not available
- **Updated messaging**: Added notes about Docker-based builds

## Benefits

1. **No local Java required**: Developers can deploy without installing Java
2. **Consistent build environment**: Same build environment everywhere
3. **Smaller runtime image**: Only JRE needed in final image
4. **Better portability**: Works on any machine with Docker
5. **Cleaner deployment**: Single command deployment without prerequisites

## Prerequisites

The deployment now only requires:
- Docker
- Docker Compose
- Environment variables (TELEGRAM_BOT_TOKEN, DOMAIN_NAME)

## Usage

```bash
# Set up environment variables
cp .env.example .env
# Edit .env with your values

# Run deployment
./deploy.sh
```

The script will:
1. Check for Docker availability
2. Validate environment variables
3. Build the application inside Docker
4. Deploy all services
5. Set up SSL certificates
6. Verify deployment

## Build Process

The new build process:
1. **Builder stage**: Downloads Gradle, compiles Kotlin code, creates JAR
2. **Runtime stage**: Copies only the JAR and runtime dependencies
3. **Final image**: Minimal JRE-based image with the application

This approach ensures consistent builds across different environments while keeping the final runtime image small and efficient.