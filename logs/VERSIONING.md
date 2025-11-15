# Build Versioning Strategy

This document describes the versioning strategy implemented for the Telegram Admin Bot project.

## Overview

The project uses a hybrid versioning approach that combines semantic versioning with Git-based versioning for different environments.

## Version Formats

### Local Development
- **Format**: `0.0.1-SNAPSHOT`
- **Example**: `0.0.1-SNAPSHOT`
- **Used when**: Building locally without CI environment

### CI Builds (Non-tagged)
- **Format**: `0.0.1-<commit-short-sha>`
- **Example**: `0.0.1-693223e`
- **Used when**: Building in CI environment without Git tags

### Tagged Releases
- **Format**: `<semantic-version>`
- **Example**: `0.0.1`, `1.0.0`, `1.2.3`
- **Used when**: Building from a Git tag matching semantic version pattern

## Semantic Versioning

The project follows [Semantic Versioning 2.0.0](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible functionality additions
- **PATCH**: Backward-compatible bug fixes

## Git Tagging Strategy

### Creating a Release
```bash
# Create and push a semantic version tag
git tag v0.0.1
git push origin v0.0.1

# Or create annotated tag
git tag -a v0.0.1 -m "Release version 0.0.1"
git push origin v0.0.1
```

### Tag Naming Convention
- Use `v` prefix: `v0.0.1`, `v1.0.0`
- The build system automatically removes the `v` prefix for Maven compatibility

## Version Information Available

### JAR Manifest
Each build includes detailed version information in the JAR manifest:
- `Implementation-Version`: The calculated version
- `Implementation-Title`: Application name
- `Implementation-Vendor`: Group ID
- `Build-Timestamp`: ISO timestamp of build
- `Git-Commit`: Full Git commit SHA
- `Git-Commit-Short`: Short Git commit SHA
- `Git-Branch`: Current Git branch
- `Git-Tag`: Git tag if available

### Version Properties File
Generated at build time in `src/main/resources/version.properties`:
```properties
app.name=Telegram Admin Bot
app.group=su.dunkan
app.version=0.0.1-SNAPSHOT
build.timestamp=2025-11-15T08:23:42.273289645Z
git.commit=693223e8e8b55f7bd79fb44d5e7c3e12977b4292
git.commit.short=693223e
git.branch=main
git.tag=none
build.environment=local
```

### API Endpoint
Access version information via HTTP endpoint:
```bash
curl https://your-domain.com/version
```

## GitHub Workflows Integration

### Build and Publish Workflow
- **Tagged commits**: Uses semantic version from Git tag
- **Non-tagged commits**: Uses commit SHA for versioning
- **Releases**: Automatically creates GitHub releases for tagged commits

### Deploy to VM Workflow
- **Latest**: Deploys the latest semantic version tag
- **Specific version**: Deploys specified version (tag or commit SHA)
- **Fallback**: Falls back to commit SHA if no tags available

## Deployment Version Selection

When deploying, you can specify versions in several ways:

```bash
# Deploy latest semantic version
JAR_VERSION=latest ./deploy.sh

# Deploy specific semantic version
JAR_VERSION=0.0.1 ./deploy.sh

# Deploy specific commit
JAR_VERSION=693223e8e8b55f7bd79fb44d5e7c3e12977b4292 ./deploy.sh

# Deploy local build
JAR_VERSION=local ./deploy.sh
```

## Best Practices

1. **Always use semantic version tags for releases**
2. **Test non-tagged builds in CI before creating releases**
3. **Use the version endpoint to verify deployments**
4. **Check the JAR manifest for detailed build information**
5. **Update the base version in build.gradle.kts for major releases**

## Troubleshooting

### Version Mismatches
If you encounter version mismatches:
1. Check the JAR manifest: `jar -xf app.jar META-INF/MANIFEST.MF && cat META-INF/MANIFEST.MF`
2. Verify Git tags: `git tag -l`
3. Check CI environment variables

### Git Command Failures
The build system gracefully handles Git command failures and falls back to "unknown" values to prevent build failures.