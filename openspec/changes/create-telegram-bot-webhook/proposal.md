## Why
Transform the basic Ktor web application into a fully functional Telegram moderation bot that can be deployed on any virtual machine using Docker Compose with SSL certificates and webhook configuration.

## What Changes
- **BREAKING**: Replace basic "Hello World" web server with Telegram Bot API integration
- Add Telegram Bot API client for handling webhook updates
- Implement moderation logic to detect and delete new member messages
- Add Docker Compose configuration with Certbot for SSL certificate management
- Parameterize domain name and bot token via environment variables
- Create comprehensive deployment documentation
- Add logging infrastructure with dedicated log directory
- Add health check endpoints for monitoring

## Impact
- Affected specs: New `telegram-bot` capability
- Affected code: Application.kt, Routing.kt, application.yaml, plus new files
- New infrastructure: Docker Compose, Certbot, SSL certificates
- Deployment: Requires domain name and Telegram bot token configuration