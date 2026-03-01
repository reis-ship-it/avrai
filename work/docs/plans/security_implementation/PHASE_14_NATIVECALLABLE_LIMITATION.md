# Phase 14: NativeCallable Limitation

**Date:** December 29, 2025  
**Status:** ⚠️ Known Limitation  
**Impact:** Callback registration requires alternative approach

---

## Problem

Both `Pointer.fromFunction` and `NativeCallable.isolateLocal` have the same fundamental limitation: they cannot create function pointers for callbacks with multiple `int` parameters.

**Error with NativeCallable:**
```
Expected type 'NativeFunction<int Function(int, int, int)>' to be a valid and instantiated subtype of 'NativeType'.
```

**Root Cause:**
Dart FFI has restrictions on `NativeFunction` types that affect functions with multiple integer parameters, regardless of whether they're created via `Pointer.fromFunction` or `NativeCallable.isolateLocal`.

---

## Attempted Solutions

### ✅ Completed
1. **C Wrapper Library** - Built and functional
2. **Library Loading** - Works correctly
3. **Function Lookup** - All wrapper functions accessible
4. **Callback Function Signatures** - Updated to use `int` instead of `IntPtr`

### ❌ Failed
1. **Pointer.fromFunction** - Cannot create function pointers for `int Function(int, int, int)`
2. **NativeCallable.isolateLocal** - Same limitation as `Pointer.fromFunction`

---

## Alternative Approaches

### Option 1: Restructure C Wrapper (Recommended)

Modify the C wrapper to use a callback registry pattern:

1. **Single Registration Function:**
   ```c
   void spots_register_callback(int callback_id, void* callback);
   ```

2. **Callback Invocation by ID:**
   ```c
   int spots_invoke_callback(int callback_id, int arg1, int arg2, int arg3);
   ```

3. **Dart Side:**
   - Register callbacks with unique IDs
   - C wrapper invokes callbacks by ID
   - Avoids need for function pointer creation

### Option 2: Use Platform-Specific Code

Create platform-specific callback registration:
- **iOS:** Use Objective-C/Swift to bridge callbacks
- **Android:** Use JNI to bridge callbacks
- **Desktop:** Use platform-specific FFI mechanisms

### Option 3: Restructure Callbacks

Combine parameters into a single struct:
```dart
typedef _CallbackArgs = Struct {
  @IntPtr()
  int storeCtx;
  @IntPtr()
  int arg1;
  @IntPtr()
  int arg2;
}
```

---

## Current Status

- ✅ C wrapper library built and functional
- ✅ Library loading works
- ✅ Function lookup works
- ⚠️ Callback registration blocked by Dart FFI limitation
- ⏳ Need to implement alternative callback registration approach

---

## Next Steps

1. **Implement Option 1 (Callback Registry)** - Recommended approach
2. Update C wrapper to use registry pattern
3. Update Dart code to register callbacks by ID
4. Test end-to-end callback functionality

---

## References

- [Dart FFI NativeCallable Documentation](https://api.dart.dev/stable/dart-ffi/NativeCallable-class.html)
- [Dart FFI Limitations](https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+label%3Aarea-ffi)
- [Phase 14 Callback Registration Limitation](./PHASE_14_CALLBACK_REGISTRATION_LIMITATION.md)
