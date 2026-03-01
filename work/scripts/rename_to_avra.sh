#!/bin/bash
# AVRA Rename Script
# Automates renaming SPOTS → AVRA for external packaging

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLD_NAME="spots"
NEW_NAME="avra"
OLD_NAME_UPPER="SPOTS"
NEW_NAME_UPPER="AVRA"
OLD_BUNDLE_ID="com.reisgordon.spots"
NEW_BUNDLE_ID="com.reisgordon.avra"
OLD_PACKAGE="com.spots.app"
NEW_PACKAGE="com.avra.app"

# Backup flag
BACKUP_DIR=".avra_rename_backup_$(date +%Y%m%d_%H%M%S)"
CREATE_BACKUP=true

echo -e "${BLUE}=== AVRA Rename Script ===${NC}"

# Function to replace in file
replace_in_file() {
  local file=$1
  local search=$2
  local replace=$3
  local desc=$4
  
  if [ ! -f "$file" ]; then
    echo -e "${YELLOW}Warning: File not found: $file${NC}"
    return
  fi
  
  if grep -q "$search" "$file" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Updating $file: $desc"
    # Use perl for better cross-platform compatibility
    perl -i -pe "s|${search}|${replace}|g" "$file"
  fi
}

# Function to backup file
backup_file() {
  local file=$1
  if [ "$CREATE_BACKUP" = true ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp "$file" "$BACKUP_DIR/$file" 2>/dev/null || true
  fi
}

echo ""
echo -e "${BLUE}Phase 1: Renaming Package Folders${NC}"

# Rename package folders
PACKAGES=("spots_data:avra_data" "spots_ml:avra_ml" "spots_quantum:avra_quantum" "spots_knot:avra_knot" "spots_ai:avra_ai" "spots_core:avra_core" "spots_network:avra_network" "spots_app:avra_app")

for pkg_pair in "${PACKAGES[@]}"; do
  OLD_PKG="${pkg_pair%%:*}"
  NEW_PKG="${pkg_pair##*:}"
  
  if [ -d "packages/$OLD_PKG" ] && [ ! -d "packages/$NEW_PKG" ]; then
    echo -e "${GREEN}✓${NC} Renaming packages/$OLD_PKG → packages/$NEW_PKG"
    mv "packages/$OLD_PKG" "packages/$NEW_PKG"
  elif [ -d "packages/$NEW_PKG" ]; then
    echo -e "${YELLOW}⚠${NC} packages/$NEW_PKG already exists, skipping"
  fi
done

echo ""
echo -e "${BLUE}Phase 2: Updating Package Names in pubspec.yaml${NC}"

# Update root pubspec.yaml
backup_file "pubspec.yaml"
replace_in_file "pubspec.yaml" "name: spots" "name: avra" "Root package name"
replace_in_file "pubspec.yaml" "path: packages/spots_" "path: packages/avra_" "Package path dependencies"

# Update all package pubspec.yaml files
for pkg in data ml quantum knot ai core network app; do
  file="packages/avra_${pkg}/pubspec.yaml"
  old_pkg="spots_${pkg}"
  new_pkg="avra_${pkg}"
  
  if [ -f "$file" ]; then
    backup_file "$file"
    replace_in_file "$file" "name: $old_pkg" "name: $new_pkg" "Package name"
    replace_in_file "$file" "path: ../spots_" "path: ../avra_" "Package path dependencies"
  fi
done

echo ""
echo -e "${BLUE}Phase 3: Updating Method/Event Channels${NC}"

# Dart MethodChannels
backup_file "packages/avra_network/lib/network/ble_peripheral.dart"
replace_in_file "packages/avra_network/lib/network/ble_peripheral.dart" \
  "'spots/ble_peripheral'" "'avra/ble_peripheral'" "BLE peripheral channel"

backup_file "packages/avra_network/lib/network/ble_inbox.dart"
replace_in_file "packages/avra_network/lib/network/ble_inbox.dart" \
  "'spots/ble_inbox'" "'avra/ble_inbox'" "BLE inbox channel"

backup_file "packages/avra_network/lib/network/ble_foreground_service.dart"
replace_in_file "packages/avra_network/lib/network/ble_foreground_service.dart" \
  "'spots/ble_foreground'" "'avra/ble_foreground'" "BLE foreground channel"

backup_file "lib/core/services/device_capability_service.dart"
replace_in_file "lib/core/services/device_capability_service.dart" \
  "'spots/device_capabilities'" "'avra/device_capabilities'" "Device capabilities channel"

backup_file "lib/core/services/llm_service.dart"
replace_in_file "lib/core/services/llm_service.dart" \
  "'spots/local_llm_stream'" "'avra/local_llm_stream'" "Local LLM stream channel"

# Android MethodChannels
backup_file "android/app/src/main/kotlin/com/spots/app/MainActivity.kt"
replace_in_file "android/app/src/main/kotlin/com/spots/app/MainActivity.kt" \
  '"spots/ble_foreground"' '"avra/ble_foreground"' "BLE foreground channel (Android)"
replace_in_file "android/app/src/main/kotlin/com/spots/app/MainActivity.kt" \
  '"spots/ble_peripheral"' '"avra/ble_peripheral"' "BLE peripheral channel (Android)"
replace_in_file "android/app/src/main/kotlin/com/spots/app/MainActivity.kt" \
  '"spots/ble_inbox"' '"avra/ble_inbox"' "BLE inbox channel (Android)"
replace_in_file "android/app/src/main/kotlin/com/spots/app/MainActivity.kt" \
  '"spots/device_capabilities"' '"avra/device_capabilities"' "Device capabilities channel (Android)"
replace_in_file "android/app/src/main/kotlin/com/spots/app/MainActivity.kt" \
  '"spots/local_llm"' '"avra/local_llm"' "Local LLM channel (Android)"
replace_in_file "android/app/src/main/kotlin/com/spots/app/MainActivity.kt" \
  '"spots/local_llm_stream"' '"avra/local_llm_stream"' "Local LLM stream channel (Android)"

# iOS MethodChannels
backup_file "ios/Runner/AppDelegate.swift"
replace_in_file "ios/Runner/AppDelegate.swift" \
  '"spots/ble_inbox"' '"avra/ble_inbox"' "BLE inbox channel (iOS)"
replace_in_file "ios/Runner/AppDelegate.swift" \
  '"spots/ble_peripheral"' '"avra/ble_peripheral"' "BLE peripheral channel (iOS)"
replace_in_file "ios/Runner/AppDelegate.swift" \
  '"spots/device_capabilities"' '"avra/device_capabilities"' "Device capabilities channel (iOS)"
replace_in_file "ios/Runner/AppDelegate.swift" \
  '"spots/local_llm"' '"avra/local_llm"' "Local LLM channel (iOS)"
replace_in_file "ios/Runner/AppDelegate.swift" \
  '"spots/local_llm_stream"' '"avra/local_llm_stream"' "Local LLM stream channel (iOS)"

echo ""
echo -e "${BLUE}Phase 4: Android Platform Configuration${NC}"

# Android build.gradle
backup_file "android/app/build.gradle"
replace_in_file "android/app/build.gradle" \
  'namespace "com.spots.app"' 'namespace "com.avra.app"' "Android namespace"
replace_in_file "android/app/build.gradle" \
  'applicationId "com.spots.app"' 'applicationId "com.avra.app"' "Android application ID"

# AndroidManifest.xml
backup_file "android/app/src/main/AndroidManifest.xml"
replace_in_file "android/app/src/main/AndroidManifest.xml" \
  'package="com.spots.app"' 'package="com.avra.app"' "Android package"
replace_in_file "android/app/src/main/AndroidManifest.xml" \
  'android:label="SPOTS"' 'android:label="AVRA"' "Android app label"
replace_in_file "android/app/src/main/AndroidManifest.xml" \
  'android:scheme="spots"' 'android:scheme="avra"' "Android OAuth scheme"

# strings.xml
backup_file "android/app/src/main/res/values/strings.xml"
replace_in_file "android/app/src/main/res/values/strings.xml" \
  '<string name="app_name">SPOTS</string>' '<string name="app_name">AVRA</string>' "App name string"

# Rename Android Kotlin folder structure
echo -e "${BLUE}Phase 4.5: Renaming Android Kotlin Folder Structure${NC}"
if [ -d "android/app/src/main/kotlin/com/spots" ]; then
  echo -e "${GREEN}✓${NC} Renaming Android Kotlin folder: com/spots → com/avra"
  mkdir -p "android/app/src/main/kotlin/com/avra"
  mv "android/app/src/main/kotlin/com/spots/app" "android/app/src/main/kotlin/com/avra/app"
  rmdir "android/app/src/main/kotlin/com/spots" 2>/dev/null || true
fi

# Update Kotlin package declarations
for kt_file in android/app/src/main/kotlin/com/avra/app/*.kt android/app/src/main/kotlin/com/avra/app/services/*.kt; do
  if [ -f "$kt_file" ]; then
    backup_file "$kt_file"
    replace_in_file "$kt_file" \
      'package com.spots.app' 'package com.avra.app' "Kotlin package declaration"
    replace_in_file "$kt_file" \
      'com.spots.app.services' 'com.avra.app.services' "Kotlin service package declaration"
  fi
done

echo ""
echo -e "${BLUE}Phase 5: iOS Platform Configuration${NC}"

# Info.plist - Handle carefully with context
backup_file "ios/Runner/Info.plist"
# CFBundleDisplayName
perl -i -pe 's|<string>Spots</string>|<string>AVRA</string>|g if /CFBundleDisplayName/' "ios/Runner/Info.plist"
# CFBundleName
perl -i -pe 's|<string>spots</string>|<string>avra</string>|g if /CFBundleName/' "ios/Runner/Info.plist"
# OAuth bundle URL name
replace_in_file "ios/Runner/Info.plist" \
  'com.spots.app.oauth' 'com.avra.app.oauth' "OAuth bundle URL name"
# OAuth URL scheme
perl -i -pe 's|<string>spots</string>|<string>avra</string>|g if /CFBundleURLSchemes/' "ios/Runner/Info.plist"
# Permission descriptions
replace_in_file "ios/Runner/Info.plist" \
  'SPOTS uses' 'AVRA uses' "Permission descriptions"
replace_in_file "ios/Runner/Info.plist" \
  'SPOTS needs' 'AVRA needs' "Permission descriptions"

# Xcode project bundle identifier
backup_file "ios/Runner.xcodeproj/project.pbxproj"
replace_in_file "ios/Runner.xcodeproj/project.pbxproj" \
  'com.reisgordon.spots' 'com.reisgordon.avra' "Bundle identifier"
replace_in_file "ios/Runner.xcodeproj/project.pbxproj" \
  'com.spots.spots.RunnerTests' 'com.avra.avra.RunnerTests' "Test bundle identifier"

echo ""
echo -e "${BLUE}Phase 6: Web Platform Configuration${NC}"

# web/index.html
backup_file "web/index.html"
replace_in_file "web/index.html" \
  'content="spots"' 'content="AVRA"' "Apple web app title"
replace_in_file "web/index.html" \
  '<title>spots</title>' '<title>AVRA</title>' "Web page title"

# web/manifest.json
backup_file "web/manifest.json"
replace_in_file "web/manifest.json" \
  '"name": "spots"' '"name": "AVRA"' "Manifest name"
replace_in_file "web/manifest.json" \
  '"short_name": "spots"' '"short_name": "AVRA"' "Manifest short name"

echo ""
echo -e "${BLUE}Phase 7: Workspace Configuration${NC}"

# melos.yaml
backup_file "melos.yaml"
replace_in_file "melos.yaml" \
  'name: SPOTS' 'name: AVRA' "Workspace name"
replace_in_file "melos.yaml" \
  'scope: "spots_' 'scope: "avra_' "Package scopes"
replace_in_file "melos.yaml" \
  'Bootstrapping SPOTS workspace' 'Bootstrapping AVRA workspace' "Bootstrap message"

echo ""
echo -e "${BLUE}Phase 8: Summary${NC}"

echo -e "${GREEN}✓ Rename completed!${NC}"
if [ "$CREATE_BACKUP" = true ]; then
  echo -e "${BLUE}Backup created in: $BACKUP_DIR${NC}"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run 'flutter pub get' to update dependencies"
echo "2. Run 'flutter clean' and rebuild"
echo "3. Test app on both platforms"
echo "4. Update README.md branding if desired"
echo ""
