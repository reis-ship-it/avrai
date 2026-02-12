# Apple Developer Integration Guide for AVRAI

**Date:** January 6, 2025  
**Status:** ✅ Active Guide  
**Purpose:** Step-by-step guide to integrate Apple Developer credentials into AVRA project

---

## Overview

This guide walks you through integrating your Apple Developer Program credentials into the AVRAI iOS project to enable signed builds for device testing, TestFlight, and App Store distribution.

---

## Prerequisites

1. **Active Apple Developer Program membership** ($99/year)
   - Not just an Apple ID - you need the paid Developer Program
   - Verify at: https://developer.apple.com/account

2. **Xcode installed** (latest version recommended)
   - Download from Mac App Store or developer.apple.com

3. **Your Apple Developer Team ID**
   - Find it in Apple Developer portal or Xcode Settings → Accounts

---

## Current Project Configuration

The AVRAI project is already configured with:

- **Bundle Identifier:** `com.avrai.app`
- **Development Team:** `9B53VAY977` (configured in `ios/Runner.xcodeproj/project.pbxproj`)
- **Signing Style:** Automatic (managed by Xcode)
- **Code Sign Identity:** Apple Development (for Debug/Profile) / Apple Distribution (for Release)

---

## Step-by-Step Integration

### Step 1: Sign into Xcode

1. Open **Xcode**
2. Go to **Xcode → Settings** (or **Preferences** on older versions)
3. Click **Accounts** tab
4. Click **+** button (bottom left)
5. Select **Apple ID**
6. Sign in with your Apple Developer account credentials
7. Verify your team appears in the list

