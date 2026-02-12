# Platform Setup: Android

**Date:** December 28, 2025  
**Status:** ⏳ Setup Guide  
**Purpose:** Configure Android to use Rust knot_math library

---

## Overview

Android requires Rust libraries to be compiled for specific architectures and placed in `jniLibs` directories.

---

## Prerequisites

1. **Rust toolchains for Android:**
   ```bash
   rustup target add aarch64-linux-android
   rustup target add armv7-linux-androideabi
   rustup target add x86_64-linux-android
   rustup target add i686-linux-android
   ```

2. **Android NDK:** Required for linking (usually comes with Android Studio)

---

## Build Script

Create `scripts/build_rust_android.sh`:

```bash
#!/bin/bash
# Build Rust library for Android platforms

set -e

cd native/knot_math

# Build for all Android architectures
echo "Building for aarch64-linux-android..."
cargo build --target aarch64-linux-android --release

echo "Building for armv7-linux-androideabi..."
cargo build --target armv7-linux-androideabi --release

echo "Building for x86_64-linux-android..."
cargo build --target x86_64-linux-android --release

echo "Building for i686-linux-android..."
cargo build --target i686-linux-android --release

# Copy libraries to Android project
echo "Copying libraries to Android project..."

mkdir -p ../../android/app/src/main/jniLibs/arm64-v8a
mkdir -p ../../android/app/src/main/jniLibs/armeabi-v7a
mkdir -p ../../android/app/src/main/jniLibs/x86_64
mkdir -p ../../android/app/src/main/jniLibs/x86

cp target/aarch64-linux-android/release/libknot_math.so \
   ../../android/app/src/main/jniLibs/arm64-v8a/

cp target/armv7-linux-androideabi/release/libknot_math.so \
   ../../android/app/src/main/jniLibs/armeabi-v7a/

cp target/x86_64-linux-android/release/libknot_math.so \
   ../../android/app/src/main/jniLibs/x86_64/

cp target/i686-linux-android/release/libknot_math.so \
   ../../android/app/src/main/jniLibs/x86/

echo "✅ Android libraries built and copied successfully"
```

---

## Android Configuration

### 1. Update `android/app/build.gradle`

Add to `android` block:

```gradle
android {
    // ... existing configuration ...
    
    sourceSets {
        main {
            jniLibs.srcDirs = ['src/main/jniLibs']
        }
    }
}
```

### 2. Update `android/build.gradle` (if needed)

Ensure NDK version is specified:

```gradle
android {
    ndkVersion "25.1.8937393" // Or your NDK version
}
```

---

## Testing

### Build and Test:

```bash
# 1. Build Rust libraries
./scripts/build_rust_android.sh

# 2. Build Flutter app
flutter build apk --debug

# 3. Run on Android device/emulator
flutter run
```

### Verify Library Loading:

The library should be automatically loaded by flutter_rust_bridge when the app starts.

---

## Troubleshooting

### Library Not Found:
- Check `jniLibs` directory structure
- Verify library names match (`libknot_math.so`)
- Check `build.gradle` sourceSets configuration

### Architecture Mismatch:
- Ensure all required architectures are built
- Check device architecture: `adb shell getprop ro.product.cpu.abi`

### Build Errors:
- Verify NDK is installed
- Check Rust toolchain installation
- Ensure Cargo.toml has `crate-type = ["cdylib"]`

---

**Status:** ⏳ Setup Guide Complete - Ready for Implementation
