package su.dunkan

import io.ktor.server.config.*

/**
 * Configuration data classes for the Telegram bot application
 * Provides type-safe access to configuration values
 */

/**
 * Telegram bot configuration
 */
data class TelegramConfig(
    val botToken: String,
    val domain: String
) {
    companion object {
        fun fromApplicationConfig(config: ApplicationConfig): TelegramConfig {
            val botToken = config.property("telegram.bot.token").getString()
            val domain = config.property("telegram.domain").getString()
            
            if (botToken.isBlank()) {
                throw IllegalArgumentException("TELEGRAM_BOT_TOKEN environment variable is required")
            }
            
            if (domain.isBlank()) {
                throw IllegalArgumentException("DOMAIN_NAME environment variable is required")
            }
            
            return TelegramConfig(botToken, domain)
        }
    }
    
    /**
     * Validate configuration values
     */
    fun validate(): Boolean {
        return botToken.isNotBlank() && 
               domain.isNotBlank() && 
               domain.matches(Regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"))
    }
}

/**
 * Application configuration
 */
data class AppConfig(
    val telegram: TelegramConfig,
    val port: Int = 8080
) {
    companion object {
        fun fromApplicationConfig(config: ApplicationConfig): AppConfig {
            val telegramConfig = TelegramConfig.fromApplicationConfig(config)
            val port = config.propertyOrNull("ktor.deployment.port")?.getString()?.toIntOrNull() ?: 8080
            
            return AppConfig(telegramConfig, port)
        }
    }
    
    /**
     * Validate all configuration
     */
    fun validate(): Boolean {
        return telegram.validate() && port in (1..65535)
    }
}