**Verification:**
- Your team name should appear
- Team ID should match (or you'll need to update it - see Step 2)

---

### Step 2: Verify/Update Team ID

**Option A: Verify in Xcode (Recommended)**

1. Open `ios/Runner.xcworkspace` in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In the Project Navigator, select **Runner** (top-level project)

3. Select **Runner** target (under TARGETS)

4. Go to **Signing & Capabilities** tab

5. Check:
   - ✅ **Automatically manage signing** is checked
   - **Team:** Should show your Apple Developer team
   - **Bundle Identifier:** `com.avrai.app`
   - **Provisioning Profile:** Should auto-generate (or show existing)

6. If team doesn't match:
   - Select your team from the dropdown
   - Xcode will automatically update the project file

**Option B: Manual Update (if needed)**

If you need to manually update the Team ID:

1. Find your Team ID in Xcode Settings → Accounts
2. Update `ios/Runner.xcodeproj/project.pbxproj`:
   - Search for `DEVELOPMENT_TEAM = 9B53VAY977;`
   - Replace `9B53VAY977` with your Team ID
   - Update in all build configurations (Debug, Release, Profile)

---

### Step 3: Verify Bundle Identifier

The bundle identifier must be **unique** and **available under your team**.

**Current:** `com.avrai.app`

**To verify:**
1. In Xcode → Signing & Capabilities
2. If you see an error about bundle ID not being available:
   - Change to a unique identifier (e.g., `com.avrai.app.dev`)
   - Or register the bundle ID in Apple Developer portal first

**To register in portal:**
1. Go to https://developer.apple.com/account/resources/identifiers/list
2. Click **+** → **App IDs**
3. Enter bundle identifier
4. Select capabilities (if needed)
5. Register

---

### Step 4: Device Setup (for Development Builds)

If you want to install the app directly on your iPhone:

1. **Connect iPhone** to Mac via USB
2. **Trust Computer** on iPhone (if prompted)
3. **Enable Developer Mode** on iPhone:
   - Settings → Privacy & Security → Developer Mode → ON
   - Reboot iPhone
   - Confirm when prompted after reboot
4. **Register Device** (automatic if using automatic signing):
   - Xcode will automatically register your device when you build
   - Or manually: Xcode → Window → Devices and Simulators → Add device

---

### Step 5: Build and Test

#### Development Build (for your device)

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Install iOS pods
cd ios && pod install && cd ..

# Build development IPA
flutter build ipa --release --export-method development
```

**Output:** `build/ios/ipa/*.ipa`

**Install on device:**
- Drag IPA to Xcode → Window → Devices and Simulators
- Or use `xcrun devicectl device install app --device <device-id> <ipa-path>`

#### App Store Build (for TestFlight/App Store)

```bash
# Build App Store IPA
flutter build ipa --release --export-method app-store
```

**Output:** `build/ios/ipa/*.ipa`

**Upload to App Store Connect:**
1. Go to https://appstoreconnect.apple.com
2. Create app (if first time)
3. Upload IPA via Transporter app or Xcode → Organizer → Distribute App

---

## Troubleshooting

### Error: "No profiles for 'com.reisgordon.avra' were found"

**Solution:**
1. Ensure you're signed into Xcode with Apple Developer account
2. Check "Automatically manage signing" is enabled
3. Verify bundle identifier is registered in Apple Developer portal
4. Try: Xcode → Product → Clean Build Folder (Shift+Cmd+K)

### Error: "Communication with Apple failed"

**Solution:**
1. Check internet connection
2. Verify Apple Developer account is active
3. Try signing out and back into Xcode
4. Check Apple Developer portal status

### Error: "Device not registered"

**Solution:**
1. Connect device to Mac
2. Trust computer on device
3. Enable Developer Mode (Settings → Privacy & Security → Developer Mode)
4. Xcode should auto-register, or manually add in Devices window

### Error: "Provisioning profile expired"

**Solution:**
1. Xcode → Settings → Accounts → Download Manual Profiles
2. Or let automatic signing regenerate profiles
3. Clean build folder and rebuild

### Build succeeds but app won't install

**Solution:**
1. Verify Developer Mode is enabled on device
2. Check device is registered to your team
3. Trust the developer certificate: Settings → General → VPN & Device Management → Trust

---

## Capabilities and Entitlements

The AVRAI app uses these capabilities (already configured in Info.plist):

- **Background Modes:**
  - Location updates
  - Background processing
  - Bluetooth (central & peripheral)
  - Background fetch
  - Remote notifications
  - Audio
  - Nearby interaction

- **Permissions:**
  - Location (Always and When In Use)
  - Bluetooth
  - Camera
  - Photo Library

**Note:** Some capabilities may require additional setup in Apple Developer portal:
- Push Notifications → Requires APNs certificate
- App Groups → Requires group identifier registration
- Associated Domains → Requires domain verification

---

## App Store Connect Setup

### First-Time Setup

1. **Create App:**
   - Go to https://appstoreconnect.apple.com
   - My Apps → + → New App
   - Fill in app information
   - Bundle ID: `com.avrai.app`

2. **App Information:**
   - Name: AVRAI
   - Primary Language: English
   - Bundle ID: Select `com.avrai.app`
   - SKU: Unique identifier (e.g., `avrai-001`)

3. **Prepare for Submission:**
   - Upload screenshots
   - Write description
   - Set pricing
   - Configure App Privacy details

### TestFlight Setup

1. **Upload Build:**
   - Use Transporter app or Xcode Organizer
   - Upload IPA built with `--export-method app-store`

2. **Add Testers:**
   - App Store Connect → TestFlight
   - Add internal testers (up to 100)
   - Add external testers (up to 10,000) - requires Beta App Review

3. **Test:**
   - Testers receive email invitation
   - Install TestFlight app on device
   - Install AVRAI from TestFlight

---

## Verification Checklist

Before building for distribution, verify:

- [ ] Signed into Xcode with Apple Developer account
- [ ] Team ID matches in Xcode Settings → Accounts
- [ ] Bundle identifier is unique and registered
- [ ] "Automatically manage signing" is enabled
- [ ] No signing errors in Xcode
- [ ] Device registered (for development builds)
- [ ] Developer Mode enabled on device (iOS 16+)
- [ ] App Store Connect app created (for distribution)
- [ ] All required capabilities configured
- [ ] Privacy descriptions added to Info.plist

---

## Quick Reference Commands

```bash
# Clean and rebuild
flutter clean && flutter pub get && cd ios && pod install && cd ..

# Development build
flutter build ipa --release --export-method development

# App Store build
flutter build ipa --release --export-method app-store

# Simulator build (no signing needed)
flutter run -d <simulator-id>

# Check connected devices
flutter devices

# Open Xcode workspace
open ios/Runner.xcworkspace
```

---

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Signing Guide](https://developer.apple.com/support/code-signing/)

---

## Support

If you encounter issues:

1. Check Xcode build logs for specific errors
2. Verify Apple Developer account status
3. Check Flutter iOS deployment documentation
4. Review Apple Developer forums

---

**Last Updated:** January 7, 2025  
**Maintained by:** AVRAI Development Team
