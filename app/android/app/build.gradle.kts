import com.google.gms.googleservices.GoogleServicesTask
import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") apply false
    id("com.google.firebase.crashlytics") apply false
}

// Selection is per invocation. A leftover JSON cannot silently enable Firebase.
val pourluneRepo = rootProject.projectDir.parentFile.parentFile
val firebaseEnvironment = providers.gradleProperty("POURLUNE_FIREBASE_ENV").getOrElse("none")
val firebaseDirectory = file(providers.gradleProperty("POURLUNE_FIREBASE_CONFIG_DIR")
    .getOrElse(pourluneRepo.resolve("app/config/firebase").path))
val firebaseRegistry = providers.gradleProperty("POURLUNE_FIREBASE_REGISTRY")
    .getOrElse(pourluneRepo.resolve("docs/development/evidence/firebase-integration/registration.json").path)
val pourluneApplicationId = if (firebaseEnvironment == "prod") "com.pourlune.app" else "dev.pourlune.pourlune_dev"
val pourlunePython = System.getenv("POURLUNE_PYTHON")
    ?: pourluneRepo.resolve(".venv/bin/python").takeIf { it.exists() }?.path ?: "python3"
val admobAppId = providers.gradleProperty("POURLUNE_ADMOB_APP_ID")
    .getOrElse("ca-app-pub-3940256099942544~3347511713")
val admobRegistration = providers.gradleProperty("POURLUNE_ADMOB_REGISTRATION").getOrElse("")
val admobCheck = providers.exec {
    commandLine(listOf(pourlunePython, pourluneRepo.resolve("tools/validation/admob_config.py").path,
        "--platform", "android", "--native-id", pourluneApplicationId,
        "--native-app-id", admobAppId) +
        if (admobRegistration.isEmpty()) emptyList() else listOf("--registration", admobRegistration))
    environment("DART_DEFINES", providers.gradleProperty("dart-defines").getOrElse(""))
    isIgnoreExitValue = true
}
check(admobCheck.result.get().exitValue == 0) {
    "Pourlune AdMob selection rejected; inspect explicit platform/App ID/test configuration."
}
val firebaseCheck = providers.exec {
    commandLine(pourlunePython, pourluneRepo.resolve("tools/validation/firebase_config.py").path,
        "--environment", firebaseEnvironment, "--platform", "android",
        "--config-dir", firebaseDirectory.path, "--registry", firebaseRegistry,
        "--check-build", "--native-id", pourluneApplicationId)
    environment("DART_DEFINES", providers.gradleProperty("dart-defines").getOrElse(""))
    isIgnoreExitValue = true
}
check(firebaseCheck.result.get().exitValue == 0) {
    "Pourlune Firebase selection rejected. Run firebase_config.py; no config contents are logged."
}
if (firebaseEnvironment != "none") {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
    // The plugin assigns its default search paths when variants register tasks.
    // Apply our validated file after those registration actions.
    afterEvaluate {
        tasks.withType<GoogleServicesTask>().configureEach {
            googleServicesJsonFiles.set(listOf(firebaseDirectory.resolve("$firebaseEnvironment/android/google-services.json")))
        }
    }
}

android {
    namespace = "dev.pourlune.pourlune_dev"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Default/QA installs keep the development identity; prod is explicit.
        applicationId = pourluneApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        manifestPlaceholders["POURLUNE_DISPLAY_NAME"] =
            if (firebaseEnvironment == "prod") "Pourlune" else "Pourlune Dev"
        manifestPlaceholders["POURLUNE_ADMOB_APP_ID"] =
            admobAppId
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes.configureEach {
        if (firebaseEnvironment != "none") {
            extensions.configure<CrashlyticsExtension> {
                // Production is compile-only in this batch, with no uploads.
                mappingFileUploadEnabled = firebaseEnvironment == "dev"
                nativeSymbolUploadEnabled = false
            }
        }
    }

    // Release signing is intentionally unconfigured.

}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
