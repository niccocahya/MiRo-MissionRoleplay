plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.miro_app"
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
        applicationId = "com.example.miro_app"
        minSdk = flutter.minSdkVersion  // ✅ FIXED: Support Android 5.0+ (safe & wide compatibility)
        targetSdk = 34  // ✅ FIXED: Latest stable
        versionCode = 1
        versionName = "1.0.0"
        
        // ✅ ADDED: Explicit build features
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        
        release {
            // ✅ FIXED: Use debug signing untuk APK demo
            signingConfig = signingConfigs.getByName("debug")
            
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
