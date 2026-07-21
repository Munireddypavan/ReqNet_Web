<div align="center">

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:00F7F7,100:7B42F6&height=180&section=header&text=ResQNet&fontSize=80&fontColor=fff&animation=twinkling&fontAlignY=38&desc=Offline%20Mesh%20Communication%20for%20Emergencies&descAlignY=60&descSize=18&descColor=ccf"/>

<br>

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-In%20Progress-orange?style=for-the-badge"/>
<img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge"/>

<br><br>

> **ResQNet** is an offline-first, peer-to-peer mesh communication app built for disaster and emergency scenarios where internet connectivity is unavailable. It uses Bluetooth and WiFi Direct (via Google's Nearby Connections API) to form a decentralized mesh network between nearby Android devices — no internet, no towers, no infrastructure needed.

<br>

<img src="https://user-images.githubusercontent.com/74038190/212284100-561aa473-3905-4a80-b561-0d28506553ee.gif" width="100%">

</div>

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [🏗️ Architecture](#-architecture)
- [📸 Screenshots](#-screenshots)
- [⚙️ Prerequisites](#-prerequisites)
- [💻 Setup on PC (Development)](#-setup-on-pc-development)
- [📱 Install on Android Device](#-install-on-android-device)
- [🔑 Permissions Required](#-permissions-required)
- [📦 Dependencies](#-dependencies)
- [🗂️ Project Structure](#-project-structure)
- [🚧 Known Issues](#-known-issues)
- [🤝 Contributing](#-contributing)

---

## ✨ Features

| Feature | Description | Status |
|:---|:---|:---:|
| 📶 Mesh Networking | Bluetooth + WiFi Direct device discovery & connection | ✅ Done |
| 🗺️ Live Node Map | Real-time visual map of connected devices in the mesh | ✅ Done |
| 📢 Emergency Broadcasts | Send broadcast messages to all nearby nodes | ✅ Done |
| 💬 P2P Chat | Direct encrypted messaging between mesh peers | 🔧 In Progress |
| 🔗 Multi-hop Routing | Route messages through intermediate nodes (mesh relay) | 🔧 In Progress |
| 🔒 Encryption | End-to-end encrypted messages using AES | ✅ Done |
| 💾 Offline Storage | Local SQLite database to persist messages and node data | ✅ Done |
| 📡 Auto-scan | Automatic periodic re-discovery of nearby devices | ✅ Done |

---

## 🏗️ Architecture

```
ResQNet
├── lib/
│   ├── main.dart                  # App entry point, provider setup
│   ├── theme.dart                 # Global theme & color system
│   ├── screens/
│   │   ├── main_scaffold.dart     # Bottom nav & screen switching
│   │   ├── map_screen.dart        # Live node map view
│   │   ├── chats_screen.dart      # P2P chat list
│   │   ├── broadcast_screen.dart  # Emergency broadcast UI
│   │   └── status_screen.dart     # Network & device status
│   ├── providers/
│   │   ├── mesh_provider.dart     # Mesh network state management
│   │   └── chat_provider.dart     # Chat state management
│   └── services/
│       ├── mesh_network_manager.dart  # Nearby Connections API wrapper
│       ├── mesh_router.dart           # Multi-hop message routing logic
│       ├── mesh_database.dart         # SQLite database service
│       └── hardware_service.dart      # Device hardware info
```

**Tech Stack:**
- **Framework:** Flutter (Dart)
- **Mesh Networking:** Google Nearby Connections API
- **Local DB:** SQLite via `sqflite`
- **State Management:** Provider
- **Encryption:** AES via `encrypt` package
- **Hardware:** `flutter_blue_plus`, `device_info_plus`, `connectivity_plus`

---

## 📸 Screenshots

> *(Screenshots coming soon)*

---

## ⚙️ Prerequisites

Before setting up, make sure you have the following installed:

### On Your PC

| Tool | Version | Download |
|:---|:---|:---|
| Flutter SDK | >= 3.0.0 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | Included with Flutter | — |
| Android Studio | Latest | [developer.android.com](https://developer.android.com/studio) |
| Android SDK | API Level 21+ | Via Android Studio |
| Git | Any | [git-scm.com](https://git-scm.com/) |
| Java JDK | 17+ | [adoptium.net](https://adoptium.net/) |

### On Your Android Device

- Android **6.0 (API 23) or higher**
- Bluetooth & Location enabled
- WiFi enabled (for WiFi Direct)
- USB Debugging enabled (for development installs)

---

## 💻 Setup on PC (Development)

### Step 1 — Clone the Repository


### Step 2 — Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3 — Verify Flutter Setup

```bash
flutter doctor
```
Make sure the Android toolchain shows no critical errors. Accept Android licenses if prompted:
```bash
flutter doctor --android-licenses
```

### Step 4 — Connect Your Android Device

1. Enable **Developer Options** on your phone:  
   Go to `Settings → About Phone → tap "Build Number" 7 times`
2. Enable **USB Debugging** in Developer Options
3. Connect your phone via USB
4. Verify it's detected:
   ```bash
   flutter devices
   ```
   Your device should appear in the list.

### Step 5 — Run the App

```bash
flutter run
```

To run on a specific device if multiple are connected:
```bash
flutter run -d <device-id>
```

> ⚡ The first build may take **2–5 minutes** as Gradle downloads dependencies. Subsequent builds are much faster.

---

## 📱 Install on Android Device

2. On your Android device, go to `Settings → Security → Enable "Install from Unknown Sources"`
3. Open the downloaded APK and tap **Install**
4. Grant all required permissions when prompted

### Option B — Build APK from Source


Transfer `app-release.apk` to your phone and install it.

### Option C — Run Directly via USB (Development)

Follow the [Setup on PC](#-setup-on-pc-development) guide above and use `flutter run`.

---

## 🔑 Permissions Required

ResQNet requires the following Android permissions:

| Permission | Reason |
|:---|:---|
| `BLUETOOTH` / `BLUETOOTH_ADMIN` | Discover and connect to nearby devices |
| `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` / `BLUETOOTH_ADVERTISE` | Required for Android 12+ BLE |
| `ACCESS_FINE_LOCATION` | Required by Android for Bluetooth scanning |
| `ACCESS_COARSE_LOCATION` | Fallback location for peer discovery |
| `NEARBY_WIFI_DEVICES` | WiFi Direct peer-to-peer communication |
| `CHANGE_WIFI_STATE` / `ACCESS_WIFI_STATE` | Manage WiFi for mesh networking |
| `READ_EXTERNAL_STORAGE` | (If file sharing is added in future) |

> All permissions are requested at runtime when you first launch the app.

---

## 📦 Dependencies

| Package | Purpose |
|:---|:---|
| `nearby_connections` | Google Nearby Connections API for mesh networking |
| `flutter_blue_plus` | Bluetooth Low Energy scanning |
| `provider` | State management |
| `sqflite` | Local SQLite database |
| `path_provider` | File system access for DB |
| `encrypt` | AES encryption for messages |
| `uuid` | Unique IDs for nodes and messages |
| `geolocator` | Device location (used with node mapping) |
| `device_info_plus` | Fetch device name/model |
| `connectivity_plus` | Monitor network connectivity status |
| `google_fonts` | Custom UI fonts |
| `shared_preferences` | Lightweight key-value storage |
| `intl` | Date/time formatting |
| `http` | Optional HTTP requests |

---

## 🗂️ Project Structure

```
flutter_app/
├── android/              # Android native config & permissions
├── ios/                  # iOS native config (not primary target)
├── lib/
│   ├── main.dart
│   ├── theme.dart
│   ├── screens/          # All UI screens
│   ├── providers/        # State management
│   └── services/         # Business logic & APIs
├── test/                 # Unit tests
├── pubspec.yaml          # Dependencies
└── README.md
```

---

## 🚧 Known Issues

- **OneDrive interference**: If your project folder is inside OneDrive, build files can get corrupted. Move the project to a local path like `C:\dev\ResQNet` to avoid issues.
- **First build slow**: Gradle dependencies take time on the first build — this is normal.
- **Android cmdline-tools**: If `flutter doctor` reports missing `cmdline-tools`, install it via Android Studio → SDK Manager → SDK Tools → Android SDK Command-line Tools.
- **Multi-hop messaging**: Currently in development — messages only travel one hop between directly connected peers.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your branch: `git checkout -b feature/YourFeature`
3. Commit your changes: `git commit -m "Add YourFeature"`
4. Push to the branch: `git push origin feature/YourFeature`
5. Open a Pull Request

---

<div align="center">

*Built with ❤️ for emergency resilience*

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:7B42F6,100:00F7F7&height=120&section=footer"/>

</div>
