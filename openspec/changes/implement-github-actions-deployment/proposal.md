## Why
The current deployment process relies on local Docker builds and manual execution of the deploy.sh script on VM instances. This creates inconsistencies between environments, makes deployments error-prone, and lacks automated artifact management. Implementing GitHub Actions will provide consistent builds, artifact storage, and automated deployment workflows.

## What Changes
- **BREAKING**: Replace local Docker builds with GitHub Actions-based jar artifact creation
- Add GitHub Actions workflow for building and publishing jar artifacts to GitHub Packages
- Modify Dockerfile to download jar artifacts from GitHub Packages instead of building from source
- Update deploy.sh script to use new Dockerfile approach
- Add separate GitHub Action for manual deployment to VM instances
- Create comprehensive README for GitHub Actions setup and environment variables

## Impact
- Affected specs: ci-cd (new capability)
- Affected code: Dockerfile, deploy.sh, .github/workflows/ (new)
- New dependencies: GitHub Packages, GitHub Actions deployment workflows
- Deployment process changes from local builds to artifact-based deployment