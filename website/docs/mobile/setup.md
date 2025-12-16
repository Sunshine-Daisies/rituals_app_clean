---
sidebar_position: 1
---

# Setup & Installation

This guide covers the complete setup process for the Flutter mobile application.

## Prerequisites

Before you begin, ensure you have the following installed:

*   **Flutter SDK** (v3.22 or higher) - [Install Guide](https://docs.flutter.dev/get-started/install)
*   **Dart SDK** (Included with Flutter)
*   **IDE:** VS Code (Recommended) or Android Studio
*   **Android Toolchain:** Android Studio with SDK Command-line Tools
*   **iOS Toolchain:** Xcode (macOS only)

## Installation Steps

### 1. Clone & Navigate
Open your terminal and navigate to the project root (where `pubspec.yaml` is located).

```bash
cd rituals_app
```

### 2. Install Dependencies
Fetch all the required packages listed in `pubspec.yaml`.

```bash
flutter pub get
```

### 3. Environment Configuration (.env) ⚙️

The app uses `flutter_dotenv` to manage environment variables. You **must** create a `.env` file in the root directory.

1.  Create a file named `.env` in the root folder.
2.  Add the `API_URL` variable. The value depends on where you are running the app:

**Option A: Android Emulator**
Android Emulator sees `localhost` as `10.0.2.2`.
```env
API_URL=http://10.0.2.2:3001/api
```

**Option B: iOS Simulator**
iOS Simulator shares the network with the host machine.
```env
API_URL=http://localhost:3001/api
```

**Option C: Physical Device**
Use your computer's local IP address. Ensure both devices are on the same Wi-Fi.
```env
API_URL=http://192.168.1.X:3001/api
```

### 4. Firebase Configuration 🔥

This app uses Firebase for Authentication and Push Notifications.

*   **Android:**
    *   Download `google-services.json` from the Firebase Console.
    *   Place it in: `android/app/google-services.json`.

*   **iOS:**
    *   Download `GoogleService-Info.plist`.
    *   Place it in: `ios/Runner/GoogleService-Info.plist`.

## Running the App

### Start via Terminal
```bash
flutter run
```

### Start via VS Code
1.  Open the `main.dart` file.
2.  Press `F5` or go to **Run > Start Debugging**.

## Troubleshooting

### 🔴 Connection Refused (SocketException)
*   **Cause:** The app cannot reach the backend server.
*   **Fix:**
    *   Ensure the backend is running (`npm run dev` in `backend/`).
    *   Check your `.env` file. If using Android Emulator, use `10.0.2.2`, not `localhost`.
    *   If using a physical device, ensure your firewall allows connections to port `3001`.

### 🔴 Gradle Errors
*   **Fix:** Clean the build cache.
    ```bash
    flutter clean
    flutter pub get
    cd android
    ./gradlew clean
    cd ..
    flutter run
    ```

### 🔴 CocoaPods Errors (iOS)
*   **Fix:** Reinstall pods.
    ```bash
    cd ios
    rm -rf Pods
    rm Podfile.lock
    pod install
    cd ..
    ```
