import java.time.Instant

buildscript {
    repositories {
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

repositories {
    mavenCentral()
    maven { url = uri("https://jitpack.io") }
}
plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.ktor)
    kotlin("kapt") version "2.2.20"
    `maven-publish`
}


group = "su.dunkan"

// Version management configuration
val isCI = System.getenv("GITHUB_ACTIONS") != null

// Safe Git information extraction
fun safeGitCommand(vararg args: String): String = try {
    providers.exec { commandLine(*args) }.standardOutput.asText.get().trim()
} catch (e: Exception) {
    "unknown"
}

val gitCommitSha = safeGitCommand("git", "rev-parse", "HEAD")
val gitCommitShortSha = safeGitCommand("git", "rev-parse", "--short", "HEAD")
val gitTag = safeGitCommand("git", "describe", "--tags", "--exact-match", "--always")
val gitBranch = safeGitCommand("git", "rev-parse", "--abbrev-ref", "HEAD")

// Semantic version configuration
val baseVersion = "0.0.1"

// Determine final version
version = if (isCI) {
    // In CI environment
    if (gitTag.matches(Regex("^v?\\d+\\.\\d+\\.\\d+.*"))) {
        // Use semantic version from Git tag (remove 'v' prefix if present)
        gitTag.removePrefix("v")
    } else {
        // Use commit SHA for non-tagged builds
        "$baseVersion-$gitCommitShortSha"
    }
} else {
    // Local development
    if (gitTag.matches(Regex("^v?\\d+\\.\\d+\\.\\d+.*"))) {
        gitTag.removePrefix("v")
    } else {
        "$baseVersion-SNAPSHOT"
    }
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
    implementation(libs.retrofit)

    // HTTP client for Telegram Bot API
    implementation(libs.ktor.client.core)
    implementation(libs.ktor.client.cio)
    implementation(libs.ktor.client.content.negotiation)
    // JSON support
    // Gson support (kotlin-telegram-bot library includes Gson)
    implementation(libs.gson)
    // Telegram Bot library
    implementation(libs.kotlin.telegram.bot)

    testImplementation(libs.ktor.server.test.host)
    testImplementation(libs.kotlin.test.junit)
    testImplementation(libs.ktor.client.mock)
}

// Task to generate version information file
tasks.register("generateVersionProperties") {
    doLast {
        val versionFile = file("src/main/resources/version.properties")
        versionFile.parentFile.mkdirs()
        versionFile.writeText(
            """
            # Application Version Information
            # Generated at build time
            
            app.name=Telegram Admin Bot
            app.group=${project.group}
            app.version=${project.version}
            build.timestamp=${Instant.now()}
            git.commit=$gitCommitSha
            git.commit.short=$gitCommitShortSha
            git.branch=$gitBranch
            git.tag=${if (gitTag.matches(Regex("^v?\\d+\\.\\d+\\.\\d+.*"))) gitTag else "none"}
            build.environment=${if (isCI) "ci" else "local"}
        """.trimIndent()
        )
    }
}

// Make build tasks depend on version generation
tasks.named("processResources") {
    dependsOn("generateVersionProperties")
}

// Configure fat JAR creation
tasks.named<Jar>("jar") {
    archiveBaseName.set("tg-admin")
    archiveClassifier.set("") // Remove "-all" suffix for consistency

    manifest {
        attributes(
            "Main-Class" to "io.ktor.server.netty.EngineMain",
            "Implementation-Version" to project.version,
            "Implementation-Title" to "Telegram Admin Bot",
            "Implementation-Vendor" to "su.dunkan",
            "Built-By" to System.getProperty("user.name", "unknown"),
            "Build-Timestamp" to Instant.now().toString(),
            "Git-Commit" to gitCommitSha,
            "Git-Commit-Short" to gitCommitShortSha,
            "Git-Branch" to gitBranch,
            "Git-Tag" to (if (gitTag.matches(Regex("^v?\\d+\\.\\d+\\.\\d+.*"))) gitTag else "none")
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
                url.set("https://github.com/${System.getenv("GITHUB_REPOSITORY") ?: "IT-Union-DAO/tg-admin"}")

                scm {
                    connection.set("scm:git:git://github.com/${System.getenv("GITHUB_REPOSITORY") ?: "IT-Union-DAO/tg-admin"}.git")
                    developerConnection.set("scm:git:ssh://github.com:${System.getenv("GITHUB_REPOSITORY") ?: "IT-Union-DAO/tg-admin"}.git")
                    url.set("https://github.com/${System.getenv("GITHUB_REPOSITORY") ?: "IT-Union-DAO/tg-admin"}/tree/main")
                }
            }
        }
    }

    repositories {
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/${System.getenv("GITHUB_REPOSITORY") ?: "IT-Union-DAO/tg-admin"}")
            credentials {
                username = System.getenv("GITHUB_ACTOR")
                password = System.getenv("GITHUB_TOKEN")
            }
        }
    }
}