# Phase 14.3: Platform-Specific Testing Plan

**Date:** December 28, 2025  
**Status:** 📋 Planning - macOS Complete, Other Platforms Pending  
**Phase:** 14.3 (FFI Bindings Implementation)

---

## 🎯 **Overview**

Phase 14.3 FFI bindings are **100% complete** for macOS. This document outlines the plan for expanding to other platforms (Android, iOS, Linux, Windows).

---

## ✅ **Completed (macOS)**

- ✅ FFI bindings implemented and tested
- ✅ Native library loading working
- ✅ All core functionality verified (identity keys, prekeys, X3DH, encryption, decryption)
- ✅ Python experiments: 12/12 tests passing
- ✅ Flutter tests: functionality working
- ✅ Production safeguards in place

---

## 📋 **Platform Expansion Plan**

### **Android**

#### **Prerequisites**
- [ ] Android NDK installed
- [ ] Rust toolchain for Android targets:
  - `rustup target add aarch64-linux-android`
  - `rustup target add armv7-linux-androideabi`
  - `rustup target add x86_64-linux-android`
  - `rustup target add i686-linux-android`

#### **Implementation Steps**
1. **Build libsignal-ffi for Android**
   ```bash
   cd native/signal_ffi
   cargo build --target aarch64-linux-android --release
   # Repeat for other targets
   ```

2. **Create Android JNI wrapper** (if needed)
   - Place `.so` files in `android/app/src/main/jniLibs/{arch}/`
   - Update `build.gradle` to include native libraries

3. **Update Dart FFI bindings**
   - Add Android library path detection
   - Test library loading on Android device/emulator

4. **Testing**
   - Unit tests on Android emulator
   - Integration tests on physical device
   - Verify all FFI functions work

**Estimated Time:** 4-6 hours

---

### **iOS**

#### **Prerequisites**
- [ ] Xcode installed
- [ ] Rust toolchain for iOS targets:
  - `rustup target add aarch64-apple-ios` (device)
  - `rustup target add x86_64-apple-ios` (simulator)
  - `rustup target add aarch64-apple-ios-sim` (Apple Silicon simulator)

#### **Implementation Steps**
1. **Build libsignal-ffi for iOS**
   ```bash
   cd native/signal_ffi
   cargo build --target aarch64-apple-ios --release
   cargo build --target x86_64-apple-ios --release
   cargo build --target aarch64-apple-ios-sim --release
   ```

2. **Create iOS framework** (if needed)
   - Create Xcode framework project
   - Link libsignal-ffi static library
   - Update `Podfile` to include framework

3. **Update Dart FFI bindings**
   - Add iOS library path detection
   - Handle simulator vs device differences
   - Test library loading on iOS device/simulator

4. **Testing**
   - Unit tests on iOS simulator
   - Integration tests on physical device
   - Verify all FFI functions work

**Estimated Time:** 4-6 hours

---

### **Linux**

#### **Prerequisites**
- [ ] Rust toolchain for Linux
- [ ] Build dependencies: `pkg-config`, `libssl-dev`, `libclang-dev`

#### **Implementation Steps**
1. **Build libsignal-ffi for Linux**
   ```bash
   cd native/signal_ffi
   cargo build --target x86_64-unknown-linux-gnu --release
   # Or for ARM: cargo build --target aarch64-unknown-linux-gnu --release
   ```

2. **Update Dart FFI bindings**
   - Add Linux library path detection
   - Handle `.so` file loading
   - Test library loading on Linux system

3. **Testing**
   - Unit tests on Linux system
   - Integration tests
   - Verify all FFI functions work

**Estimated Time:** 2-3 hours

---

### **Windows**

#### **Prerequisites**
- [ ] Rust toolchain for Windows
- [ ] Visual Studio Build Tools (for C++ compilation)
- [ ] Windows SDK

#### **Implementation Steps**
1. **Build libsignal-ffi for Windows**
   ```bash
   cd native/signal_ffi
   cargo build --target x86_64-pc-windows-msvc --release
   # Or for ARM: cargo build --target aarch64-pc-windows-msvc --release
   ```

