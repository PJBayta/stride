# stride

Stride is a lightweight, offline-first fitness tracking application built with Flutter. It is inspired by Strava but focuses on simplicity, speed, and privacy instead of social networking.

The goal of Stride is to provide a fast and reliable activity tracker that performs well on low-end Android devices while keeping the user experience clean and distraction-free.

---

## Project Vision

Stride is designed around the following principles:

- 🚀 Performance-first
- 📱 Offline-first
- 🔒 Privacy-first
- 🎯 Minimalist user experience
- 🔋 Battery efficient
- 🗺️ Reliable GPS tracking

Unlike Strava, Stride intentionally excludes social networking features, allowing users to focus solely on tracking their activities.

---

## MVP Features

The first version of Stride includes:

- 🏠 Home
- 🏃 Activity Tracking (GPS, timer, distance, speed, pace)
- 📊 Activity Summary
- 📜 Activity History
- 👤 Profile Statistics
- ⚙️ Settings

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter | Cross-platform mobile development |
| Dart | Programming language |
| Riverpod | State management |
| Drift (SQLite) | Local database |
| flutter_map | Interactive maps |
| OpenStreetMap | Map provider |
| geolocator | GPS location services |
| shared_preferences | Local settings storage |

---

## Project Structure

```
lib/
├── core/
├── features/
├── database/
├── models/
├── providers/
├── services/
├── widgets/
└── main.dart
```

Detailed documentation is available in the `docs/` directory.

---

## Development Status

🚧 Currently in development

Current phase:
- Project setup
- UI implementation
- Flutter architecture

Upcoming phases:
- Local database
- GPS tracking
- Activity recording
- Statistics
- Settings

---

## Roadmap

Version 1.0 (MVP)

- Offline activity tracking
- Local SQLite storage
- Activity history
- Personal statistics
- Material Design 3 interface

Future versions may include:

- Cloud synchronization
- User authentication
- Personal records
- Goals and achievements
- Wearable device integration

---

## License

This project is currently under development and has no official license assigned.
