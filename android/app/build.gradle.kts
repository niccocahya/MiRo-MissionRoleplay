import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Kunci rilis SENGAJA nggak ditulis langsung di sini -- dibaca dari
// key.properties (gitignored, lihat .gitignore) biar password kuncinya
// nggak pernah ke-commit. Kalau file ini nggak ada (mis. orang lain
// clone repo ini tanpa kuncinya, atau CI tanpa akses ke kunci rilis),
// JANGAN bikin build gagal total -- biarin fallback ke kunci debug,
// tapi tetap dicetak peringatannya biar jelas kenapa APK release-nya
// nggak "beneran" release-signed.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    logger.warn(
        "⚠️  android/key.properties nggak ketemu -- APK release bakal " +
        "ditandatangani pakai kunci DEBUG, bukan kunci rilis asli. " +
        "Aman buat testing lokal, TAPI JANGAN dipakai buat publish."
    )
}

android {
    namespace = "com.miro.app"
    compileSdk = 36  // ✅ UPDATE
    ndkVersion = "28.2.13676358"  // ✅ UPDATE

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.miro.app"
        minSdk = flutter.minSdkVersion  // ✅ FIXED: Support Android 5.0+ (safe & wide compatibility)
        targetSdk = 34  // ✅ FIXED: Latest stable
        versionCode = 1
        versionName = "1.0.0"
        
        // ✅ ADDED: Explicit build features
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                // rootProject.file, BUKAN file() polos -- key.properties nyimpen
                // path relatif ke android/ (tempat file properties-nya sendiri),
                // tapi file() di app/build.gradle.kts ini nge-resolve relatif ke
                // android/app/, bukan android/. Ketauan gara-gara build beneran
                // gagal nyari keystore-nya padahal filenya ada.
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }

        release {
            // Kunci rilis ASLI dipakai kalau key.properties ada (lihat
            // catatan di atas file ini); fallback ke debug cuma buat
            // orang/mesin yang nggak pegang kuncinya, BUKAN buat publish.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // ✅ DISABLE minify dulu (enable later kalau stable)
            isMinifyEnabled = false
            isShrinkResources = false

            // ✅ PROGUARD rules (aman untuk sekarang)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // ✅ ADDED: Lint options (ignore warnings yg tidak kritis)
    lint {
        disable.addAll(listOf(
            "MissingTranslation",
            "ExtraTranslation"
        ))
    }
}

flutter {
    source = "../.."
}