2. **Update Dart FFI bindings**
   - Add Windows library path detection
   - Handle `.dll` file loading
   - Test library loading on Windows system

3. **Testing**
   - Unit tests on Windows system
   - Integration tests
   - Verify all FFI functions work

**Estimated Time:** 3-4 hours

---

## 🔧 **Common Implementation Tasks**

### **1. Update Library Path Detection**

Add platform-specific paths to `SignalFFIBindings._loadLibrary()`:

```dart
String _getLibraryPath() {
  if (Platform.isAndroid) {
    // Android: Load from JNI libraries
    return 'libsignal_ffi.so';
  } else if (Platform.isIOS) {
    // iOS: Load from framework
    return 'libsignal_ffi.framework/libsignal_ffi';
  } else if (Platform.isLinux) {
    // Linux: Load from system or bundled path
    return 'libsignal_ffi.so';
  } else if (Platform.isWindows) {
    // Windows: Load DLL
    return 'signal_ffi.dll';
  } else if (Platform.isMacOS) {
    // macOS: Already implemented
    return 'libsignal_ffi.dylib';
  }
  throw UnsupportedError('Platform not supported: ${Platform.operatingSystem}');
}
```

### **2. Update Build Scripts**

Create platform-specific build scripts:
- `scripts/build_signal_ffi_android.sh`
- `scripts/build_signal_ffi_ios.sh`
- `scripts/build_signal_ffi_linux.sh`
- `scripts/build_signal_ffi_windows.sh`

### **3. Update CI/CD**

Add platform-specific test jobs:
- Android: Test on emulator
- iOS: Test on simulator
- Linux: Test on GitHub Actions runner
- Windows: Test on GitHub Actions runner

---

## 📊 **Testing Strategy**

### **Unit Tests**
- Test library loading on each platform
- Test all FFI functions (identity keys, prekeys, X3DH, encryption, decryption)
- Test error handling
- Test memory management

### **Integration Tests**
- Test full Signal Protocol flow (key exchange → encryption → decryption)
- Test session persistence
- Test key rotation

### **Platform-Specific Considerations**

#### **Android**
- Test on multiple architectures (ARM, x86)
- Test on different Android versions (API 21+)
- Handle JNI library loading

#### **iOS**
- Test on simulator and device
- Handle code signing
- Test on different iOS versions (iOS 12+)

#### **Linux**
- Test on different distributions (Ubuntu, Debian, etc.)
- Handle library dependencies
- Test on different architectures (x86_64, ARM)

#### **Windows**
- Test on different Windows versions (Windows 10+)
- Handle DLL loading
- Test on different architectures (x86_64, ARM)

---

## 🎯 **Success Criteria**

### **Phase 14.3 Complete When:**
- [x] macOS: FFI bindings working ✅
- [ ] Android: FFI bindings working
- [ ] iOS: FFI bindings working
- [ ] Linux: FFI bindings working
- [ ] Windows: FFI bindings working
- [ ] All platforms: Unit tests passing
- [ ] All platforms: Integration tests passing
- [ ] All platforms: Production safeguards verified

---

## 📝 **Notes**

- **macOS is complete** - All core functionality verified
- **Other platforms** - Can be implemented incrementally as needed
- **Priority:** Android and iOS are highest priority (mobile platforms)
- **Linux and Windows** - Lower priority (desktop platforms)

---

## 🔗 **Resources**

- **libsignal-ffi:** https://github.com/signalapp/libsignal
- **Dart FFI:** https://dart.dev/guides/libraries/c-interop
- **Rust Cross-Compilation:** https://rust-lang.github.io/rustup/cross-compilation.html
- **Android NDK:** https://developer.android.com/ndk
- **iOS Framework Guide:** https://developer.apple.com/documentation/xcode/building-a-framework

---

**Last Updated:** December 28, 2025  
**Status:** Planning - macOS Complete, Other Platforms Pending
