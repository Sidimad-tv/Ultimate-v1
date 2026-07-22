# Sidimad-XtreamProv1 — Windows EXE Build Guide

Complete reference for building, rebuilding, cleaning, and distributing the Windows desktop executable.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Project Structure — Windows](#2-project-structure--windows)
3. [Key Config Files](#3-key-config-files)
4. [Build Commands](#4-build-commands)
5. [Output Location](#5-output-location)
6. [Dart Source Files](#6-dart-source-files)
7. [Windows Native Files](#7-windows-native-files)
8. [Asset Files](#8-asset-files)
9. [CI/CD — GitHub Actions](#9-cicd--github-actions)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Prerequisites

| Tool | Version | Path / Install |
|------|---------|----------------|
| Flutter SDK | 3.44.6+ | `C:\Program Files\flutter\bin\flutter.bat` |
| Visual Studio 2022 | With "Desktop development with C++" workload | Required by `flutter build windows` |
| CMake | 3.14+ (bundled with VS) | `C:\Program Files\Microsoft Visual Studio\...\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin` |
| Git | 2.x+ | `C:\Program Files\Git\bin\git.exe` |

### Verify prerequisites

```powershell
flutter doctor -v
```

Look for `[✓] Flutter (Channel stable, 3.44.6, ...)` and `[✓] Visual Studio - develop Windows apps`.

---

## 2. Project Structure — Windows

```
windows/
├── .gitignore
├── CMakeLists.txt                          # Root CMake — sets BINARY_NAME, install rules
├── flutter/
│   ├── CMakeLists.txt                      # Flutter-managed CMake
│   ├── generated_plugins.cmake             # Auto-generated plugin list
│   ├── generated_plugin_registrant.cc      # Auto-generated plugin registration (C++)
│   └── generated_plugin_registrant.h       # Auto-generated plugin header
└── runner/
    ├── CMakeLists.txt                      # Runner CMake — compiles .cpp/.rc into exe
    ├── flutter_window.cpp                  # Flutter window host (Dart-embedding HWND)
    ├── flutter_window.h
    ├── main.cpp                            # WinMain entry point — creates window, runs Flutter
    ├── resource.h
    ├── resources/
    │   └── app_icon.ico                    # Windows taskbar / explorer icon
    ├── Runner.rc                           # Windows resource file (icon, version info, metadata)
    ├── runner.exe.manifest                 # App manifest (DPI awareness, COM, etc.)
    ├── utils.cpp                           # HWND / COM helper utilities
    ├── utils.h
    ├── win32_window.cpp                    # Win32 window creation / message loop
    └── win32_window.h
```

**Build output directory:**
```
build/windows/x64/runner/Release/
├── Sidimad-XtreamProv1.exe                # Main executable
├── flutter_windows.dll                    # Flutter engine
├── flutter_assets/                        # Compiled Dart code + assets
│   ├── kernel_blob.bin
│   ├── assets/
│   │   └── lumen_loader.json              # Lottie animation
│   └── ...
├── *.dll                                  # Plugin native libraries (media_kit, mpv, etc.)
└── data/
    └── icudtl.dat                         # ICU data
```

---

## 3. Key Config Files

### `windows/CMakeLists.txt` (root)

Controls:
- **BINARY_NAME** — set to `"Sidimad-XtreamProv1"` (line 6)
- C++ standard: C++17
- Install targets: exe, ICU data, Flutter assets, AOT library
- Plugin bundled libraries

### `windows/runner/CMakeLists.txt`

Compiles:
- `flutter_window.cpp` — Flutter engine host
- `main.cpp` — WinMain entry point
- `utils.cpp` — HWND/COM helpers
- `win32_window.cpp` — Win32 window wrapper
- `Runner.rc` — Version info + icon reference
- `runner.exe.manifest` — Windows manifest
- Links: `flutter.dll`, `flutter_wrapper_app`, `dwmapi.lib`

### `windows/runner/Runner.rc`

Contains:
- Windows version info (FILEVERSION, PRODUCTVERSION)
- App icon reference (`IDI_ICON1` → `app_icon.ico`)
- File description: `"Sidimad-XtreamProv1"`
- Product name: `"Sidimad-XtreamProv1"`

### `windows/runner/main.cpp`

- Creates `FlutterWindow` with title `L"Sidimad-XtreamProv1"`
- Initializes COM, sets DPI awareness
- Runs WinMain message loop

### `pubspec.yaml` (root)

```yaml
name: sidimad_xtream_prov1
version: 1.1.0+1
environment:
  sdk: ^3.10.8
```

The `version` field maps to `Runner.rc` version info and the exe's file properties.

---

## 4. Build Commands

All commands run from the project root:
```
C:\Users\SidimaD\Documents\00000-MyProje\3-TMDB-MOVIES\Sidimad-XtreamProv1
```

### First-time build

```powershell
# 1. Get dependencies
flutter pub get

# 2. Build release exe
flutter build windows --release
```

### Full rebuild (clean + build)

```powershell
flutter clean
flutter pub get
flutter build windows --release
```

### Debug build

```powershell
flutter build windows --debug
```

### Profile build (for performance profiling)

```powershell
flutter build windows --profile
```

### Quick rebuild (no clean — incremental)

```powershell
flutter build windows --release
```

CMake caches compilation. Only changed files recompile. This takes ~10-30 seconds vs ~3-5 minutes for a full build.

### Run directly without building

```powershell
flutter run -d windows
```

### All commands reference

| Command | Description | Duration |
|---------|-------------|----------|
| `flutter clean` | Deletes `build/`, `.dart_tool/`, generated files | 5s |
| `flutter pub get` | Resolves and downloads dependencies | 5-10s |
| `flutter build windows --release` | Full release build | 3-5 min (first), 10-30s (incremental) |
| `flutter build windows --debug` | Debug build with symbols | 2-3 min |
| `flutter build windows --profile` | Profile build for perf testing | 2-3 min |
| `flutter run -d windows` | Build + run in debug mode | 30-60s |
| `flutter doctor -v` | Verify SDK + toolchain | 10s |

---

## 5. Output Location

```
build/windows/x64/runner/Release/
```

To zip for distribution:

```powershell
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "Sidimad-XtreamProv1-Windows.zip"
```

The `.exe` can be run directly from the Release folder — it's self-contained (no installer needed).

---

## 6. Dart Source Files

All Dart code compiled into the Windows exe:

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
| `lib/updater.dart` | Auto-update — checks GitHub releases, downloads APK/exe |
| `lib/pip.dart` | Picture-in-Picture — platform channel to native Android/Windows PiP |
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

## 7. Windows Native Files

### C++ Source

| File | Purpose |
|------|---------|
| `windows/runner/main.cpp` | `WinMain` — COM init, DPI awareness, creates `FlutterWindow`, runs message loop |
| `windows/runner/flutter_window.cpp` | `FlutterWindow` class — hosts Flutter engine in Win32 HWND |
| `windows/runner/win32_window.cpp` | Win32 window creation, message handling, DPI scaling |
| `windows/runner/utils.cpp` | Utility functions — HWND helpers, COM string conversion |

### C++ Headers

| File | Purpose |
|------|---------|
| `windows/runner/flutter_window.h` | `FlutterWindow` class declaration |
| `windows/runner/win32_window.h` | `Win32Window` class declaration |
| `windows/runner/utils.h` | Utility function declarations |
| `windows/runner/resource.h` | Resource IDs (`IDI_ICON1`, etc.) |

### Windows Resources

| File | Purpose |
|------|---------|
| `windows/runner/Runner.rc` | Version info, icon binding, file description metadata |
| `windows/runner/runner.exe.manifest` | Windows app manifest (DPI, COM, UAC, common controls v6) |
| `windows/runner/resources/app_icon.ico` | App icon (taskbar, explorer, alt-tab) |

### Generated (auto by Flutter)

| File | Purpose |
|------|---------|
| `windows/flutter/generated_plugins.cmake` | CMake plugin list — auto-generated from `pubspec.yaml` |
| `windows/flutter/generated_plugin_registrant.cc` | Plugin registration — calls `RegisterPlugin()` for each plugin |
| `windows/flutter/generated_plugin_registrant.h` | Header for plugin registration |
| `windows/flutter/CMakeLists.txt` | Flutter-managed CMake for engine + plugins |

---

## 8. Asset Files

| File | Used In | Description |
|------|---------|-------------|
| `assets/icon/logo.png` | App icon source | Used by `flutter_launcher_icons` to generate platform icons |
| `assets/lumen_loader.json` | `pubspec.yaml` assets | Lottie animation shown during app loading |

---

## 9. CI/CD — GitHub Actions

**Workflow:** `.github/workflows/build.yml`

### Triggers
- Push to `main` branch
- Manual dispatch (`workflow_dispatch`)

### Jobs

| Job | Runner | Steps |
|-----|--------|-------|
| `build-windows` | `windows-latest` | checkout → flutter (channel: stable) → pub get → build windows --release → upload artifact |
| `build-android` | `ubuntu-latest` | checkout → Java 17 → flutter (channel: stable) → pub get → build apk --release → upload artifact |
| `release` | `ubuntu-latest` | Download both artifacts → zip Windows → rename APK → delete old release → create new GitHub Release |

### Release assets
- `Sidimad-XtreamProv1-Windows.zip` — Full Windows build folder
- `Sidimad-XtreamProv1-Android.apk` — Universal Android APK

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

## 10. Troubleshooting

### "Unable to determine Flutter version"
The `subosito/flutter-action` needs `channel: stable` without `flutter-version`. Already fixed.

### Build fails with "Visual Studio not found"
Install Visual Studio 2022 with **"Desktop development with C++"** workload.

### "Permission denied" on `flutter.bat`
Run PowerShell as Administrator, or check Windows Defender isn't blocking.

### exe won't start on another PC
The exe depends on Visual C++ Runtime. Install [VC++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist) on the target machine.

### Plugins missing from exe
Run `flutter clean` then `flutter pub get` to regenerate `generated_plugins.cmake`.

### Old exe still running
Kill it before rebuilding:
```powershell
taskkill /F /IM Sidimad-XtreamProv1.exe 2>$null
```

### Windows Firewall blocking exe
```powershell
New-NetFirewallRule -DisplayName "Sidimad-XtreamProv1" -Direction Inbound -Program "C:\...\Sidimad-XtreamProv1.exe" -Action Allow -Profile Private
New-NetFirewallRule -DisplayName "Sidimad-XtreamProv1" -Direction Outbound -Program "C:\...\Sidimad-XtreamProv1.exe" -Action Allow -Profile Private
```
