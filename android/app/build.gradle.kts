plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.docora.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required for Java 8 APIs like LocalDateTime (used by drift)
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.docora.app"
        minSdk = flutter.minSdkVersion                      // Android 6.0 Marshmallow
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing configs — release config added in Phase 12
    signingConfigs {
        create("release") {
            // Populated via environment variables in CI / Phase 12
            // storeFile = file(System.getenv("KEYSTORE_PATH") ?: "")
            // storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            // keyAlias = System.getenv("KEY_ALIAS") ?: ""
            // keyPassword = System.getenv("KEY_PASSWORD") ?: ""
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // Use debug signing for now — replaced with release keys in Phase 12
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    // Lint — treat errors as errors, not warnings
    lint {
        abortOnError = true
        checkReleaseBuilds = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for Java 8 time APIs (required by Drift)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}
