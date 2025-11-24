# Telegram Moderation Bot



A lightweight Telegram bot for simple moderation procedures. The bot automatically tracks new members joining groups and
deletes the "new member joined" service messages to keep group chats clean.

Built with Kotlin and Ktor, deployed using Docker Compose with automated SSL certificates via Certbot. Now supports *
*GitHub Actions-based CI/CD** for automated jar artifact building and deployment.

## Features

- 🤖 **Automatic Moderation**: Detects and deletes "new member joined" messages
- 🔄 **Webhook-based**: Real-time updates via Telegram Bot API webhooks
- 🔒 **SSL Secured**: Automatic SSL certificate management with Let's Encrypt
- 🐳 **Docker Ready**: Complete containerized deployment with Docker Compose
- 📊 **Health Monitoring**: Built-in health check endpoints
- 📝 **Comprehensive Logging**: Detailed activity logs for monitoring and debugging

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- A domain name pointing to your server
- Telegram Bot Token (get from [@BotFather](https://t.me/BotFather))

**Note**: No local Java installation required! The build happens inside Docker containers.

### Option 1: GitHub Actions Deployment (Recommended)

For production deployments with automated CI/CD:

1. **Set up GitHub Secrets** (see [GITHUB_ACTIONS_SETUP.md](logs/GITHUB_ACTIONS_SETUP.md)):
    - `VM_SSH_KEY`, `VM_HOST`, `VM_USER` for VM access
    - `TELEGRAM_BOT_TOKEN`, `DOMAIN_NAME` for application
    - `GITHUB_TOKEN` for package access (auto-provided)

2. **Configure Repository**:
   ```bash
   git clone <repository-url>
   cd tg-admin
   git push origin main  # Triggers automated build
   ```

3. **Deploy Manually**:
    - Go to `Actions` tab in GitHub
    - Run `Deploy to Production VM` workflow
    - Choose version and environment

### Option 2: Local Deployment

For development or manual deployment:

```bash
git clone <repository-url>
cd tg-admin

# Copy environment template and configure
cp .env.example .env
nano .env  # Edit with your bot token and domain

# Make deployment script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

That's it! Your bot will be deployed with SSL certificates and ready to use.

## Configuration

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Required: Your Telegram Bot Token from @BotFather
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz

# Required: Your domain name (must point to this server)
DOMAIN_NAME=your-domain.com

# Optional: Custom port (default: 8080)
BOT_PORT=8080

# Email for SSL certificate registration and renewal
# Used by Let's Encrypt for certificate expiration notices
CERTBOT_EMAIL=admin@your-domain.com

# GitHub Packages Configuration (optional)
GITHUB_TOKEN=your_github_token
GITHUB_REPOSITORY=owner/repo
JAR_VERSION=latest
```

**For complete environment variable reference**, see [ENVIRONMENT_VARIABLES.md](logs/ENVIRONMENT_VARIABLES.md).

### Getting a Bot Token

1. Start a chat with [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` command
3. Follow the instructions to create your bot
4. Copy the bot token provided by BotFather
5. Add the token to your `.env` file

## Deployment Options

### Option 1: GitHub Actions Deployment (Production Recommended)

Automated deployment with CI/CD pipeline:

1. **Automated Build**: Jar artifacts built on main branch push
2. **Manual Deployment**: Trigger deployment from GitHub Actions
3. **Version Control**: Deploy specific versions or latest
4. **Rollback Support**: Easy rollback to previous versions

**Setup**: See [GITHUB_ACTIONS_SETUP.md](logs/GITHUB_ACTIONS_SETUP.md) for detailed configuration.

### Option 2: Local Deployment (Development)

Use the provided deployment script:

```bash
./deploy.sh
```

This script supports:

- **GitHub Packages**: Download pre-built artifacts (default)
- **Local Build**: Build from source with `JAR_VERSION=local`

**Build Options**:

```bash
# Use GitHub Packages artifact
./deploy.sh

# Use specific version
JAR_VERSION=abc123def456 ./deploy.sh

# Use local build
JAR_VERSION=local ./deploy.sh
```

### Option 3: Manual Deployment

```bash
# 1. Create necessary directories
mkdir -p logs certbot/conf certbot/www

# 2. Start services
docker compose up -d --build

# 3. Generate SSL certificate
docker compose run --rm certbot certonly --webroot -w /var/www/certbot -d your-domain.com --email your-email@domain.com --agree-tos --no-eff-email

# 4. Restart Nginx to apply SSL
docker compose restart nginx
```

## SSL Certificate Management

### Automatic Certificate Creation

The updated configuration now automatically creates SSL certificates on first run:

```bash
# Certificates will be created automatically when:
docker compose up -d
```

### Manual Certificate Management

```bash
# Check certificate status
docker exec certbot certbot certificates

# Force certificate renewal
docker exec certbot certbot renew --force-renewal

# Test renewal (dry run)
docker exec certbot certbot renew --dry-run

# Initialize certificates manually (if automatic fails)
./scripts/init-certbot.sh
```

### Troubleshooting SSL Issues

1. **Certificates not created**: Check that `DOMAIN_NAME` and `CERTBOT_EMAIL` are set in `.env`
2. **ACME challenge fails**: Ensure port 80 is accessible and domain DNS is configured
3. **Permission errors**: Run `chmod 755 certbot/` and ensure proper ownership

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Telegram API  │◄──►│   Nginx      │◄──►│   Bot Service   │
│                 │    │ (SSL Proxy)  │    │   (Kotlin)      │
└─────────────────┘    └──────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────┐
                       │   Certbot    │
                       │ (SSL Certs)  │
                       └──────────────┘
```

## API Endpoints

- `GET /` - Basic service information
- `GET /health` - Health check with bot status
- `POST /webhook` - Telegram webhook endpoint (internal)

## Monitoring and Logs

### View Application Logs

```bash
# Follow real-time logs
docker compose logs -f bot

# View Nginx logs
docker compose logs -f nginx

# View all services
docker compose logs -f
```

### Health Check

Monitor your bot's health:

```bash
curl https://your-domain.com/health
```

Response example:

```json
{
  "status": "healthy",
  "bot": {
    "id": 123456789,
    "username": "your_bot",
    "firstName": "Moderation Bot"
  },
  "timestamp": 1699999999999
}
```

## Bot Usage

1. **Add to Group**: Add your bot to the Telegram group where you want moderation
2. **Admin Rights**: Ensure the bot has admin rights to delete messages
3. **Automatic Operation**: The bot will automatically detect and delete new member messages

## Troubleshooting

### Common Issues

#### GitHub Actions Deployment Problems

- **Build Failures**: Check workflow logs, verify Java version and dependencies
- **SSH Issues**: Validate VM access, check SSH key format in secrets
- **Artifact Download**: Ensure GitHub token has `read:packages` permission

**Detailed troubleshooting**: See [GITHUB_ACTIONS_SETUP.md](logs/GITHUB_ACTIONS_SETUP.md)

#### Bot Not Responding

```bash
# Check bot logs
docker compose logs bot

# Verify bot token
curl -s "https://api.telegram.org/botYOUR_TOKEN/getMe"
```

#### SSL Certificate Issues

```bash
# Check certificate status
docker compose run --rm certbot certificates

# Force renewal
docker compose run --rm certbot renew --force-renewal
```

#### Webhook Not Working

```bash
# Check webhook status
curl -s "https://api.telegram.org/botYOUR_TOKEN/getWebhookInfo"

# Manually set webhook
curl -X POST "https://api.telegram.org/botYOUR_TOKEN/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://your-domain.com/webhook"}'
```

**Comprehensive troubleshooting**: See [TROUBLESHOOTING.md](logs/TROUBLESHOOTING.md)

### Service Management

```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart bot

# Stop all services
docker compose down

# Update and redeploy
git pull
docker compose up -d --build
```

## Development

### Local Development

```bash
# Run locally (requires Java 21+)
./gradlew run

# Run tests
./gradlew test

# Build JAR
./gradlew build

# Build using Docker (no local Java required)
docker compose build bot
```

### Project Structure

```
src/main/kotlin/
├── Application.kt          # Main application entry point
├── Routing.kt              # HTTP routing configuration
├── TelegramBotService.kt   # Bot API integration
└── Configuration.kt        # Configuration management

src/main/resources/
├── application.yaml        # Application configuration
└── logback.xml            # Logging configuration

docker-compose.yml          # Service orchestration
Dockerfile                  # Container definition
nginx/                      # Nginx configuration
├── nginx.conf
└── conf.d/
    └── default.conf
```

## Security Considerations

- **Bot Token**: Keep your bot token secure and never commit it to version control
- **SSL**: All traffic is encrypted with Let's Encrypt certificates
- **Rate Limiting**: Built-in rate limiting to respect Telegram API limits
- **Minimal Permissions**: Bot only requires message deletion permissions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter issues:

1. **Check documentation**:
    - [GITHUB_ACTIONS_SETUP.md](logs/GITHUB_ACTIONS_SETUP.md) for CI/CD issues
    - [ENVIRONMENT_VARIABLES.md](logs/ENVIRONMENT_VARIABLES.md) for configuration
    - [TROUBLESHOOTING.md](logs/TROUBLESHOOTING.md) for comprehensive troubleshooting
    - [ACT_USAGE.md](logs/ACT_USAGE.md) for local pipeline testing

2. **Review the application logs**:
   ```bash
   docker compose logs bot
   ```

3. **Open an issue on GitHub** with:
    - Environment details
    - Error messages
    - Steps to reproduce
    - Diagnostic information

---

**Note**: This bot is designed for simple moderation tasks. For complex moderation needs, consider using more advanced
bot frameworks or custom solutions.
