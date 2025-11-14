#!/bin/bash

# Telegram Bot Deployment Script
# This script deploys the Telegram moderation bot with SSL certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are available
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        print_error "Please install Docker before running this script"
        print_error "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check if Docker Compose is available
    if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH"
        print_error "Please install Docker Compose before running this script"
        print_error "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Check if required environment variables are set
check_env_vars() {
    print_status "Checking environment variables..."
    
    # Required variables
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        print_error "TELEGRAM_BOT_TOKEN environment variable is not set"
        print_error "Please set it in your .env file or export it before running this script"
        exit 1
    fi
    
    if [ -z "$DOMAIN_NAME" ]; then
        print_error "DOMAIN_NAME environment variable is not set"
        print_error "Please set it in your .env file or export it before running this script"
        exit 1
    fi
    
    # Optional variables with defaults
    if [ -z "$CERTBOT_EMAIL" ]; then
        print_warning "CERTBOT_EMAIL environment variable is not set"
        print_warning "Using default: admin@$DOMAIN_NAME"
        export CERTBOT_EMAIL="admin@$DOMAIN_NAME"
    fi
    
    # GitHub Packages configuration
    if [ -z "$GITHUB_REPOSITORY" ]; then
        print_warning "GITHUB_REPOSITORY environment variable is not set"
        print_warning "Using default: dunkan/tg-admin"
        export GITHUB_REPOSITORY="dunkan/tg-admin"
    fi
    
    if [ -z "$JAR_VERSION" ]; then
        print_warning "JAR_VERSION environment variable is not set"
        print_warning "Using default: latest"
        export JAR_VERSION="latest"
    fi
    
    if [ -z "$MAVEN_REPO_URL" ]; then
        print_warning "MAVEN_REPO_URL environment variable is not set"
        print_warning "Using default: https://maven.pkg.github.com"
        export MAVEN_REPO_URL="https://maven.pkg.github.com"
    fi
    
    # Check if we should use local build (fallback)
    if [ -z "$GITHUB_TOKEN" ] && [ "$JAR_VERSION" != "local" ]; then
        print_warning "GITHUB_TOKEN is not set - will attempt anonymous download"
        print_warning "If download fails, set JAR_VERSION=local to use local build"
        print_warning "For private repositories, GITHUB_TOKEN is required"
        
        # Validate GitHub token format if provided
    elif [ -n "$GITHUB_TOKEN" ]; then
        if [[ "$GITHUB_TOKEN" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] || [[ "$GITHUB_TOKEN" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
            print_status "✅ GitHub token format is valid"
        else
            print_warning "GitHub token format may be invalid"
            print_warning "Expected format: ghp_... (classic) or github_pat_... (fine-grained)"
        fi
    fi
    
    print_status "Environment variables check passed"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p logs
    mkdir -p certbot/conf
    mkdir -p certbot/www
    mkdir -p certbot/conf/live
    mkdir -p certbot/conf/archive
    mkdir -p certbot/conf/renewal
    
    print_status "Directories created"
}

# Generate initial SSL certificate
generate_ssl_certificate() {
    print_status "Generating SSL certificate for $DOMAIN_NAME..."
    
    # Check if certificate already exists
    if [ -d "certbot/conf/live/$DOMAIN_NAME" ]; then
        print_warning "SSL certificate already exists for $DOMAIN_NAME"
        return
    fi
    
    # Create the necessary directory structure for certificates
    mkdir -p certbot/conf/live/$DOMAIN_NAME
    mkdir -p certbot/conf/archive/$DOMAIN_NAME
    mkdir -p certbot/conf/renewal
    
    # Determine compose files based on build method
    COMPOSE_FILES="docker-compose.yml"
    if [ "$JAR_VERSION" = "local" ]; then
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.local.yml"
    fi
    
    # Generate temporary certificate for initial setup
    print_status "Generating temporary SSL certificate for initial setup..."
    docker compose $COMPOSE_FILES run --rm --entrypoint "\
        openssl req -x509 -nodes -newkey rsa:4096 -days 1 -keyout '/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem' -out '/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem' -subj '/CN=localhost'" certbot
    
    print_status "Temporary SSL certificate generated"
}

# Obtain Let's Encrypt certificate
obtain_letsencrypt_certificate() {
    print_status "Obtaining Let's Encrypt certificate for $DOMAIN_NAME..."
    
    # Determine compose files based on build method
    COMPOSE_FILES="docker-compose.yml"
    if [ "$JAR_VERSION" = "local" ]; then
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.local.yml"
    fi
    
    # Wait for nginx to start
    sleep 10
    
    # Request certificate from Let's Encrypt
    print_status "Requesting Let's Encrypt certificate..."
    docker compose $COMPOSE_FILES run --rm --entrypoint "\
        certbot certonly --webroot -w /var/www/certbot \
        --email $CERTBOT_EMAIL \
        -d $DOMAIN_NAME \
        --rsa-key-size 4096 \
        --agree-tos \
        --force-renewal \
        --non-interactive" certbot
    
    print_status "Let's Encrypt certificate obtained successfully"
}

# Build the application (now happens in Docker or downloads from GitHub Packages)
build_application() {
    print_status "Application deployment method: $JAR_VERSION"
    
    if [ "$JAR_VERSION" = "local" ]; then
        print_status "Building application locally using Dockerfile.local..."
        print_status "This is useful for development or when GitHub Packages are unavailable"
        
        # Use local build override
        export DOCKER_BUILDKIT=1
        docker compose -f docker-compose.yml -f docker-compose.local.yml build bot
    else
        print_status "Downloading jar artifact from GitHub Packages..."
        print_status "Repository: $GITHUB_REPOSITORY"
        print_status "Version: $JAR_VERSION"
        print_status "Maven Repository: $MAVEN_REPO_URL"
        
        # Build with artifact download
        export DOCKER_BUILDKIT=1
        docker compose build bot
    fi
    
    print_status "Application preparation completed"
}

# Deploy the application
deploy_application() {
    print_status "Deploying Telegram bot application..."
    
    # Determine compose files based on build method
    COMPOSE_FILES="docker-compose.yml"
    if [ "$JAR_VERSION" = "local" ]; then
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.local.yml"
        print_status "Using local build configuration"
    else
        print_status "Using GitHub Packages artifact configuration"
    fi
    
    # Build and start services
    print_status "Building and starting services..."
    docker compose $COMPOSE_FILES up -d --build
    
    print_status "Application deployed successfully"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Wait for services to start
    sleep 30
    
    # Check health endpoint
    if curl -f -s "https://$DOMAIN_NAME/health" > /dev/null; then
        print_status "Health check passed - bot is running"
    else
        print_error "Health check failed - please check the logs"
        docker compose logs bot
        exit 1
    fi
    
    # Check bot connectivity
    bot_info=$(curl -s "https://$DOMAIN_NAME/health" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$bot_info" ]; then
        print_status "Bot is connected: @$bot_info"
    else
        print_warning "Bot connectivity check failed - webhook may need manual registration"
    fi
}

# Main deployment function
main() {
    print_status "Starting Telegram bot deployment..."
    print_status "Note: This script supports both GitHub Packages and local builds"
    
    # Load environment variables from .env file if it exists
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        print_status "Loaded environment variables from .env file"
    fi
    
    check_prerequisites
    check_env_vars
    create_directories
    build_application
    generate_ssl_certificate
    deploy_application
    obtain_letsencrypt_certificate
    verify_deployment
    
    print_status "Deployment completed successfully!"
    print_status "Your Telegram bot is now running at https://$DOMAIN_NAME"
    print_status "Webhook URL: https://$DOMAIN_NAME/webhook"
    print_status "Health check: https://$DOMAIN_NAME/health"
    
    # Show useful commands
    echo ""
    print_status "Useful commands:"
    echo "  View logs: docker compose logs -f bot"
    echo "  Stop services: docker compose down"
    echo "  Restart services: docker compose restart"
    echo "  Update SSL certificate: docker compose run --rm certbot renew"
    echo ""
    print_status "Build options:"
    echo "  GitHub Packages: JAR_VERSION=<commit-sha> ./deploy.sh"
    echo "  Local build: JAR_VERSION=local ./deploy.sh"
    echo "  Latest version: JAR_VERSION=latest ./deploy.sh"
}

# Run main function
main "$@"