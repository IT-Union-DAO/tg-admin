# Design: Kotlin Telegram Library Integration

## Architecture Overview

This change focuses on replacing custom Telegram API types with the official `kotlin-telegram-bot` library types while maintaining the existing service architecture.

## Current Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Ktor Web     │◄──►│ TelegramBotService│◄──►│ Custom Types    │
│   Server       │    │                  │    │ (Message, User, │
│                │    │                  │    │ Chat, etc.)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Target Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Ktor Web     │◄──►│ TelegramBotService│◄──►│ Library Types   │
│   Server       │    │                  │    │ (kotlin-telegram│
│                │    │                  │    │ -bot)          │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Type Mapping Strategy

### Custom → Library Type Mapping

| Custom Type | Library Type | Notes |
|-------------|--------------|-------|
| `Update` | `com.github.kotlintelegrambot.entities.Update` | Direct replacement |
| `Message` | `com.github.kotlintelegrambot.entities.Message` | Enhanced with more fields |
| `Chat` | `com.github.kotlintelegrambot.entities.Chat` | Direct replacement |
| `User` | `com.github.kotlintelegrambot.entities.User` | Direct replacement |
| `BotInfo` | `com.github.kotlintelegrambot.entities.User` | Use User type with bot fields |
| `ApiResponse` | Library response types | Replace with specific response types |

### Serialization Strategy

**Current**: Custom kotlinx.serialization
**Target**: Library's built-in serialization (Gson-based)

#### Options Considered:

1. **Full Library Migration** (Recommended)
   - Use library's serialization completely
   - Replace kotlinx.serialization with Gson
   - Benefits: Consistency, library support
   - Drawbacks: Major serialization change

2. **Hybrid Approach**
   - Keep kotlinx.serialization for webhook
   - Use library types only for data structures
   - Benefits: Gradual migration
   - Drawbacks: Complexity, potential conflicts

3. **Adapter Pattern**
   - Create adapters between library types and current serialization
   - Benefits: Isolation of changes
   - Drawbacks: Overhead, maintenance burden

**Decision**: Option 1 (Full Library Migration) for long-term maintainability

## Integration Points

### 1. Dependency Management

```kotlin
// gradle/libs.versions.toml
[versions]
kotlin-telegram-bot = "latest" // Check latest version

[libraries]
kotlin-telegram-bot = { module = "com.github.kotlintelegrambot:kotlin-telegram-bot", version.ref = "kotlin-telegram-bot" }
```

### 2. Service Layer Changes

**TelegramBotService.kt modifications:**

```kotlin
// Before
import kotlinx.serialization.Serializable
import su.dunkan.*

// After  
import com.github.kotlintelegrambot.entities.*
import com.google.gson.Gson
```

### 3. Webhook Processing

**Key Changes:**
- Replace JSON deserialization with library's parsing
- Update type checks for new member detection
- Maintain existing business logic flow

### 4. Configuration Updates

- Remove custom serialization configuration
- Add library-specific configuration if needed
- Update test configurations

## Migration Strategy

### Phase 1: Foundation
1. Add library dependency
2. Update imports in TelegramBotService
3. Replace data class definitions
4. Update build configuration

### Phase 2: Service Integration
1. Modify webhook processing logic
2. Update API call methods
3. Replace serialization/deserialization
4. Update error handling

### Phase 3: Testing & Validation
1. Update unit tests
2. Integration testing with real Telegram API
3. Performance validation
4. Documentation updates

## Backward Compatibility

### External Interfaces
- **Webhook endpoint**: No changes (still receives JSON)
- **Health check**: No changes (same response format)
- **Configuration**: No changes (same environment variables)

### Internal Interfaces
- **Method signatures**: Minimal changes (type replacements)
- **Business logic**: No changes (same algorithms)
- **Error handling**: Enhanced with library-specific exceptions

## Error Handling Strategy

### Current Approach
```kotlin
catch (e: Exception) {
    logger.error("Error processing update", e)
    false
}
```

### Enhanced Approach
```kotlin
catch (e: TelegramApiException) {
    logger.error("Telegram API error: ${e.errorCode}", e)
    false
} catch (e: JsonSyntaxException) {
    logger.error("JSON parsing error", e)
    false
} catch (e: Exception) {
    logger.error("Unexpected error", e)
    false
}
```

## Performance Considerations

### Serialization Performance
- **Library**: Gson (generally faster for simple objects)
- **Current**: kotlinx.serialization (optimized for Kotlin)
- **Impact**: Minimal for webhook processing scale

### Memory Usage
- Library types may have more fields
- Slight increase in memory footprint
- Acceptable trade-off for functionality

## Testing Strategy

### Unit Tests
- Mock library types
- Test type conversion logic
- Validate error handling

### Integration Tests
- Real Telegram Bot API calls
- Webhook processing with actual updates
- End-to-end workflow validation

### Regression Tests
- Ensure existing functionality preserved
- Performance benchmarks
- Memory usage validation

## Rollback Plan

### If Issues Arise
1. Revert to custom types (git checkout)
2. Remove library dependency
3. Restore original serialization
4. Redeploy previous version

### Rollback Triggers
- Breaking changes in production
- Performance degradation > 20%
- Critical bugs in core functionality
- Library compatibility issues

## Documentation Updates

### Code Documentation
- Update class-level documentation
- Add library-specific usage examples
- Document migration decisions

### README Updates
- Update dependency information
- Add library version requirements
- Update development setup instructions

## Future Considerations

### Extended Library Usage
After initial integration, consider:
- Using library's bot abstraction layer
- Implementing additional Telegram features
- Leveraging library's utilities and helpers

### Monitoring Enhancements
- Library-specific metrics
- Enhanced error reporting
- Performance monitoring with library types