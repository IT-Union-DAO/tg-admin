## Context
The current deployment process uses local Docker builds which can lead to inconsistencies between development and production environments. The project needs a reliable, automated deployment pipeline that creates reproducible jar artifacts and enables seamless deployment to VM instances.

## Goals / Non-Goals
- Goals: 
  - Automated jar artifact creation via GitHub Actions
  - Centralized artifact storage in GitHub Packages
  - Simplified VM deployment using pre-built artifacts
  - Manual deployment trigger for production releases
- Non-Goals:
  - Complete CI/CD pipeline with automated testing (future scope)
  - Multi-environment deployment (dev/staging/prod)
  - Container registry migration (staying with Docker-based deployment)

## Decisions
- Decision: Use GitHub Packages for artifact storage
  - Rationale: Native integration with GitHub Actions, free for public repositories, simple authentication
  - Alternatives considered: Nexus, Artifactory, AWS S3 (more complex, additional costs)

- Decision: Modify Dockerfile to download artifacts instead of building
  - Rationale: Smaller final Docker images, faster builds on VM, consistent runtime environment
  - Alternatives considered: Multi-stage builds with artifact caching (more complex)

- Decision: Separate manual deployment workflow
  - Rationale: Production deployments should be intentional and manually triggered
  - Alternatives considered: Automatic deployment on merge (too risky for production)

## Risks / Trade-offs
- Risk: GitHub Packages downtime blocks deployments
  - Mitigation: Keep local build capability as fallback option
- Risk: Authentication complexity for private packages
  - Mitigation: Use GitHub token authentication with clear documentation
- Trade-off: Increased initial setup complexity for long-term deployment reliability
- Trade-off: Dependency on GitHub ecosystem vs self-hosted solutions

## Migration Plan
1. Setup GitHub Actions workflows while keeping current deployment functional
2. Test new deployment process in parallel with existing method
3. Update documentation and provide transition guide
4. Switch to new deployment method once validated
5. Remove old build logic from Dockerfile after successful migration

## Open Questions
- Should we implement versioned releases or use latest tag for artifacts?
- Do we need rollback capability to previous jar versions?
- Should we implement health checks in the deployment workflow?
- How to handle GitHub Packages rate limits for frequent deployments?