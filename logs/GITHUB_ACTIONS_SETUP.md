# GitHub Actions Deployment Setup Guide

This guide explains how to set up and use the GitHub Actions workflows for automated jar artifact building and deployment to production VM instances.

## Overview

The Telegram Admin Bot now uses GitHub Actions for:
- **Automated jar building** on main branch pushes
- **Artifact publishing** to GitHub Packages
- **Manual deployment** to production VM instances
- **Versioned releases** with proper artifact management

## Prerequisites

1. **GitHub Repository**: The bot must be in a GitHub repository
2. **VM Access**: SSH access to production VM instance
3. **Domain Name**: Configured domain pointing to the VM
4. **Docker & Docker Compose**: Installed on the VM
5. **GitHub Token**: Personal Access Token with appropriate permissions

## Required GitHub Secrets

Configure these secrets in your GitHub repository (`Settings` → `Secrets and variables` → `Actions`):

### Core Secrets
| Secret | Description | Required |
|--------|-------------|----------|
| `VM_SSH_KEY` | SSH private key for VM access | ✅ |
| `VM_HOST` | VM hostname or IP address | ✅ |
| `VM_USER` | SSH username for VM access | ✅ |
| `TELEGRAM_BOT_TOKEN` | Telegram Bot API token | ✅ |
| `DOMAIN_NAME` | Domain name for SSL certificates | ✅ |
| `GITHUB_TOKEN` | GitHub token for package access | ✅ (auto-provided) |

### Optional Secrets
| Secret | Description | Default |
|--------|-------------|---------|
| `CERTBOT_EMAIL` | Email for Let's Encrypt certificates | `admin@$DOMAIN_NAME` |
| `GITHUB_REPOSITORY` | Repository name (owner/repo) | `dunkan/tg-admin` |
| `MAVEN_REPO_URL` | GitHub Packages URL | `https://maven.pkg.github.com` |

## Setting Up GitHub Secrets

### 1. VM SSH Key
```bash
# Generate SSH key pair (if you don't have one)
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy"

# Add public key to VM
ssh-copy-id -i ~/.ssh/id_rsa.pub user@your-vm-host

# Copy private key content
cat ~/.ssh/id_rsa
```

Add the private key content as `VM_SSH_KEY` secret in GitHub.

