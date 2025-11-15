#!/bin/bash

# Script to create a minimal deployment package
# This avoids transferring unnecessary files and preserves certbot data

echo "📦 Creating deployment package..."

# Create temporary deployment directory
DEPLOY_DIR="deployment-package"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

# Copy essential files
echo "📁 Copying essential files..."

# Docker files
cp docker-compose.yml "$DEPLOY_DIR/"
cp docker-compose.local.yml "$DEPLOY_DIR/" 2>/dev/null || echo "docker-compose.local.yml not found, skipping"
cp Dockerfile "$DEPLOY_DIR/"
cp Dockerfile.local "$DEPLOY_DIR/" 2>/dev/null || echo "Dockerfile.local not found, skipping"

# Nginx configuration
mkdir -p "$DEPLOY_DIR/nginx"
cp -r nginx/* "$DEPLOY_DIR/nginx/" 2>/dev/null || echo "nginx directory not found, skipping"

# Scripts
mkdir -p "$DEPLOY_DIR/scripts"
cp scripts/*.sh "$DEPLOY_DIR/scripts/" 2>/dev/null || echo "scripts directory not found, skipping"

# Remove the deployment package script from the package to avoid recursion
rm "$DEPLOY_DIR/scripts/create-deployment-package.sh" 2>/dev/null || true

# Configuration files
cp deploy.sh "$DEPLOY_DIR/" 2>/dev/null || echo "deploy.sh not found, skipping"
cp .env.example "$DEPLOY_DIR/" 2>/dev/null || echo ".env.example not found, skipping"
cp gradle.properties "$DEPLOY_DIR/" 2>/dev/null || echo "gradle.properties not found, skipping"

# Make scripts executable
chmod +x "$DEPLOY_DIR/scripts/"*.sh 2>/dev/null
chmod +x "$DEPLOY_DIR/deploy.sh" 2>/dev/null

echo "✅ Deployment package created in: $DEPLOY_DIR"
echo ""
echo "📋 Package contents:"
find "$DEPLOY_DIR" -type f | sort