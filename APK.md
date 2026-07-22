# Sidimad-XtreamProv1 — Android APK Build Guide

Complete reference for building, rebuilding, cleaning, and distributing the Android APK.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Project Structure — Android](#2-project-structure--android)
3. [Key Config Files](#3-key-config-files)
4. [Build Commands](#4-build-commands)
5. [Output Location](#5-output-location)
6. [Dart Source Files](#6-dart-source-files)
7. [Android Native Files](#7-android-native-files)
8. [Asset & Icon Files](#8-asset--icon-files)
9. [Signing](#9-signing)
10. [CI/CD — GitHub Actions](#10-cicd--github-actions)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Prerequisites

| Tool | Version | Path / Install |
|------|---------|----------------|
| Flutter SDK | 3.44.6+ | `C:\Program Files\flutter\bin\flutter.bat` |
| Android Studio | Latest | With Android SDK, SDK Platform-Tools, Build-Tools |
| Java (JDK) | 17 | Bundled with Android Studio or standalone |
| Android SDK | API 35+ | `C:\Users\SidimaD\AppData\Local\Android\Sdk` |
| Gradle | 8.14 (auto-downloaded) | Via `gradlew` wrapper |

### Verify prerequisites

```powershell
flutter doctor -v
```

Look for:
- `[✓] Flutter`
- `[✓] Android toolchain - develop for Android devices`
- `[✓] Android Studio`
- `[✓] Java version 17+`

### Environment variables (if not auto-detected)

```powershell
$env:ANDROID_HOME = "C:\Users\SidimaD\AppData\Local\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

---

## 2. Project Structure — Android

```
android/
├── .gitignore
├── build.gradle.kts                         # Root Gradle — repositories, build dir
├── settings.gradle.kts                      # Plugin versions (AGP 8.11.1, Kotlin 2.2.20)
├── gradle.properties                        # JVM args, AndroidX, Kotlin flags
├── local.properties                         # SDK/Flutter paths (auto-generated, gitignored)
├── key.properties                           # Release keystore config (gitignored)
├── gradlew                                  # Gradle wrapper (Linux)
├── gradlew.bat                              # Gradle wrapper (Windows)
├── gradle/
│   └── wrapper/
│       └── gradle-wrapper.properties        # Gradle version (8.14)
└── app/
    ├── build.gradle.kts                     # App-level Gradle — namespace, SDK, signing
    ├── lumen.keystore                       # Release signing keystore
    └── src/
        ├── debug/
        │   └── AndroidManifest.xml          # Debug-only: INTERNET permission
        ├── profile/
        │   └── AndroidManifest.xml          # Profile-only: INTERNET permission
        └── main/
            ├── AndroidManifest.xml          # Main manifest — label, icon, permissions, PiP
            ├── kotlin/
            │   └── com/sidimad/xtreamprov1/
            │       └── MainActivity.kt      # Kotlin — PiP MethodChannel, FlutterActivity
            ├── java/
            │   └── io/flutter/plugins/      # Auto-generated plugin registrations
            └── res/
                ├── drawable/
                │   ├── launch_background.xml
                │   └── tv_banner.png        # Android TV banner (320x180)
                ├── drawable-v21/
                │   └── launch_background.xml
                ├── drawable-mdpi/
                │   └── ic_launcher_foreground.png   (48x48)
                ├── drawable-hdpi/
                │   └── ic_launcher_foreground.png   (72x72)
                ├── drawable-xhdpi/
                │   └── ic_launcher_foreground.png   (96x96)
                ├── drawable-xxhdpi/
                │   └── ic_launcher_foreground.png   (144x144)
                ├── drawable-xxxhdpi/
                │   └── ic_launcher_foreground.png   (192x192)
                ├── mipmap-anydpi-v26/
                │   └── ic_launcher.xml              # Adaptive icon definition
                ├── mipmap-mdpi/
                │   └── ic_launcher.png              (48x48)
                ├── mipmap-hdpi/
                │   └── ic_launcher.png              (72x72)
                ├── mipmap-xhdpi/
                │   └── ic_launcher.png              (96x96)
                ├── mipmap-xxhdpi/
                │   └── ic_launcher.png              (144x144)
                ├── mipmap-xxxhdpi/
                │   └── ic_launcher.png              (192x192)
                ├── values/
                │   ├── colors.xml                   # Icon background: #0A1412
                │   └── styles.xml                   # App theme
                └── values-night/
                    └── styles.xml                   # Night mode theme
```

**Build output:**
```
build/app/outputs/
├── flutter-apk/
│   └── app-release.apk                    # Universal APK (~94 MB)
├── mapping/release/
│   └── mapping.txt                        # ProGuard/R8 mapping (for crash reports)
├── logs/
│   └── manifest-merger-*.txt              # Manifest merge log
├── native-debug-symbols/
│   └── release/
│       └── ...                            # Native debug symbols
└── sdk-dependencies/
    └── release/
        └── ...                            # SDK dependency list
```

---

## 3. Key Config Files

### `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.sidimad.xtreamprov1"         // R class package
    compileSdk = flutter.compileSdkVersion         // Auto from Flutter
    ndkVersion = flutter.ndkVersion                // Auto from Flutter

    defaultConfig {
        applicationId = "com.sidimad.xtreamprov1"  // Play Store package name
        minSdk = flutter.minSdkVersion              // Auto from Flutter
        targetSdk = flutter.targetSdkVersion        // Auto from Flutter
        versionCode = flutter.versionCode           // From pubspec.yaml (1)
        versionName = flutter.versionName           // From pubspec.yaml (1.1.0)
    }
}
```

### `android/build.gradle.kts` (root)

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### `android/settings.gradle.kts`

```kotlin
plugins {
    id("com.android.application") version "8.11.1" apply false     // AGP
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false // Kotlin
}
```

### `android/gradle.properties`

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m
android.useAndroidX=true
android.builtInKotlin=false
android.newDsl=false
```

### `android/gradle/wrapper/gradle-wrapper.properties`

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip
```

### `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
    <uses-feature android:name="android.software.leanback" android:required="false"/>
    <uses-feature android:name="android.hardware.touchscreen" android:required="false"/>
    <uses-feature android:name="android.software.picture_in_picture" android:required="false"/>

    <application
        android:label="Sidimad-XtreamProv1"
        android:icon="@mipmap/ic_launcher"
        android:banner="@drawable/tv_banner"
        android:usesCleartextTraffic="true">
        <activity
            android:name=".MainActivity"
            android:supportsPictureInPicture="true"
            android:resizeableActivity="true"
            ...>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
                <category android:name="android.intent.category.LEANBACK_LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### `pubspec.yaml` (root)

```yaml
name: sidimad_xtream_prov1
version: 1.1.0+1
# versionCode = 1, versionName = "1.1.0"

environment:
  sdk: ^3.10.8
```

---

## 4. Build Commands

All commands run from the project root.

### First-time build

```powershell
# 1. Get dependencies
flutter pub get

# 2. Build universal release APK
flutter build apk --release
```

### Full rebuild (clean + build)

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

### Debug APK

```powershell
flutter build apk --debug
```

### Profile APK (performance profiling)

```powershell
flutter build apk --profile
```

### Quick rebuild (incremental — no clean)

```powershell
flutter build apk --release
```

Gradle caches compiled code. Only changed files recompile. First build downloads dependencies (~5-8 min). Subsequent builds are faster (~2-4 min).

### Build per-architecture APKs (smaller individual files)

```powershell
flutter build apk --split-per-abi --release
```

Output:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk    (~30 MB)
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk      (~32 MB)
build/app/outputs/flutter-apk/app-x86_64-release.apk          (~35 MB)
```

### Build app bundle (for Play Store)

```powershell
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Run directly on device/emulator

```powershell
flutter run --release
```

### All commands reference

| Command | Description | Duration |
|---------|-------------|----------|
| `flutter clean` | Deletes `build/`, `.dart_tool/`, generated files | 5s |
| `flutter pub get` | Resolves and downloads dependencies | 5-10s |
| `flutter build apk --release` | Universal APK (all architectures) | 5-8 min (first), 2-4 min (cached) |
| `flutter build apk --debug` | Debug APK with logging | 3-5 min |
| `flutter build apk --profile` | Profile APK for perf testing | 3-5 min |
| `flutter build apk --split-per-abi --release` | Per-architecture APKs | 5-8 min |
| `flutter build appbundle --release` | Play Store AAB bundle | 5-8 min |
| `flutter run --release` | Build + deploy to connected device | 30-60s |
| `flutter devices` | List connected devices/emulators | 1s |
| `flutter doctor -v` | Verify SDK + toolchain | 10s |

---

## 5. Output Location

### Universal APK (default)

```
build/app/outputs/flutter-apk/app-release.apk
```

~94 MB. Works on all Android devices (arm, arm64, x86, x86_64).

### Per-architecture APKs

```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk   (32-bit ARM)
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk     (64-bit ARM)
build/app/outputs/flutter-apk/app-x86_64-release.apk        (64-bit Intel)
```

### Rename for distribution

```powershell
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "Sidimad-XtreamProv1-Android.apk"
```

---

## 6. Dart Source Files

All Dart code compiled into the APK:

### Core (`lib/`)

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point, `runApp()`, provider setup |
| `lib/models.dart` | Data models: `XtreamProfile`, `XtreamCredentials`, `Channel`, `Movie`, `Series`, `Episode` |
| `lib/xtream.dart` | Xtream Codes API client — auth, catalog, VOD, series, EPG, M3U parsing |
| `lib/store.dart` | Persistent storage — `SharedPreferences` + `FlutterSecureStorage`, key migration |
| `lib/theme.dart` | Theme system — accent presets, `ThemeController`, dark/light modes |
| `lib/playback.dart` | Video playback — `libmpv` controller, auto-reconnect, skip-intro, up-next |
| `lib/downloads.dart` | Download manager — queue, pause/resume (HTTP Range), persistence |
| `lib/updater.dart` | Auto-update — checks GitHub releases `Sidimad-tv/Ultimate-v1`, downloads APK |
| `lib/pip.dart` | Picture-in-Picture — platform channel `sidimad/pip` to native PiP |
| `lib/session.dart` | Session management — active profile, login state |
| `lib/split.dart` | Split-view logic for tablet/desktop layouts |
| `lib/responsive.dart` | Responsive breakpoints (mobile / tablet / desktop) |
| `lib/catalog_cache.dart` | In-memory cache for channel/movie/series catalogs |
| `lib/epg_cache.dart` | EPG data caching |
| `lib/home_config.dart` | Home screen layout configuration |
| `lib/library.dart` | User library — favorites, watch history |
| `lib/refresh.dart` | Background refresh logic |
| `lib/stats.dart` | Usage statistics tracking |
| `lib/tmdb.dart` | TMDB API client — metadata, images, recommendations |
| `lib/discovery.dart` | Service discovery / auto-login |
| `lib/widgets.dart` | Shared widgets — ShimmerLoading, GridLoading, LumenMark, FocusableTap |

### Screens (`lib/screens/`)

| File | Purpose |
|------|---------|
| `lib/screens/login_screen.dart` | Login — saved playlists dropdown, test server chips, local M3U, URL dialog |
| `lib/screens/shell.dart` | Main shell — sidebar with 10 pages, fullscreen toggle, auto-refresh, updater |
| `lib/screens/home_screen.dart` | Spotlight hero, bento tiles, Top 10, new releases, recommendations |
| `lib/screens/search_screen.dart` | Search across channels, movies, series |
| `lib/screens/profile_screen.dart` | Profile management, saved playlists, accent picker, theme, stats, downloads |
| `lib/screens/player_host.dart` | Video player host — overlay controls, PiP, gesture handling |
| `lib/screens/movie_detail_screen.dart` | Movie detail — metadata, TMDB info, play button |
| `lib/screens/series_detail_screen.dart` | Series detail — seasons, episodes, metadata |
| `lib/screens/epg_guide_screen.dart` | EPG guide — program schedule grid |
| `lib/screens/guide_screen.dart` | Channel guide — category browsing |
| `lib/screens/downloads_screen.dart` | Download queue and completed downloads |
| `lib/screens/mylist_screen.dart` | User's favorites / watchlist |
| `lib/screens/category_sheet.dart` | Category filter bottom sheet |
| `lib/screens/customize_home_screen.dart` | Customize home screen layout |
| `lib/screens/globe_screen.dart` | Globe / browse screen |
| `lib/screens/stats_screen.dart` | Usage statistics dashboard |
| `lib/screens/swipe_screen.dart` | Swipeable content browser |
| `lib/screens/split_picker.dart` | Split-view layout picker |
| `lib/screens/update_dialog.dart` | Update available dialog |

**Total: 40 Dart files (21 core + 19 screens)**

---

## 7. Android Native Files

### Kotlin

| File | Purpose |
|------|---------|
| `android/app/src/main/kotlin/com/sidimad/xtreamprov1/MainActivity.kt` | FlutterActivity subclass with PiP MethodChannel |

**MainActivity.kt details:**
- Package: `com.sidimad.xtreamprov1`
- Channel: `sidimad/pip`
- Methods: `setPipAllowed`, `enterPip`, `isSupported`, `pipChanged` (callback)
- Supports Android O+ (API 26+) PiP with 16:9 aspect ratio
- Auto-enters PiP on `onUserLeaveHint` when video is active

### Android Manifests

| File | Purpose |
|------|---------|
| `android/app/src/main/AndroidManifest.xml` | Main — permissions, label, icon, PiP, TV, cleartext |
| `android/app/src/debug/AndroidManifest.xml` | Debug — INTERNET permission |
| `android/app/src/profile/AndroidManifest.xml` | Profile — INTERNET permission |

### Gradle Files

| File | Purpose |
|------|---------|
| `android/app/build.gradle.kts` | App config — namespace, applicationId, SDK, signing |
| `android/build.gradle.kts` | Root — repositories, build directory |
| `android/settings.gradle.kts` | Plugins — AGP 8.11.1, Kotlin 2.2.20 |
| `android/gradle.properties` | JVM args, AndroidX, Kotlin flags |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.14 distribution |
| `android/gradlew` | Gradle wrapper script (Linux) |
| `android/gradlew.bat` | Gradle wrapper script (Windows) |

---

## 8. Asset & Icon Files

### Source logo

| File | Description |
|------|-------------|
| `assets/icon/logo.png` | Master logo — used by `flutter_launcher_icons` and manual icon generation |

### Android launcher icons (generated from logo.png)

| Path | Size | Density |
|------|------|---------|
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | 48x48 | mdpi |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | 72x72 | hdpi |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | 96x96 | xhdpi |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | 144x144 | xxhdpi |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | 192x192 | xxxhdpi |

### Adaptive icon foreground (generated from logo.png)

| Path | Size | Density |
|------|------|---------|
| `android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png` | 48x48 | mdpi |
| `android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png` | 72x72 | hdpi |
| `android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png` | 96x96 | xhdpi |
| `android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png` | 144x144 | xxhdpi |
| `android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png` | 192x192 | xxxhdpi |

### Adaptive icon definition

| File | Description |
|------|-------------|
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Background: `@color/ic_launcher_background` (#0A1412), Foreground: `@drawable/ic_launcher_foreground` with 16% inset |

### Android TV

| File | Size | Description |
|------|------|-------------|
| `android/app/src/main/res/drawable/tv_banner.png` | 320x180 | Android TV / Google TV home row banner |

### Colors

| File | Description |
|------|-------------|
| `android/app/src/main/res/values/colors.xml` | Icon background color: `#0A1412` (dark green-black) |

### Regenerate icons from logo.png

If you update `assets/icon/logo.png`, regenerate all icons:

```powershell
Add-Type -AssemblyName System.Drawing
$src = "assets\icon\logo.png"
$res = "android\app\src\main\res"

function Resize-Icon($s, $d, $w, $h) {
    $img = [System.Drawing.Image]::FromFile($s)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $w, $h)
    $bmp.Save($d, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose(); $img.Dispose()
}

# Launcher icons
Resize-Icon $src "$res\mipmap-mdpi\ic_launcher.png" 48 48
Resize-Icon $src "$res\mipmap-hdpi\ic_launcher.png" 72 72
Resize-Icon $src "$res\mipmap-xhdpi\ic_launcher.png" 96 96
Resize-Icon $src "$res\mipmap-xxhdpi\ic_launcher.png" 144 144
Resize-Icon $src "$res\mipmap-xxxhdpi\ic_launcher.png" 192 192

# Adaptive foreground
Resize-Icon $src "$res\drawable-mdpi\ic_launcher_foreground.png" 48 48
Resize-Icon $src "$res\drawable-hdpi\ic_launcher_foreground.png" 72 72
Resize-Icon $src "$res\drawable-xhdpi\ic_launcher_foreground.png" 96 96
Resize-Icon $src "$res\drawable-xxhdpi\ic_launcher_foreground.png" 144 144
Resize-Icon $src "$res\drawable-xxxhdpi\ic_launcher_foreground.png" 192 192

# TV banner
Resize-Icon $src "$res\drawable\tv_banner.png" 320 180

Write-Host "All icons regenerated."
```

---

## 9. Signing

### Keystore location

```
android/app/lumen.keystore
```

### Key properties

```
android/key.properties
```

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=<alias>
storeFile=app/lumen.keystore
```

Both files are **gitignored** — never commit them.

### How signing works

In `android/app/build.gradle.kts`:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystore = keystorePropertiesFile.exists()

signingConfigs {
    if (hasKeystore) {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName(if (hasKeystore) "release" else "debug")
    }
}
```

- If `key.properties` exists → signed with release keystore
- If missing → falls back to debug keystore (fine for testing)

### Verify APK signature

```powershell
apksigner verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

### Create a new keystore

```powershell
keytool -genkey -v -keystore sidimad.keystore -alias sidimad -keyalg RSA -keysize 2048 -validity 10000
```

---

## 10. CI/CD — GitHub Actions

**Workflow:** `.github/workflows/build.yml`

### Triggers
- Push to `main` branch
- Manual dispatch (`workflow_dispatch`)

### Android build job

| Step | Command / Action |
|------|-----------------|
| 1. Checkout | `actions/checkout@v4` |
| 2. Setup Java | `actions/setup-java@v4` (Temurin JDK 17) |
| 3. Setup Flutter | `subosito/flutter-action@v2` (channel: stable) |
| 4. Dependencies | `flutter pub get` |
| 5. Build APK | `flutter build apk --release` |
| 6. Upload artifact | `actions/upload-artifact@v4` → `build/app/outputs/flutter-apk/app-release.apk` |

### Release job

| Step | Command / Action |
|------|-----------------|
| 1. Download artifacts | Windows zip + Android APK |
| 2. Zip Windows build | `zip -r ../Sidimad-XtreamProv1-Windows.zip .` |
| 3. Rename APK | `app-release.apk` → `Sidimad-XtreamProv1-Android.apk` |
| 4. Delete old release | `gh release delete latest --yes --cleanup-tag` |
| 5. Create release | `gh release create latest` with both assets |

### To trigger manually

```powershell
gh workflow run "Build & Release" --repo Sidimad-tv/Ultimate-v1
```

### To check run status

```powershell
gh run list --repo Sidimad-tv/Ultimate-v1 --limit 5
gh run view <run-id> --repo Sidimad-tv/Ultimate-v1
gh run view <run-id> --repo Sidimad-tv/Ultimate-v1 --log-failed
```

---

## 11. Troubleshooting

### "Gradle daemon" stuck

```powershell
# Kill all Gradle daemons
gradlew --stop
# Or
taskkill /F /IM java.exe
```

### "SDK location not found"

Ensure `android/local.properties` exists with:
```properties
sdk.dir=C:\\Users\\SidimaD\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\Program Files\\flutter
```

### "Minimum SDK version" error

The app's `minSdk` is inherited from `flutter.minSdkVersion`. To override:
```kotlin
// In android/app/build.gradle.kts
minSdk = 21  // Override if needed
```

### NDK version mismatch

```powershell
# List installed NDKs
Get-ChildItem "$env:ANDROID_HOME\ndk\"
```

Set the correct version in `android/app/build.gradle.kts` or let Flutter auto-detect.

### Out of memory during build

Increase Gradle JVM heap in `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G
```

### "Manifest merger failed"

Check for conflicting declarations across:
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`
- Plugin manifests

### APK is too large (~94 MB)

The APK includes all architectures (arm, arm64, x86, x86_64). For smaller APKs:

```powershell
# Build per-architecture (each ~30 MB)
flutter build apk --split-per-abi --release
```

### First build is slow

First build downloads:
- Gradle 8.14 distribution (~150 MB)
- Android build tools
- libmpv native libraries (4 architectures)
- All plugin dependencies

Subsequent builds use Gradle cache and are much faster.

### "Permission denied" on gradlew

```powershell
chmod +x android/gradlew
# Or on Windows, ensure gradlew.bat is used
```

### Old APK still installed

Uninstall the old version first (different `applicationId` means it's a separate install):

```powershell
adb uninstall com.sidimad.xtreamprov1
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Install via ADB

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

### Check installed version on device

```powershell
adb shell dumpsys package com.sidimad.xtreamprov1 | Select-String "versionName|versionCode"
```
