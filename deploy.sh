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

# Check if required environment variables are set
check_env_vars() {
    print_status "Checking environment variables..."
    
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
    
    if [ -z "$CERTBOT_EMAIL" ]; then
        print_warning "CERTBOT_EMAIL environment variable is not set"
        print_warning "Using default: admin@$DOMAIN_NAME"
        export CERTBOT_EMAIL="admin@$DOMAIN_NAME"
    fi
    
    print_status "Environment variables check passed"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p logs
    mkdir -p certbot/conf
    mkdir -p certbot/www
    
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
    
    # Generate temporary certificate for initial setup
    docker-compose run --rm --entrypoint "\
        openssl req -x509 -nodes -newkey rsa:4096 -days 1 -keyout '/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem' -out '/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem' -subj '/CN=localhost'" certbot
    
    print_status "Temporary SSL certificate generated"
}

# Obtain Let's Encrypt certificate
obtain_letsencrypt_certificate() {
    print_status "Obtaining Let's Encrypt certificate for $DOMAIN_NAME..."
    
    # Wait for nginx to start
    sleep 10
    
    # Request certificate from Let's Encrypt
    docker-compose run --rm --entrypoint "\
        certbot certonly --webroot -w /var/www/certbot \
        --email $CERTBOT_EMAIL \
        -d $DOMAIN_NAME \
        --rsa-key-size 4096 \
        --agree-tos \
        --force-renewal \
        --non-interactive" certbot
    
    print_status "Let's Encrypt certificate obtained successfully"
}

# Deploy the application
deploy_application() {
    print_status "Deploying Telegram bot application..."
    
    # Build and start services
    docker-compose up -d --build
    
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
        docker-compose logs bot
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
    
    # Load environment variables from .env file if it exists
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        print_status "Loaded environment variables from .env file"
    fi
    
    check_env_vars
    create_directories
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
    echo "  View logs: docker-compose logs -f bot"
    echo "  Stop services: docker-compose down"
    echo "  Restart services: docker-compose restart"
    echo "  Update SSL certificate: docker-compose run --rm certbot renew"
}

# Run main function
main "$@"