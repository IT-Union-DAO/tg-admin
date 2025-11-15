# GitHub Actions Local Testing with act

This guide explains how to test your GitHub workflows locally using [nektos/act](https://github.com/nektos/act).

## Prerequisites

### 1. Install Docker

Make sure Docker is installed and running on your system:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac)
- [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

### 2. Install act

```bash
# macOS (using Homebrew)
brew install act

# Linux (using curl)
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Windows (using Chocolatey)
choco install act

# Or download from GitHub releases
# https://github.com/nektos/act/releases
```

## Setup

### 1. Copy Environment File

```bash
cp .env.example .env
```

### 2. Edit .env File

Update the `.env` file with your actual values:

```bash
# Required for testing
TELEGRAM_BOT_TOKEN=your_actual_bot_token
GITHUB_TOKEN=your_github_personal_access_token

# Optional for deployment testing
DOMAIN_NAME=test.your-domain.com
CERTBOT_EMAIL=admin@your-domain.com
```

### 3. Create GitHub Personal Access Token

For GitHub Packages access, create a token with these scopes:

- `repo` (full control)
- `read:packages`
- `write:packages`

## Testing Workflows

### List Available Workflows

```bash
act -l
```

### Test Build and Publish Workflow

```bash
# Dry run to see what would happen
act --dryrun

# Run build workflow
act -W .github/workflows/build-and-publish.yml

# Run with specific event
act push -W .github/workflows/build-and-publish.yml
```

### Test Deploy Workflow

```bash
# Test deploy workflow (manual trigger)
act workflow_dispatch -W .github/workflows/deploy-to-vm.yml

# Test with specific inputs
act workflow_dispatch -W .github/workflows/deploy-to-vm.yml -e .github/workflows/deploy-inputs.json
```

### Test All Workflows

```bash
# Run all workflows that would trigger on push
act push

# Run all workflows that would trigger manually
act workflow_dispatch
```

## Common Commands

### Verbose Output

```bash
act -v
```

### Specific Runner Size

```bash
# Use larger runner for complex workflows
act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

### Clean Cache

```bash
# Clear act cache if experiencing issues
act -c
```

### Skip Specific Steps

```bash
# Skip steps that require external services
act --skip-checkout
```

## Workflow-Specific Testing

### Build and Publish Workflow

This workflow tests:

- ✅ Java/Kotlin compilation
- ✅ Gradle build process
- ✅ Unit tests
- ✅ JAR packaging
- ✅ GitHub Packages publishing

### Deploy to VM Workflow

This workflow tests:

- ✅ Environment validation
- ✅ SSH connection setup
- ✅ Deployment script execution
- ✅ Health checks

### Test Workflows

This workflow tests:

- ✅ Workflow syntax validation
- ✅ Gradle configuration
- ✅ Local build verification

## Troubleshooting

### Common Issues

**"Docker not running"**

- Start Docker Desktop
- Run `docker ps` to verify

**"Permission denied"**

- Ensure Docker daemon is running with proper permissions
- On Linux, add your user to docker group: `sudo usermod -aG docker $USER`

**"GitHub token not working"**

- Verify token has correct scopes
- Check token expiration
- Ensure `.env` file is properly formatted

**"Workflow not found"**

- Check workflow file paths
- Verify YAML syntax with `yamllint`

### Debug Mode

```bash
# Enable debug output
act -v --debug

# Check act version
act --version

# List available images
act -l
```

### Testing GitHub Actions Locally

Use [act](https://github.com/nektos/act) to test GitHub Actions workflows locally:

```bash
# Install act
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Test workflows with helper scripts
./scripts/validate-workflows.sh
./scripts/test-workflows.sh list
./scripts/test-workflows.sh build

# Important: Use --bind flag to avoid certbot permission issues
act --bind -W .github/workflows/build-and-publish.yml
```

**Note**: Always use the `--bind` flag with act to avoid permission issues with the certbot directory.

## Best Practices

1. **Test frequently** - Run act before pushing to catch issues early
2. **Use dry runs** - Use `--dryrun` to preview workflow execution
3. **Keep tokens secure** - Never commit `.env` file to version control
4. **Update regularly** - Keep act and Docker images updated
5. **Monitor resource usage** - Large workflows may require significant resources

## Resources

- [act GitHub Repository](https://github.com/nektos/act)
- [act Documentation](https://github.com/nektos/act#readme)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)