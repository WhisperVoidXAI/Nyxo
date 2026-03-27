plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_app"
    compileSdk = 36

    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.my_app"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

// Flutter tooling expects APKs under <project>/build/app/outputs/flutter-apk/ (see gradle.dart listApkPaths).
// AGP writes them under android/app/build/outputs/apk/<variant>/ — copy after assemble so tooling finds them.
afterEvaluate {
    tasks.named("assembleRelease").configure {
        doLast("copyReleaseApksToFlutterOutputs") {
            val flutterProjectRoot = rootProject.projectDir.parentFile
            val flutterApkDir = File(flutterProjectRoot, "build/app/outputs/flutter-apk")
            flutterApkDir.mkdirs()
            val apkDir = File(layout.buildDirectory.get().asFile, "outputs/apk/release")
            apkDir.listFiles()?.filter { it.extension.equals("apk", ignoreCase = true) }?.forEach { apk ->
                apk.copyTo(File(flutterApkDir, apk.name), overwrite = true)
            }
        }
    }
}
