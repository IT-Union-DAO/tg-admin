#!/bin/bash

# Script to initialize SSL certificates with Certbot
# Usage: ./scripts/init-certbot.sh

set -e

echo "🔧 Initializing SSL certificates..."

# Check if environment variables are set
if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ DOMAIN_NAME environment variable is not set"
    exit 1
fi

if [ -z "$CERTBOT_EMAIL" ]; then
    echo "❌ CERTBOT_EMAIL environment variable is not set"
    exit 1
fi

# Create certbot directories
mkdir -p certbot/conf certbot/www

# Check if certificates already exist
if [ -f "certbot/conf/live/$DOMAIN_NAME/fullchain.pem" ]; then
    echo "✅ SSL certificates already exist for $DOMAIN_NAME"
    echo "📋 To force renewal, run: docker exec certbot certbot renew --force-renewal"
    exit 0
fi

echo "📝 Creating SSL certificates for $DOMAIN_NAME..."

# Stop certbot container if running
docker stop certbot 2>/dev/null || true

# Create certificates using webroot method
echo "🌐 Requesting SSL certificates from Let's Encrypt..."
docker run -it --rm \
  --name certbot-init \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  --email "$CERTBOT_EMAIL" \
  --agree-tos \
  --no-eff-email \
  -d "$DOMAIN_NAME"

echo "✅ SSL certificates created successfully!"
echo "📋 Certificate location: certbot/conf/live/$DOMAIN_NAME/"

# Restart services
echo "🔄 Restarting services..."
docker-compose up -d

echo "🎉 SSL setup complete!"
echo "📋 To check certificate status: docker exec certbot certbot certificates"
echo "📋 To test renewal: docker exec certbot certbot renew --dry-run"