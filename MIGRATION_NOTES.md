# Migration Notes: kotlin-telegram-bot Integration

## Task 1: Setup and Dependency Integration

### Changes Made

1. **Added kotlin-telegram-bot library dependency**
   - Version: 6.3.0 (latest stable)
   - Maven coordinates: `io.github.kotlin-telegram-bot.kotlin-telegram-bot:telegram:6.3.0`
   - Added JitPack repository to build.gradle.kts

2. **Serialization Format Analysis**
   - Current implementation uses kotlinx.serialization
   - kotlin-telegram-bot library uses Gson (via Retrofit converter)
   - Migration from kotlinx.serialization to Gson will be required in Task 3

### Breaking Changes (Upcoming)

1. **Data Class Replacement**
   - Custom Telegram data classes will be replaced with library types
   - Current classes: `Update`, `Message`, `Chat`, `User`, etc.
   - Will be replaced with library equivalents from `com.github.kotlintelegrambot.types`

2. **Serialization Migration**
   - Remove kotlinx.serialization annotations and imports
   - Add Gson dependency if needed
   - Update JSON parsing logic

3. **HTTP Client Changes**
   - Current: Custom Ktor HTTP client implementation
   - Future: Library's built-in HTTP client (Retrofit + OkHttp)

### Dependencies Added

```kotlin
// gradle/libs.versions.toml
kotlin-telegram-bot = "6.3.0"
kotlin-telegram-bot = { module = "io.github.kotlin-telegram-bot.kotlin-telegram-bot:telegram", version.ref = "kotlin-telegram-bot" }

// build.gradle.kts
implementation(libs.kotlin.telegram.bot)
```

### Repository Configuration

```kotlin
repositories {
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}
```

### Next Steps

1. **Task 2**: Replace custom data classes with library types
2. **Task 3**: Migrate from kotlinx.serialization to Gson
3. **Task 4**: Update HTTP client implementation
4. **Task 5**: Update webhook handling
5. **Task 6**: Update message deletion logic

### Compatibility Notes

- The library uses Retrofit 2.9.0 with OkHttp 4.12.0
- Gson 2.8.5 for JSON serialization
- Compatible with Kotlin coroutines
- No conflicts with existing Ktor dependencies

### Testing

- Build verification: ✅ PASSED
- Dependency resolution: ✅ PASSED
- No runtime conflicts detected