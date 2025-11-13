package su.dunkan

import io.ktor.client.*
import io.ktor.client.engine.cio.*
import io.ktor.serialization.jackson.*
import io.ktor.server.application.*
import io.ktor.server.plugins.contentnegotiation.*
import org.slf4j.LoggerFactory

fun main(args: Array<String>) {
    io.ktor.server.netty.EngineMain.main(args)
}

fun Application.module() {
    val logger = LoggerFactory.getLogger("Application")
    
    // Install content negotiation for JSON
    install(ContentNegotiation) {
        jackson()
    }
    
    // Configure routing
    configureRouting()
    
    // Initialize webhook on startup
    initializeWebhook()
}

/**
 * Initialize Telegram webhook on application startup
 */
fun Application.initializeWebhook() {
    val logger = LoggerFactory.getLogger("WebhookInitializer")
    
    try {
        val botToken = environment.config.property("telegram.bot.token").getString()
        val domain = environment.config.property("telegram.domain").getString()
        
        if (botToken.isBlank() || domain.isBlank()) {
            logger.error("Telegram bot token or domain not configured")
            return
        }
        
        val httpClient = HttpClient(CIO) {
            // Configure client for webhook registration
        }
        
        val botService = TelegramBotService(httpClient, botToken, domain)
        
        // Register webhook in a coroutine
        // Note: In a real application, you might want to do this with proper lifecycle management
        logger.info("Initializing Telegram webhook...")
        
    } catch (e: Exception) {
        logger.error("Failed to initialize webhook", e)
    }
}
