# Phase 14: Hybrid FFI Bindings Implementation Plan

**Date:** December 28, 2025  
**Status:** 📋 Hybrid Approach - Option A (Android) + Option B (iOS)  
**Strategy:** Use pre-built binaries where available, build from source where needed

---

## 🎯 **Strategy Overview**

**Hybrid Approach:**
- **Option A (Pre-built):** Android, macOS, Linux, Windows
- **Option B (Build from Source):** iOS (required - no pre-built binaries available)

**Rationale:**
- iOS has no pre-built binaries available from Signal
- Android has excellent Maven support with pre-built binaries
- Desktop platforms can use pre-built binaries (future support)
- This balances speed (Android) with completeness (iOS)

---

## 📋 **Platform Requirements**

### **Current SPOTS Platforms:**
- ✅ **Android** (Android 6+) - Use Option A
- ✅ **iOS** (iOS 13+) - Use Option B
- ⏳ **macOS** (Future) - Use Option A
- ⏳ **Linux** (Future) - Use Option A
- ⏳ **Windows** (Future) - Use Option A

---

## 🔧 **Implementation Steps**

### **Phase 1: Android (Option A - Pre-built Binaries)**

#### **Step 1.1: Setup Maven Repository Access**

Create `scripts/extract_signal_android_libs.sh`:

```bash
#!/bin/bash
# Extract native libraries from Signal's Maven packages for Android

set -e

echo "📦 Extracting Signal Protocol libraries for Android"
echo ""

# Create directory structure
mkdir -p native/signal_ffi/android/{armeabi-v7a,arm64-v8a,x86,x86_64}
mkdir -p temp/maven_extract

# Maven repository URL
MAVEN_REPO="https://build-artifacts.signal.org/libraries/maven"
GROUP_ID="org.signal"
ARTIFACT_ID="libsignal-android"
VERSION="latest"  # Update to specific version

echo "Downloading libsignal-android from Maven..."
# Note: This requires Maven or manual download
# For now, we'll document the manual process

echo ""
echo "Manual extraction steps:"
echo "1. Download libsignal-android JAR from:"
echo "   ${MAVEN_REPO}/${GROUP_ID//./\/}/${ARTIFACT_ID}/"
echo ""
echo "2. Extract JAR file:"
echo "   unzip libsignal-android-*.jar -d temp/maven_extract/"
echo ""
echo "3. Copy native libraries:"
echo "   cp temp/maven_extract/lib/armeabi-v7a/libsignal_jni.so native/signal_ffi/android/armeabi-v7a/"
echo "   cp temp/maven_extract/lib/arm64-v8a/libsignal_jni.so native/signal_ffi/android/arm64-v8a/"
echo "   cp temp/maven_extract/lib/x86/libsignal_jni.so native/signal_ffi/android/x86/"
echo "   cp temp/maven_extract/lib/x86_64/libsignal_jni.so native/signal_ffi/android/x86_64/"
echo ""
echo "4. Clean up:"
echo "   rm -rf temp/maven_extract"
echo ""
echo "✅ Android libraries extracted"
```

#### **Step 1.2: Configure Android Build**

Update `android/app/build.gradle`:

```gradle
android {
    // ... existing configuration ...
    
    sourceSets {
        main {
            jniLibs.srcDirs = ['../native/signal_ffi/android']
        }
    }
    
    // Exclude unnecessary native libraries to reduce app size
    packagingOptions {
        resources {
            excludes += [
                "libsignal_jni*.dylib",  // macOS libraries
                "signal_jni*.dll"        // Windows libraries
            ]
        }
    }
}
```

#### **Step 1.3: Test Android Integration**

```bash
# Build Android app
flutter build apk --debug

# Test on device/emulator
flutter run -d android
```

**Estimated Time:** 30-60 minutes

---

### **Phase 2: iOS (Option B - Build from Source)**

#### **Step 2.1: Install Rust Toolchain**

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Verify installation
rustc --version  # Should be 1.70+
cargo --version
```

#### **Step 2.2: Install iOS Build Dependencies**

```bash
# Install Xcode Command Line Tools (if not installed)
xcode-select --install

# Install additional tools
brew install cmake protobuf  # macOS only
```

#### **Step 2.3: Clone and Build libsignal-ffi for iOS**

```bash
# Create directory structure
mkdir -p native/signal_ffi/ios
cd native/signal_ffi

