# Phase 14: FFI Bindings Implementation Plan

**Date:** December 28, 2025  
**Status:** 📋 Ready for Implementation  
**Priority:** High - Blocks Signal Protocol Integration

---

## 🎯 **Objective**

Implement actual FFI bindings in `lib/core/crypto/signal/signal_ffi_bindings.dart` to connect Dart code with libsignal-ffi (Rust library).

---

## 📋 **Required Functions**

Based on `SignalProtocolService` requirements, the following functions must be implemented:

### **1. Identity Key Management**
- `generateIdentityKeyPair()` → Returns `SignalIdentityKeyPair`
- **libsignal-ffi function:** `signal_generate_identity_key_pair()`

### **2. Prekey Bundle Generation**
- `generatePreKeyBundle()` → Returns `SignalPreKeyBundle`
- **libsignal-ffi functions:**
  - `signal_generate_signed_pre_key()`
  - `signal_generate_one_time_pre_key()`
  - `signal_create_pre_key_bundle()`

### **3. Message Encryption**
- `encryptMessage()` → Returns `SignalEncryptedMessage`
- **libsignal-ffi function:** `signal_encrypt_message()`
- **Dependencies:**
  - Session state (from `SignalSessionManager`)
  - Recipient's prekey bundle

### **4. Message Decryption**
- `decryptMessage()` → Returns `Uint8List` (plaintext)
- **libsignal-ffi function:** `signal_decrypt_message()`
- **Dependencies:**
  - Session state (from `SignalSessionManager`)
  - Sender's identity key

### **5. Session Management**
- `establishSession()` → Creates/updates session state
- **libsignal-ffi function:** `signal_process_pre_key_bundle()`
- **Dependencies:**
  - Identity key pair
  - Prekey bundle

---

## 🔧 **Implementation Steps**

### **Step 1: Setup Environment (5-10 minutes)**

```bash
# Run setup script
./scripts/setup_signal_ffi.sh

# Or manually check:
rustc --version  # Should be 1.70+
cargo --version
```

### **Step 2: Obtain libsignal-ffi Library (10-30 minutes)**

**Option A: Pre-built Binaries (Recommended)**
1. Download from: https://github.com/signalapp/libsignal/releases
2. Extract to: `native/signal_ffi/{platform}/`
3. Organize by platform (android, ios, macos, linux, windows)

**Option B: Build from Source**
```bash
git clone https://github.com/signalapp/libsignal.git native/signal_ffi/libsignal
cd native/signal_ffi/libsignal
cargo build --release
# Copy built libraries to platform directories
```

### **Step 3: Update FFI Bindings File (2-4 hours)**

Replace `lib/core/crypto/signal/signal_ffi_bindings.dart` with actual implementation:

1. **Add imports:**
```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';
```

2. **Load library:**
```dart
DynamicLibrary _loadLibrary() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libsignal_ffi.so');
  } else if (Platform.isIOS) {
    return DynamicLibrary.process();
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('libsignal_ffi.dylib');
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libsignal_ffi.so');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('signal_ffi.dll');
  } else {
    throw SignalProtocolException('Unsupported platform');
  }
}
```

3. **Define function signatures:**
   - Reference: `libsignal-ffi` API documentation
   - Example structure in: `signal_ffi_bindings_template.dart`

4. **Implement wrapper methods:**
   - Handle memory allocation/deallocation
   - Convert between Dart and C types
   - Handle errors

### **Step 4: Platform-Specific Configuration**

#### **Android**
Update `android/app/build.gradle`:
```gradle
android {
    sourceSets {
        main {
            jniLibs.srcDirs = ['../native/signal_ffi/android']
        }
    }
}
```

#### **iOS**
1. Add framework to Xcode project
2. Link framework in `ios/Podfile` or Xcode settings

#### **macOS**
1. Add dylib to Xcode project
2. Configure library search paths

### **Step 5: Testing (1-2 hours)**

```bash
# Unit tests
flutter test test/core/crypto/signal/

# Platform tests
flutter run -d android
flutter run -d ios
flutter run -d macos
```

---

## 📚 **Reference Documentation**

### **libsignal-ffi API**
- **Repository:** https://github.com/signalapp/libsignal
- **FFI Documentation:** https://github.com/signalapp/libsignal/tree/main/rust/bridge/ffi
- **API Reference:** Check `libsignal-ffi` source code for exact function signatures

### **Dart FFI**
- **Guide:** https://dart.dev/guides/libraries/c-interop
- **Package:** https://pub.dev/packages/ffi

### **Template Files**
- `lib/core/crypto/signal/signal_ffi_bindings_template.dart` - Structure template
- `lib/core/crypto/signal/signal_ffi_bindings.dart` - Current placeholder (to replace)

---

## ⚠️ **Important Notes**

1. **Function Signatures:** libsignal-ffi API may change. Always check the latest documentation.

2. **Memory Management:** 
   - Use `malloc()` and `free()` from `package:ffi/ffi.dart`
   - Always free allocated memory
   - Use `try-finally` to ensure cleanup

3. **Error Handling:**
   - libsignal-ffi uses error codes
   - Convert C error codes to Dart exceptions
   - Provide meaningful error messages

4. **Platform Differences:**
   - Android: `.so` files in `jniLibs`
   - iOS: Framework linked at build time
   - macOS: `.dylib` files
   - Linux: `.so` files
   - Windows: `.dll` files

---

## ✅ **Success Criteria**

- [ ] FFI bindings compile without errors
- [ ] All required functions implemented
- [ ] Unit tests pass
- [ ] Works on all target platforms
- [ ] No memory leaks
- [ ] Error handling works correctly
- [ ] `SignalProtocolService` can use bindings

---

## 🆘 **Common Issues**

1. **Library not found:**
   - Check library path
   - Verify platform-specific configuration
   - Ensure library is in correct directory

2. **Function not found:**
   - Verify function name matches libsignal-ffi API
   - Check library version compatibility
   - Ensure library is loaded before binding

3. **Memory errors:**
   - Check for proper memory allocation/deallocation
   - Use `try-finally` for cleanup
   - Verify pointer validity before use

---

**Last Updated:** December 28, 2025  
**Status:** Ready for Implementation
