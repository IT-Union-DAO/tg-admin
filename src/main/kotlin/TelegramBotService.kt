package su.dunkan

import com.github.kotlintelegrambot.bot
import com.github.kotlintelegrambot.entities.ChatId
import com.github.kotlintelegrambot.entities.Update
import com.github.kotlintelegrambot.entities.User
import com.github.kotlintelegrambot.network.bimap
import org.slf4j.LoggerFactory

/**
 * Service class for interacting with Telegram Bot API
 * Handles webhook registration, message processing, and deletion
 */
class TelegramBotService(
    private val botToken: String,
    private val domain: String
) {
    private val logger = LoggerFactory.getLogger(TelegramBotService::class.java)

    private val libraryBot = bot {
        token = botToken
    }

    /**
     * Register webhook with Telegram Bot API
     */
    suspend fun registerWebhook(): Boolean {
        val webhookUrl = "https://$domain/webhook"
        return libraryBot.setWebhook(url = webhookUrl).bimap(mapError = { false }, mapResponse = { true })
    }

    /**
     * Process incoming webhook update
     */
    fun processUpdate(update: Update): Boolean {
        return try {
            when {
                update.message?.newChatMembers?.isNotEmpty() == true -> {
                    val message = update.message!!
                    logger.info("New member message detected in chat ${message.chat.id} with ${message.newChatMembers?.size} members")
                    // Log member details for debugging
                    message.newChatMembers?.forEach { member ->
                        logger.debug("New member: id=${member.id}, firstName='${member.firstName}', username='${member.username}'")
                    }
                    print(message)
                    deleteMessage(message.chat.id, message.messageId)
                    return true
                }

                update.channelPost?.newChatMembers?.isNotEmpty() == true -> {
                    val channelPost = update.channelPost!!
                    logger.info("New member message detected in channel ${channelPost.chat.id} with ${channelPost.newChatMembers?.size} members")
                    // Log member details for debugging
                    channelPost.newChatMembers?.forEach { member ->
                        logger.debug("New channel member: id=${member.id}, firstName='${member.firstName}', username='${member.username}'")
                    }
                    deleteMessage(channelPost.chat.id, channelPost.messageId)
                    true
                }


                update.message?.leftChatMember != null -> {
                    val message = update.message!!
                    deleteMessage(message.chat.id, message.messageId)
                    true
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
    private fun deleteMessage(chatId: Long, messageId: Long): Boolean =
        libraryBot.deleteMessage(ChatId.fromId(chatId), messageId).get()

    /**
     * Get bot information to verify connectivity
     */
    fun getBotInfo(): User? = libraryBot.getMe().get()
}
