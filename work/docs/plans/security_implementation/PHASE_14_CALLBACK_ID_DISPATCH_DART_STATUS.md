# Phase 14: Callback ID Dispatch - Dart Implementation Status

**Date:** December 29, 2025  
**Status:** ⚠️ Blocked by Struct Pointer Limitation  
**Progress:** Rust wrapper complete, Dart implementation in progress

---

## ✅ **Completed**

1. **Rust Wrapper Implementation** ✅
   - Callback ID dispatch system implemented
   - Hardcoded callback IDs per wrapper function
   - `CallbackArgs` struct defined
   - Dispatch function pattern implemented
   - Successfully compiled and built

2. **Dart Bindings Structure** ✅
   - `SignalRustWrapperBindings` updated for dispatch pattern
   - `CallbackArgs` struct defined in `signal_rust_wrapper_bindings.dart`
   - Function pointer getters implemented

3. **Store Callbacks Structure** ✅
   - Callback registry implemented
   - Callback IDs defined (must match Rust constants)
   - Callback implementations created
   - Dispatch function structure ready

---

## ⚠️ **Blocking Issue**

### **Struct Pointer Limitation**

**Error:**
```
The type '_DispatchCallback' given to 'fromFunction' must be a valid 'dart:ffi' native function type
```

**Root Cause:**
`Pointer.fromFunction` appears to have the same limitation with struct pointers as it does with multiple parameters. The error suggests that `Pointer<CallbackArgs>` might not be a valid type for `NativeFunction`.

**Test Required:**
We need to verify if `Pointer.fromFunction` works with struct pointers at all:

```dart
final class TestStruct extends Struct {
  @Uint64()
  external int value;
}

typedef TestCallback = int Function(Pointer<TestStruct>);

int testCallback(Pointer<TestStruct> args) {
  return args.ref.value.toInt();
}

// CRITICAL TEST:
final callbackPtr = Pointer.fromFunction<TestCallback>(testCallback);
```

---

## 🔧 **Potential Solutions**

### **Option 1: Test Struct Pointers**

If struct pointers work, we can proceed with the current implementation.

### **Option 2: Callback ID via Context Pointer**

If struct pointers don't work, we can:
1. Store callback ID in the first 8 bytes of `store_ctx`
2. Rust wrapper extracts callback ID from `store_ctx`
3. Rust wrapper calls a single dispatch function with just the callback ID (as `int`)
4. Dart dispatch function looks up callback by ID

**But:** This still requires creating a function pointer for `int Function(int)`, which should work.

### **Option 3: Platform-Specific Code**

Use platform-specific code to create function pointers:
- **iOS:** Objective-C/Swift
- **Android:** JNI
- **Desktop:** Platform-specific FFI

---

## 📋 **Next Steps**

1. ⏳ **Test struct pointers** with `Pointer.fromFunction`
2. ⏳ **If they work:** Complete the implementation
3. ⏳ **If they don't:** Implement Option 2 (callback ID via context pointer)

---

## 📝 **Code Status**

### **Rust Wrapper** ✅
- ✅ Callback ID constants defined
- ✅ `CallbackArgs` struct defined
- ✅ Dispatch function pattern implemented
- ✅ All wrapper functions updated
- ✅ Successfully compiled and built

### **Dart Bindings** ✅
- ✅ `CallbackArgs` struct defined
- ✅ Dispatch callback typedefs defined
- ✅ Registration function implemented
- ✅ Function pointer getters implemented

### **Store Callbacks** ⚠️
- ✅ Callback registry implemented
- ✅ Callback IDs defined
- ✅ Callback implementations created
- ⚠️ **BLOCKED:** `Pointer.fromFunction` with struct pointers

---

**Last Updated:** December 29, 2025  
**Status:** Waiting for struct pointer test results
