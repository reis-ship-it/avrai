# Phase 14: Platform Bridge - Next Steps

**Date:** December 29, 2025  
**Status:** ⚠️ Need Alternative Registration Mechanism  
**Issue:** Still need to pass Dart callback to C bridge

---

## 🔍 **The Remaining Challenge**

Even with the platform bridge, we still need to **pass the Dart callback to C**. The problem is:
- We can't create function pointers in Dart for `Int32 Function(Uint64)`
- We need some way to register the callback with the C bridge

---

## 💡 **Possible Solutions**

### **Option 1: Use dlsym / Dynamic Symbol Lookup**

The C bridge can use `dlsym` to look up a Dart function by name:
```c
// In C bridge
void* callback = dlsym(RTLD_DEFAULT, "signal_dispatch_callback");
```

**Pros:**
- No function pointer creation in Dart
- Works with any function signature

**Cons:**
- Requires exporting function with specific name
- Platform-specific (dlsym is Unix-specific)

### **Option 2: Use a Callback Registry with IDs**

Instead of function pointers, use a callback ID system:
1. Dart registers callback with unique ID
2. C bridge stores callback by ID
3. C function calls callback by ID

**But:** We still need to pass the callback somehow...

### **Option 3: Use Platform Channels (Flutter)**

Use Flutter's platform channels instead of FFI:
- Dart → Platform Channel → Native Code
- Native Code → Platform Channel → Dart

**Pros:**
- No FFI limitations
- Well-supported by Flutter

**Cons:**
- More overhead than direct FFI
- Different architecture

### **Option 4: Use Isolates with Message Passing**

Use Dart isolates to communicate:
- Main isolate → Worker isolate (via messages)
- Worker isolate handles callbacks

**Pros:**
- No FFI limitations
- Pure Dart solution

**Cons:**
- More complex architecture
- Performance overhead

---

## 🎯 **Recommended Approach**

**Use Option 1 (dlsym) for now**, then implement Option 3 (Platform Channels) as a more robust long-term solution.

---

**Last Updated:** December 29, 2025  
**Status:** Evaluating registration mechanisms
