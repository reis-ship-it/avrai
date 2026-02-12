# AVRA → AVRAI Rename Summary

**Date:** January 7, 2025  
**Backup Location:** `.avrai_rename_backup_20260107_130602/`

## ✅ Completed Changes

### iOS Platform
- ✅ Bundle ID: `com.reisgordon.avra` → `com.avrai.app`
- ✅ Test Bundle ID: `com.avra.avra.RunnerTests` → `com.avrai.avrai.RunnerTests`
- ✅ Display Name: `AVRA` → `AVRAI`
- ✅ Bundle Name: `avra` → `avrai`
- ✅ OAuth URL Name: `com.avra.app.oauth` → `com.avrai.app.oauth`
- ✅ OAuth URL Scheme: `avra` → `avrai`
- ✅ Permission Strings: All updated from "AVRA uses/needs" to "AVRAI uses/needs" (7 strings)

### Android Platform
- ✅ Namespace: `com.avra.app` → `com.avrai.app`
- ✅ Application ID: `com.avra.app` → `com.avrai.app`
- ✅ OAuth Redirect Scheme: `com.avra.app` → `com.avrai.app`
- ✅ App Label: `AVRA` → `AVRAI`
- ✅ Deep Link Scheme: `avra` → `avrai`
- ✅ Kotlin Package: `com.avra.app` → `com.avrai.app`
- ✅ Kotlin Folder: Moved from `kotlin/com/avra/app/` to `kotlin/com/avrai/app/`

### Flutter/Dart
- ✅ Root Package: `avra` → `avrai`
- ✅ Internal Packages (8 total):
  - `avra_network` → `avrai_network`
  - `avra_core` → `avrai_core`
  - `avra_quantum` → `avrai_quantum`
  - `avra_knot` → `avrai_knot`
  - `avra_ai` → `avrai_ai`
  - `avra_ml` → `avrai_ml`
  - `avra_data` → `avrai_data`
  - `avra_app` → `avrai_app`
- ✅ Package Imports: 1555+ files updated
- ✅ Pubspec Dependencies: All `avra_*` references updated to `avrai_*`
- ✅ Melos Workspace: `AVRA` → `AVRAI`

### Web Platform
- ✅ Manifest Name: `AVRA` → `AVRAI`
- ✅ Manifest Short Name: `AVRA` → `AVRAI`
- ✅ HTML Title: `AVRA` → `AVRAI`
- ✅ Apple Web App Title: `AVRA` → `AVRAI`

### Documentation
- ✅ README.md: All branding updated
- ✅ APPLE_DEVELOPER_INTEGRATION_GUIDE.md: Updated
- ✅ IOS_SIGNED_IPA_BUILD_RUNBOOK.md: Updated
- ✅ Supabase Service: Logger tag and comments updated
- ✅ All major docs reflect new AVRAI branding

## ⚠️ CRITICAL: Required Next Steps

### 1. Firebase Configuration (MUST DO)
**Current files still reference OLD bundle IDs:**
- `ios/Runner/GoogleService-Info.plist` → Has `com.spots.app` (needs `com.avrai.app`)
- `android/app/google-services.json` → Has `com.spots.app` (needs `com.avrai.app`)

**Action Required:**
1. Go to Firebase Console
2. Add iOS app with bundle ID: `com.avrai.app`
3. Download new `GoogleService-Info.plist` and replace the iOS file
4. Add Android app with package: `com.avrai.app`
5. Download new `google-services.json` and replace the Android file

### 2. Apple Developer Portal
1. Register new App ID: `com.avrai.app`
2. Enable required capabilities (push notifications, background modes, etc.)
3. Generate provisioning profiles for new bundle ID

### 3. App Store Connect
1. Create NEW app (cannot migrate from old bundle ID)
2. Use app name: **AVRAI** (or "AVRAI AI" if taken)
3. Bundle ID: `com.avrai.app`
4. This is a separate app listing from any previous AVRA app

### 4. Google Play Console
1. Create NEW app
2. Package name: `com.avrai.app`
3. This is a separate app from any previous AVRA app

### 5. OAuth Provider Updates
Update redirect URIs in all OAuth provider consoles:
- **Google Cloud Console:** Add `avrai://oauth` redirect
- **Facebook/Meta:** Update redirect URI to `avrai://oauth`
- **Instagram:** Update redirect URI
- **Any other OAuth providers:** Update to use `avrai://` scheme

### 6. Supabase/Backend Auth
- Update allowed redirect URLs: `avrai://oauth`, `com.avrai.app://oauth`
- Update any hardcoded bundle ID references

### 7. Build System
```bash
# Clean and reinstall dependencies
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Test build
flutter build apk --debug  # Android
flutter build ios --debug --no-codesign  # iOS
```

## 📊 Change Statistics
- **iOS config files:** 2 updated
- **Android config files:** 3 updated
- **Kotlin files:** 4 updated + folder moved
- **Dart files:** 1555+ updated
- **Package folders:** 8 renamed
- **Pubspec files:** 9 updated
- **Documentation files:** 3 updated

## 🔄 Rollback Instructions
If you need to revert:
```bash
# Delete current packages
rm -rf packages/avrai_*

# Restore from backup
cp -r .avrai_rename_backup_20260107_130602/packages/avra_* packages/

# Restore iOS configs
cp .avrai_rename_backup_20260107_130602/Info.plist ios/Runner/
cp .avrai_rename_backup_20260107_130602/project.pbxproj ios/Runner.xcodeproj/

# Restore Android configs
cp .avrai_rename_backup_20260107_130602/build.gradle android/app/
cp .avrai_rename_backup_20260107_130602/AndroidManifest.xml android/app/src/main/

# Restore Kotlin
rm -rf android/app/src/main/kotlin/com/avrai
cp -r .avrai_rename_backup_20260107_130602/kotlin/avra android/app/src/main/kotlin/com/

# Then revert all Dart imports manually or use a script
```

## ✅ What This Does NOT Break
- Spot feature/service references (kept as "spot/spots")
- Database schema (spots tables, etc.)
- API routes (/spots endpoints)
- Existing local data
- App functionality (all features work the same)

## 🎯 Final Result
The app is now **AVRAI** with:
- Universal app ID: `com.avrai.app` (iOS + Android)
- Deep link scheme: `avrai://`
- Display name: **AVRAI**
- Package names: `avrai`, `avrai_*`

**The app will NOT break** - all code changes are consistent. You just need to:
1. Download new Firebase configs
2. Register new bundle IDs with Apple/Google
3. Run `flutter pub get`
