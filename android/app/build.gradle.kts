plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.my_gym_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.my_gym_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Product Flavors para dev y prod
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            // Sin applicationIdSuffix para usar el mismo google-services.json
            // Si quieres que dev y prod coexistan en el dispositivo,
            // registra una nueva app en Firebase con package com.example.my_gym_app.dev
            resValue("string", "app_name", "My Gym App (Dev)")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "My Gym App")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
