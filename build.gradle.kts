plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.ktor)
    kotlin("kapt") version "2.2.20"
    `maven-publish`
}

repositories {
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}

group = "su.dunkan"
version = "0.0.1"

// Use Git commit SHA for versioning in CI
val gitCommitSha = providers.exec {
    commandLine("git", "rev-parse", "HEAD")
}.standardOutput.asText.get().trim()

// Override version for CI builds
if (System.getenv("GITHUB_ACTIONS") != null) {
    version = gitCommitSha
}

application {
    mainClass = "io.ktor.server.netty.EngineMain"
}

dependencies {
    implementation(libs.ktor.server.core)
    implementation(libs.ktor.server.netty)
    implementation(libs.logback.classic)
    implementation(libs.ktor.server.config.yaml)
    implementation(libs.ktor.server.content.negotiation)
    implementation(libs.ktor.serialization.jackson)
    
    // HTTP client for Telegram Bot API
    implementation(libs.ktor.client.core)
    implementation(libs.ktor.client.cio)
    implementation(libs.ktor.client.content.negotiation)
    
    // JSON support
    implementation(libs.jackson.datatype.jsr310)
    // Gson support (kotlin-telegram-bot library includes Gson)
    // implementation("com.google.code.gson:gson:2.8.5") // Already included via telegram library
    
    // Telegram Bot library
    implementation(libs.kotlin.telegram.bot)
    
    testImplementation(libs.ktor.server.test.host)
    testImplementation(libs.kotlin.test.junit)
    testImplementation(libs.ktor.client.mock)
}

// Configure fat JAR creation
tasks.named<Jar>("jar") {
    archiveBaseName.set("tg-admin")
    archiveClassifier.set("") // Remove "-all" suffix for consistency
    
    manifest {
        attributes(
            "Main-Class" to "io.ktor.server.netty.EngineMain",
            "Implementation-Version" to project.version,
            "Git-Commit" to (System.getenv("GITHUB_SHA") ?: "local")
        )
    }
    
    // Include all dependencies in the JAR
    from(configurations.runtimeClasspath.get().filter { it.name.endsWith("jar") }.map { zipTree(it) })
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}

// Publishing configuration for GitHub Packages
publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            artifact(tasks.named("jar")) {
                artifactId = "tg-admin"
            }
            
            pom {
                name.set("Telegram Admin Bot")
                description.set("A Telegram bot for simple moderation procedures")
                url.set("https://github.com/${System.getenv("GITHUB_REPOSITORY") ?: "dunkan/tg-admin"}")
                
                developers {
                    developer {
                        name.set("Andrei Dunai")
                    }
                }
                
                scm {
                    connection.set("scm:git:git://github.com/${System.getenv("GITHUB_REPOSITORY") ?: "dunkan/tg-admin"}.git")
                    developerConnection.set("scm:git:ssh://github.com:${System.getenv("GITHUB_REPOSITORY") ?: "dunkan/tg-admin"}.git")
                    url.set("https://github.com/${System.getenv("GITHUB_REPOSITORY") ?: "dunkan/tg-admin"}/tree/main")
                }
            }
        }
    }
}