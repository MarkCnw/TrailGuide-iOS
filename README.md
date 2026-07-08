<p align="center">
  <img width="200" alt="TrailGuide Logo" src="https://github.com/user-attachments/assets/d141d71f-eb0b-4de7-8a4c-b0db04ce7627" />
</p>

<h1 align="center">
  TrailGuide: Solo Hike & Backtrack Navigation
</h1>

<p align="center">
  <strong>A Native iOS application for solo hikers, featuring smart route tracking and an intelligent backtrack navigation system, even without cell service.</strong>
</p>

<p align="center">
  Designed with an <strong>Offline-First</strong> and <strong>Privacy-First</strong> approach. All trip data is processed and stored locally on the device (<strong>100% On-Device</strong>), requiring no external servers or internet connection.
</p>

<p align="center">
  <img alt="iOS" src="https://img.shields.io/badge/iOS-17.0+-black?logo=apple">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9+-orange?logo=swift">
  <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-blue?logo=swift">
  <img alt="Architecture" src="https://img.shields.io/badge/Architecture-Clean_Architecture-4CAF50">
  <img alt="MVVM" src="https://img.shields.io/badge/Pattern-MVVM-purple">
  <img alt="MapKit" src="https://img.shields.io/badge/Map-MapKit-success">
  <img alt="SwiftData" src="https://img.shields.io/badge/Database-SwiftData-red">
</p>

---

# 📖 Project Overview

TrailGuide is an iOS application developed with **Swift** and **SwiftUI** to enhance the safety of solo hikers navigating through areas with no cellular coverage.

The system acts as a **Digital Breadcrumb**, continuously recording GPS locations in the background while passing the data through a noise-reduction pipeline to generate the most accurate trail possible.

When it's time to head back, the app automatically generates a **Backtrack Navigation** route from your recorded data and tracks your position in real-time. If you wander off the safe path, the system issues immediate warnings via on-screen banners and Text-to-Speech (TTS) voice alerts.

All trip records, including paths, distances, and durations, are securely stored inside the device using **SwiftData**, ensuring full offline capability and absolute data privacy.

---

# ✨ Core Capabilities

- 🗺️ Real-time route tracking utilizing MapKit and CoreLocation.
- 🎯 Multi-stage GPS noise reduction pipeline for high-precision mapping.
- ↩️ Automatic generation of backtrack navigation routes.
- 🚨 Real-time off-route detection using cross-track distance math.
- 🗣️ Immediate alerts via Text-to-Speech (TTS) and UI banners.
- 🔋 Dynamic GPS accuracy adjustment for battery optimization.
- 🏛️ Highly maintainable codebase built on Clean Architecture and MVVM.

---

# 🚀 App Previews

## 📍 Smart Route Tracking
While hiking, the system continuously records your GPS coordinates. It filters out anomalies, jitters, and stationary noise in the background to draw a smooth and highly accurate trail.

<p align="center">
  <img width="250" alt="Smart Route Tracking" src="https://github.com/user-attachments/assets/abd8ef9c-b05a-4efb-99ea-a11d7c0624d0" />
</p>

---

## ↩️ Backtrack Navigation
When returning, the system simplifies your raw path into clean waypoints (Path Simplification), drawing a dashed guide line on the map to help you navigate back to your starting point effortlessly.

<p align="center">
  <img width="250" alt="Backtrack Navigation" src="https://github.com/user-attachments/assets/d6f6dda6-4b07-4324-a9bc-21110feed802" />
</p>

---

## 🚨 Off-Route Detection & Voice Alert
If you deviate beyond a safe distance from your backtrack route, a red warning banner appears instantly, and the app speaks out loud via Text-to-Speech to guide you back on track.

<p align="center">
  <img width="250" alt="Off-Route Detection" src="https://github.com/user-attachments/assets/ce730205-63dc-4d07-b946-1a1381a9a75b" />
</p>

---

## 🗺️ Trip History
Upon ending the hike, your total distance, duration, and the precise route polyline are automatically saved into the local SwiftData database, allowing you to review your past adventures anytime.

<p align="center">
  <img width="230" alt="Trip History 1" src="https://github.com/user-attachments/assets/9c98824e-d833-4add-8f7b-e0227a231368" />
  &nbsp; &nbsp;
  <img width="230" alt="Trip History 2" src="https://github.com/user-attachments/assets/76c0c3b2-308a-43d6-ae75-3c699a1771d6" />
  &nbsp; &nbsp;
  <img width="230" alt="Trip History 3" src="https://github.com/user-attachments/assets/59a2ab48-b881-487a-9c34-e8bc72d5270b" />
</p>

---

# 🌟 Key Features

