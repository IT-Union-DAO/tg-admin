# Environment Variables and Secrets Reference

This document provides a comprehensive reference for all environment variables and secrets used by the Telegram Admin Bot deployment system.

## Environment Variables Categories

### 1. Application Configuration
| Variable | Description | Required | Default | Example |
|----------|-------------|-----------|---------|---------|
| `TELEGRAM_BOT_TOKEN` | Telegram Bot API token for bot authentication | ✅ | - | `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz` |
| `DOMAIN_NAME` | Domain name for SSL certificates and webhook URL | ✅ | - | `bot.example.com` |
| `CERTBOT_EMAIL` | Email for Let's Encrypt certificate notifications | ❌ | `admin@$DOMAIN_NAME` | `admin@example.com` |

### 2. GitHub Packages Configuration
| Variable | Description | Required | Default | Example |
|----------|-------------|-----------|---------|---------|
| `GITHUB_TOKEN` | GitHub Personal Access Token for package access | ❌* | - | `ghp_1234567890abcdef...` |
| `GITHUB_REPOSITORY` | Repository name in format `owner/repo` | ❌ | `dunkan/tg-admin` | `myorg/tg-admin` |
| `JAR_VERSION` | Version of jar artifact to deploy | ❌ | `latest` | `abc123def456` (commit SHA) |
| `MAVEN_REPO_URL` | GitHub Packages Maven repository URL | ❌ | `https://maven.pkg.github.com` | `https://maven.pkg.github.com` |

*Required for private repositories or when downloading specific versions

### 3. VM Deployment Configuration
| Variable | Description | Required | Default | Example |
|----------|-------------|-----------|---------|---------|
| `VM_HOST` | VM hostname or IP address for SSH connection | ✅† | - | `192.168.1.100` or `vm.example.com` |
| `VM_USER` | SSH username for VM access | ✅† | - | `deploy` or `ubuntu` |
| `VM_SSH_KEY` | SSH private key content for VM authentication | ✅† | - | `-----BEGIN RSA PRIVATE KEY-----...` |

†Required for GitHub Actions deployment workflow only

### 4. Java Runtime Configuration
| Variable | Description | Required | Default | Example |
|----------|-------------|-----------|---------|---------|
| `JAVA_OPTS` | JVM options and memory settings | ❌ | `-Xmx256m -Xms128m` | `-Xmx512m -Xms256m -XX:+UseG1GC` |

## GitHub Secrets Configuration

### Required Secrets for GitHub Actions

#### 1. VM Access Secrets
```yaml
VM_HOST: "your-vm-ip-or-hostname"
VM_USER: "your-ssh-username"
VM_SSH_KEY: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA...
  -----END RSA PRIVATE KEY-----
```

#### 2. Application Secrets
```yaml
TELEGRAM_BOT_TOKEN: "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz"
DOMAIN_NAME: "your-domain.com"
```

#### 3. Optional Secrets
```yaml
CERTBOT_EMAIL: "admin@your-domain.com"
GITHUB_REPOSITORY: "your-username/tg-admin"
```

### GitHub Token (Auto-provided)
GitHub automatically provides `GITHUB_TOKEN` with:
- `read:packages` - Download from GitHub Packages
- `write:packages` - Publish to GitHub Packages
- `contents:read` - Read repository contents

## Environment Variable Validation

### Token Format Validation

#### GitHub Token Formats
```bash
# Classic Personal Access Token
ghp_1234567890abcdef1234567890abcdef12345678

# Fine-grained Personal Access Token
github_pat_1234567890abcdef_1234567890abcdef1234567890abcdef12345678
```

#### Telegram Bot Token Format
```bash
# Bot token from @BotFather
1234567890:ABCdefGHIjklMNOpqrsTUVwxyz-123456789
```

### Domain Name Validation
```bash
# Valid formats
bot.example.com
subdomain.domain.org
my-bot.domain.net

# Invalid formats
http://bot.example.com  # No protocol
https://bot.example.com # No protocol
bot.example.com/path    # No path
```

## Configuration Examples

### Development Environment (.env file)
```bash
# Application configuration
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
DOMAIN_NAME=dev-bot.example.com
CERTBOT_EMAIL=dev@example.com

# GitHub Packages (optional for local builds)
GITHUB_TOKEN=ghp_1234567890abcdef1234567890abcdef12345678
GITHUB_REPOSITORY=myorg/tg-admin
JAR_VERSION=latest

# Java options
JAVA_OPTS=-Xmx256m -Xms128m
```

### Production Environment (GitHub Secrets)
```yaml
# VM Access
VM_HOST: "prod-server.example.com"
VM_USER: "deploy"
VM_SSH_KEY: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA...
  -----END RSA PRIVATE KEY-----

# Application
TELEGRAM_BOT_TOKEN: "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz"
DOMAIN_NAME: "bot.example.com"
CERTBOT_EMAIL: "admin@example.com"

# GitHub Packages
GITHUB_REPOSITORY: "myorg/tg-admin"
```

