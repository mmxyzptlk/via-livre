# VIA LIVRE - Setup Instructions

## Prerequisites

1. **Flutter SDK** (3.10.4 or higher)
   - Install from: https://flutter.dev/docs/get-started/install

2. **Firebase Account**
   - Sign up at: https://console.firebase.google.com
   - Create a new project

3. **Google Maps JavaScript API Key** (for web)
   - Get from: https://console.cloud.google.com
   - Enable "Maps JavaScript API"

## Step 1: Firebase Setup

1. **Create a new Firebase project** at https://console.firebase.google.com
   - Click "Add project"
   - Enter project name
   - Disable Google Analytics (optional)
   - Click "Create project"

2. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. **Configure Firebase for Flutter:**
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project
   - Select **Web** platform only
   - This will generate `lib/firebase_options.dart`

4. **Enable Firebase Authentication:**
   - Go to Firebase Console → Authentication
   - Click "Get started"
   - Enable "Anonymous" sign-in method
   - Save

5. **Set up Firestore Database:**
   - Go to Firebase Console → Firestore Database
   - Click "Create database"
   - Start in "Test mode" (we'll update rules)
   - Choose a location (closest to your users)
   - Click "Enable"

6. **Deploy Firestore Security Rules:**
   - Go to Firestore Database → Rules
   - Copy contents from `firebase/firestore.rules`
   - Paste into the rules editor
   - Click "Publish"

7. **Create Firestore Indexes:**
   - Go to Firestore Database → Indexes
   - Click "Create Index"
   
   **Index 1:**
   - Collection: `road_reports`
   - Fields: `is_active` (Ascending), `expires_at` (Ascending)
   - Query scope: Collection
   
   **Index 2:**
   - Collection: `road_reports`
   - Fields: `location.geohash` (Ascending), `is_active` (Ascending), `expires_at` (Ascending)
   - Query scope: Collection
   
   **Index 3:**
   - Collection: `report_votes`
   - Fields: `report_id` (Ascending), `user_id` (Ascending), `vote_type` (Ascending)
   - Query scope: Collection

## Step 2: Flutter Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate localization files:**
   ```bash
   flutter gen-l10n
   ```

3. **Configure Google Maps (Web):**

   Edit `web/index.html` and add the Google Maps JavaScript API script before the closing `</head>` tag:
   
   ```html
   <head>
     <!-- ... existing content ... -->
     <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY&libraries=geometry"></script>
   </head>
   ```

   Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key.

4. **Web Location Permissions:**

   The app uses the browser's Geolocation API. Note that:
   - HTTPS is required for geolocation (except localhost)
   - Users will be prompted by the browser to allow location access
   - No additional configuration needed

## Step 3: Run the App

```bash
# Run in Chrome (default)
flutter run -d chrome

# Or run in a specific browser
flutter run -d web-server --web-port 8080
```

**Note:** For production, build the web app:
```bash
flutter build web
```

The output will be in `build/web/` directory.

## Project Structure

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
│   └── create_report_screen.dart # Create new report form
├── services/
│   └── firebase_service.dart     # Firebase API service
├── utils/
│   └── geohash.dart              # Geohash utility
└── main.dart                     # App entry point

firebase/
├── firestore.rules               # Firestore security rules
└── DATA_STRUCTURE.md             # Data structure documentation
```

## Features

✅ Anonymous authentication  
✅ Real-time map updates via Firestore streams  
✅ GPS-based location tracking  
✅ Report creation with issue types  
✅ Vote system (confirm/dismiss)  
✅ Automatic report expiration (4 hours)  
✅ Bilingual support (English/Portuguese)  
✅ Geohash-based location queries  

## Legal Compliance

The app includes:
- Neutral wording throughout
- Disclaimer banner on map screen
- No language promoting law enforcement evasion
- Anonymous auth support

## Troubleshooting

### Location not working
- Ensure browser location permissions are granted (check browser settings)
- Verify the app is served over HTTPS (required for geolocation API, except localhost)
- Check browser console for permission errors
- Some browsers may require user interaction before requesting location

### Maps not loading
- Verify Google Maps JavaScript API key is correct in `web/index.html`
- Check API key restrictions in Google Cloud Console
- Ensure Maps JavaScript API is enabled (not Android SDK)
- Check browser console for JavaScript errors
- Verify the API key allows your domain in restrictions

### Firebase connection errors
- Verify `firebase_options.dart` is generated (run `flutterfire configure`)
- Check Firebase project is active
- Verify Firestore security rules allow anonymous access
- Ensure Firestore indexes are created

### Reports not appearing
- Check Firestore security rules
- Verify geohash indexes are created
- Check Firestore database connection in Firebase Console
- Verify real-time listeners are working

### Build errors
- Run `flutter clean` then `flutter pub get`
- Ensure `firebase_options.dart` exists
- Check that all Firebase dependencies are installed
- For web, ensure you have Chrome installed for testing
- Run `flutter doctor` to check Flutter web support

## Next Steps

1. Customize marker icons for each issue type
2. Add report filtering by issue type
3. Implement user reporting/flagging system
4. Add push notifications for nearby reports (Firebase Cloud Messaging)
5. Create admin dashboard for moderation

## Firebase Console Links

- **Project Overview:** https://console.firebase.google.com
- **Authentication:** Firebase Console → Authentication
- **Firestore Database:** Firebase Console → Firestore Database
- **Security Rules:** Firestore Database → Rules
- **Indexes:** Firestore Database → Indexes
