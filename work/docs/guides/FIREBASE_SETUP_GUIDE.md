# Firebase Setup Guide for AVRAI

**Current Bundle IDs:**
- iOS: `com.avrai.app`
- Android: `com.avrai.app`

**Firebase Project:** avrai (already created)

---

## Step 1: Add iOS App to Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **avrai** project
3. Click the **iOS** icon (or Project Settings → Add App → iOS)
4. Enter details:
   - **iOS bundle ID:** `com.avrai.app`
   - **App nickname:** AVRAI iOS (optional)
   - **App Store ID:** Leave blank (can add later)
5. Click **Register app**
6. Download `GoogleService-Info.plist`
7. **Important:** Don't click "Next" yet - we'll add it manually

---

## Step 2: Add Android App to Firebase Project

1. In the same Firebase Console project
2. Click the **Android** icon (or Project Settings → Add App → Android)
3. Enter details:
   - **Android package name:** `com.avrai.app`
   - **App nickname:** AVRAI Android (optional)
   - **Debug signing certificate SHA-1:** (optional, can add later)
4. Click **Register app**
5. Download `google-services.json`
6. **Important:** Don't click "Next" yet - we'll add it manually

---

## Step 3: Replace Config Files

Once you've downloaded the config files, place them here:

### iOS Config
**Location:** `ios/Runner/GoogleService-Info.plist`
**Action:** Replace the existing file with your downloaded `GoogleService-Info.plist`

### Android Config
**Location:** `android/app/google-services.json`
**Action:** Replace the existing file with your downloaded `google-services.json`

---

## Step 4: Verify Config Files

After placing the files, verify they have the correct bundle IDs:

### iOS Check
```bash
grep "BUNDLE_ID" ios/Runner/GoogleService-Info.plist
# Should show: <string>com.avrai.app</string>
```

### Android Check
```bash
grep "package_name" android/app/google-services.json
# Should show: "com.avrai.app"
```

---

## Step 5: Update Dependencies

After config files are in place, run:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Install iOS pods (required after config change)
cd ios && pod install && cd ..

# Verify no build errors
flutter build apk --debug  # Test Android
flutter build ios --debug --no-codesign  # Test iOS
```

---

## Step 6: Enable Firebase Services (in Firebase Console)

After apps are registered, enable the services you need:

1. **Authentication:**
   - Firebase Console → Authentication → Get Started
   - Enable Email/Password, Google, etc.

2. **Firestore Database:**
   - Firebase Console → Firestore Database → Create Database
   - Choose location, start in test mode (update rules later)

3. **Storage** (if needed):
   - Firebase Console → Storage → Get Started

4. **Cloud Messaging** (for push notifications):
   - Already enabled if you see GCM_SENDER_ID in config

---

## Troubleshooting

### Config file not found
- Ensure files are named exactly: `GoogleService-Info.plist` and `google-services.json`
- Check file paths match exactly: `ios/Runner/` and `android/app/`

### Build errors after config update
- Run `flutter clean`
- Run `cd ios && pod install && cd ..`
- Delete `ios/Podfile.lock` if pod install fails, then retry

### Firebase not initialized
- Ensure config files have correct bundle IDs
- Check Firebase SDK is initialized in your Dart code
- Verify `firebase_core` package is in `pubspec.yaml`

---

## Next Steps (After Firebase Setup)

1. ✅ Firebase configs: DONE (once you complete above steps)
2. ⏳ Apple Developer Portal: Register bundle ID `com.avrai.app`
3. ⏳ App Store Connect: Create new app named "AVRAI"
4. ⏳ Google Play Console: Create new app with package `com.avrai.app`
5. ⏳ OAuth Providers: Update redirect URIs to `avrai://oauth`