### 2. Telegram Bot Token
1. Create a bot via [@BotFather](https://t.me/BotFather)
2. Copy the bot token
3. Add as `TELEGRAM_BOT_TOKEN` secret

### 3. Domain Configuration
Ensure your domain points to the VM:
```bash
# Test DNS resolution
nslookup your-domain.com
```

Add the domain as `DOMAIN_NAME` secret.

## Workflow Usage

### Automated Build & Publish

The `build-and-publish.yml` workflow runs automatically:
- **Trigger**: Push to `main` branch
- **Action**: Builds jar and publishes to GitHub Packages
- **Output**: Versioned artifact with Git commit SHA

### Manual Deployment

The `deploy-to-vm.yml` workflow allows manual deployment:
- **Trigger**: Manual dispatch from GitHub Actions tab
- **Options**: 
  - `version`: Specific commit SHA or `latest`
  - `environment`: `production` or `staging`

#### Running Manual Deployment

1. Go to `Actions` tab in GitHub repository
2. Select `Deploy to Production VM` workflow
3. Click `Run workflow`
4. Choose deployment options:
   - **Version**: Use commit SHA for specific version, or `latest`
   - **Environment**: Choose target environment
5. Click `Run workflow`

## Local Development

### Using GitHub Packages Artifacts

```bash
# Set environment variables
export GITHUB_TOKEN=your_github_token
export JAR_VERSION=commit_sha_or_latest
export GITHUB_REPOSITORY=owner/repo

# Deploy using GitHub Packages artifact
./deploy.sh
```

### Local Build Fallback

```bash
# Use local build instead of downloading artifacts
export JAR_VERSION=local
./deploy.sh
```

### Environment Variables File

Create `.env` file for local development:
```bash
# Required
TELEGRAM_BOT_TOKEN=your_bot_token
DOMAIN_NAME=your-domain.com

# Optional (for GitHub Packages)
GITHUB_TOKEN=your_github_token
GITHUB_REPOSITORY=owner/repo
JAR_VERSION=latest

# Optional (SSL)
CERTBOT_EMAIL=admin@your-domain.com
```

## Artifact Management

### Finding Artifact Versions

1. Go to repository `Packages` tab
2. Click on `su.dunkan/tg-admin` package
3. View available versions (Git commit SHAs)

### Downloading Artifacts Manually

```bash
# Using Maven coordinates
mvn dependency:get \
  -DremoteRepositories=https://maven.pkg.github.com/owner/repo \
  -Dartifact=su.dunkan:tg-admin:version

# Using curl (with authentication)
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://maven.pkg.github.com/owner/repo/su/dunkan/tg-admin/version/tg-admin-version.jar
```

## Troubleshooting

### Common Issues

#### 1. GitHub Token Permissions
**Error**: `401 Unauthorized` when downloading artifacts

**Solution**: Ensure GitHub token has `read:packages` permission:
```bash
# Check token permissions
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user
```

#### 2. SSH Connection Issues
**Error**: `Permission denied` during VM deployment

**Solution**: Verify SSH key setup:
```bash
# Test SSH connection
ssh -i ~/.ssh/id_rsa user@vm-host

# Check authorized_keys on VM
cat ~/.ssh/authorized_keys
```

#### 3. Docker Build Failures
**Error**: `Failed to download jar artifact`

**Solution**: Use local build fallback:
```bash
export JAR_VERSION=local
./deploy.sh
```

#### 4. SSL Certificate Issues
**Error**: Let's Encrypt certificate generation fails

**Solution**: Ensure domain is properly configured:
```bash
# Check domain resolution
nslookup your-domain.com

# Test HTTP access
curl -I http://your-domain.com
```

### Debug Mode

Enable debug logging in workflows:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

### Logs and Monitoring

#### GitHub Actions Logs
- View in `Actions` tab → workflow run → job logs
- Check for build failures, authentication issues, or deployment errors

#### VM Deployment Logs
```bash
# View application logs
docker compose logs -f bot

# View nginx logs
docker compose logs -f nginx

# Check container status
docker compose ps
```

#### Health Checks
```bash
# Application health
curl https://your-domain.com/health

# SSL certificate status
curl -I https://your-domain.com
```

## Security Considerations

### GitHub Secrets Management
- Use fine-grained personal access tokens when possible
- Rotate tokens regularly
- Limit token permissions to minimum required
- Never commit secrets to repository

### VM Security
- Use SSH key-based authentication only
- Disable password authentication
- Keep system packages updated
- Use firewall rules to restrict access

### Network Security
- Use HTTPS for all communications
- Validate SSL certificates
- Monitor access logs
- Implement rate limiting where possible

## Advanced Configuration

### Custom Maven Repository
To use a different Maven repository:

1. Update `MAVEN_REPO_URL` secret
2. Modify `build.gradle.kts` publishing configuration
3. Update Dockerfile download URLs

### Multi-Environment Deployment
For staging/production separation:

1. Create separate VM secrets (`STAGING_VM_HOST`, `PRODUCTION_VM_HOST`)
2. Duplicate deployment workflow with environment-specific configurations
3. Use environment-specific domain names

### Automated Testing
Add testing to the build workflow:

```yaml
- name: Run tests
  run: ./gradlew test

- name: Integration tests
  run: docker compose -f docker-compose.test.yml up --abort-on-container-exit
```

## Migration from Old Deployment

### Backup Current Setup
```bash
# Export current configuration
docker compose config > current-compose.yml

# Backup SSL certificates
tar -czf certbot-backup.tar.gz certbot/

# Save environment variables
env > current-env.txt
```

### Migration Steps
1. Set up GitHub secrets
2. Test new deployment with `JAR_VERSION=local`
3. Switch to GitHub Packages: `JAR_VERSION=latest`
4. Verify application functionality
5. Remove old build artifacts

### Rollback Plan
If new deployment fails:

```bash
# Stop new deployment
docker compose down

# Restore previous configuration
docker compose -f docker-compose.old.yml up -d

# Verify functionality
curl https://your-domain.com/health
```

## Support and Maintenance

### Regular Tasks
- **Monthly**: Rotate GitHub tokens
- **Quarterly**: Update dependencies
- **As needed**: Renew SSL certificates (automated)

### Monitoring
- Set up alerts for deployment failures
- Monitor GitHub Actions workflow runs
- Track application health metrics
- Review VM resource usage

### Documentation Updates
- Keep this guide updated with workflow changes
- Document any custom configurations
- Maintain troubleshooting steps
- Record successful deployment patterns

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Packages Documentation](https://docs.github.com/en/packages)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Telegram Bot API Documentation](https://core.telegram.org/bots/api)