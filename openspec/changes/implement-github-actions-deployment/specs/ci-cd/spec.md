## ADDED Requirements

### Requirement: Automated Jar Artifact Building
The system SHALL automatically build jar artifacts when code is pushed to the main branch using GitHub Actions.

#### Scenario: Main branch push triggers build
- **WHEN** code is pushed to the main branch
- **THEN** GitHub Actions workflow builds the jar artifact
- **AND** the artifact is published to GitHub Packages
- **AND** the build status is reported on the commit

#### Scenario: Build failure handling
- **WHEN** the jar build fails
- **THEN** GitHub Actions reports the failure
- **AND** no artifact is published
- **AND** notifications are sent to contributors

### Requirement: Artifact Storage and Versioning
The system SHALL store built jar artifacts in GitHub Packages with proper versioning.

#### Scenario: Artifact versioning
- **WHEN** a jar artifact is built
- **THEN** it is tagged with the Git commit SHA
- **AND** it is published to GitHub Packages with the project version
- **AND** the artifact is downloadable using standard Maven coordinates

#### Scenario: Artifact access control
- **WHEN** accessing private artifacts
- **THEN** GitHub token authentication is required
- **AND** only authorized users can download artifacts
- **AND** access is logged for security auditing

### Requirement: Docker-based Artifact Deployment
The system SHALL use Docker to deploy applications using pre-built jar artifacts from GitHub Packages.

#### Scenario: Docker image creation
- **WHEN** building a Docker image for deployment
- **THEN** the Dockerfile downloads the jar artifact from GitHub Packages
- **AND** the artifact is placed in the correct runtime location
- **AND** the image includes all necessary runtime dependencies

#### Scenario: Authentication for artifact download
- **WHEN** Docker build needs to access private artifacts
- **THEN** GitHub token is passed as build argument
- **AND** the token is used for Maven repository authentication
- **AND** the token is not stored in the final image

### Requirement: Manual Production Deployment
The system SHALL provide a manual GitHub Action for deploying new jar versions to production VM instances.

#### Scenario: Manual deployment trigger
- **WHEN** a maintainer triggers the deployment workflow
- **THEN** the workflow connects to the production VM
- **AND** it pulls the latest jar artifact
- **AND** it updates the running Docker container
- **AND** it verifies the deployment success

#### Scenario: Deployment validation
- **WHEN** deployment is completed
- **THEN** health checks are performed on the running application
- **AND** SSL certificate validity is verified
- **AND** bot connectivity is tested
- **AND** deployment status is reported

### Requirement: Environment Configuration Management
The system SHALL manage environment variables and secrets for GitHub Actions workflows.

#### Scenario: Required environment variables
- **WHEN** setting up GitHub Actions
- **THEN** all required environment variables are documented
- **AND** GitHub secrets are configured for sensitive values
- **AND** validation ensures all variables are present before deployment

#### Scenario: Configuration validation
- **WHEN** workflows are executed
- **THEN** environment variables are validated
- **AND** missing required variables cause workflow failure
- **AND** clear error messages guide configuration fixes