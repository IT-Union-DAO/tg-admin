package su.dunkan

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory

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
    private val json = Json { ignoreUnknownKeys = true }
    
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
                    logger.info("New member message detected in chat ${update.message.chat.id}")
                    deleteMessage(update.message.chat.id, update.message.messageId)
                }
                update.channelPost?.newChatMembers?.isNotEmpty() == true -> {
                    logger.info("New member message detected in channel ${update.channelPost.chat.id}")
                    deleteMessage(update.channelPost.chat.id, update.channelPost.messageId)
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
    private suspend fun deleteMessage(chatId: Long, messageId: Int): Boolean {
        return try {
            val response: ApiResponse = httpClient.post("https://api.telegram.org/bot$botToken/deleteMessage") {
                contentType(ContentType.Application.Json)
                setBody(DeleteMessageRequest(chatId, messageId))
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

// Data classes for Telegram Bot API

@Serializable
data class Update(
    val updateId: Int,
    val message: Message? = null,
    val channelPost: Message? = null
)

@Serializable
data class Message(
    val messageId: Int,
    val chat: Chat,
    val newChatMembers: List<User>? = null
)

@Serializable
data class Chat(
    val id: Long,
    val type: String
)

@Serializable
data class User(
    val id: Long,
    val isBot: Boolean,
    val firstName: String
)

@Serializable
data class SetWebhookRequest(
    val url: String,
    val allowedUpdates: List<String> = listOf("message", "channel_post")
)

@Serializable
data class DeleteMessageRequest(
    val chatId: Long,
    val messageId: Int
)

@Serializable
data class ApiResponse(
    val ok: Boolean,
    val description: String? = null
)

@Serializable
data class SetWebhookResponse(
    val ok: Boolean,
    val description: String? = null,
    val result: Boolean? = null
)

@Serializable
data class GetMeResponse(
    val ok: Boolean,
    val result: BotInfo? = null,
    val description: String? = null,
    val errorCode: Int? = null
)

@Serializable
data class BotInfo(
    val id: Long,
    val isBot: Boolean,
    val firstName: String,
    val username: String
)