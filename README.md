# VIA LIVRE

A bilingual (Portuguese/English) community road awareness web application built with Flutter and Firebase.

## 🎯 Purpose

VIA LIVRE allows users to report and view road issues such as accidents, floods, construction, protests, fallen trees, and other obstructions. The app is informational only and does NOT promote evading law enforcement.

## ⚖️ Legal Compliance

- Uses neutral wording throughout the application
- Includes disclaimer: "User-generated information. Accuracy not guaranteed. This app does not promote avoidance of law enforcement."
- No language about "avoiding police" or "speed traps"
- Supports anonymous authentication

## ✨ Features

- ✅ **Anonymous Sign-in** - No account required (Firebase Anonymous Auth)
- ✅ **Real-time Map** - View nearby road reports on an interactive map with real-time updates
- ✅ **Create Reports** - Report road issues with GPS location and optional description
- ✅ **Issue Types** - Accident, construction, flood, fallen tree, protest, other
- ✅ **Report Filtering** - Filter reports by issue type using filter chips
- ✅ **Color-coded Markers** - Visual markers on the map colored by issue type
- ✅ **Location Display** - Reverse geocoding shows address/location name for reports
- ✅ **Distance Validation** - Reports must be within 10km of your current location
- ✅ **Confirmation System** - Vote "Still present" or "No longer present" with vote counts
- ✅ **Auto-expiration** - Reports automatically expire after 2 hours
- ✅ **Bilingual UI** - Full support for English and Portuguese with language switching
- ✅ **Geohash-based Queries** - Efficient location-based searches using Firestore
- ✅ **About Screen** - Information about the app and its features

## 🛠️ Tech Stack

- **Flutter Web** 3.10.4+
- **Firebase** (Firestore + Firebase Auth)
- **Google Maps Flutter** for map display and interaction
- **Google Maps JavaScript API** (for web platform)
- **Geolocator** for GPS location services
- **Google Fonts** (Noto Sans) for typography
- **Material 3** design system

## 📋 Prerequisites

1. Flutter SDK (3.10.4 or higher) with web support
2. Firebase account and project
3. Google Maps JavaScript API key (for web)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
flutter pub get
flutter gen-l10n
```

### 2. Configure Firebase

1. Create a Firebase project at https://console.firebase.google.com
2. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. This will generate `firebase_options.dart` and configure your app

### 3. Set up Firestore

1. Go to Firebase Console → Firestore Database
2. Create a database (start in test mode, then update with security rules)
3. Copy `firebase/firestore.rules` to Firestore Rules in the console
4. Create the required indexes (see `firebase/DATA_STRUCTURE.md`)

### 4. Configure Google Maps

1. Get a Google Maps JavaScript API key from https://console.cloud.google.com
2. Enable "Maps JavaScript API" (for web platform)
3. Enable "Geocoding API" (for reverse geocoding location names)
4. Update `web/index.html`:
   - Find the script tag with `YOUR_GOOGLE_MAPS_API_KEY`
   - Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

### 5. Run the App

```bash
# Run in Chrome (default)
flutter run -d chrome

# Or build for production
flutter build web
```

## 📁 Project Structure

```
lib/
├── config/
│   └── firebase_config.dart      # Firebase configuration notes
├── l10n/
│   ├── app_en.arb                # English translations
│   └── app_pt.arb                # Portuguese translations
├── models/
│   ├── issue_type.dart           # Issue type enum
│   ├── road_report.dart          # Road report model
│   └── report_vote.dart          # Vote model
├── screens/
│   ├── map_screen.dart           # Main map with reports
│   ├── create_report_screen.dart # Create new report form
│   └── about_screen.dart         # About and information screen
├── services/
│   └── firebase_service.dart     # Firebase API service
├── utils/
│   └── geohash.dart              # Geohash utility for location queries
└── main.dart                     # App entry point

firebase/
├── firestore.rules               # Firestore security rules
└── DATA_STRUCTURE.md             # Data structure documentation
```

## 🗄️ Database Structure

The app uses Firestore with geohash for location queries:

- **road_reports** - Stores road issue reports with geohash
- **report_votes** - Stores user votes (confirm/dismiss)
- **Security Rules** - Firestore rules for anonymous access
- **Auto-expiration** - Reports expire after 2 hours (filtered in queries)
- **Geohash Indexes** - Optimized for location queries

See `firebase/DATA_STRUCTURE.md` for full schema details.

## 🌍 Localization

The app supports English and Portuguese. Translations are in:
- `lib/l10n/app_en.arb` (English)
- `lib/l10n/app_pt.arb` (Portuguese)

Users can switch languages via the language button in the map screen.

## 🔒 Security & Privacy

- Anonymous authentication (no personal data required)
- Firestore Security Rules enforce data access
- No tracking or analytics by default

## 🐛 Troubleshooting

### Location not working
- Ensure browser location permissions are granted (HTTPS required)
- Check browser console for permission errors
- Verify the app is served over HTTPS (required for geolocation API)

### Maps not loading
- Verify Google Maps JavaScript API key is correct in `web/index.html`
- Check API key restrictions in Google Cloud Console
- Ensure Maps JavaScript API is enabled
- Check browser console for JavaScript errors

### Firebase connection errors
- Verify Firebase is initialized correctly
- Check `firebase_options.dart` is generated
- Verify Firestore security rules allow anonymous access
- Ensure Firestore indexes are created

### Reports not appearing
- Check Firestore security rules
- Verify geohash indexes are created
- Check Firestore database connection

## 📝 License

This project is provided as-is for educational and community purposes.

## 🤝 Contributing

Contributions are welcome! Please ensure:
- Code follows Flutter best practices
- Legal compliance is maintained
- Translations are updated for both languages

## 📚 Additional Documentation

See `SETUP.md` for detailed setup instructions.
