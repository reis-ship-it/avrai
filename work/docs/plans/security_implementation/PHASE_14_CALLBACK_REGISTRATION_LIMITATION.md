# Phase 14: Callback Registration Limitation

**Date:** December 29, 2025  
**Status:** ⚠️ Known Limitation  
**Impact:** Callback registration requires alternative approach

---

## Problem

Dart FFI's `Pointer.fromFunction` cannot create function pointers for callbacks with multiple `int` parameters (even when those `int`s represent pointer addresses).

**Error:**
```
Expected type 'NativeFunction<int Function(int, int, int)>' to be a valid and instantiated subtype of 'NativeType'.
```

**Affected:**
- All callback registration attempts using `Pointer.fromFunction`
- Callbacks with 2+ `int` parameters (representing pointer addresses)

---

## Root Cause

`Pointer.fromFunction` has strict limitations on function signatures it can handle. Even simple `int` parameters cause issues when there are multiple parameters, likely due to internal Dart FFI restrictions on `NativeFunction` type validation.

---

## Solutions

### Option 1: Use NativeCallable.isolateLocal (Recommended)

`NativeCallable.isolateLocal` can create function pointers that `Pointer.fromFunction` cannot:

```dart
final nativeCallable = NativeCallable.isolateLocal<int Function(int, int, int)>(
  _loadSessionCallback,
);
final callbackPtr = nativeCallable.nativeFunction;
```

**Pros:**
- Works with complex function signatures
- Supported by Dart FFI

**Cons:**
- More complex API
- Potential performance implications
- Requires isolate-local functions

### Option 2: Restructure C Wrapper

Modify the C wrapper to accept callback registration differently:
- Use a single registration function that takes a callback ID and function pointer
- Store callbacks in a registry keyed by ID
- Callbacks are invoked by ID rather than direct function pointer

### Option 3: Use Platform-Specific Code

Create platform-specific code (C/Objective-C/Swift) to bridge the callback registration, avoiding Dart FFI limitations entirely.

---

## Current Status

- ✅ C wrapper library built and functional
- ✅ Library loading works
- ✅ Function lookup works
- ⚠️ Callback registration blocked by `Pointer.fromFunction` limitation
- ⏳ Need to implement alternative callback registration approach

---

## Next Steps

1. Implement `NativeCallable.isolateLocal` approach for callback registration
2. Test callback registration and invocation
3. Verify end-to-end store callback functionality

---

## References

- [Dart FFI NativeCallable Documentation](https://api.dart.dev/stable/dart-ffi/NativeCallable-class.html)
- [Dart FFI Limitations](https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+label%3Aarea-ffi)
