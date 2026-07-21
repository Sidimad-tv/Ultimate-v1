# Sidimad-XtreamProv1

A native, premium **IPTV player** for your own Xtream / M3U subscription — Live TV, Movies and Series with a cinematic UI, on **iOS, Android, Android TV, macOS, Windows and Linux**.

> Bring your own provider. Sidimad-XtreamProv1 plays the IPTV service **you already pay for** — it ships with no channels or content of its own.

---

## ✨ Features

- **Live TV** with EPG (now/next), catch-up, and a polished channel guide
- **Movies & Series** with TMDB-enriched art, ratings, cast and trailers
- **Immersive home** — full-bleed spotlight hero + scrollable shelves
- **My List**, Continue Watching, Recently watched, and watch stats
- **Discover globe**, search with sort/filter, multi-profile
- **Premium player** — A/V track & subtitle controls, subtitle styling & sync,
  speed, sleep timer, picture-in-picture mini-player, hold-for-2×
- **TV remote / D-pad** navigation on Android TV (focus highlights, direct transport)
- **Desktop-native** layout (sidebar, keyboard shortcuts, real fullscreen)
- **M3U / playlist URL** login with local file support
- **Saved playlists** quick-switch dropdown
- **Offline downloads** for movies & series episodes (pause/resume/queue)
- **Auto-reconnect** on stream drop with exponential back-off
- **Customizable accent colour** (presets + custom colour wheel)
- **Dark / Light / System** theme support
- **Split-screen** — watch two streams at once
- **In-app updates** — check for newer builds from the Profile screen

## 🛠️ Tech

Flutter • [media_kit](https://pub.dev/packages/media_kit) (libmpv) for native MKV/TS/HLS playback • Xtream Codes API • TMDB metadata • M3U/XMLTV support.

## 🤖 Build locally

```bash
flutter pub get
flutter run                       # current device
flutter build apk --release       # Android
flutter build macos --release     # macOS
flutter build windows --release   # Windows (on Windows)
flutter build linux --release     # Linux
```

## 📄 License

MIT © Sidimad. This is a player only and includes no content; you are responsible for the sources you add.
