package su.dunkan

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
// kotlinx.serialization removed - using Gson via telegram library
import org.slf4j.LoggerFactory
import com.github.kotlintelegrambot.entities.Update
import com.github.kotlintelegrambot.entities.Message
import com.github.kotlintelegrambot.entities.Chat
import com.github.kotlintelegrambot.entities.User

/**
 * Service class for interacting with Telegram Bot API
 * Handles webhook registration, message processing, and deletion
 */
class TelegramBotService(
    private val httpClient: HttpClient,
    private val botToken: String,
    private val domain: String
) {
    private val logger = LoggerFactory.getLogger(TelegramBotService::class.java)
    // Json configuration removed - using Gson via telegram library
    
    /**
     * Register webhook with Telegram Bot API
     */
    suspend fun registerWebhook(): Boolean {
        return try {
            val webhookUrl = "https://$domain/webhook"
            logger.info("Registering webhook: $webhookUrl")
            
            val response: SetWebhookResponse = httpClient.post("https://api.telegram.org/bot$botToken/setWebhook") {
                contentType(ContentType.Application.Json)
                setBody(SetWebhookRequest(webhookUrl))
            }.body()
            
            if (response.ok) {
                logger.info("Webhook registered successfully")
                true
            } else {
                logger.error("Failed to register webhook: ${response.description}")
                false
            }
        } catch (e: Exception) {
            logger.error("Error registering webhook", e)
            false
        }
    }
    
    /**
     * Process incoming webhook update
     */
    suspend fun processUpdate(update: Update): Boolean {
        return try {
            when {
                update.message?.newChatMembers?.isNotEmpty() == true -> {
                    val message = update.message!!
                    logger.info("New member message detected in chat ${message.chat.id}")
                    deleteMessage(message.chat.id, message.messageId)
                }
                update.channelPost?.newChatMembers?.isNotEmpty() == true -> {
                    val channelPost = update.channelPost!!
                    logger.info("New member message detected in channel ${channelPost.chat.id}")
                    deleteMessage(channelPost.chat.id, channelPost.messageId)
                }
                else -> {
                    logger.debug("Ignoring update type: ${update.updateId}")
                    true
                }
            }
        } catch (e: Exception) {
            logger.error("Error processing update ${update.updateId}", e)
            false
        }
    }
    
    /**
     * Delete a message from chat
     */
    private suspend fun deleteMessage(chatId: Long, messageId: Long): Boolean {
        return try {
            val response: ApiResponse = httpClient.post("https://api.telegram.org/bot$botToken/deleteMessage") {
                contentType(ContentType.Application.Json)
                setBody(DeleteMessageRequest(chatId, messageId.toInt()))
            }.body()
            
            if (response.ok) {
                logger.info("Successfully deleted message $messageId from chat $chatId")
                true
            } else {
                logger.error("Failed to delete message: ${response.description}")
                false
            }
        } catch (e: Exception) {
            logger.error("Error deleting message $messageId from chat $chatId", e)
            false
        }
    }
    
    /**
     * Get bot information to verify connectivity
     */
    suspend fun getBotInfo(): BotInfo? {
        return try {
            val response: GetMeResponse = httpClient.get("https://api.telegram.org/bot$botToken/getMe").body()
            if (response.ok) {
                response.result
            } else {
                logger.error("Failed to get bot info: ${response.description}")
                null
            }
        } catch (e: Exception) {
            logger.error("Error getting bot info", e)
            null
        }
    }
}

// Custom data classes removed - now using library types from com.github.kotlintelegrambot.entities
// Temporary request/response classes for HTTP client compatibility (no @Serializable annotations)

data class SetWebhookRequest(
    val url: String,
    val allowedUpdates: List<String> = listOf("message", "channel_post")
)

data class DeleteMessageRequest(
    val chatId: Long,
    val messageId: Int
)

data class ApiResponse(
    val ok: Boolean,
    val description: String? = null
)

data class SetWebhookResponse(
    val ok: Boolean,
    val description: String? = null,
    val result: Boolean? = null
)

data class GetMeResponse(
    val ok: Boolean,
    val result: BotInfo? = null,
    val description: String? = null,
    val errorCode: Int? = null
)

data class BotInfo(
    val id: Long,
    val isBot: Boolean,
    val firstName: String,
    val username: String
)