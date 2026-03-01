#!/bin/bash
# Verify Firebase config files have correct bundle IDs for AVRAI

set -e

echo "=== Firebase Config Verification ==="
echo ""

# Expected values
EXPECTED_IOS_BUNDLE="com.avrai.app"
EXPECTED_ANDROID_PACKAGE="com.avrai.app"

# Check iOS config
IOS_CONFIG="ios/Runner/GoogleService-Info.plist"
if [ -f "$IOS_CONFIG" ]; then
    echo "✓ iOS config file exists: $IOS_CONFIG"
    
    # Extract bundle ID (handle plist format)
    ACTUAL_IOS_BUNDLE=$(grep -A 1 "BUNDLE_ID" "$IOS_CONFIG" | tail -1 | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
    
    if [ "$ACTUAL_IOS_BUNDLE" = "$EXPECTED_IOS_BUNDLE" ]; then
        echo "✅ iOS bundle ID is correct: $ACTUAL_IOS_BUNDLE"
    else
        echo "❌ iOS bundle ID mismatch!"
        echo "   Expected: $EXPECTED_IOS_BUNDLE"
        echo "   Found: $ACTUAL_IOS_BUNDLE"
        echo "   Action: Re-download GoogleService-Info.plist from Firebase Console"
    fi
else
    echo "❌ iOS config file not found: $IOS_CONFIG"
    echo "   Action: Download GoogleService-Info.plist and place in ios/Runner/"
fi

echo ""

# Check Android config
ANDROID_CONFIG="android/app/google-services.json"
if [ -f "$ANDROID_CONFIG" ]; then
    echo "✓ Android config file exists: $ANDROID_CONFIG"
    
    # Extract package name from JSON
    ACTUAL_ANDROID_PACKAGE=$(grep -A 2 "android_client_info" "$ANDROID_CONFIG" | grep "package_name" | sed 's/.*"package_name": *"\(.*\)".*/\1/' | head -1)
    
    if [ "$ACTUAL_ANDROID_PACKAGE" = "$EXPECTED_ANDROID_PACKAGE" ]; then
        echo "✅ Android package name is correct: $ACTUAL_ANDROID_PACKAGE"
    else
        echo "❌ Android package name mismatch!"
        echo "   Expected: $EXPECTED_ANDROID_PACKAGE"
        echo "   Found: $ACTUAL_ANDROID_PACKAGE"
        echo "   Action: Re-download google-services.json from Firebase Console"
    fi
else
    echo "❌ Android config file not found: $ANDROID_CONFIG"
    echo "   Action: Download google-services.json and place in android/app/"
fi

echo ""
echo "=== Summary ==="
if [ "$ACTUAL_IOS_BUNDLE" = "$EXPECTED_IOS_BUNDLE" ] && [ "$ACTUAL_ANDROID_PACKAGE" = "$EXPECTED_ANDROID_PACKAGE" ]; then
    echo "✅ All Firebase configs are correct!"
    echo ""
    echo "Next steps:"
    echo "1. Run: flutter clean && flutter pub get"
    echo "2. Run: cd ios && pod install && cd .."
    echo "3. Test builds: flutter build apk --debug"
else
    echo "⚠️  Config files need to be updated"
    echo ""
    echo "Follow FIREBASE_SETUP_GUIDE.md to:"
    echo "1. Add iOS app to Firebase project with bundle ID: $EXPECTED_IOS_BUNDLE"
    echo "2. Add Android app to Firebase project with package: $EXPECTED_ANDROID_PACKAGE"
    echo "3. Download and replace config files"
fi
