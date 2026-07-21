# Lumen TV — Project Guide

## Overview

Flutter-based IPTV player using **libmpv** for playback (native TS/MKV/HLS). Connects to Xtream Codes API, TMDB for metadata, with EPG, downloads, and multi-profile support.

---

## Complete File Tree

```
Lumen-App-main/
│
├── .dart_tool/                          # Flutter tool cache (auto-generated)
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   ├── config.yml
│   │   └── feature_request.yml
│   ├── workflows/build.yml
│   └── PULL_REQUEST_TEMPLATE.md
│
├── android/                             # Android platform project
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── lumen.keystore
│   │   └── src/
│   │       ├── debug/AndroidManifest.xml
│   │       ├── main/
│   │       │   ├── AndroidManifest.xml
│   │       │   ├── java/io/flutter/plugins/GeneratedPluginRegistrant.java
│   │       │   ├── kotlin/com/lumen/lumen_tv/MainActivity.kt
│   │       │   └── res/                 # drawable*, mipmap*, values, values-night
│   │       └── profile/AndroidManifest.xml
│   ├── build.gradle.kts
│   ├── gradle/wrapper/gradle-wrapper.properties
│   ├── gradle.properties
│   ├── key.properties
│   ├── local.properties
│   └── settings.gradle.kts
│
├── assets/
│   ├── icon/lumen_icon.png              # App icon
│   ├── lumen_loader.json                # Lottie loader animation
│   └── lumen_wordmark.svg               # Logo wordmark
│
├── build/                               # Build output (auto-generated)
│   └── windows/x64/runner/Release/      # ** Final .exe output folder **
│       ├── lumen_tv.exe                 # Standalone executable (~93 KB stub)
│       ├── flutter_windows.dll
│       ├── libmpv-2.dll
│       ├── *.dll                        # Plugin DLLs & ANGLE/vulkan deps
│       └── data/                        # app.so + flutter_assets + icudtl.dat
│
├── docs/
│   ├── blog/building-lumen.md
│   ├── screenshots/                     # home.png, movies.png, live.png, etc.
│   ├── social/                          # square.png, twitter.png
│   └── DEMO_SCRIPT.md
│
├── ios/                                 # iOS Xcode project (Swift)
├── linux/                               # Linux CMake project (C++)
├── macos/                               # macOS Xcode project (Swift)
│
├── lib/                                 # ** Main Dart source code **
│   ├── screens/                         # UI screens
│   │   ├── category_sheet.dart
│   │   ├── customize_home_screen.dart
│   │   ├── downloads_screen.dart
│   │   ├── epg_guide_screen.dart
│   │   ├── globe_screen.dart
│   │   ├── guide_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart            # Login screen (port 3550)
│   │   ├── movie_detail_screen.dart
│   │   ├── mylist_screen.dart
│   │   ├── player_host.dart
│   │   ├── profile_screen.dart
│   │   ├── search_screen.dart
│   │   ├── series_detail_screen.dart
│   │   ├── shell.dart                   # Main shell after login
│   │   ├── split_picker.dart
│   │   ├── stats_screen.dart
│   │   ├── swipe_screen.dart
│   │   └── update_dialog.dart
│   ├── catalog_cache.dart               # Catalog caching layer
│   ├── discovery.dart
│   ├── downloads.dart                   # Download manager
│   ├── epg_cache.dart                   # EPG caching layer
│   ├── home_config.dart
│   ├── library.dart
│   ├── main.dart                        # App entry point
│   ├── models.dart                      # Data models (~261 lines)
│   ├── pip.dart                         # Picture-in-picture
│   ├── playback.dart                    # Media playback controller
│   ├── refresh.dart
│   ├── responsive.dart
│   ├── session.dart
│   ├── split.dart
│   ├── stats.dart
│   ├── store.dart                       # Secure credential storage
│   ├── theme.dart                       # Dark/light theme (~210 lines)
│   ├── tmdb.dart                        # TMDB API key & calls (~93 lines)
│   ├── tmdb.dart.bak                    # *** Backup of original tmdb.dart ***
│   ├── updater.dart
│   ├── widgets.dart
│   └── xtream.dart                     # Xtream Codes API client (~260 lines)
│
├── test/
│   └── widget_test.dart
│
├── windows/                             # ** Windows platform project **
│   ├── flutter/
│   │   ├── CMakeLists.txt
│   │   ├── ephemeral/                   # Auto-generated Flutter bindings
│   │   ├── generated_plugin_registrant.cc/.h
│   │   └── generated_plugins.cmake
│   ├── runner/
│   │   ├── resources/app_icon.ico       # Windows app icon
│   │   ├── CMakeLists.txt               # Runner build config (~34 lines)
│   │   ├── flutter_window.cpp/.h
│   │   ├── main.cpp                     # Windows entry point
│   │   ├── resource.h
│   │   ├── runner.exe.manifest
│   │   ├── Runner.rc
│   │   ├── utils.cpp/.h
│   │   └── win32_window.cpp/.h
│   ├── .gitignore
│   └── CMakeLists.txt                   # Top-level Windows CMake (~89 lines)
│
├── .flutter-plugins-dependencies
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── MARKETING.md
├── pubspec.lock
├── pubspec.yaml                         # Dependencies (~107 lines)
├── README.md
└── STORE_LISTING.md
```