# Clone libsignal repository
git clone https://github.com/signalapp/libsignal.git libsignal
cd libsignal

# Add iOS targets
rustup target add aarch64-apple-ios        # iOS devices (ARM64)
rustup target add x86_64-apple-ios        # iOS simulator (Intel)
rustup target add aarch64-apple-ios-sim    # iOS simulator (Apple Silicon)

# Build for iOS devices
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (choose based on your Mac architecture)
# For Intel Macs:
cargo build --release --target x86_64-apple-ios
# For Apple Silicon Macs:
cargo build --release --target aarch64-apple-ios-sim

# The built library will be in:
# target/aarch64-apple-ios/release/libsignal_ffi.a
# target/x86_64-apple-ios/release/libsignal_ffi.a (Intel)
# target/aarch64-apple-ios-sim/release/libsignal_ffi.a (Apple Silicon)
```

#### **Step 2.4: Create iOS Framework**

Create `scripts/create_ios_framework.sh`:

```bash
#!/bin/bash
# Create iOS framework from built libsignal-ffi

set -e

echo "📱 Creating iOS framework for libsignal-ffi"
echo ""

FRAMEWORK_NAME="SignalFFI"
FRAMEWORK_DIR="native/signal_ffi/ios/${FRAMEWORK_NAME}.framework"
LIB_DIR="native/signal_ffi/libsignal/target"

# Create framework structure
mkdir -p "${FRAMEWORK_DIR}/Headers"
mkdir -p "${FRAMEWORK_DIR}/Modules"

# Copy static library
# Note: You may need to create a universal binary for both device and simulator
cp "${LIB_DIR}/aarch64-apple-ios/release/libsignal_ffi.a" \
   "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"

# Create module map
cat > "${FRAMEWORK_DIR}/Modules/module.modulemap" << EOF
framework module ${FRAMEWORK_NAME} {
    umbrella header "${FRAMEWORK_NAME}.h"
    export *
    module * { export * }
}
EOF

# Create umbrella header (if needed)
# Note: libsignal-ffi may provide C headers
touch "${FRAMEWORK_DIR}/Headers/${FRAMEWORK_NAME}.h"

echo "✅ iOS framework created at: ${FRAMEWORK_DIR}"
echo ""
echo "Next steps:"
echo "1. Add framework to Xcode project"
echo "2. Link framework in iOS build settings"
echo "3. Update FFI bindings to load framework"
```

#### **Step 2.5: Configure iOS Build**

Update `ios/Podfile` (if using CocoaPods):

```ruby
# Add SignalFFI framework
pod 'SignalFFI', :path => '../native/signal_ffi/ios'
```

Or manually add to Xcode project:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Drag `SignalFFI.framework` into project
3. Add to "Frameworks, Libraries, and Embedded Content"
4. Set "Embed & Sign"

#### **Step 2.6: Test iOS Integration**

```bash
# Build iOS app
flutter build ios --debug --no-codesign

# Test on simulator/device
flutter run -d ios
```

**Estimated Time:** 1-2 hours (first time), 30-60 minutes (subsequent builds)

---

### **Phase 3: Update FFI Bindings**

#### **Step 3.1: Platform-Specific Library Loading**

Update `lib/core/crypto/signal/signal_ffi_bindings.dart`:

```dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

