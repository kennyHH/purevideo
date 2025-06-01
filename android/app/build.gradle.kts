import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "io.github.majusss.purevideo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "io.github.majusss.purevideo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

	signingConfigs {
		create("release") {
			// Try to read from environment variables (for CI/GitHub Actions)
			// Fallback to key.properties for local builds
			keyAlias = System.getenv("SIGNING_KEY_ALIAS") ?: keystoreProperties["keyAlias"] as String
			keyPassword = System.getenv("SIGNING_KEY_PASSWORD") ?: keystoreProperties["keyPassword"] as String
			storePassword = System.getenv("SIGNING_STORE_PASSWORD") ?: keystoreProperties["storePassword"] as String

			val storeFileFromEnv = System.getenv("SIGNING_STORE_FILE")
			if (storeFileFromEnv != null) {
				storeFile = file(storeFileFromEnv) // Use absolute path from env var
			} else {
				// Fallback for local builds, assumes path in key.properties is relative to the app module or correctly pathed
				storeFile = keystoreProperties["storeFile"]?.let { file(it.toString()) }
			}
		}
	}
	
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            ndk {
                abiFilters.add("arm64-v8a")
            }
        }
    }
}

flutter {
    source = "../.."
}
