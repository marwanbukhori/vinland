# Engage360 - Complete Setup Guide

This guide details exactly how to set up the **Engage360** project from scratch, assuming a fresh machine. Follow these steps to get the app running on an Android Emulator.

---

## 1. Prerequisites Setup

Before cloning the code, ensure you have the necessary tools installed.

### A. Install Git
- **Mac**: `brew install git` (if using Homebrew) or download from [git-scm.com](https://git-scm.com/).
- **Verify**: Run `git --version` in terminal.

### B. Install Flutter SDK
1. Download the Flutter SDK for your OS from [flutter.dev](https://docs.flutter.dev/get-started/install).
2. Extract the file and update your `PATH` variable.
3. **Verify**: Run `flutter doctor`. It will tell you what else is missing.

### C. Install Android Studio
1. Download & Install [Android Studio](https://developer.android.com/studio).
2. Open Android Studio. Go to **Settings/Preferences** -> **Languages & Frameworks** -> **Android SDK**.
3. Under **SDK Platforms**, check **Android 14 (API 34)** or **Android 15 (API 35)** and click Apply to download.
4. Under **SDK Tools**, check **Android SDK Command-line Tools (latest)** and click Apply.
5. **Verify**: Run `flutter doctor` again. Accept licenses if prompted (`flutter doctor --android-licenses`).

### D. Install Node.js & Firebase CLI
1. Download Node.js from [nodejs.org](https://nodejs.org/) (LTS version).
2. Install Firebase CLI globally:
   ```bash
   npm install -g firebase-tools
   ```
3. Login to Firebase:
   ```bash
   firebase login
   ```

---

## 2. Setting Up the Project

### A. Clone the Repository
Open your terminal and navigate to your desired folder:
```bash
# Navigate to your workspace
cd ~/Documents/2030

# Clone the repository
git clone <YOUR_REPO_URL> engage360

# Enter the directory
cd engage360
```

### B. Install Dependencies
Download all the Flutter packages used in the project:
```bash
flutter pub get
```

---

## 3. Firebase Configuration

This app relies on Firebase for Auth and Database. You must link it to your Firebase project.

### A. Initialize FlutterFire
1. Install the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. Configure the project (Select your Firebase project, e.g., `engage360-fd4fa`):
   ```bash
   flutterfire configure --project=engage360-fd4fa --platforms=android,ios
   ```
   *Note: This will generate `lib/firebase_options.dart`.*

### B. Deploy Security Rules
The app enforces security rules for features like Self Check-in. You **must** deploy these rules:
```bash
firebase deploy --only firestore:rules
```

---

## 4. Setting Up Android Emulator

To run the app, you need a virtual device.

1. Open **Android Studio**.
2. Click on the **Device Manager** icon (Phone icon) in the toolbar, or go to `Tools > Device Manager`.
3. Click **Create Device (+)**.
4. **Select Hardware**: Choose **Pixel 8** or **Pixel 9** (Screen size is standard). Click Next.
5. **System Image**: 
   - Choose a Release Name (e.g., **VanillaIceCream** or **UpsideDownCake**).
   - Click the **Download** icon next to it if not installed.
   - Once downloaded, select it and click Next.
6. **AVD Name**: Give it a simple name (e.g., "Pixel 9 API 35").
7. Click **Finish**.
8. **Launch**: Click the **Play** (▶) button in Device Manager to launch the emulator.

---

## 5. Running the App

Once the Emulator is up and running on your screen:

1. Return to your terminal (ensure you are inside `engage360` folder).
2. Run the application:
   ```bash
   flutter run
   ```
   
   *Tip: If you have multiple devices connected, run `flutter devices` to get the Device ID, then run `flutter run -d <DEVICE_ID>`.*

3. **Hot Reload**: When you make code changes, press `r` in the terminal to instantly update the UI.
4. **Hot Restart**: Press `R` (Shift+r) to restart the app state completely.

---

## Common Issues & Fixes

- **"GeneratedAppGlideModule not found"**: Run `flutter clean` then `flutter pub get`.
- **"Permission Denied" in Firestore**: Ensure you ran the `firebase deploy` step above.
- **Gradle Errors**: Ensure your Java version matches. Run `flutter doctor -v` to check the Java bundled with Android Studio.

---

**Setup Complete!** You are now ready to develop on Engage360.