---

## Key Files to Modify

| File | Purpose | Lines |
|------|---------|-------|
| `lib/main.dart` | App entry point, theme, gate logic | 174 |
| `lib/screens/login_screen.dart` | Login UI, port hint (3550) | 253 |
| `lib/tmdb.dart` | TMDB API key | 93 |
| `lib/xtream.dart` | Xtream Codes client | 260 |
| `lib/models.dart` | Data models | 261 |
| `lib/store.dart` | Credential persistence | 87 |
| `lib/theme.dart` | Dark/light theme | 210 |
| `pubspec.yaml` | Dependencies & metadata | 107 |
| `windows/runner/Runner.rc` | Windows .exe metadata (version, company) | |
| `windows/runner/main.cpp` | Windows entry point | |
| `windows/CMakeLists.txt` | Windows build config | 89 |
| `windows/runner/CMakeLists.txt` | Runner build config | 34 |
| `analysis_options.yaml` | Dart lint rules | |

---

## How to Build the .exe (Windows)

### Build Prerequisites (developer only — end users do NOT need these)

- Flutter SDK 3.44.6+ installed at `C:\flutter`
- Windows 10/11 with Visual Studio 2022 (C++ tools)

> **End users only need the built `Release\` folder** — `lumen_tv.exe` + DLLs. No SDK, no Visual Studio required to run it.

### Build Commands

```powershell
# 1. Clean previous build
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build Windows release .exe
flutter build windows --release

# 4. Output location
#    build\windows\x64\runner\Release\lumen_tv.exe
#    + all required DLLs in same folder
```

### Common Modifications

**Change TMDB API Key** (`lib/tmdb.dart`):
```dart
// Find: static const apiKey = '...';
static const apiKey = 'YOUR_NEW_KEY';
```

**Change Port Hint** (`lib/screens/login_screen.dart`):
```dart
// Look for port hint text or default port value
// Current: 3550
```

**Change App Name / Company / Version** (`windows/runner/Runner.rc`):
```rc
// VS_VERSION_INFO block — change CompanyName, FileVersion, ProductName, etc.
```

**Change App Icon** (`windows/runner/resources/app_icon.ico`):
Replace `windows/runner/resources/app_icon.ico` with your own `.ico` file.

---

## Full Build Workflow

```powershell
# === SET UP ===
# Verify Flutter installation
flutter --version

# Check Windows build tools
flutter config --list

# Build for the first time (downloads dependencies + native libs)
flutter pub get

# === DEVELOPMENT ===
# Run in debug mode (hot-reload enabled)
flutter run -d windows

