package su.dunkan

import com.github.kotlintelegrambot.entities.Update
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import org.slf4j.LoggerFactory

/**
 * Configure routing for the Telegram bot application
 * Includes webhook endpoint and health check endpoints
 */
fun Application.configureRouting() {
    val logger = LoggerFactory.getLogger("Routing")

    // Get configuration from environment
    val botToken = environment.config.property("telegram.bot.token").getString()
    val domain = environment.config.property("telegram.domain").getString()

    // Initialize bot service
    val botService = TelegramBotService(botToken, domain)

    routing {
        // Webhook endpoint for Telegram updates
        post("/webhook") {
            try {
                val update = call.receive<Update>()
                logger.info("Received update: ${update.updateId}")

                val success = botService.processUpdate(update)
                if (success) {
                    call.respond(HttpStatusCode.OK)
                } else {
                    call.respond(HttpStatusCode.InternalServerError)
                }
            } catch (e: Exception) {
                logger.error("Error processing webhook", e)
                call.respond(HttpStatusCode.BadRequest)
            }
        }

        // Health check endpoint
        get("/health") {
            try {
                val botInfo = botService.getBotInfo()
                if (botInfo != null) {
                    call.respond(
                        mapOf(
                            "status" to "healthy",
                            "bot" to mapOf(
                                "id" to botInfo.id,
                                "username" to botInfo.username,
                                "firstName" to botInfo.firstName
                            ),
                            "timestamp" to System.currentTimeMillis()
                        )
                    )
                } else {
                    call.respond(
                        HttpStatusCode.ServiceUnavailable,
                        mapOf(
                            "status" to "unhealthy",
                            "error" to "Bot API connection failed",
                            "timestamp" to System.currentTimeMillis()
                        )
                    )
                }
            } catch (e: Exception) {
                logger.error("Health check failed", e)
                call.respond(
                    HttpStatusCode.InternalServerError,
                    mapOf(
                        "status" to "error",
                        "error" to e.message,
                        "timestamp" to System.currentTimeMillis()
                    )
                )
            }
        }

        // Basic info endpoint
        get("/") {
            call.respond(
                mapOf(
                    "service" to "Telegram Moderation Bot",
                    "version" to "1.0.0",
                    "status" to "running"
                )
            )
        }
    }
}
