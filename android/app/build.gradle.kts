plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.onfinity.music"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.onfinity.music"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // TODO: Create a release keystore and configure here (C-04)
        // keytool -genkey -v -keystore ~/onfinity-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias onfinity
        // Then uncomment the following:
        // create("release") {
        //     storeFile = file(System.getenv("KEYSTORE_PATH") ?: "../onfinity-release.jks")
        //     storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
        //     keyAlias = System.getenv("KEY_ALIAS") ?: "onfinity"
        //     keyPassword = System.getenv("KEY_PASSWORD") ?: ""
        // }
    }

    buildTypes {
        release {
            // TODO: Switch to release signing config when keystore is ready
            // signingConfig = signingConfigs.getByName("release")
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}