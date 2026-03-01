# Phase 14: Struct Pointer Test Needed

**Date:** December 29, 2025  
**Status:** ⚠️ Critical Test Required  
**Question:** Does `Pointer.fromFunction` work with `Pointer<Struct>` Function(...)?

---

## 🎯 **The Critical Question**

We've implemented the callback ID dispatch system using a single-parameter struct pattern:

```dart
typedef DispatchCallback = int Function(Pointer<CallbackArgs>);
```

**Question:** Can Dart create function pointers for this signature?

---

## 🧪 **Test Required**

```dart
// Test if Pointer.fromFunction works with struct pointers
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

**Expected Result:**
- ✅ **If it works:** Our callback ID dispatch system will work!
- ❌ **If it fails:** We need yet another approach (callback ID via context pointer, or platform-specific code)

---

## ⚠️ **Current Compilation Error**

```
Expected type 'NativeFunction<int Function(Pointer<CallbackArgs>)>' 
to be a valid and instantiated subtype of 'NativeType'.
```

**Possible Causes:**
1. `Pointer.fromFunction` doesn't work with struct pointers (same limitation)
2. `CallbackArgs` needs to be defined in the same file
3. Some other FFI limitation we haven't discovered

---

## 🔧 **If Struct Pointers Don't Work**

### **Alternative: Callback ID via Context Pointer**

Instead of passing callback ID in the struct, we can:
1. Store callback ID in the first 8 bytes of `store_ctx`
2. Rust wrapper extracts callback ID from `store_ctx`
3. Rust wrapper calls a single dispatch function with just the callback ID
4. Dart dispatch function looks up callback by ID

**But wait:** This still requires creating a function pointer, which might have the same limitation!

### **Alternative: Platform-Specific Code**

Use platform-specific code to create function pointers:
- **iOS:** Objective-C/Swift
- **Android:** JNI
- **Desktop:** Platform-specific FFI

---

## 📋 **Next Steps**

1. ⏳ **Test if struct pointers work** with `Pointer.fromFunction`
2. ⏳ **If they work:** Complete the implementation
3. ⏳ **If they don't:** Implement alternative approach (platform-specific or callback ID via context)

---

**Last Updated:** December 29, 2025  
**Status:** Critical Test Required
