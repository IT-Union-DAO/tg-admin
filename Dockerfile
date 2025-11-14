# Telegram Moderation Bot - Artifact-based Deployment
# This Dockerfile downloads pre-built jar artifacts from GitHub Packages
# Use build-arg JAR_VERSION to specify the version (defaults to latest)

FROM eclipse-temurin:21-jre-alpine

# Install curl for health checks and wget for artifact download
RUN apk add --no-cache curl wget

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
    echo "Downloading jar artifact version: ${JAR_VERSION}" && \
    \
    # Set repository coordinates
    REPO_OWNER=$(echo "${GITHUB_REPOSITORY:-dunkan/tg-admin}" | cut -d'/' -f1) && \
    REPO_NAME=$(echo "${GITHUB_REPOSITORY:-dunkan/tg-admin}" | cut -d'/' -f2) && \
    GROUP_ID="su.dunkan" && \
    ARTIFACT_ID="tg-admin" && \
    \
    echo "Repository: ${REPO_OWNER}/${REPO_NAME}" && \
    echo "Maven coordinates: ${GROUP_ID}:${ARTIFACT_ID}:${JAR_VERSION}" && \
    \
    # Download the jar artifact
    if [ -n "${GITHUB_TOKEN}" ]; then \
        echo "Using authenticated download with GitHub token" && \
        wget --header="Authorization: token ${GITHUB_TOKEN}" \
             --header="Accept: application/octet-stream" \
             "${MAVEN_REPO_URL}/${REPO_OWNER}/${REPO_NAME}/${GROUP_ID}/${ARTIFACT_ID}/${JAR_VERSION}/${ARTIFACT_ID}-${JAR_VERSION}.jar" \
             -O app.jar || { \
            echo "Failed to download with token, trying without authentication..." && \
            wget "${MAVEN_REPO_URL}/${REPO_OWNER}/${REPO_NAME}/${GROUP_ID}/${ARTIFACT_ID}/${JAR_VERSION}/${ARTIFACT_ID}-${JAR_VERSION}.jar" \
                 -O app.jar; \
        } \
    else \
        echo "Using anonymous download" && \
        wget "${MAVEN_REPO_URL}/${REPO_OWNER}/${REPO_NAME}/${GROUP_ID}/${ARTIFACT_ID}/${JAR_VERSION}/${ARTIFACT_ID}-${JAR_VERSION}.jar" \
             -O app.jar || { \
            echo "Failed to download from GitHub Packages, falling back to local build..." && \
            echo "This fallback is for development/testing only" && \
            exit 1; \
        } \
    fi && \
    \
    # Verify the jar was downloaded
    if [ ! -f "app.jar" ] || [ ! -s "app.jar" ]; then \
        echo "Error: Failed to download jar artifact" && \
        exit 1; \
    fi && \
    \
    echo "Jar artifact downloaded successfully" && \
    ls -la app.jar && \
    \
    # Extract jar info for verification
    echo "Jar information:" && \
    file app.jar && \
    echo "Jar size: $(stat -c%s app.jar) bytes"

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]