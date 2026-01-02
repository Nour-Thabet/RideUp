plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")

    // Flutter plugin (DOIT être après Android & Kotlin)
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.covoiturage"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.covoiturage"
        minSdk = flutter.minSdkVersion
        //targetSdkVersion flutter.targetSdkVersion

        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}
