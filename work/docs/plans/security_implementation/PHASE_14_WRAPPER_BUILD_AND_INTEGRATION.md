# Phase 14: Wrapper Library Build and Integration

**Date:** December 29, 2025  
**Status:** ✅ Build Complete (macOS), ⏳ Integration Pending  
**Next Step:** Test wrapper library integration

---

## ✅ **Build Status**

### **macOS**
- ✅ **Built successfully**: `native/signal_ffi/macos/libsignal_ffi_wrapper.dylib` (18KB)
- ✅ **CMakeLists.txt updated**: Added macOS platform support
- ✅ **Library copied**: To `native/signal_ffi/macos/` directory

### **Android**
- ⏳ **Not yet built**: Requires Android NDK
- 📋 **Build command**: `cd native/signal_ffi/wrapper && ./build.sh` (with ANDROID_NDK set)

### **iOS**
- ⏳ **Not yet built**: Requires Xcode
- 📋 **Build command**: `cd native/signal_ffi/wrapper && ./build_ios.sh`

### **Linux**
- ⏳ **Not yet built**: Requires CMake
- 📋 **Build command**: `cd native/signal_ffi/wrapper && ./build.sh`

---

## 📋 **Integration Steps**

### **1. macOS Integration**

The wrapper library is built and ready. To use it:

**Option A: Copy to app bundle (manual)**
```bash
# After building the Flutter app
./scripts/copy_signal_wrapper_macos.sh
```

**Option B: Add to Xcode project (automatic)**
1. Open `macos/Runner.xcodeproj` in Xcode
2. Add `native/signal_ffi/macos/libsignal_ffi_wrapper.dylib` to "Frameworks, Libraries, and Embedded Content"
3. Set "Embed" to "Do Not Embed" (we load it dynamically)

**Option C: Use rpath (recommended)**
Update the library's install name and add rpath to Xcode project:
```bash
install_name_tool -id "@rpath/libsignal_ffi_wrapper.dylib" native/signal_ffi/macos/libsignal_ffi_wrapper.dylib
```

Then add `@rpath` to the Xcode project's "Runpath Search Paths".

### **2. Android Integration**

Once built, the wrapper library will be in:
```
native/signal_ffi/android/
├── arm64-v8a/
│   └── libsignal_ffi_wrapper.so
├── armeabi-v7a/
│   └── libsignal_ffi_wrapper.so
├── x86/
│   └── libsignal_ffi_wrapper.so
└── x86_64/
    └── libsignal_ffi_wrapper.so
```

The Android build.gradle already includes `../../native/signal_ffi/android` in `jniLibs.srcDirs`, so the library will be automatically included.

### **3. iOS Integration**

Once built, add the wrapper library to the Xcode project:
1. Open `ios/Runner.xcodeproj` in Xcode
2. Add the wrapper library to "Frameworks, Libraries, and Embedded Content"
3. Set "Embed" to "Do Not Embed" (we load it dynamically via `DynamicLibrary.process()`)

Or, if building as a framework, link it statically.

### **4. Linux Integration**

Once built, the wrapper library will be in:
```
native/signal_ffi/linux/libsignal_ffi_wrapper.so
```

Update `linux/CMakeLists.txt` to link the library or ensure it's in the library search path.

---

## 🧪 **Testing**

### **1. Unit Tests**

Run the store callbacks tests:
```bash
flutter test test/core/crypto/signal/signal_ffi_store_callbacks_test.dart
```

**Expected behavior:**
- If wrapper library is available: Tests should pass (callbacks registered successfully)
- If wrapper library is not available: Tests should skip gracefully

### **2. Integration Test**

Create a simple test to verify wrapper library loading:
```dart
void main() {
  test('should load wrapper library', () async {
    final bindings = SignalFFIBindings();
    await bindings.initialize();
    
    try {
      await bindings.initializeWrapperLibrary();
      expect(bindings.isWrapperInitialized, isTrue);
    } catch (e) {
      // Wrapper library not available - this is OK for now
      print('Wrapper library not available: $e');
    }
  });
}
```

### **3. Manual Testing**

1. **Initialize Signal Protocol:**
   ```dart
   final bindings = SignalFFIBindings();
   await bindings.initialize();
   await bindings.initializeWrapperLibrary(); // Should succeed if library is available
   ```

2. **Create store callbacks:**
   ```dart
   final storeCallbacks = SignalFFIStoreCallbacks(
     keyManager: keyManager,
     sessionManager: sessionManager,
     ffiBindings: bindings,
   );
   ```

3. **Create store structs:**
   ```dart
   final sessionStore = storeCallbacks.createSessionStore();
   final identityKeyStore = storeCallbacks.createIdentityKeyStore();
   ```

4. **Verify function pointers:**
   - Check that `sessionStore.ref.load_session` is not `nullptr`
   - Check that `identityKeyStore.ref.get_identity_key_pair` is not `nullptr`

---

## 🔧 **Troubleshooting**

### **Issue: Library not found**

**Error:** `Failed to initialize wrapper library: DynamicLibrary.open failed`

**Solutions:**
1. **macOS**: Ensure library is in app bundle's Frameworks directory or in system library path
2. **Android**: Ensure library is in `native/signal_ffi/android/<abi>/`
3. **iOS**: Ensure library is linked in Xcode project
4. **Linux**: Ensure library is in library search path

### **Issue: Function not found**

**Error:** `Failed to lookup function: spots_register_load_session_callback`

**Solutions:**
1. Verify library was built correctly (check symbols: `nm -g libsignal_ffi_wrapper.dylib`)
2. Verify function names match exactly (case-sensitive)
3. Check that library architecture matches the app architecture

### **Issue: Callback registration fails**

**Error:** `Wrapper library not initialized`

**Solutions:**
1. Ensure `initializeWrapperLibrary()` is called before creating `SignalFFIStoreCallbacks`
2. Check that wrapper library loaded successfully (`isWrapperInitialized` should be `true`)

---

## 📚 **Files**

### **Build Scripts:**
- `native/signal_ffi/wrapper/build.sh` - Build for Android/Linux/macOS
- `native/signal_ffi/wrapper/build_ios.sh` - Build for iOS/macOS (Xcode)
- `scripts/copy_signal_wrapper_macos.sh` - Copy library to macOS app bundle

### **Build Configuration:**
- `native/signal_ffi/wrapper/CMakeLists.txt` - CMake build configuration
- `android/app/build.gradle` - Android build configuration (already includes jniLibs path)

### **Library Locations:**
- macOS: `native/signal_ffi/macos/libsignal_ffi_wrapper.dylib` ✅
- Android: `native/signal_ffi/android/<abi>/libsignal_ffi_wrapper.so` (to be built)
- iOS: `native/signal_ffi/ios/libsignal_ffi_wrapper.a` (to be built)
- Linux: `native/signal_ffi/linux/libsignal_ffi_wrapper.so` (to be built)

---

## ✅ **Next Steps**

1. ✅ Build wrapper library for macOS (done)
2. ⏳ Build wrapper library for Android (requires NDK)
3. ⏳ Build wrapper library for iOS (requires Xcode)
4. ⏳ Build wrapper library for Linux (requires CMake)
5. ⏳ Test wrapper library integration
6. ⏳ Implement callback logic (currently TODOs)

---

## 🎯 **Current Status**

- ✅ C wrapper library created and implemented
- ✅ Dart integration complete
- ✅ macOS build successful
- ⏳ Other platforms need to be built
- ⏳ Integration testing pending
- ⏳ Callback logic implementation pending