DynamicLibrary _loadLibrary() {
  if (Platform.isAndroid) {
    // Android: Load from JNI
    return DynamicLibrary.open('libsignal_jni.so');
  } else if (Platform.isIOS) {
    // iOS: Load from framework (linked in Xcode project)
    return DynamicLibrary.process();
  } else if (Platform.isMacOS) {
    // macOS: Load from dylib
    return DynamicLibrary.open('libsignal_ffi.dylib');
  } else if (Platform.isLinux) {
    // Linux: Load from so
    return DynamicLibrary.open('libsignal_ffi.so');
  } else if (Platform.isWindows) {
    // Windows: Load from dll
    return DynamicLibrary.open('signal_ffi.dll');
  } else {
    throw SignalProtocolException('Unsupported platform: ${Platform.operatingSystem}');
  }
}
```

#### **Step 3.2: Implement Function Bindings**

Follow the structure in `signal_ffi_bindings_template.dart` and implement actual bindings based on libsignal-ffi API.

---

## 📁 **Project Structure**

```
SPOTS/
├── native/
│   └── signal_ffi/
│       ├── android/
│       │   ├── armeabi-v7a/
│       │   │   └── libsignal_jni.so
│       │   ├── arm64-v8a/
│       │   │   └── libsignal_jni.so
│       │   ├── x86/
│       │   │   └── libsignal_jni.so
│       │   └── x86_64/
│       │       └── libsignal_jni.so
│       ├── ios/
│       │   └── SignalFFI.framework/
│       │       ├── SignalFFI (binary)
│       │       ├── Headers/
│       │       └── Modules/
│       ├── libsignal/              # Source repository (for iOS builds)
│       │   └── (cloned repository)
│       ├── macos/                  # Future: extracted from Maven
│       ├── linux/                  # Future: extracted from Maven
│       └── windows/                # Future: extracted from Maven
├── scripts/
│   ├── extract_signal_android_libs.sh
│   └── create_ios_framework.sh
└── lib/
    └── core/
        └── crypto/
            └── signal/
                └── signal_ffi_bindings.dart
```

---

## ⏱️ **Time Estimates**

| Phase | Platform | Time | Notes |
|-------|----------|------|-------|
| Phase 1 | Android | 30-60 min | Pre-built binaries |
| Phase 2 | iOS | 1-2 hours | First build (includes Rust setup) |
| Phase 2 | iOS | 30-60 min | Subsequent builds |
| Phase 3 | FFI Bindings | 2-4 hours | Implementation |
| Phase 4 | Testing | 1-2 hours | All platforms |
| **Total** | **All** | **5-10 hours** | First-time setup |

---

## ✅ **Success Criteria**

### **Android:**
- [ ] Native libraries extracted from Maven packages
- [ ] Libraries placed in correct directory structure
- [ ] Android build includes native libraries
- [ ] FFI bindings load successfully
- [ ] Basic encryption/decryption works

### **iOS:**
- [ ] Rust toolchain installed
- [ ] libsignal-ffi built for iOS (device + simulator)
- [ ] Framework created and added to Xcode project
- [ ] FFI bindings load successfully
- [ ] Basic encryption/decryption works

### **Integration:**
- [ ] `SignalProtocolService` works on both platforms
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] No memory leaks
- [ ] Error handling works correctly

---

## 🆘 **Troubleshooting**

### **Android Issues:**

**Problem:** Libraries not found at runtime
- **Solution:** Verify `jniLibs.srcDirs` in `build.gradle`
- **Solution:** Check library architecture matches device

**Problem:** App size too large
- **Solution:** Use `packagingOptions` to exclude unused architectures
- **Solution:** Build separate APKs per architecture

### **iOS Issues:**

**Problem:** Build fails with "target not found"
- **Solution:** Run `rustup target add aarch64-apple-ios`
- **Solution:** Verify Xcode Command Line Tools installed

**Problem:** Framework not found at runtime
- **Solution:** Verify framework is embedded in Xcode project
- **Solution:** Check "Embed & Sign" setting

**Problem:** Simulator vs Device architecture mismatch
- **Solution:** Build universal binary or separate builds
- **Solution:** Use `lipo` to combine architectures

---

## 📚 **Reference Documentation**

- **Signal Maven Repository:** https://build-artifacts.signal.org/libraries/maven/
- **libsignal Repository:** https://github.com/signalapp/libsignal
- **Rust iOS Targets:** https://doc.rust-lang.org/nightly/rustc/platform-support.html
- **Dart FFI Guide:** https://dart.dev/guides/libraries/c-interop

---

## 🎯 **Next Steps**

1. **Start with Android (Option A):**
   - Extract libraries from Maven
   - Configure Android build
   - Test basic integration

2. **Then iOS (Option B):**
   - Set up Rust toolchain
   - Build libsignal-ffi
   - Create framework
   - Configure iOS build
   - Test integration

3. **Implement FFI Bindings:**
   - Update `signal_ffi_bindings.dart`
   - Implement all required functions
   - Test on both platforms

4. **Full Integration:**
   - Update `SignalProtocolService`
   - Add unit tests
   - Add integration tests
   - Test end-to-end

---

**Last Updated:** December 28, 2025  
**Status:** Ready for Implementation
