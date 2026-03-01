# Phase 14: Store Callbacks FFI Limitation

## Problem

Dart FFI has a limitation where `NativeFunction` with multiple pointer-like parameters (`IntPtr`, `Pointer<Void>`, etc.) cannot be used in struct fields when creating function pointers with `Pointer.fromFunction`.

**Error:**
```
Expected type 'NativeFunction<int Function(IntPtr, IntPtr, IntPtr)>' to be a valid and instantiated subtype of 'NativeType'.
```

## Affected Callbacks

**ALL callbacks** cannot be created using `Pointer.fromFunction` when used in struct fields due to Dart FFI limitations. The error occurs with various parameter combinations:

- `_getIdentityKeyPairCallback` - Fails with `Pointer<Void> + Pointer<Struct>`
- `_getLocalRegistrationIdCallback` - Fails with `Pointer<Void> + Pointer<Uint32>`
- `_saveIdentityKeyCallback` - Fails with multiple `IntPtr` parameters
- `_getIdentityKeyCallback` - Fails with multiple `IntPtr` parameters
- `_isTrustedIdentityCallback` - Fails with multiple `IntPtr` parameters

**Root Cause:** Dart FFI has restrictions on `NativeFunction` types when used in struct fields. The exact limitations are not well-documented, but appear to affect functions with pointer parameters when used in this context.

## Solutions

### Option 1: C Wrapper Functions (Recommended)

Create C wrapper functions that take the struct parameters and call the Dart callbacks:

```c
// wrapper.c
int save_identity_key_wrapper(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerPublicKey public_key) {
    // Call Dart callback through a different mechanism
    // This avoids the NativeFunction limitation
}
```

### Option 2: Restructure Callbacks

Restructure the callbacks to have fewer pointer parameters by:
- Combining parameters into a single struct
- Using a different callback pattern
- Passing data through the context pointer

### Option 3: Use NativeCallable.isolateLocal

Use `NativeCallable.isolateLocal` instead of `Pointer.fromFunction`, but this requires a different approach and may have performance implications.

### Option 4: Manual Function Pointer Creation

Manually create function pointers using platform-specific code, but this is complex and platform-dependent.

## Current Status

The store callback infrastructure is in place with:
- ✅ Struct definitions matching C API
- ✅ Callback function signatures defined
- ✅ Context management system
- ✅ Working callbacks (session store, identity key pair, registration ID)
- ⚠️ Problematic callbacks marked with TODO comments

## Next Steps

1. Implement C wrapper functions for the problematic callbacks
2. Or restructure the callbacks to avoid the limitation
3. Test the complete store callback system once wrappers are in place

## References

- [Dart FFI Documentation](https://dart.dev/guides/libraries/c-interop)
- [Known FFI Limitations](https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+label%3Aarea-ffi)