| Feature | Description |
|----------|-------------|
| 🗺️ Smart Route Tracking | Real-time trail recording using MapKit and CoreLocation |
| ↩️ Backtrack Navigation | Automatically generates a return route from recorded data |
| 🎯 GPS Noise Reduction | Multi-stage GPS signal filtering to enhance path accuracy |
| ⚠️ Off-Route Detection | Detects route deviation and alerts the user immediately |
| 🗣️ Voice & Banner Alert | Delivers warnings via TTS and UI notification banners |
| 🔋 Battery Optimization | Dynamically adjusts GPS accuracy to reduce battery consumption |
| 💾 On-Device Storage | Safely stores all trip data locally using SwiftData |

---

# 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Swift |
| UI Framework | SwiftUI |
| Architecture | Clean Architecture + MVVM |
| Database | SwiftData |
| Map | MapKit |
| Location | CoreLocation |
| Audio | AVFoundation (AVSpeechSynthesizer) |
| Notifications | UserNotifications |
| Reactive | Combine |

---

# 🏛️ System Architecture

TrailGuide is engineered with **Clean Architecture** and the **MVVM** pattern, ensuring clear separation between the Presentation, Domain, and Data layers. This makes the system scalable, testable, and highly maintainable.

## Architecture Diagram

```text
                 SwiftUI Views
                       │
                       ▼
             ViewModels (@Observable)
                       │
                       ▼
                 Domain Use Cases
      (e.g., SaveTripUseCase, LocationCalculator)
                       │
                       ▼
             Repository Interfaces
           ┌───────────┴───────────┐
           ▼                       ▼
   Location Repository     TripHistory Repository
           │                       │
           ▼                       ▼
 CoreLocation Manager        SwiftData Context
      (Data Source)             (Data Source)
```

---

# 📂 Project Structure

```text
TrailGuide
│
├── App                 # App Entry Point & DI Container
├── Core                # Utilities & Math formulas (LocationCalculator)
├── Data
│   ├── DataSources     # LocationManager, LocalNotificationService
│   ├── Models          # SwiftData Schemas (TripHistoryModel)
│   └── Repositories    # Implementation of Repository Interfaces
├── Domain
│   ├── Entities        # Business Models (TripHistory, UserProfileEntity)
│   ├── Interfaces      # Repository Protocols
│   └── UseCases        # SaveTripUseCase, GetAllTripsUseCase, etc.
└── Presentation
    ├── Common          # Custom Alerts, Shared UI Components
    └── Features
        ├── Breadcrumb  # Solo Hike tracking, Map UI, and Backtrack
        └── History     # Trip history lists and detailed views
```

| Folder | Responsibility |
|----------|---------|
| App | Application entry point and Dependency Injection container. |
| Core | Centralized utilities and complex mathematical functions. |
| Data | Data management layer including Data Sources, Models, and Repositories. |
| Domain | Core business logic encompassing Entities and Use Cases. |
| Presentation | User interface layer containing SwiftUI Views and ViewModels. |

---

# 🔄 GPS Processing Pipeline

A robust pipeline is implemented in `LocationRepositoryImpl` to filter raw GPS data before rendering, preventing zigzag jumps or track overlapping in dense forests:

```text
📡 CoreLocation (Fetches raw GPS from hardware)
      │
      ▼
🎯 Accuracy Filter (Drops coordinates if horizontal accuracy > 35m)
      │
      ▼
🛑 Stationary Detection (Pauses recording if speed < 0.5 m/s for over 30s)
      │
      ▼
🚀 Speed Anomaly Detection (Drops points if hiking speed exceeds 15 km/h)
      │
      ▼
📏 Distance Filter (Records next point only if moved > 10m from the last point)
      │
      ▼
📈 Moving Average Smoothing (Averages the last 2 points to smooth the trail)
      │
      ▼
🗺️ MapKit Polyline Rendering (Draws the refined, smooth path on the map)
```

---

# ⚙️ Development Challenges

| Challenge | Solution | Result |
|------------|-----------|----------|
| **GPS Jitter & Inaccuracy** | Developed a multi-stage signal filtering pipeline and applied Moving Average Smoothing. | The path rendered on the map is exceptionally smooth and accurate, eliminating zigzag jumps. |
| **Cluttered Backtrack Route** | Utilized `LocationCalculator.simplifyPath` to filter out turns with bearing changes under 30°. | Significantly reduced unnecessary waypoints, making backtrack navigation easier to read and faster to process. |
| **Off-Route Detection Accuracy** | Calculated Cross-Track Distance between the user's location and the main trail line. | Precisely alerts the user immediately when they stray more than 5 meters from the original path. |
| **High Battery Consumption** | Dynamically toggled `CLLocationManager` modes (Battery Saving for normal hiking / High Accuracy for backtracking). | Conserved battery life during normal use while ensuring maximum safety during backtrack navigation. |

---

# 🚀 Installation

```bash
git clone [https://github.com/MarkCnw/TrailGuide-iOS.git](https://github.com/MarkCnw/TrailGuide-iOS.git)
cd TrailGuide-iOS
open TrailGuide.xcodeproj
```
