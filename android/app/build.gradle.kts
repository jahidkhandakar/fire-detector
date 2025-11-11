plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase plugin
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.pranisheba.fire_alarm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Load signing props from android/key.properties
    val keystoreProps = Properties().apply {
        val f = rootProject.file("key.properties")
        if (f.exists()) load(FileInputStream(f))
    }

    signingConfigs {
        create("release") {
            val storePath = keystoreProps.getProperty("storeFile") ?: ""
            // Resolve relative to android/ (rootProject) first, then app/ as fallback
            val rootResolved = rootProject.file(storePath)
            val moduleResolved = file(storePath)
            storeFile = when {
                rootResolved.exists() -> rootResolved
                moduleResolved.exists() -> moduleResolved
                else -> throw GradleException("Keystore not found: $storePath (checked ${rootResolved.path} and ${moduleResolved.path})")
            }
            storePassword = keystoreProps.getProperty("storePassword")
            keyAlias = keystoreProps.getProperty("keyAlias")
            keyPassword = keystoreProps.getProperty("keyPassword")
        }
    }

    defaultConfig {
        applicationId = "com.pranisheba.fire_alarm"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1 
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        // Required for new Firebase SDKs (Java 17 compatibility)
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

dependencies {
    // ✅ Enable core library desugaring for modern Java features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // ✅ Import the Firebase BoM — it auto-manages Firebase versions
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))

    // ✅ Add only the Firebase SDKs you need (no versions)
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}

flutter {
    source = "../.."
}
