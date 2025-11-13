# Project Context

## Purpose
A Telegram bot for simple moderation procedures. The bot tracks new members joining Telegram groups and automatically deletes the "new member joined" messages to keep group chats clean. Built for deployment on virtual machines with domain names using Docker Compose.

## Tech Stack
- **Language**: Kotlin 2.2.20
- **Framework**: Ktor 3.3.2 (web framework)
- **Server**: Netty (embedded server)
- **Build Tool**: Gradle with Kotlin DSL
- **Logging**: Logback 1.4.14
- **Configuration**: YAML-based configuration
- **Deployment**: Docker Compose
- **Testing**: Kotlin Test with JUnit

## Project Conventions

### Code Style
- Package naming follows reverse domain convention: `su.dunkan`
- Kotlin idiomatic code style with proper null safety
- Function naming uses camelCase
- Configuration externalized in YAML files
- Gradle version catalog for dependency management

### Architecture Patterns
- **Modular Design**: Separation of concerns with dedicated files for routing (`Routing.kt`) and application setup (`Application.kt`)
- **Ktor Application Pattern**: Uses Ktor's plugin-based architecture with `Application.module()` as the entry point
- **Configuration-Driven**: External configuration via `application.yaml`
- **Netty Engine**: Uses Netty as the embedded web server

### Testing Strategy
- Unit testing with Kotlin Test framework
- JUnit integration for test execution
- Ktor test host for HTTP endpoint testing
- Test dependencies managed through Gradle

### Git Workflow
- Standard Git flow with main branch for production
- .gitignore excludes build artifacts, IDE files (.idea/, .vscode/), and temporary files
- Gradle wrapper included for consistent builds

## Domain Context
This is a Telegram moderation bot that integrates with the Telegram Bot API. The bot needs to:
- Monitor group member changes
- Identify and delete system messages about new members
- Maintain group chat cleanliness
- Operate within Telegram's API rate limits and permissions

## Important Constraints
- Must comply with Telegram Bot API terms of service
- Rate limiting considerations for API calls
- Permission-based access to group messages
- Deployment requires domain name and SSL for webhook configuration
- Resource-efficient for continuous operation

## External Dependencies
- **Telegram Bot API**: Core service for bot functionality
- **Docker**: Containerization for deployment
- **Docker Compose**: Multi-container orchestration
- **Virtual Machine**: Hosting environment with domain name requirement
- **Maven Central**: Primary dependency repository
