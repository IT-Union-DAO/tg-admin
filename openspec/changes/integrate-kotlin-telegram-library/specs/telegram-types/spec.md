# Telegram Types Integration Specification

## ADDED Requirements

### Requirement: Replace Custom Telegram API Types with Library Types
The system SHALL replace all custom Telegram Bot API data classes with official types from `kotlin-telegram-bot` library to ensure API compatibility and reduce maintenance overhead.

#### Scenario: Webhook Message Processing
When the bot receives a webhook update from Telegram, the system should deserialize the JSON payload using library types instead of custom data classes.

**Given:** A webhook POST request with Telegram update JSON
**When:** The system processes the webhook
**Then:** The JSON should be deserialized into `com.github.kotlintelegrambot.entities.Update`
**And:** All nested objects should use library types (Message, User, Chat, etc.)
**And:** Business logic should work unchanged with new types

#### Scenario: Bot Information Retrieval
When the system queries the Telegram Bot API for bot information, it should use library types for requests and responses.

**Given:** A valid bot token
**When:** The system calls `getMe` API endpoint
**Then:** The response should be parsed into `com.github.kotlintelegrambot.entities.User`
**And:** Bot-specific fields (isBot, username, etc.) should be accessible
**And:** Error handling should use library exception types

#### Scenario: Message Deletion API Call
When the system deletes a message from a chat, it should use library types for the request structure.

**Given:** A chat ID and message ID
**When:** The system calls `deleteMessage` API endpoint
**Then:** The request should use library's request structure
**And:** The response should be parsed into library response type
**And:** Success/failure should be determined from library response fields

### Requirement: Update Serialization Framework
The system SHALL migrate from kotlinx.serialization to library's preferred serialization approach (Gson-based) to ensure compatibility with library types.

#### Scenario: JSON Deserialization
When processing incoming webhook JSON, the system should use the library's serialization approach.

**Given:** JSON payload from Telegram webhook
**When:** The system deserializes the payload
**Then:** Gson should be used instead of kotlinx.serialization
**And:** Library types should be properly instantiated
**And:** Unknown fields should be handled gracefully

#### Scenario: JSON Serialization
When making API calls to Telegram, the system should serialize request objects using the library's approach.

**Given:** A request object (e.g., SetWebhookRequest)
**When:** The system serializes the object to JSON
**Then:** Gson should serialize the library type correctly
**And:** Field names should match Telegram API expectations
**And:** Optional fields should be handled properly

### Requirement: Maintain Business Logic Compatibility
The system SHALL ensure all existing business logic continues to work with new library types without functional changes.

#### Scenario: New Member Detection
When processing messages to detect new member joins, the logic should work with library Message types.

**Given:** A Message object from the library
**When:** The system checks for new members
**Then:** The `newChatMembers` field should be accessed correctly
**And:** Non-null checks should work as before
**And:** Member deletion logic should function unchanged

#### Scenario: Error Handling
When API calls fail, the system should handle library-specific exceptions appropriately.

**Given:** A failed API call (network error, invalid request, etc.)
**When:** The system catches the exception
**Then:** Library exception types should be caught and handled
**And:** Error logging should include relevant details
**And:** Fallback behavior should remain consistent

### Requirement: Update Build Configuration
The system SHALL modify Gradle build configuration to include kotlin-telegram-bot library and remove unnecessary serialization dependencies.

#### Scenario: Dependency Resolution
When building the project, Gradle should correctly resolve all dependencies including the new library.

**Given:** Updated build.gradle.kts with library dependency
**When:** Gradle resolves dependencies
**Then:** kotlin-telegram-bot should be included in the classpath
**And:** Version conflicts should be resolved
**And:** Build should complete successfully

#### Scenario: Test Execution
When running tests, the test classpath should include both the library and any required test dependencies.

**Given:** Updated test configuration
**When:** Tests are executed
**Then:** Library types should be available in test code
**And:** Mock objects should use library types
**And:** All tests should pass with new types

## MODIFIED Requirements

### Requirement: TelegramBotService Type Usage
The system SHALL update TelegramBotService to use library types instead of custom data classes for all internal operations.

**Previous Implementation:** Custom data classes in `su.dunkan` package
**New Implementation:** Library types from `com.github.kotlintelegrambot.entities`

#### Scenario: Service Method Signatures
All public methods in TelegramBotService should use library types for parameters and return values.

**Given:** TelegramBotService class
**When:** Examining method signatures
**Then:** Update, Message, Chat, User types should be from the library
**And:** Response types should be library response types
**And:** No custom data classes should be used in public APIs

#### Scenario: Internal Processing
Internal service methods should work with library types throughout the processing pipeline.

**Given:** Webhook update processing
**When:** The service processes an update
**Then:** All intermediate objects should be library types
**And:** Type conversions should be minimized
**And:** Business logic should access library type properties

### Requirement: Test Compatibility
The system SHALL update all test cases to use library types instead of custom data classes.

**Previous Implementation:** Tests using custom su.dunkan types
**New Implementation:** Tests using library types

#### Scenario: Unit Test Data
Test fixtures and mock objects should use library types.

**Given:** Test classes in src/test/kotlin
**When:** Creating test data
**Then:** Message, User, Chat objects should be library types
**And:** Test assertions should work with library type properties
**And:** Mock objects should implement library type interfaces

#### Scenario: Integration Testing
Integration tests should validate webhook processing with real JSON using library types.

**Given:** Integration test setup
**When:** Processing actual webhook JSON
**Then:** Deserialization should produce library types
**And:** End-to-end processing should work correctly
**And:** API responses should match library type expectations

## REMOVED Requirements

### Requirement: Custom Data Class Maintenance
Remove all custom Telegram API data classes and their maintenance overhead.

**Removed Classes:**
- `su.dunkan.Update`
- `su.dunkan.Message`
- `su.dunkan.Chat`
- `su.dunkan.User`
- `su.dunkan.BotInfo`
- `su.dunkan.ApiResponse`
- `su.dunkan.SetWebhookRequest`
- `su.dunkan.SetWebhookResponse`
- `su.dunkan.DeleteMessageRequest`
- `su.dunkan.GetMeResponse`

#### Scenario: Code Cleanup
After migration, custom data classes should be completely removed from the codebase.

**Given:** Completed migration to library types
**When:** Searching the codebase
**Then:** No custom Telegram data classes should exist
**And:** No imports of custom types should remain
**And:** Build should succeed without custom classes

### Requirement: Custom Serialization Configuration
Remove kotlinx.serialization configuration specific to custom Telegram types.

**Removed Configuration:**
- Custom JsonSerializers for Telegram types
- Serialization modules for custom types
- Type adapters for API compatibility

#### Scenario: Build Simplification
The build configuration should be simplified after removing custom serialization.

**Given:** Updated build.gradle.kts
**When:** Examining serialization setup
**Then:** No custom serializers should be configured
**And:** kotlinx.serialization usage should be minimized
**And:** Library's serialization should be used instead