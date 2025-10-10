plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.farmmobi.farmer360"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Use Java 11
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // Enable API desugaring (required by :ota_update)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // Kotlin DSL requires a String here (use double quotes)
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.farmmobi.farmer360"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // If minSdk ≤ 20, also enable multidex
        // multiDexEnabled = true
    }

    buildTypes {
        release {
            // Replace with proper signing config for release
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Desugared JDK library required by :ota_update (AAR metadata demands 2.1.4+)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
