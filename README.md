# GPS Speedometer & Trip Analysis App

A production-ready Flutter application for tracking real-time speed, recording trips, and analyzing driving data. Built with Vertical Slice Architecture and Clean Architecture principles.

## 🚀 Current Features

*   **Real-time GPS Tracking:** Monitor live speed, maximum speed, average speed, and distance traveled.
*   **Trip Recording:** Start, stop, and save trips. The app logs location points continuously during an active trip.
*   **Trip Analysis:** View historical trips with detailed metrics (duration, distance, top speed, average speed).
*   **Local Persistence:** Robust, offline-first data storage using **Drift (SQLite)**.
*   **Settings Management:** Customizable preferences (e.g., speed units).
*   **State Management:** Reactive clean UI powered by **GetX**.

## 🛠️ Missing Features (Planned Additions)

The following features are planned for future development to make this an ultimate driving companion app:

*   **🗺️ Map Integration & Route Playback:** Visualize live trips on a map (using `flutter_map`) and replay previous routes with polyline drawing.
*   **📹 Dashcam Video Overlay:** Record video using the device camera with real-time speed, location, and timestamp watermarks overlaid on the footage.
*   **📁 GPX Export & Import:** Export recorded trips to standard `.gpx` format for use in other GIS tools, and import existing GPX files.
*   **🪞 HUD (Head-Up Display) Mode:** A mirrored UI mode designed to be reflected on the car's windshield for safe night driving.
*   **🔋 Background Location Tracking:** Continue to record trip data seamlessly even when the app is in the background or the screen is locked.
*   **⚠️ Speed Limit Alerts:** Configurable audio and visual warnings when exceeding predefined speed limits.

## 🏗️ Technical Stack

*   **Framework:** Flutter (Dart)
*   **Architecture:** Vertical Slice Architecture + Clean Architecture
*   **State Management & Routing:** GetX
*   **Database:** Drift (SQLite)
*   **Location:** Geolocator

## 🏃 Getting Started

1.  Ensure you have **FVM** (Flutter Version Management) installed.
2.  Run `fvm flutter pub get` to fetch dependencies.
3.  Run `fvm dart run build_runner build --delete-conflicting-outputs` to generate Drift database files.
4.  Run `fvm flutter run` to start the app.
