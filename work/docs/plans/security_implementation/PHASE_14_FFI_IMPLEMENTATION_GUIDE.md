# Phase 14: FFI Bindings Implementation Guide

**Date:** December 28, 2025  
**Status:** 📋 Implementation Guide  
**Next Step:** FFI Bindings Implementation

---

## 🎯 **Overview**

This guide provides step-by-step instructions for implementing actual FFI bindings to connect Dart code with libsignal-ffi (Rust library).

---

## 📋 **Prerequisites Checklist**

- [ ] Rust toolchain installed (`rustc --version` and `cargo --version`)
- [ ] Build tools installed (CMake, protobuf-compiler, etc.)
- [ ] libsignal-ffi library obtained (pre-built or built from source)
- [ ] Platform-specific build tools ready (Xcode for iOS, NDK for Android, etc.)

---

## 🔧 **Step-by-Step Implementation**

### **Step 1: Add FFI Package Dependency**

Add to `pubspec.yaml`:

```yaml
dependencies:
  ffi: ^2.1.0  # For FFI bindings
```

Then run:
```bash
flutter pub get
```

### **Step 2: Obtain libsignal-ffi Library**

**Option A: Use Pre-built Binaries (Recommended)**
1. Download from Signal's releases: https://github.com/signalapp/libsignal/releases
2. Extract to `native/signal_ffi/` directory
3. Organize by platform:
   ```
   native/signal_ffi/
   ├── android/
   │   └── libsignal_ffi.so
   ├── ios/
   │   └── SignalFFI.framework
   ├── macos/
   │   └── libsignal_ffi.dylib
   ├── linux/
   │   └── libsignal_ffi.so
   └── windows/
       └── signal_ffi.dll
   ```

**Option B: Build from Source**
```bash
git clone https://github.com/signalapp/libsignal.git
cd libsignal
cargo build --release

# Copy built libraries to native/signal_ffi/
```

### **Step 3: Update FFI Bindings File**

Replace `lib/core/crypto/signal/signal_ffi_bindings.dart` with actual bindings.

**Reference:** `lib/core/crypto/signal/signal_ffi_bindings_template.dart` for structure.

**Key Steps:**
1. Load library using `_loadLibrary()` method
2. Define function signatures (typedefs)
3. Bind functions using `_lib.lookup<NativeFunction<...>>()`
4. Implement Dart wrapper methods
5. Handle memory management (malloc/free)
6. Implement error handling

### **Step 4: Platform-Specific Configuration**

#### **Android**

**`android/app/build.gradle`:**
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

**`ios/Podfile`:**
```ruby
# Add SignalFFI framework
pod 'SignalFFI', :path => '../native/signal_ffi/ios'
```

**`ios/Runner.xcodeproj`:**
- Add framework to "Link Binary With Libraries"
- Set framework search paths

#### **macOS**

**`macos/Runner.xcodeproj`:**
- Add dylib to "Link Binary With Libraries"
- Set library search paths

#### **Linux**

**`linux/CMakeLists.txt`:**
```cmake
target_link_libraries(runner PRIVATE signal_ffi)
```

#### **Windows**

**`windows/CMakeLists.txt`:**
```cmake
target_link_libraries(runner PRIVATE signal_ffi)
```

### **Step 5: Implement Function Bindings**

For each libsignal-ffi function:

1. **Define Native Function Signature:**
```dart
typedef NativeGenerateIdentityKeyPair = Pointer Function();
typedef GenerateIdentityKeyPair = Pointer Function();
```

2. **Bind Function:**
```dart
final _generateIdentityKeyPair = _lib!
    .lookup<NativeFunction<NativeGenerateIdentityKeyPair>>(
        'signal_generate_identity_key_pair')
    .asFunction<GenerateIdentityKeyPair>();
```

3. **Implement Dart Wrapper:**
```dart
Future<SignalIdentityKeyPair> generateIdentityKeyPair() async {
  final resultPtr = _generateIdentityKeyPair();
  if (resultPtr == nullptr) {
    _checkError();
    throw SignalProtocolException('Failed to generate identity key pair');
  }
  
  // Parse result and convert to Dart types
  // ... (implementation specific to libsignal-ffi API)
  
  return SignalIdentityKeyPair(/* ... */);
}
```

### **Step 6: Memory Management**

**Always free allocated memory:**

```dart
final ptr = malloc<Uint8>(length);
try {
  // Use ptr
  ptr.asTypedList(length).setAll(0, data);
  
  // Call FFI function
  final result = _ffiFunction(ptr, length);
  
  return result;
} finally {
  malloc.free(ptr); // Always free
}
```

### **Step 7: Error Handling**

```dart
void _checkError() {
  final errorPtr = _getLastError();
  if (errorPtr != nullptr) {
    final error = errorPtr.toDartString();
    throw SignalProtocolException('FFI error: $error');
  }
}
```

---

## 🧪 **Testing Strategy**

