# Phase 14: Callback ID Dispatch - Rust Implementation Complete

**Date:** December 29, 2025  
**Status:** ✅ Rust Implementation Complete  
**Next Step:** Update Dart Code

---

## ✅ **What Was Completed**

### **1. Rust Wrapper Updated**

**Location:** `native/signal_ffi/wrapper_rust/src/lib.rs`

**Changes:**
- ✅ Implemented `CallbackArgs` struct (single parameter for dispatch)
- ✅ Changed to single dispatch function registration
- ✅ Updated all wrapper functions to pack parameters into `CallbackArgs`
- ✅ Extract callback ID from `store_ctx` (first 8 bytes)

**Key Implementation:**
```rust
// Single dispatch function (Dart CAN create function pointers for this!)
type DispatchCallback = extern "C" fn(*const CallbackArgs) -> c_int;

// Callback args struct (all parameters packed into one struct)
#[repr(C)]
pub struct CallbackArgs {
    pub callback_id: u64,
    pub store_ctx: *mut c_void,
    pub arg1: *mut c_void,
    pub arg2: *mut c_void,
    pub arg3: *mut c_void,
    pub direction: u32,
}
```

### **2. Build Status**

- ✅ Rust code compiles successfully
- ✅ Ready to build for all platforms

---

## 🏗️ **Architecture**

```
libsignal-ffi calls wrapper function
    ↓
Rust wrapper extracts callback ID from store_ctx
    ↓
Rust wrapper packs parameters into CallbackArgs struct
    ↓
Rust wrapper calls Dart dispatch function with struct
    ↓
Dart dispatch function looks up callback by ID
    ↓
Dart dispatch function invokes actual callback
```

---

## 📋 **Next Steps**

1. ✅ Rust wrapper updated
2. ⏳ Define `CallbackArgs` struct in Dart FFI
3. ⏳ Implement Dart dispatch function
4. ⏳ Update Dart store callbacks to register with IDs
5. ⏳ Test end-to-end callback registration and invocation

---

## 🔧 **Dart Implementation Required**

### **1. CallbackArgs Struct (Dart FFI)**

```dart
final class CallbackArgs extends Struct {
  @Uint64()
  external int callbackId;
  
  external Pointer<Void> storeCtx;
  external Pointer<Void> arg1;
  external Pointer<Void> arg2;
  external Pointer<Void> arg3;
  @Uint32()
  external int direction;
}
```

### **2. Dispatch Function**

```dart
typedef DispatchCallback = int Function(Pointer<CallbackArgs>);

int _dispatchCallback(Pointer<CallbackArgs> args) {
  final callbackId = args.ref.callbackId;
  final callback = _callbackRegistry[callbackId];
  if (callback == null) {
    return 1; // Error: callback not found
  }
  
  // Invoke callback with unpacked parameters
  return callback(
    args.ref.storeCtx,
    args.ref.arg1,
    args.ref.arg2,
    args.ref.arg3,
    args.ref.direction,
  );
}
```

### **3. Registration**

```dart
// Register dispatch function (Dart CAN create this function pointer!)
final dispatchPtr = Pointer.fromFunction<DispatchCallback>(_dispatchCallback);
_rustWrapper.registerDispatchCallback(dispatchPtr.cast<Void>());
```

---

**Last Updated:** December 29, 2025  
**Status:** Rust Complete - Ready for Dart Implementation
