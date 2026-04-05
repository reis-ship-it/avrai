# Phase 14: Callback ID Dispatch Implementation Plan

**Date:** December 29, 2025  
**Status:** 📋 Implementation Plan  
**Approach:** Single-Parameter Struct Pattern

---

## 🎯 **The Problem**

Dart FFI cannot create function pointers for callbacks with multiple parameters:
- ❌ `int Function(int, int, int)`
- ❌ `int Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)`

**Root Cause:** Dart FFI's `Pointer.fromFunction` has internal restrictions on `NativeFunction` type validation.

---

## ✅ **Solution: Single-Parameter Struct Pattern**

Instead of multiple parameters, we pack everything into a **single struct**:

```dart
// Dart CAN create function pointers for this!
typedef DispatchCallback = int Function(Pointer<CallbackArgs>);
```

### **Architecture:**

```
Dart Code
    ↓ (registers callback with ID, stores in Dart registry)
Dart Registry (HashMap<CallbackId, Function>)
    ↓ (single dispatch function pointer - Dart CAN create this!)
Rust Wrapper (calls dispatch function with struct)
    ↓ (unpacks struct, extracts callback ID)
Dart Dispatch Function (looks up callback by ID)
    ↓ (invokes actual callback)
Dart Callback Implementation
```

---

## 🔧 **Implementation Details**

### **1. Callback Args Struct (C/Rust)**

```c
typedef struct {
    uint64_t callback_id;      // Callback ID
    void* store_ctx;           // Store context
    void* arg1;                 // First parameter
    void* arg2;                 // Second parameter
    void* arg3;                 // Third parameter (if needed)
    uint32_t direction;         // For is_trusted_identity
} CallbackArgs;
```

### **2. Dart Dispatch Function**

```dart
// Dart CAN create function pointers for this!
typedef DispatchCallback = int Function(Pointer<CallbackArgs>);

int _dispatchCallback(Pointer<CallbackArgs> args) {
  final callbackId = args.ref.callback_id;
  final callback = _callbackRegistry[callbackId];
  if (callback == null) {
    return 1; // Error: callback not found
  }
  
  // Invoke callback with unpacked parameters
  return callback(
    args.ref.store_ctx,
    args.ref.arg1,
    args.ref.arg2,
    args.ref.arg3,
  );
}
```

### **3. Rust Wrapper**

```rust
// Wrapper function (called by libsignal-ffi)
#[no_mangle]
pub extern "C" fn spots_rust_load_session_wrapper(
    store_ctx: *mut c_void,
    recordp: *mut SignalMutPointerSessionRecord,
    address: *const SignalConstPointerProtocolAddress,
) -> c_int {
    // Extract callback ID from store_ctx (first 8 bytes)
    let callback_id = unsafe { *(store_ctx as *const u64) };
    
    // Pack parameters into struct
    let args = CallbackArgs {
        callback_id,
        store_ctx,
        arg1: recordp as *mut c_void,
        arg2: address as *mut c_void,
        arg3: std::ptr::null_mut(),
        direction: 0,
    };
    
    // Call Dart dispatch function
    let dispatch_fn = get_dispatch_function();
    dispatch_fn(&args)
}
```

---

## 📋 **Implementation Steps**

1. ✅ Define `CallbackArgs` struct in Rust
2. ✅ Create Dart FFI struct definition
3. ✅ Implement dispatch function in Dart
4. ✅ Update Rust wrapper to pack parameters into struct
5. ✅ Test end-to-end callback registration and invocation

---

## ✅ **Advantages**

1. **Works with Dart FFI** - Single parameter struct is supported
2. **Type-Safe** - Struct ensures all parameters are passed correctly
3. **Flexible** - Can handle different callback signatures
4. **Clean** - Clear separation between Rust and Dart

---

**Last Updated:** December 29, 2025  
**Status:** Implementation Plan Ready
