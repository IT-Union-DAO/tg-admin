package su.dunkan

import com.google.gson.Strictness
import io.ktor.serialization.gson.*
import io.ktor.server.application.*
import io.ktor.server.plugins.contentnegotiation.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory

fun main(args: Array<String>) {
    io.ktor.server.netty.EngineMain.main(args)
}

fun Application.module() {
    val logger = LoggerFactory.getLogger("Application")

    // Install content negotiation for JSON
    install(ContentNegotiation) {
        gson {
            setStrictness(Strictness.LENIENT)
            setPrettyPrinting()
        }
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

        val botService = TelegramBotService(botToken, domain)

        // Register webhook in a coroutine
        // Note: In a real application, you might want to do this with proper lifecycle management
        logger.info("Initializing Telegram webhook...")

        // Launch webhook registration in a coroutine
        CoroutineScope(Dispatchers.IO).launch {
            val success = botService.registerWebhook()
            if (success) {
                logger.info("Webhook registration completed successfully")
            } else {
                logger.error("Webhook registration failed")
            }
        }

    } catch (e: Exception) {
        logger.error("Failed to initialize webhook", e)
    }
}
