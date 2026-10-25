# 🚨 Emergency Assistance
**Mobile Application Development Lab — Mini Project**

---

## 📋 Project Overview

**Emergency Assistance** is an Android mobile application that allows a user to quickly send an SOS emergency alert to pre-saved emergency contacts along with their current GPS location. The app is designed to be fast, accessible, and usable even in high-stress situations.

---

## 🎯 Objective

To develop a beginner-friendly, fully functional emergency assistance mobile app using Flutter that demonstrates:
- Mobile UI/UX design principles
- Local data storage (SQLite + SharedPreferences)
- GPS/location services
- Permission handling
- State management
- Demo Mode for safe testing

---

## ✨ Features

| Feature | Description |
|---|---|
| **SOS Button** | Large animated red button — press and hold to activate |
| **5-Second Countdown** | Prevents accidental triggering — cancel anytime |
| **GPS Location** | Retrieves real device location on SOS activation |
| **Emergency Contacts** | Add, edit, delete, and manage contacts with SQLite |
| **SOS History** | Stores all past SOS events with date, time, location |
| **Demo Mode** | Simulates SOS without sending real SMS (on by default) |
| **Real SMS Mode** | Opens native SMS app with pre-filled emergency message |
| **Settings** | Configure countdown, demo mode, and permissions |
| **Location Screen** | View coordinates, open in Maps, share location |
| **Splash Screen** | Animated intro screen |

---

## 🛠️ Technology Used

| Technology | Purpose |
|---|---|
| **Flutter 3.x** | UI framework (cross-platform, Android) |
| **Dart** | Programming language |
| **sqflite** | Local SQLite database for contacts & SOS history |
| **shared_preferences** | User settings (countdown, demo mode) |
| **geolocator** | GPS location & permission handling |
| **url_launcher** | Open Maps, SMS app, share links |
| **intl** | Date/time formatting |
| **permission_handler** | Runtime permissions |

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry, theme, routes
├── utils/
│   └── constants.dart          # Colors, styles, strings, routes
├── models/
│   ├── contact_model.dart      # Emergency contact data model
│   └── sos_record_model.dart   # SOS history record model
├── services/
│   ├── storage_service.dart    # SQLite + SharedPreferences
│   ├── location_service.dart   # GPS + permissions
│   └── sos_service.dart        # SOS orchestration
├── widgets/
│   ├── sos_button.dart         # Animated pulsing SOS button
│   ├── countdown_overlay.dart  # Countdown screen (5→0)
│   ├── contact_card.dart       # Contact list card
│   └── history_card.dart       # SOS history card
└── screens/
    ├── splash_screen.dart      # Animated splash
    ├── home_screen.dart        # Dashboard + bottom nav
    ├── contacts_screen.dart    # Contact management
    ├── location_screen.dart    # GPS display & sharing
    ├── history_screen.dart     # SOS history log
    └── settings_screen.dart    # App configuration
```

---

## ⚙️ Installation Steps

### Prerequisites
- Flutter SDK 3.x installed
- Android Studio or VS Code with Flutter extension
- Android device or emulator (API 21+)

### Steps

1. **Clone / open the project**
   ```bash
   cd MADL-MiniProject
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Connect** an Android device (USB debugging enabled) or start an emulator

4. **Run the app**
   ```bash
   flutter run
   ```

---

## ▶️ How to Run

```bash
# Development run with hot reload
flutter run

# Build release APK
flutter build apk --release
```

The release APK will be at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 How to Test SOS

### Demo Mode (Default — Safe for Testing)
1. Open the app → Home Screen
2. **Press and hold** the red SOS button
3. Watch the **5-second countdown** appear
4. Either:
   - Let it count down to 0 → SOS activates
   - Tap **CANCEL SOS** → cancels
5. After activation: view the result dialog showing:
   - ✅ SOS Activated
   - ✅ Location Retrieved (or ⚠️ if GPS off)
   - ✅ Alert Sent
6. Check **History tab** to see the saved record

### Real SMS Mode
1. Go to **Settings**
2. Toggle **Demo Mode OFF**
3. Activate SOS → the native SMS app opens with pre-filled message
4. Send the SMS manually

---

## ⚠️ Limitations

1. **SMS is not sent automatically** — in Real mode, it opens the SMS app; the user must tap Send
2. **No background SOS** — the app must be open to trigger SOS
3. **GPS accuracy** — may take a few seconds on first use; accuracy depends on device
4. **No map rendering** — Maps open in browser/Maps app (no embedded map)
5. **English only** — no multi-language support

---

## 🚀 Future Enhancements

- [ ] One-tap SOS from notification bar or widget
- [ ] Background location tracking during emergency
- [ ] Automatic SMS sending without opening SMS app
- [ ] Embedded Google Maps view
- [ ] Voice alert (text-to-speech)
- [ ] SOS via WhatsApp / emergency calling
- [ ] Wearable integration (Android Wear)
- [ ] Multi-language support
- [ ] Cloud backup for contacts and history

---

## 📱 Screenshots

| Screen | Description |
|---|---|
| Splash | Animated red logo splash |
| Home | SOS button + quick actions |
| Countdown | 5-second cancel screen |
| Result | SOS confirmation dialog |
| Contacts | Manage emergency contacts |
| Location | GPS coordinates + map link |
| History | Past SOS records |
| Settings | Demo mode, countdown config |

---

## 👤 Author

**MADL Mini Project**  
Mobile Application Development Lab  
Academic Year: 2026

---

*Built with Flutter 💙 | Emergency Assistance v1.0.0*
