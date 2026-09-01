import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release real — ver android/key.properties (nunca versionado, ver
// android/.gitignore) y android/app/upload-keystore.jks, generados una sola
// vez para este proyecto. Si el archivo no existe (ej. alguien clona el repo
// sin la keystore real) se cae de vuelta a la firma de debug en vez de
// romper el build — mismo criterio best-effort que el resto de secretos
// opcionales de la app (Firebase, etc.).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val tieneFirmaReal = keystorePropertiesFile.exists()
if (tieneFirmaReal) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Notificaciones push (FCM) — PENDIENTE (ver settings.gradle.kts): una vez
// declarado el plugin ahí arriba y con google-services.json real presente,
// descomentar esto para que se aplique:
// if (file("google-services.json").exists()) {
//     apply(plugin = "com.google.gms.google-services")
// }

android {
    // "com.example.*" era el paquete genérico que deja Flutter por defecto
    // — no se puede publicar en Play Store así. Antes de cambiarlo de nuevo,
    // avisar: una vez publicada la app con un applicationId, cambiarlo es
    // prácticamente irreversible (Play Store lo trata como una app distinta).
    namespace = "com.edumon.movil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications (notificaciones push) lo exige: usa
        // APIs de java.time en versiones de Android donde no existen nativas.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.edumon.movil"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (tieneFirmaReal) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Firma real si existe key.properties (ver arriba); si no, se
            // sigue firmando con la key de debug para no romper
            // `flutter run --release` en una máquina sin la keystore real.
            signingConfig = if (tieneFirmaReal) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Requerido junto con isCoreLibraryDesugaringEnabled de arriba.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