### **1. Unit Tests**

Test each FFI function binding:

```dart
test('generateIdentityKeyPair creates valid key pair', () async {
  final bindings = SignalFFIBindings();
  await bindings.initialize();
  
  final keyPair = await bindings.generateIdentityKeyPair();
  
  expect(keyPair.publicKey, isNotNull);
  expect(keyPair.privateKey, isNotNull);
  expect(keyPair.publicKey.length, greaterThan(0));
  expect(keyPair.privateKey.length, greaterThan(0));
});
```

### **2. Integration Tests**

Test full Signal Protocol flow:

```dart
test('full encryption/decryption flow', () async {
  // Generate identity keys
  // Create prekey bundles
  // Perform X3DH key exchange
  // Encrypt message
  // Decrypt message
  // Verify plaintext matches
});
```

### **3. Platform Tests**

Test on each platform:
- Android (ARM, x86)
- iOS (simulator, device)
- macOS
- Linux
- Windows

---

## ⚠️ **Common Issues & Solutions**

### **Issue 1: Library Not Found**

**Symptoms:**
- `DynamicLibrary.open()` throws exception
- "Library not found" error

**Solutions:**
- Verify library is in correct location
- Check library search paths
- Ensure library is linked in build configuration
- Verify library architecture matches platform (ARM vs x86)

### **Issue 2: Memory Leaks**

**Symptoms:**
- App memory usage increases over time
- Crashes after many operations

**Solutions:**
- Always free allocated memory in `finally` blocks
- Use `malloc.free()` for all `malloc()` calls
- Check for double-free errors
- Use memory profiling tools

### **Issue 3: Thread Safety**

**Symptoms:**
- Random crashes
- Data corruption

**Solutions:**
- libsignal-ffi is thread-safe, but ensure Dart calls are synchronized if needed
- Use locks for shared state
- Test concurrent operations

### **Issue 4: Platform-Specific Issues**

**Symptoms:**
- Works on one platform, fails on another
- Different behavior across platforms

**Solutions:**
- Test on each platform
- Handle platform-specific quirks
- Check platform-specific documentation

---

## 📚 **libsignal-ffi API Reference**

### **Key Functions to Bind**

#### **Identity Keys**
- `signal_generate_identity_key_pair()` - Generate identity key pair
- `signal_identity_key_pair_get_public_key()` - Get public key
- `signal_identity_key_pair_get_private_key()` - Get private key

#### **Prekeys**
- `signal_generate_signed_prekey()` - Generate signed prekey
- `signal_generate_one_time_prekey()` - Generate one-time prekey
- `signal_pre_key_bundle_create()` - Create prekey bundle

#### **X3DH Key Exchange**
- `signal_x3dh_initiate_key_exchange()` - Initiate X3DH
- `signal_x3dh_complete_key_exchange()` - Complete X3DH

#### **Double Ratchet**
- `signal_double_ratchet_encrypt()` - Encrypt message
- `signal_double_ratchet_decrypt()` - Decrypt message
- `signal_double_ratchet_create_session()` - Create session

#### **Session Management**
- `signal_session_save()` - Save session state
- `signal_session_load()` - Load session state
- `signal_session_delete()` - Delete session

**Note:** Actual function names and signatures may vary. Check libsignal-ffi documentation for exact API.

---

## ✅ **Implementation Checklist**

- [ ] Rust toolchain installed
- [ ] libsignal-ffi library obtained/built
- [ ] FFI package added to `pubspec.yaml`
- [ ] Library loading implemented
- [ ] Function signatures defined
- [ ] Functions bound to native library
- [ ] Dart wrapper methods implemented
- [ ] Memory management implemented
- [ ] Error handling implemented
- [ ] Unit tests written
- [ ] Integration tests written
- [ ] Android tested
- [ ] iOS tested
- [ ] macOS tested
- [ ] Linux tested (if applicable)
- [ ] Windows tested (if applicable)

---

## 🔗 **Resources**

- **libsignal-ffi Repository:** https://github.com/signalapp/libsignal
- **libsignal-ffi Documentation:** https://github.com/signalapp/libsignal/tree/main/rust/bridge/ffi
- **Dart FFI Guide:** https://dart.dev/guides/libraries/c-interop
- **FFI Package:** https://pub.dev/packages/ffi
- **Signal Protocol Specification:** https://signal.org/docs/

---

## 📝 **Next Steps After FFI Bindings**

1. **Test FFI Bindings**
   - Run unit tests
   - Run integration tests
   - Test on all platforms

2. **Integrate with Protocols**
   - Use integration helpers to add Signal Protocol
   - Update `AI2AIProtocol`
   - Update `AnonymousCommunicationProtocol`

3. **Full Testing**
   - End-to-end tests
   - Security validation
   - Performance testing

---

**Last Updated:** December 28, 2025  
**Status:** Implementation Guide Complete - Ready for FFI Bindings
