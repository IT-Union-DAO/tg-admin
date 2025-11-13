# Troubleshooting Guide

This guide covers common issues and solutions for deploying and running the Telegram Moderation Bot.

## Table of Contents

- [Deployment Issues](#deployment-issues)
- [Bot Configuration Problems](#bot-configuration-problems)
- [SSL Certificate Issues](#ssl-certificate-issues)
- [Webhook Problems](#webhook-problems)
- [Performance Issues](#performance-issues)
- [Logging and Debugging](#logging-and-debugging)

## Deployment Issues

### Docker Compose Fails to Start

**Problem**: `docker-compose up` fails with various errors

**Solutions**:

1. **Check Docker installation**:
   ```bash
   docker --version
   docker compose --version
   ```

2. **Check port conflicts**:
   ```bash
   # Check if ports 80/443 are in use
   sudo netstat -tulpn | grep :80
   sudo netstat -tulpn | grep :443
   ```

3. **Check Docker daemon**:
   ```bash
   sudo systemctl status docker
   sudo systemctl restart docker
   ```

4. **Clean up Docker resources**:
   ```bash
   docker system prune -f
   docker compose down -v
   docker compose up -d --build
   ```

### Out of Memory Errors

**Problem**: Container crashes due to insufficient memory

**Solutions**:

1. **Check available memory**:
   ```bash
   free -h
   docker stats
   ```

2. **Adjust Java heap size** in `docker-compose.yml`:
   ```yaml
   environment:
     - JAVA_OPTS=-Xmx256m -Xms128m
   ```

3. **Add swap space** on the server if needed

## Bot Configuration Problems

### Invalid Bot Token

**Problem**: Bot fails to start with authentication errors

**Symptoms**:
- Health check shows "Bot API connection failed"
- Logs contain "401 Unauthorized" errors

**Solutions**:

1. **Verify bot token**:
   ```bash
   curl -s "https://api.telegram.org/botYOUR_TOKEN/getMe"
   ```

2. **Get new token** from @BotFather if needed:
   - Send `/token` command to @BotFather
   - Select your bot
   - Generate new token

3. **Check environment variable**:
   ```bash
   echo $TELEGRAM_BOT_TOKEN
   docker compose exec bot env | grep TELEGRAM_BOT_TOKEN
   ```

### Domain Name Issues

**Problem**: Domain not resolving or incorrect configuration

**Symptoms**:
- SSL certificate generation fails
- Webhook registration fails
- Nginx shows 502 Bad Gateway

**Solutions**:

1. **Check DNS resolution**:
   ```bash
   nslookup your-domain.com
   dig your-domain.com
   ```

2. **Verify domain points to server**:
   ```bash
   curl -I http://your-domain.com
   ```

3. **Check Nginx configuration**:
   ```bash
   docker compose exec nginx nginx -t
   ```

## SSL Certificate Issues

### Certificate Generation Fails

**Problem**: Let's Encrypt certificate cannot be obtained

**Symptoms**:
- Certbot shows "Challenge failed" errors
- Nginx shows SSL certificate errors

**Solutions**:

1. **Check domain DNS**:
   ```bash
   # Ensure A record points to your server IP
   dig your-domain.com A
   ```

2. **Check port 80 accessibility**:
   ```bash
   # From external machine
   curl -I http://your-domain.com
   ```

3. **Manual certificate generation**:
   ```bash
   docker compose run --rm certbot certonly \
     --webroot -w /var/www/certbot \
     -d your-domain.com \
     --email admin@your-domain.com \
     --agree-tos --no-eff-email
   ```

4. **Use staging environment for testing**:
   ```bash
   docker compose run --rm certbot certonly \
     --webroot -w /var/www/certbot \
     -d your-domain.com \
     --email admin@your-domain.com \
     --agree-tos --no-eff-email \
     --staging
   ```

### Certificate Renewal Fails

**Problem**: SSL certificates expire and don't auto-renew

**Solutions**:

1. **Check renewal process**:
   ```bash
   docker compose run --rm certbot renew --dry-run
   ```

2. **Force renewal**:
   ```bash
   docker compose run --rm certbot renew --force-renewal
   ```

3. **Check Certbot logs**:
   ```bash
   docker compose logs certbot
   ```

4. **Restart Nginx after renewal**:
   ```bash
   docker compose restart nginx
   ```

## Webhook Problems

### Webhook Not Receiving Updates

**Problem**: Bot doesn't receive Telegram updates

**Symptoms**:
- Bot is in groups but doesn't delete messages
- No webhook activity in logs

**Solutions**:

1. **Check webhook registration**:
   ```bash
   curl -s "https://api.telegram.org/botYOUR_TOKEN/getWebhookInfo"
   ```

2. **Manually set webhook**:
   ```bash
   curl -X POST "https://api.telegram.org/botYOUR_TOKEN/setWebhook" \
     -H "Content-Type: application/json" \
     -d '{"url": "https://your-domain.com/webhook"}'
   ```

3. **Test webhook endpoint**:
   ```bash
   curl -X POST https://your-domain.com/webhook \
     -H "Content-Type: application/json" \
     -d '{"update_id": 12345, "message": {"message_id": 1, "chat": {"id": 123}, "new_chat_members": [{"id": 456, "is_bot": false, "first_name": "Test"}]}}'
   ```

4. **Check Nginx proxy configuration**:
   ```bash
   docker compose exec nginx nginx -t
   docker compose logs nginx
   ```

### Bot Permissions Issues

**Problem**: Bot can't delete messages

**Symptoms**:
- Bot receives updates but doesn't delete messages
- API returns "forbidden" errors

**Solutions**:

1. **Check bot permissions in group**:
   - Bot must be admin in the group
   - Bot must have "Delete messages" permission

2. **Test API directly**:
   ```bash
   # Get chat info
   curl -s "https://api.telegram.org/botYOUR_TOKEN/getChat?chat_id=@your_group"
   
   # Try to delete a message (replace with actual message ID)
   curl -X POST "https://api.telegram.org/botYOUR_TOKEN/deleteMessage" \
     -H "Content-Type: application/json" \
     -d '{"chat_id": "@your_group", "message_id": 123}'
   ```

## Performance Issues

### High Memory Usage

**Problem**: Container uses excessive memory

**Solutions**:

1. **Monitor memory usage**:
   ```bash
   docker stats
   docker compose exec bot jstat -gc 1
   ```

2. **Adjust JVM settings**:
   ```yaml
   environment:
     - JAVA_OPTS=-Xmx256m -Xms128m -XX:+UseG1GC
   ```

3. **Enable JVM monitoring**:
   ```yaml
   environment:
     - JAVA_OPTS=-Xmx256m -Xms128m -XX:+PrintGCDetails -XX:+PrintGCTimeStamps
   ```

### Slow Response Times

**Problem**: Bot responds slowly to updates

**Solutions**:

1. **Check network latency**:
   ```bash
   ping api.telegram.org
   curl -w "@curl-format.txt" -o /dev/null -s "https://api.telegram.org/botYOUR_TOKEN/getMe"
   ```

2. **Monitor API rate limits**:
   ```bash
   # Check for rate limiting in logs
   docker compose logs bot | grep -i "rate\|limit\|429"
   ```

3. **Optimize Docker resources**:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '0.5'
         memory: 512M
   ```

## Logging and Debugging

### Enable Debug Logging

**Problem**: Need more detailed logs for troubleshooting

**Solution**:

1. **Update log level** in `application.yaml`:
   ```yaml
   logging:
     level:
       su.dunkan: DEBUG
       io.ktor: DEBUG
       org.slf4j: DEBUG
   ```

2. **Or set via environment variable**:
   ```yaml
   environment:
     - LOG_LEVEL=DEBUG
   ```

### View Specific Logs

**Bot application logs**:
```bash
docker compose logs -f bot
docker compose logs --tail=100 bot
```

**Nginx access logs**:
```bash
docker compose exec nginx tail -f /var/log/nginx/access.log
```

**Nginx error logs**:
```bash
docker compose exec nginx tail -f /var/log/nginx/error.log
```

**Certbot logs**:
```bash
docker compose logs certbot
```

### Health Check Debugging

**Test health endpoint**:
```bash
curl -v https://your-domain.com/health
curl -v http://localhost:8080/health  # Direct to container
```

**Check container health**:
```bash
docker compose ps
docker inspect telegram-moderation-bot
```

## Emergency Recovery

### Complete Reset

If everything fails, perform a complete reset:

```bash
# Stop all services
docker compose down -v

# Remove all containers and images
docker system prune -a

# Remove certificates (backup first if needed)
sudo rm -rf certbot/conf/live/your-domain.com

# Redeploy from scratch
./deploy.sh
```

### Backup Important Data

Before resetting, backup:

```bash
# Backup certificates
sudo cp -r certbot/conf certbot-conf-backup

# Backup logs
cp -r logs logs-backup

# Backup configuration
cp .env .env.backup
cp docker-compose.yml docker-compose.yml.backup
```

## Getting Help

If you're still having issues:

1. **Collect diagnostic information**:
   ```bash
   docker compose logs > docker-logs.txt
   docker compose ps > docker-status.txt
   docker version > docker-version.txt
   ```

2. **Check GitHub issues** for similar problems

3. **Create a new issue** with:
   - Your environment details
   - Error messages
   - Steps to reproduce
   - Diagnostic information

---

**Remember**: Most issues are related to configuration, DNS, or permissions. Double-check these first before diving into complex debugging.