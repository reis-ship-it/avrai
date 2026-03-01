# Phase 14: C Wrapper Implementation Complete

**Date:** December 29, 2025  
**Status:** ✅ Complete (Implementation)  
**Next Step:** Build wrapper library and test

---

## ✅ **Summary of Accomplishments**

This document summarizes the completion of the C wrapper implementation for Signal Protocol store callbacks, which solves the Dart FFI limitation where complex callback signatures cannot be used directly in struct fields.

### **1. C Wrapper Library Created**

Created a complete C wrapper library in `native/signal_ffi/wrapper/`:

- **`wrapper.h`**: Header file with function declarations for:
  - Callback registration functions (7 functions)
  - Wrapper functions that match libsignal-ffi's expected signatures (7 functions)
  
- **`wrapper.c`**: Implementation with:
  - Global callback registry (stores registered Dart callbacks)
  - Registration functions (store Dart callbacks in registry)
  - Wrapper functions (look up registered callbacks and invoke them)

- **`CMakeLists.txt`**: Build configuration for Android and Linux

- **`build.sh`**: Build script for Android, Linux, and macOS

- **`build_ios.sh`**: Build script for iOS and macOS using Xcode

### **2. Dart Integration Updated**

Updated Dart code to use the C wrapper:

- **`SignalFFIBindings`** (`lib/core/crypto/signal/signal_ffi_bindings.dart`):
  - Added `_loadWrapperLibrary()` method for platform-specific library loading
  - Added `initializeWrapperLibrary()` method to load and bind wrapper functions
  - Added callback registration methods (7 methods)
  - Added wrapper function pointer getters (7 getters)
  - Added struct definitions needed for wrapper function signatures
  - Updated `initialize()` to optionally initialize wrapper library

- **`SignalFFIStoreCallbacks`** (`lib/core/crypto/signal/signal_ffi_store_callbacks.dart`):
  - Updated constructor to require `SignalFFIBindings` parameter
  - Added `_registerCallbacks()` method to register all callbacks with wrapper library
  - Updated `createSessionStore()` to use wrapper function pointers
  - Updated `createIdentityKeyStore()` to use wrapper function pointers
  - Updated callback implementations to use simplified signatures (all pointers as `void*`)
  - Updated callback typedefs to match simplified signatures

- **Test file** (`test/core/crypto/signal/signal_ffi_store_callbacks_test.dart`):
  - Updated to initialize wrapper library before creating `SignalFFIStoreCallbacks`
  - Updated to pass `ffiBindings` parameter

### **3. Architecture**

The solution uses a two-layer approach:

1. **Dart → C Registration**: Dart creates function pointers with simplified signatures (all `void*`) and registers them with the C wrapper library.

2. **C → Dart Invocation**: When libsignal-ffi calls a wrapper function, the wrapper looks up the registered Dart callback and invokes it with the parameters converted to `void*`.

3. **Store Structs**: The store structs use wrapper function pointers (which have the exact signatures libsignal-ffi expects), not the Dart callbacks directly.

### **4. How It Works**

```
libsignal-ffi calls wrapper function
    ↓
Wrapper function looks up registered Dart callback
    ↓
Wrapper converts parameters to void* and calls Dart callback
    ↓
Dart callback casts parameters back to proper types and implements logic
    ↓
Dart callback returns result
    ↓
Wrapper returns result to libsignal-ffi
```

---

## ⚠️ **Next Steps**

### **1. Build Wrapper Library**

The C wrapper library needs to be built for each platform:

```bash
# Android/Linux/macOS
cd native/signal_ffi/wrapper
./build.sh

# iOS/macOS (Xcode)
./build_ios.sh
```

**Prerequisites:**
- CMake (for Android/Linux/macOS)
- Xcode (for iOS/macOS)
- Android NDK (for Android, if building for Android)

### **2. Update Build Configuration**

Update platform-specific build configurations to include the wrapper library:

- **Android**: Update `android/app/build.gradle` to include wrapper library in `jniLibs`
- **iOS**: Add wrapper library to Xcode project and link it
- **macOS**: Add wrapper library to Xcode project and link it
- **Linux**: Update CMakeLists.txt to link wrapper library

### **3. Test**

Once the wrapper library is built and linked:

1. Run unit tests: `flutter test test/core/crypto/signal/signal_ffi_store_callbacks_test.dart`
2. Test on actual devices/simulators
3. Verify that store callbacks are invoked correctly

### **4. Implement Callback Logic**

The callback implementations currently have `TODO` comments. These need to be implemented:

- `_loadSessionCallback`: Load session from `sessionManager`
- `_storeSessionCallback`: Store session via `sessionManager`
- `_getIdentityKeyPairCallback`: Get identity key pair from `keyManager`
- `_getLocalRegistrationIdCallback`: Get registration ID from `keyManager`
- `_saveIdentityKeyCallback`: Save identity key via `keyManager`
- `_getIdentityKeyCallback`: Get identity key from `keyManager`
- `_isTrustedIdentityCallback`: Check trust via `keyManager`

---

## 📚 **Files Created/Modified**

### **Created:**
- `native/signal_ffi/wrapper/wrapper.h`
- `native/signal_ffi/wrapper/wrapper.c`
- `native/signal_ffi/wrapper/CMakeLists.txt`
- `native/signal_ffi/wrapper/build.sh`
- `native/signal_ffi/wrapper/build_ios.sh`
- `docs/plans/security_implementation/PHASE_14_C_WRAPPER_IMPLEMENTATION_COMPLETE.md`

### **Modified:**
- `lib/core/crypto/signal/signal_ffi_bindings.dart`
- `lib/core/crypto/signal/signal_ffi_store_callbacks.dart`
- `test/core/crypto/signal/signal_ffi_store_callbacks_test.dart`

---

## ✅ **Status**

- ✅ C wrapper library created (header, implementation, build configs)
- ✅ Dart integration updated (bindings, store callbacks, tests)
- ⏳ Wrapper library needs to be built
- ⏳ Build configurations need to be updated
- ⏳ Callback logic needs to be implemented

---

## 🎯 **Next Recommended Step**

Build the wrapper library for at least one platform (e.g., macOS for development) and test the integration:

```bash
cd native/signal_ffi/wrapper
./build_ios.sh  # or ./build.sh for Linux/macOS
```

Then update the build configuration to link the wrapper library and test.
