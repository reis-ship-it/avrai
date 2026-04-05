# Phase 14: FFI Bindings Roadmap

**Date:** December 28, 2025  
**Status:** 📋 Roadmap  
**Next Step:** FFI Bindings Implementation

---

## 🎯 **Objective**

Create actual FFI bindings to connect Dart code with libsignal-ffi (Rust library) to enable full Signal Protocol functionality.

---

## 📋 **Prerequisites**

### **1. Rust Toolchain**
- Install Rust: https://rustup.rs/
- Verify installation: `rustc --version` and `cargo --version`
- Required version: Rust 1.70+ (libsignal-ffi requirement)

### **2. Build Tools**

**macOS:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install additional tools (if needed)
brew install cmake protobuf
```

**Linux:**
```bash
sudo apt-get install clang libclang-dev cmake make protobuf-compiler
```

**Windows:**
- Install Visual Studio Build Tools
- Install CMake
- Install Protocol Buffers compiler

### **3. libsignal-ffi Library**

**Option A: Use Pre-built Binaries (Recommended)**
- Download from Signal's releases
- Place in `native/signal_ffi/` directory

**Option B: Build from Source**
```bash
git clone https://github.com/signalapp/libsignal.git
cd libsignal
cargo build --release
```

---

## 🔧 **Implementation Steps**

### **Step 1: Project Structure Setup**

Create directory structure:
```
SPOTS/
├── native/
│   └── signal_ffi/
│       ├── android/          # Android .so files
│       ├── ios/              # iOS framework
│       ├── macos/            # macOS .dylib
│       ├── linux/            # Linux .so
│       └── windows/          # Windows .dll
├── lib/
│   └── core/
│       └── crypto/
│           └── signal/
│               └── signal_ffi_bindings.dart  # Update with actual bindings
```

### **Step 2: Platform-Specific Library Loading**

Update `signal_ffi_bindings.dart`:

```dart
import 'dart:ffi';
import 'dart:io';

DynamicLibrary _loadLibrary() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libsignal_ffi.so');
  } else if (Platform.isIOS) {
    return DynamicLibrary.process(); // Framework linked
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('libsignal_ffi.dylib');
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libsignal_ffi.so');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('signal_ffi.dll');
  } else {
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
```

### **Step 3: Function Signatures**

Define FFI function signatures based on libsignal-ffi API:

```dart
// Example: Identity key generation
typedef NativeGenerateIdentityKeyPair = Pointer Function();
typedef GenerateIdentityKeyPair = Pointer Function();

final _generateIdentityKeyPair = _lib
    .lookup<NativeFunction<NativeGenerateIdentityKeyPair>>(
        'signal_generate_identity_key_pair')
    .asFunction<GenerateIdentityKeyPair>();

// Example: Message encryption
typedef NativeEncryptMessage = Pointer Function(
  Pointer<Uint8> plaintext,
  Int32 length,
  Pointer<Utf8> recipientId,
);
typedef EncryptMessage = Pointer Function(
  Pointer<Uint8> plaintext,
  int length,
  Pointer<Utf8> recipientId,
);
```

### **Step 4: Memory Management**

Handle memory allocation/deallocation:

```dart
Future<Uint8List> encryptMessageDart(
  Uint8List plaintext,
  String recipientId,
) async {
  // Allocate memory
  final plaintextPtr = malloc<Uint8>(plaintext.length);
  plaintextPtr.asTypedList(plaintext.length).setAll(0, plaintext);
  
  final recipientIdPtr = recipientId.toNativeUtf8();
  
  try {
    // Call FFI function
    final resultPtr = encryptMessage(
      plaintextPtr,
      plaintext.length,
      recipientIdPtr,
    );
    
    // Copy result back to Dart
    final result = resultPtr.asTypedList(/* length */).toList();
    
    return Uint8List.fromList(result);
  } finally {
    // Free memory
    malloc.free(plaintextPtr);
    malloc.free(recipientIdPtr);
  }
}
```

### **Step 5: Error Handling**

Handle FFI errors:

```dart
String? _getLastError() {
  final errorPtr = _lib.lookup<NativeFunction<...>>('signal_get_last_error')();
  if (errorPtr == nullptr) {
    return null;
  }
  final error = errorPtr.toDartString();
  return error;
}

void _checkError() {
  final error = _getLastError();
  if (error != null) {
    throw SignalProtocolException('FFI error: $error');
  }
}
```

---

## 📚 **libsignal-ffi API Reference**

Key functions to bind:

### **Identity Keys**
- `signal_generate_identity_key_pair()`
- `signal_identity_key_pair_get_public_key()`
- `signal_identity_key_pair_get_private_key()`

### **Prekeys**
- `signal_generate_signed_prekey()`
- `signal_generate_one_time_prekey()`
- `signal_pre_key_bundle_create()`

### **X3DH Key Exchange**
- `signal_x3dh_initiate_key_exchange()`
- `signal_x3dh_complete_key_exchange()`

### **Double Ratchet**
- `signal_double_ratchet_encrypt()`
- `signal_double_ratchet_decrypt()`
- `signal_double_ratchet_create_session()`

### **Session Management**
- `signal_session_save()`
- `signal_session_load()`
- `signal_session_delete()`

---

## 🧪 **Testing Strategy**

### **1. Unit Tests**
- Test each FFI function binding
- Test memory management
- Test error handling

### **2. Integration Tests**
- Test identity key generation
- Test prekey bundle creation
- Test X3DH key exchange
- Test message encryption/decryption

### **3. End-to-End Tests**
- Test full Signal Protocol flow
- Test session persistence
- Test key rotation

---

## ⚠️ **Common Issues & Solutions**

### **Issue 1: Library Not Found**
**Solution:** Ensure library is in correct location and linked properly

### **Issue 2: Memory Leaks**
**Solution:** Always free allocated memory in finally blocks

### **Issue 3: Thread Safety**
**Solution:** Ensure FFI calls are thread-safe (libsignal-ffi is thread-safe)

### **Issue 4: Platform-Specific Issues**
**Solution:** Test on each platform, handle platform-specific quirks

---

## 📝 **Implementation Checklist**

- [ ] Rust toolchain installed
- [ ] libsignal-ffi library obtained/built
- [ ] Project structure created
- [ ] Library loading implemented
- [ ] Function signatures defined
- [ ] Memory management implemented
- [ ] Error handling implemented
- [ ] Unit tests written
- [ ] Integration tests written
- [ ] All platforms tested

---

## 🔗 **Resources**

- **libsignal-ffi Documentation:** https://github.com/signalapp/libsignal
- **Dart FFI Guide:** https://dart.dev/guides/libraries/c-interop
- **Signal Protocol Specification:** https://signal.org/docs/

---

**Last Updated:** December 28, 2025  
**Status:** Roadmap Complete - Ready for Implementation
