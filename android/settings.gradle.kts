pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

// Notificaciones push (FCM) — PENDIENTE, ver checklist al final de la
// respuesta del asistente: cuando exista android/app/google-services.json
// real, agregar acá `id("com.google.gms.google-services") version "4.4.2"
// apply false` (dentro del bloque plugins de arriba) y descomentar el bloque
// correspondiente en app/build.gradle.kts. En esta máquina, intentar
// resolver ese plugin ahora mismo rompe CUALQUIER build por un problema de
// certificado SSL (mismo síntoma que bloqueó `git push`, PKIX path building
// failed) — no es específico de Firebase, es de la máquina.

include(":app")