### Staging Environment (GitHub Secrets)
```yaml
# VM Access
VM_HOST: "staging-server.example.com"
VM_USER: "staging"
VM_SSH_KEY: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA...
  -----END RSA PRIVATE KEY-----

# Application
TELEGRAM_BOT_TOKEN: "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz"
DOMAIN_NAME: "staging-bot.example.com"
CERTBOT_EMAIL: "staging@example.com"

# GitHub Packages
GITHUB_REPOSITORY: "myorg/tg-admin"
JAR_VERSION: "abc123def456"  # Specific version for staging
```

## Security Best Practices

### Token Management
1. **Use fine-grained tokens** when possible
2. **Limit token permissions** to minimum required
3. **Rotate tokens regularly** (every 90 days recommended)
4. **Never commit tokens** to version control
5. **Use different tokens** for different environments

### SSH Key Management
1. **Generate dedicated keys** for deployment
2. **Use strong key algorithms** (RSA 4096+ or Ed25519)
3. **Restrict key usage** to specific users/commands
4. **Monitor SSH access logs** regularly
5. **Disable password authentication** on VM

### Environment-Specific Security
```bash
# Development: Use test tokens and domains
TELEGRAM_BOT_TOKEN=test_bot_token
DOMAIN_NAME=dev-bot.localhost

# Staging: Use staging-specific resources
TELEGRAM_BOT_TOKEN=staging_bot_token
DOMAIN_NAME=staging-bot.example.com

# Production: Use production tokens and domains
TELEGRAM_BOT_TOKEN=production_bot_token
DOMAIN_NAME=bot.example.com
```

## Troubleshooting Environment Variables

### Common Issues and Solutions

#### 1. Invalid GitHub Token
**Error**: `401 Unauthorized` when accessing GitHub Packages

**Diagnosis**:
```bash
# Test token validity
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user

# Check token permissions
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user/repos
```

**Solution**: Generate new token with `read:packages` permission

#### 2. Invalid Telegram Bot Token
**Error**: `404 Not Found` or `401 Unauthorized` from Telegram API

**Diagnosis**:
```bash
# Test bot token
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"
```

**Solution**: Verify token with @BotFather, regenerate if necessary

#### 3. Domain Resolution Issues
**Error**: SSL certificate generation fails

**Diagnosis**:
```bash
# Check DNS resolution
nslookup $DOMAIN_NAME

# Test HTTP access
curl -I http://$DOMAIN_NAME
```

**Solution**: Configure DNS properly, ensure port 80/443 accessible

#### 4. SSH Connection Failures
**Error**: `Permission denied` or `Connection refused`

**Diagnosis**:
```bash
# Test SSH connection
ssh -v $VM_USER@$VM_HOST

# Check SSH key format
ssh-keygen -l -f ~/.ssh/id_rsa
```

**Solution**: Verify SSH key setup, check VM SSH configuration

## Environment Variable Precedence

Variables are loaded in this order (later overrides earlier):

1. **Default values** (hardcoded in scripts)
2. **.env file** (if exists)
3. **Shell environment** (exported variables)
4. **GitHub Secrets** (in GitHub Actions)
5. **Command line arguments** (script-specific)

## Migration Guide

### From Environment Files to GitHub Secrets

1. **Identify variables** in current `.env` file
2. **Create GitHub secrets** for each variable
3. **Update workflows** to use secrets
4. **Test deployment** with new configuration
5. **Remove sensitive data** from `.env` file

### Example Migration
```bash
# Before (.env file)
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
DOMAIN_NAME=bot.example.com

# After (GitHub Secrets)
# TELEGRAM_BOT_TOKEN -> GitHub Secret
# DOMAIN_NAME -> GitHub Secret
# .env file contains only non-sensitive defaults
```

## Validation Scripts

### Environment Variable Validator
```bash
#!/bin/bash
# validate-env.sh

validate_required() {
    local var_name=$1
    local var_value=${!var_name}
    
    if [ -z "$var_value" ]; then
        echo "❌ Required variable $var_name is not set"
        return 1
    else
        echo "✅ $var_name is set"
        return 0
    fi
}

validate_token_format() {
    local token=$1
    local token_name=$2
    
    if [[ "$token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] || \
       [[ "$token" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
        echo "✅ $token_name format is valid"
        return 0
    else
        echo "❌ $token_name format is invalid"
        return 1
    fi
}

# Validate required variables
validate_required "TELEGRAM_BOT_TOKEN"
validate_required "DOMAIN_NAME"

# Validate token formats if set
if [ -n "$GITHUB_TOKEN" ]; then
    validate_token_format "$GITHUB_TOKEN" "GITHUB_TOKEN"
fi
```

### GitHub Secrets Validator
```yaml
# .github/workflows/validate-secrets.yml
name: Validate Secrets

on:
  workflow_dispatch:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - name: Validate required secrets
      run: |
        if [ -z "${{ secrets.VM_HOST }}" ]; then
          echo "❌ VM_HOST secret is required"
          exit 1
        fi
        
        if [ -z "${{ secrets.TELEGRAM_BOT_TOKEN }}" ]; then
          echo "❌ TELEGRAM_BOT_TOKEN secret is required"
          exit 1
        fi
        
        echo "✅ All required secrets are configured"
```

## Additional Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Environment Variables Best Practices](https://12factor.net/config)
- [Telegram Bot API Authentication](https://core.telegram.org/bots/api#authorizing-your-bot)
- [SSH Key Management](https://www.ssh.com/ssh/key/)