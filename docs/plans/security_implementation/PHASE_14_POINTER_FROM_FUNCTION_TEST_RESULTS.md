# Phase 14: Pointer.fromFunction Test Results

**Date:** December 29, 2025  
**Status:** ❌ Test Failed - Limitation Confirmed  
**Impact:** Need to implement callback ID dispatch system

---

## 🧪 **Test Results**

### **Test: Pointer.fromFunction with Pointer<Void> Function(...)**

**Test Code:**
```dart
typedef TestCallback = int Function(
  Pointer<Void> ctx,
  Pointer<Void> arg1,
  Pointer<Void> arg2,
);

int _testCallback(Pointer<Void> ctx, Pointer<Void> arg1, Pointer<Void> arg2) {
  return 0;
}

final callbackPtr = Pointer.fromFunction<TestCallback>(_testCallback);
```

**Result:** ❌ **FAILED**

**Error:**
```
Expected type 'NativeFunction<int Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)>' 
to be a valid and instantiated subtype of 'NativeType'.
```

---

## 📊 **Conclusion**

**`Pointer.fromFunction` does NOT work with:**
- ❌ `int Function(int, int, int)` - Multiple `int` parameters
- ❌ `IntPtr Function(IntPtr, IntPtr, IntPtr)` - Multiple `IntPtr` parameters
- ❌ `int Function(Pointer<Void>, Pointer<Void>, Pointer<Void>)` - Multiple `Pointer<Void>` parameters

**The fundamental limitation:**
Dart FFI's `Pointer.fromFunction` cannot create function pointers for callbacks with **multiple pointer-like parameters**, regardless of whether they're `int`, `IntPtr`, or `Pointer<Void>`.

---

## ✅ **Solution: Callback ID Dispatch System**

Since `Pointer.fromFunction` doesn't work, we need to implement the **Callback ID Dispatch Pattern**:

### **Architecture:**

```
Dart Code
    ↓ (registers callback with unique ID)
Rust Wrapper (stores callback by ID)
    ↓ (single dispatch function pointer)
Dart Dispatch Function (looks up callback by ID)
    ↓ (invokes actual callback)
Dart Callback Implementation
```

### **Implementation:**

1. **Dart registers callbacks** with unique IDs (no function pointers needed!)
2. **Rust wrapper** stores callback IDs
3. **Single dispatch function** (Dart can create this - it has only one parameter!)
4. **Dispatch function** looks up callback by ID and invokes it

---

## 🔧 **Next Steps**

1. ✅ **Rust wrapper built** - Library exists and is functional
2. ⏳ **Implement callback ID dispatch system** in Rust wrapper
3. ⏳ **Update Dart code** to use callback IDs instead of function pointers
4. ⏳ **Test end-to-end** callback registration and invocation

---

## 📝 **Key Insight**

The Rust wrapper is still valuable because:
- ✅ It can create function pointers that Dart cannot
- ✅ It provides a clean interface for callback management
- ✅ It handles the complexity of bridging Dart and libsignal-ffi

We just need to use the callback ID dispatch pattern instead of direct function pointer registration.

---

**Last Updated:** December 29, 2025  
**Status:** Test Complete - Fallback Approach Required
