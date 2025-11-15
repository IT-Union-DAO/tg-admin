# Troubleshooting Guide

This guide helps diagnose and resolve common issues with the Telegram Admin Bot deployment system, including both traditional deployment and new GitHub Actions-based workflow.

## Table of Contents

- [GitHub Actions Issues](#github-actions-issues)
- [Docker and Container Issues](#docker-and-container-issues)
- [Application Issues](#application-issues)
- [Network and SSL Issues](#network-and-ssl-issues)
- [Performance Issues](#performance-issues)
- [Emergency Procedures](#emergency-procedures)
- [Debugging Tools](#debugging-tools)

## GitHub Actions Issues

### Build Failures

#### Issue: Gradle Build Fails in GitHub Actions
**Symptoms**:
- GitHub Actions workflow fails during `./gradlew build`
- Compilation errors or dependency resolution failures

**Solutions**:
1. **Check workflow logs** for specific error messages
2. **Verify Java version** compatibility (using Java 21)
3. **Update dependencies** in `build.gradle.kts`
4. **Clear Gradle cache**:
   ```yaml
   - name: Clear Gradle cache
     run: rm -rf ~/.gradle/caches
   ```

#### Issue: GitHub Packages Publishing Fails
**Symptoms**:
- Build succeeds but publishing fails
- `401 Unauthorized` or `403 Forbidden` errors

**Solutions**:
1. **Check GitHub token permissions**:
   - Must have `write:packages` scope
   - Repository access must be enabled
2. **Verify repository settings**:
   - Go to repository `Settings` → `Actions` → `General`
   - Ensure "Allow GitHub Actions to create and approve pull requests" is enabled
3. **Check package naming** in `build.gradle.kts`

### Deployment Failures

#### Issue: SSH Connection to VM Fails
**Symptoms**:
- Workflow fails at SSH connection step
- `Permission denied` or `Connection refused` errors

**Solutions**:
1. **Verify SSH key format** in GitHub secrets:
   ```yaml
   VM_SSH_KEY: |
     -----BEGIN RSA PRIVATE KEY-----
     MIIEpAIBAAKCAQEA...
     -----END RSA PRIVATE KEY-----
   ```
2. **Test SSH connection locally**:
   ```bash
   ssh -i ~/.ssh/id_rsa user@vm-host
   ```
3. **Check VM SSH configuration**:
   ```bash
   # Ensure public key is in authorized_keys
   cat ~/.ssh/authorized_keys
   # Check SSH daemon is running
   sudo systemctl status sshd
   ```

#### Issue: Artifact Download Fails
**Symptoms**:
- Docker build fails during jar download
- `404 Not Found` or `401 Unauthorized` from GitHub Packages

**Solutions**:
1. **Verify artifact exists** in repository `Packages` tab
2. **Check GitHub token** has `read:packages` permission
3. **Use local build fallback**:
   ```bash
   export JAR_VERSION=local
   ./deploy.sh
   ```

#### Issue: Local GitHub Actions Testing with act Fails
**Symptoms**:
- `act` command fails with permission errors
- Error messages about `certbot/conf/accounts` directory
- File copying fails during workflow execution

**Solutions**:
1. **Use --bind flag** to mount directories instead of copying:
   ```bash
   # Test individual workflows
   act --bind -W .github/workflows/build-and-publish.yml
   act --bind -W .github/workflows/deploy-to-vm.yml --dryrun
   act --bind -W .github/workflows/test-workflows.yml --dryrun
   
   # Test all workflows
   act --bind
   ```
2. **Root Cause**: The `certbot/conf/accounts` directory has restrictive permissions (`drwx------`) owned by root
3. **Alternative**: If you need to test without --bind, temporarily fix permissions:
   ```bash
   sudo chmod 755 certbot/conf/accounts
   ```
4. **Note**: The --bind flag is the recommended solution as it doesn't require permission changes

## Docker and Container Issues

### Container Startup Failures

#### Issue: Bot Container Fails to Start
**Symptoms**:
- Container exits immediately after starting
- `docker compose ps` shows restart count increasing

**Diagnosis**:
```bash
# Check container logs
docker compose logs bot

# Inspect container exit code
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.ExitCode}}"
```

**Solutions**:
1. **Check jar file exists** in container:
   ```bash
   docker compose exec bot ls -la /app/
   docker compose exec bot file /app/app.jar
   ```
2. **Validate environment variables**:
   ```bash
   docker compose exec bot env | grep -E "(TELEGRAM|DOMAIN)"
   ```
3. **Test Java application manually**:
   ```bash
   docker compose exec bot java -jar app.jar
   ```

#### Issue: Nginx Configuration Errors
**Symptoms**:
- Nginx container fails to start
- 502 Bad Gateway errors
- SSL certificate issues

**Solutions**:
1. **Test nginx configuration**:
   ```bash
   docker compose exec nginx nginx -t
   ```
2. **Regenerate SSL certificates**:
   ```bash
   docker compose run --rm certbot renew --force-renewal
   ```
3. **Check certificate paths**:
   ```bash
   docker compose exec nginx ls -la /etc/letsencrypt/live/
   ```

### Resource Issues

#### Issue: Out of Memory Errors
**Symptoms**:
- Container crashes with OOMKilled
- Java heap space errors

**Solutions**:
1. **Increase Java heap size**:
   ```yaml
   environment:
     - JAVA_OPTS=-Xmx512m -Xms256m
   ```
2. **Add system swap**:
   ```bash
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```
3. **Monitor resource usage**:
   ```bash
   docker stats
   ```

## Application Issues

### Telegram Bot Connectivity

#### Issue: Bot Not Responding
**Symptoms**:
- Health check passes but bot doesn't respond to messages
- Webhook registration fails

**Solutions**:
1. **Test bot token**:
   ```bash
   curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"
   ```
2. **Check webhook status**:
   ```bash
   curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getWebhookInfo"
   ```
3. **Manually set webhook**:
   ```bash
   curl -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/setWebhook" \
     -H "Content-Type: application/json" \
     -d "{\"url\": \"https://your-domain.com/webhook\"}"
   ```

#### Issue: Rate Limiting
**Symptoms**:
- Bot stops responding after high activity
- `429 Too Many Requests` errors

**Solutions**:
1. **Implement rate limiting** in application code
2. **Use message queues** for high-volume scenarios
3. **Monitor API usage** and implement backoff strategies

## Network and SSL Issues

### SSL Certificate Issues

#### Issue: Let's Encrypt Certificate Fails
**Symptoms**:
- Certificate generation fails
- `Connection timeout` or `DNS problem` errors

**Solutions**:
1. **Fix DNS configuration**:
   ```bash
   nslookup your-domain.com
   dig your-domain.com
   ```
2. **Configure firewall**:
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```
3. **Use staging environment** for testing:
   ```bash
   docker compose run --rm certbot certonly \
     --webroot -w /var/www/certbot \
     -d your-domain.com --email admin@your-domain.com \
     --agree-tos --non-interactive --staging
   ```

### Connectivity Problems

#### Issue: Cannot Access Application Externally
**Symptoms**:
- Application works locally but not externally
- Connection timeout errors

**Solutions**:
1. **Check port exposure** in `docker-compose.yml`:
   ```yaml
   ports:
     - "8080:8080"  # Correct format
   ```
2. **Configure firewall**:
   ```bash
   sudo ufw allow 8080/tcp
   sudo netstat -tlnp | grep 8080
   ```
3. **Verify nginx proxy**:
   ```bash
   docker compose exec nginx nginx -t
   docker compose exec nginx cat /etc/nginx/conf.d/default.conf
   ```

## Performance Issues

### Slow Response Times

#### Issue: High Latency
**Symptoms**:
- Bot responses are slow
- Health checks timeout

**Solutions**:
1. **Optimize Java application**:
   - Profile application performance
   - Implement caching
2. **Tune JVM settings**:
   ```yaml
   environment:
     - JAVA_OPTS=-Xmx512m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
   ```
3. **Scale resources**:
   - Increase VM CPU/memory
   - Use load balancing for high traffic

### Memory Leaks

#### Issue: Memory Usage Increases Over Time
**Symptoms**:
- Container memory usage grows continuously
- Eventually crashes with OOM error

**Solutions**:
1. **Analyze heap dumps**:
   ```bash
   docker compose exec bot jmap -dump:format=b,file=heap.hprof <pid>
   ```
2. **Fix memory leaks** in application code
3. **Implement memory monitoring** and alerts

## Emergency Procedures

### Complete System Recovery

#### When Everything Fails
1. **Stop all services**:
   ```bash
   docker compose down
   ```

2. **Backup current state**:
   ```bash
   docker compose config > emergency-backup.yml
   tar -czf certbot-emergency-backup.tar.gz certbot/
   docker compose logs > emergency-logs.txt
   ```

3. **Restore from backup**:
   ```bash
   tar -xzf certbot-emergency-backup.tar.gz
   docker compose -f emergency-backup.yml up -d
   ```

4. **Verify functionality**:
   ```bash
   curl http://localhost:8080/health
   curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"
   ```

### Rollback Procedures

#### Roll to Previous Version
```bash
# 1. Identify previous version
git log --oneline -10

# 2. Checkout previous version
git checkout <previous-commit-sha>

# 3. Deploy with specific version
export JAR_VERSION=<previous-commit-sha>
./deploy.sh

# 4. Verify rollback
curl https://your-domain.com/health
```

#### Emergency Local Deployment
```bash
# When GitHub Packages are unavailable
export JAR_VERSION=local
./deploy.sh
```

## Debugging Tools

### Enhanced Logging

#### Configure Debug Logging
```yaml
# docker-compose.yml
services:
  bot:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    environment:
      - LOG_LEVEL=DEBUG
```

#### Log Analysis Commands
```bash
# Real-time monitoring
docker compose logs -f bot

# Filter by time
docker compose logs --since="2023-01-01T00:00:00" bot

# Search for errors
docker compose logs bot | grep -i error

# Export logs
docker compose logs bot > bot-logs.txt
```

### Health Monitoring

#### Custom Health Checks
```yaml
services:
  bot:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

#### Monitoring Scripts
```bash
#!/bin/bash
# monitor.sh

while true; do
    echo "$(date): Checking application health..."
    
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Application is healthy"
    else
        echo "❌ Application is unhealthy"
        docker compose logs --tail=50 bot
    fi
    
    sleep 60
done
```

### Diagnostic Information Collection

When seeking help, collect this information:

```bash
#!/bin/bash
# diagnostics.sh

echo "=== System Information ==="
uname -a
docker --version
docker compose --version

echo "=== Application Status ==="
docker compose ps
docker compose logs --tail=50 bot

echo "=== Network Tests ==="
curl -I http://localhost:8080/health
curl -I https://your-domain.com/health

echo "=== Environment Variables ==="
env | grep -E "(TELEGRAM|DOMAIN|GITHUB|JAR)"

echo "=== Resource Usage ==="
docker stats --no-stream
free -h
df -h
```

## Getting Help

### Support Channels

1. **GitHub Issues**: Create issue with diagnostic information
2. **Documentation**: 
   - [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)
   - [ENVIRONMENT_VARIABLES.md](ENVIRONMENT_VARIABLES.md)
3. **Community**: Check Telegram community forums

### Preventive Measures

1. **Regular monitoring** of system health
2. **Automated alerts** for critical failures
3. **Backup procedures** for configuration and data
4. **Testing deployments** in staging environment
5. **Documentation updates** for custom configurations

---

**Remember**: Most issues are related to configuration, network connectivity, or authentication. Start with the basics and work systematically through diagnosis steps. For GitHub Actions-specific issues, check workflow logs first.