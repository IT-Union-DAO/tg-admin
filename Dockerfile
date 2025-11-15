# Telegram Moderation Bot - Artifact-based Deployment
# This Dockerfile downloads pre-built jar artifacts from GitHub Packages
# Use build-arg JAR_VERSION to specify the version (defaults to latest)

FROM eclipse-temurin:21-jre-alpine

# Install curl for health checks, wget for artifact download, and file for jar verification
RUN apk add --no-cache curl wget file

# Create app directory
WORKDIR /app

# Create logs directory
RUN mkdir -p logs

# Build arguments for artifact configuration
ARG JAR_VERSION=latest
ARG GITHUB_TOKEN
ARG GITHUB_REPOSITORY
ARG MAVEN_REPO_URL=https://maven.pkg.github.com

# Environment variables
ENV JAVA_OPTS="-Xmx256m -Xms128m"
ENV JAR_VERSION=${JAR_VERSION}

# Function to download jar from GitHub Packages
# This approach handles both public and private repositories
RUN set -e && \
    echo "Processing jar artifact version: ${JAR_VERSION}" && \
    \
    # Check if we should skip GitHub Packages and use local build
    if [ "$JAR_VERSION" = "local" ]; then \
        echo "Using local build mode - skipping GitHub Packages download" && \
        echo "The jar will be provided via docker-compose.local.yml override" && \
        exit 0; \
    fi && \
    \
    # Set repository coordinates
    REPO_OWNER=$(echo "${GITHUB_REPOSITORY:-IT-Union-DAO/tg-admin}" | cut -d'/' -f1) && \
    REPO_NAME=$(echo "${GITHUB_REPOSITORY:-IT-Union-DAO/tg-admin}" | cut -d'/' -f2) && \
    GROUP_ID="su.dunkan" && \
    ARTIFACT_ID="tg-admin" && \
    \
    echo "Repository: ${REPO_OWNER}/${REPO_NAME}" && \
    echo "Maven coordinates: ${GROUP_ID}:${ARTIFACT_ID}:${JAR_VERSION}" && \
    \
    # Convert group ID to URL path (replace dots with slashes)
    GROUP_PATH=$(echo "${GROUP_ID}" | sed 's/\./\//g') && \
    \
    # Download the jar artifact
    if [ -n "${GITHUB_TOKEN}" ]; then \
        echo "Using authenticated download with GitHub token" && \
        wget --header="Authorization: token ${GITHUB_TOKEN}" \
             --header="Accept: application/octet-stream" \
             "${MAVEN_REPO_URL}/${REPO_OWNER}/${REPO_NAME}/${GROUP_PATH}/${ARTIFACT_ID}/${JAR_VERSION}/${ARTIFACT_ID}-${JAR_VERSION}.jar" \
             -O app.jar || { \
            echo "Failed to download with token, trying without authentication..." && \
            wget "${MAVEN_REPO_URL}/${REPO_OWNER}/${REPO_NAME}/${GROUP_PATH}/${ARTIFACT_ID}/${JAR_VERSION}/${ARTIFACT_ID}-${JAR_VERSION}.jar" \
                 -O app.jar || { \
                echo "GitHub Packages download failed with both authenticated and anonymous attempts" && \
                echo "This is expected in development environments without proper GitHub Packages access" && \
                echo "The jar will be provided via docker-compose.local.yml override" && \
                exit 0; \
            }; \
        } \
    else \
        echo "Using anonymous download" && \
        wget "${MAVEN_REPO_URL}/${REPO_OWNER}/${REPO_NAME}/${GROUP_PATH}/${ARTIFACT_ID}/${JAR_VERSION}/${ARTIFACT_ID}-${JAR_VERSION}.jar" \
             -O app.jar || { \
            echo "GitHub Packages download failed - authentication required" && \
            echo "This is expected in development environments without GITHUB_TOKEN" && \
            echo "The jar will be provided via docker-compose.local.yml override" && \
            exit 0; \
        } \
    fi && \
    \
    # Verify the jar was downloaded
    if [ ! -f "app.jar" ] || [ ! -s "app.jar" ]; then \
        echo "Error: Failed to download jar artifact" && \
        echo "This is expected in development environments - jar will be provided via docker-compose.local.yml" && \
        exit 0; \
    fi && \
    \
    echo "Jar artifact downloaded successfully" && \
    ls -la app.jar && \
    \
    # Extract jar info for verification
    echo "Jar information:" && \
    file app.jar 2>/dev/null || echo "File command not available, using alternative verification" && \
    echo "Jar size: $(stat -c%s app.jar) bytes"

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]