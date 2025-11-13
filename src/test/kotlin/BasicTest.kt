package su.dunkan

import kotlin.test.*

class BasicTest {

    @Test
    fun `test basic assertion`() {
        assertEquals(2 + 2, 4)
    }

    @Test
    fun `test data class creation`() {
        val user = User(id = 123, isBot = false, firstName = "Test")
        assertEquals(123L, user.id)
        assertEquals("Test", user.firstName)
        assertFalse(user.isBot)
    }

    @Test
    fun `test configuration validation`() {
        val config = TelegramConfig("test_token", "test.domain.com")
        assertTrue(config.validate())
    }
}