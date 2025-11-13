# Multi-stage build for Telegram Moderation Bot
# Stage 1: Build the application
FROM eclipse-temurin:21-jdk-alpine AS builder

# Install curl for downloading dependencies if needed
RUN apk add --no-cache curl

WORKDIR /build

# Copy Gradle wrapper and project files
COPY gradlew .
COPY gradle gradle
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY gradle.properties .

# Make gradlew executable
RUN chmod +x gradlew

# Copy source code
COPY src src

# Build the application
RUN ./gradlew build --no-daemon

# Stage 2: Runtime image
FROM eclipse-temurin:21-jre-alpine

# Install curl for health checks
RUN apk add --no-cache curl

WORKDIR /app

# Copy the built JAR from builder stage
COPY --from=builder /build/build/libs/tg-admin-all.jar app.jar

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 8080

# Set environment variables for Java
ENV JAVA_OPTS="-Xmx256m -Xms128m"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]