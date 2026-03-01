# Platform Testing Guide

**Date:** December 28, 2025  
**Status:** ⏳ Testing Guide  
**Purpose:** Guide for testing Rust FFI integration on each platform

---

## Overview

This guide provides instructions for testing the knot theory Rust FFI integration on Android, iOS, and macOS platforms.

---

## Prerequisites

### All Platforms:
- ✅ Rust installed (`rustup`)
- ✅ Flutter SDK installed
- ✅ Integration tests passing (7/7 tests passing)

### Android:
- Android NDK installed
- Android SDK configured
- Android device/emulator available

### iOS:
- Xcode installed
- iOS Simulator or device available
- CocoaPods installed (if using Pods)

### macOS:
- Xcode installed
- macOS development environment configured

---

## Testing Steps

### Step 1: Build Rust Libraries

#### macOS (Current Platform):
```bash
./scripts/build_rust_macos.sh
```

**Expected Output:**
```
✅ macOS library built successfully
📂 Library is in: target/{arch}-apple-darwin/release/libknot_math.dylib
```

#### Android:
```bash
./scripts/build_rust_android.sh
```

**Expected Output:**
```
✅ Android libraries built and copied successfully
📂 Libraries are in: android/app/src/main/jniLibs
```

#### iOS:
```bash
./scripts/build_rust_ios.sh
```

**Expected Output:**
```
✅ iOS libraries built successfully
📂 Libraries are in: target/{target}/release/libknot_math.a
```

---

### Step 2: Run Platform-Specific Tests

#### macOS:
```bash
flutter test test/platform/knot_math_macos_test.dart
```

**Expected:** All tests pass

#### Android:
```bash
flutter test test/platform/knot_math_android_test.dart
```

**Expected:** All tests pass (requires Android device/emulator)

#### iOS:
```bash
flutter test test/platform/knot_math_ios_test.dart
```

**Expected:** All tests pass (requires iOS Simulator/device)

---

### Step 3: Build Flutter App

#### macOS:
```bash
flutter build macos --debug
```

**Verify:**
- App builds successfully
- No linker errors
- Library loads correctly

#### Android:
```bash
flutter build apk --debug
```

**Verify:**
- APK builds successfully
- Libraries included in APK
- No missing library errors

#### iOS:
```bash
flutter build ios --debug
```

**Verify:**
- Xcode project builds successfully
- Libraries linked correctly
- No missing symbol errors

---

### Step 4: Run Full Integration Test

#### macOS:
```bash
flutter test test/core/services/knot/personality_knot_service_integration_test.dart
```

**Expected:** 7/7 tests pass

---

## Troubleshooting

### Library Not Found

**Symptoms:**
- `DynamicLibrary.open()` fails
- "Library not found" errors

**Solutions:**
1. **macOS:** Verify library is in `target/{arch}-apple-darwin/release/`
2. **Android:** Check `jniLibs` directory structure
3. **iOS:** Verify library is linked in Xcode project

### Architecture Mismatch

**Symptoms:**
- "Wrong architecture" errors
- Library loads but crashes

**Solutions:**
1. Build for correct architecture
2. Use universal binaries (iOS/macOS)
3. Check device architecture: `uname -m` (macOS)

### Linker Errors

**Symptoms:**
- Missing symbols
- Undefined references

**Solutions:**
1. Verify library is linked in build configuration
2. Check library search paths
3. Ensure all dependencies are available

---

## Test Results

### Integration Tests (Mock):
- ✅ 7/7 tests passing
- ✅ All FFI functions accessible
- ✅ Service layer working

### Platform Tests (Real FFI):
- ⏳ macOS: Pending build
- ⏳ Android: Pending build
- ⏳ iOS: Pending build

---

## Next Steps

1. **Build Rust libraries** for each platform
2. **Run platform tests** to verify integration
3. **Build Flutter apps** to verify end-to-end
4. **Test on devices** to verify real-world usage

---

**Status:** ⏳ Testing Guide Complete - Ready for Platform Testing
