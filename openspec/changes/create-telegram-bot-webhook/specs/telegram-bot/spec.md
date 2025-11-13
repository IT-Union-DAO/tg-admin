## ADDED Requirements

### Requirement: Telegram Bot Webhook Integration
The system SHALL integrate with Telegram Bot API using webhook mode to receive real-time updates.

#### Scenario: Webhook registration
- **WHEN** the application starts with valid bot token and domain
- **THEN** the system SHALL register the webhook URL with Telegram Bot API
- **AND** receive confirmation of successful registration

#### Scenario: Incoming update processing
- **WHEN** Telegram sends a webhook update to the configured endpoint
- **THEN** the system SHALL process the update within 5 seconds
- **AND** respond with HTTP 200 to acknowledge receipt

### Requirement: New Member Message Moderation
The system SHALL automatically detect and delete "new member joined" service messages from Telegram groups.

#### Scenario: New member message detection
- **WHEN** a new member joins a monitored group
- **AND** Telegram generates a service message about the new member
- **THEN** the system SHALL identify the message as a new member notification

#### Scenario: Message deletion
- **WHEN** a new member service message is identified
- **THEN** the system SHALL delete the message using Telegram Bot API
- **AND** log the deletion action for audit purposes

### Requirement: Environment-based Configuration
The system SHALL be configurable via environment variables for deployment flexibility.

#### Scenario: Bot token configuration
- **WHEN** the TELEGRAM_BOT_TOKEN environment variable is provided
- **THEN** the system SHALL use the token for Telegram Bot API authentication
- **AND** fail to start if the token is invalid or missing

#### Scenario: Domain configuration
- **WHEN** the DOMAIN_NAME environment variable is provided
- **THEN** the system SHALL use the domain for webhook URL construction
- **AND** validate the domain format before webhook registration

### Requirement: Docker Compose Deployment
The system SHALL be deployable using Docker Compose with SSL certificate management.

#### Scenario: Container orchestration
- **WHEN** docker-compose up is executed
- **THEN** the system SHALL start the bot application, Nginx proxy, and Certbot service
- **AND** establish proper network communication between services

#### Scenario: SSL certificate management
- **WHEN** the application is deployed with a valid domain
- **THEN** Certbot SHALL automatically obtain and configure SSL certificates
- **AND** set up automatic renewal before expiration

### Requirement: Health Monitoring
The system SHALL provide health check endpoints for monitoring and alerting.

#### Scenario: Application health check
- **WHEN** HTTP GET /health is requested
- **THEN** the system SHALL return HTTP 200 with application status
- **AND** include bot connection status and last webhook timestamp

#### Scenario: Bot connectivity verification
- **WHEN** the health check endpoint is called
- **THEN** the system SHALL verify Telegram Bot API connectivity
- **AND** report connection status in the health response

### Requirement: Comprehensive Logging
The system SHALL maintain detailed logs of all bot activities and system events.

#### Scenario: Action logging
- **WHEN** the bot performs any action (message deletion, webhook processing)
- **THEN** the system SHALL log the action with timestamp and relevant details
- **AND** store logs in the configured log directory

#### Scenario: Error logging
- **WHEN** an error occurs during bot operation
- **THEN** the system SHALL log the error with stack trace
- **AND** include relevant context for troubleshooting