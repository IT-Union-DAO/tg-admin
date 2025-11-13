# Telegram Moderation Bot

A lightweight Telegram bot for simple moderation procedures. The bot automatically tracks new members joining groups and deletes the "new member joined" service messages to keep group chats clean.

Built with Kotlin and Ktor, deployed using Docker Compose with automated SSL certificates via Certbot.

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

### 1. Clone and Configure

```bash
git clone <repository-url>
cd tg-admin

# Copy environment template and configure
cp .env.example .env
nano .env  # Edit with your bot token and domain
```

### 2. Deploy

```bash
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
```

### Getting a Bot Token

1. Start a chat with [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` command
3. Follow the instructions to create your bot
4. Copy the bot token provided by BotFather
5. Add the token to your `.env` file

## Deployment Options

### Option 1: Automated Deployment (Recommended)

Use the provided deployment script:

```bash
./deploy.sh
```

This script will:
- Set up Docker containers
- Generate SSL certificates
- Configure Nginx reverse proxy
- Start the bot service
- Verify deployment

### Option 2: Manual Deployment

```bash
# 1. Create necessary directories
mkdir -p logs certbot/conf certbot/www

# 2. Start services
docker-compose up -d --build

# 3. Generate SSL certificate
docker-compose run --rm certbot certonly --webroot -w /var/www/certbot -d your-domain.com --email your-email@domain.com --agree-tos --no-eff-email

# 4. Restart Nginx to apply SSL
docker-compose restart nginx
```

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
docker-compose logs -f bot

# View Nginx logs
docker-compose logs -f nginx

# View all services
docker-compose logs -f
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

#### Bot Not Responding
```bash
# Check bot logs
docker-compose logs bot

# Verify bot token
curl -s "https://api.telegram.org/botYOUR_TOKEN/getMe"
```

#### SSL Certificate Issues
```bash
# Check certificate status
docker-compose run --rm certbot certificates

# Force renewal
docker-compose run --rm certbot renew --force-renewal
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

### Service Management

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart bot

# Stop all services
docker-compose down

# Update and redeploy
git pull
docker-compose up -d --build
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

1. Check the troubleshooting section above
2. Review the application logs
3. Open an issue on GitHub with details about your environment and the problem

---

**Note**: This bot is designed for simple moderation tasks. For complex moderation needs, consider using more advanced bot frameworks or custom solutions.