# === RELEASE BUILD ===
flutter clean
flutter pub get
flutter build windows --release

# === OUTPUT ===
# Copy this folder for distribution:
copy-item -recurse build\windows\x64\runner\Release\ .\dist\
```

---

## Distribution Notes (for end users)

- **No Flutter SDK or Visual Studio needed** — just download the `Release\` folder and run `lumen_tv.exe`.
- The `.exe` is a **stub** (~93 KB); all logic is in `app.so` + Dart code.
- **Required files** alongside `lumen_tv.exe`:
  - `flutter_windows.dll`
  - `libmpv-2.dll` (media playback engine)
  - `data/app.so` (compiled Dart code)
  - `data/flutter_assets/` (fonts, assets, shaders)
  - `data/icudtl.dat` (Unicode data)
  - Plugin DLLs: `flutter_secure_storage_windows_plugin.dll`, `media_kit_*_plugin.dll`, `window_manager_plugin.dll`, etc.
  - ANGLE/vulkan: `d3dcompiler_47.dll`, `libEGL.dll`, `libGLESv2.dll`, `vk_swiftshader.dll`, `vulkan-1.dll`, `zlib.dll`
- Distribute the **entire `Release\` folder** — the exe will not work without these DLLs.
- No MSI/setup is built unless explicitly configured.

---

## File-by-File Role Summary

### `lib/` — Dart Source
- **`main.dart`**: App bootstrap, theme setup, login gate
- **`tmdb.dart`**: TMDB API configuration (key, base URL, image paths)
- **`xtream.dart`**: Xtream Codes API (live, VOD, series)
- **`models.dart`**: All data classes (Credentials, Category, MediaItem, etc.)
- **`store.dart`**: Credential persistence via `flutter_secure_storage`
- **`theme.dart`**: Theme controller, palette definitions, accent colors
- **`playback.dart`**: Media player (mpv) controller
- **`widgets.dart`**: Shared UI widgets
- **`catalog_cache.dart`**: In-memory catalog cache
- **`epg_cache.dart`**: EPG data cache
- **`downloads.dart`**: Download manager
- **`library.dart`**: User's library (favorites/my list)

### `screens/` — UI Views
- **`login_screen.dart`**: Credentials entry form
- **`shell.dart`**: Post-login navigation shell
- **`home_screen.dart`**: Main home page
- **`player_host.dart`**: Video player overlay
- **`movie_detail_screen.dart`**: Movie details + TMDB info
- **`series_detail_screen.dart`**: Series details + episodes
- **`search_screen.dart`**: Search across catalog
- **`epg_guide_screen.dart`**: TV guide / EPG grid
- **`guide_screen.dart`**: Channel guide
- **`profile_screen.dart`**: User profile / settings
- **`category_sheet.dart`**: Category picker bottom sheet
- **`downloads_screen.dart`**: Downloaded content
- **`mylist_screen.dart`**: User's favorites
- **`globe_screen.dart`**: Channel globe viewer
- **`split_picker.dart`**: Multi-view split picker
- **`swipe_screen.dart`**: Swipe-based browsing
- **`stats_screen.dart`**: Watch statistics
- **`customize_home_screen.dart`**: Home page layout customization
- **`update_dialog.dart`**: Update notification dialog

### `windows/` — Windows Platform
- **`CMakeLists.txt`**: Top-level CMake config
- **`runner/CMakeLists.txt`**: Runner executable build rules
- **`runner/main.cpp`**: Windows WinMain entry point
- **`runner/Runner.rc`**: Version info, icon resources
- **`runner/resources/app_icon.ico`**: App icon asset
- **`runner/win32_window.cpp`**: Win32 window management
- **`runner/flutter_window.cpp`**: Flutter window integration
- **`runner/utils.cpp`**: Utility functions

---

## Quick Reference

```powershell
# Build
flutter clean
flutter pub get
flutter build windows --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Output dir
build\windows\x64\runner\Release\
```
