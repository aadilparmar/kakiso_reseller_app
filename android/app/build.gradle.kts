plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kakiso_reseller_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // Application ID - ensure this matches your AndroidManifest/package
        applicationId = "com.example.kakiso_reseller_app"

        // Set minSdk to 23 because firebase_messaging (and possibly other modern plugins)
        // require at least API 23. This resolves the manifest-merge error.
        minSdk = 23

        // Keep target/version values provided by Flutter
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            // Uncomment/adjust these if you have proguard rules:
            // isMinifyEnabled = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.21")
    // Add other dependencies your app needs
coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
