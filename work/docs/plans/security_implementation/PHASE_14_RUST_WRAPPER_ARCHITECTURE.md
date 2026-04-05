# Phase 14: Rust Wrapper Layer Architecture

**Date:** December 29, 2025  
**Status:** 🚀 In Progress  
**Solution:** Rust Wrapper for Callback Registration

---

## 🎯 **Problem Solved**

Dart FFI cannot create function pointers for callbacks with multiple `int` parameters:
- `Pointer.fromFunction` fails
- `NativeCallable.isolateLocal` has the same limitation

**Solution:** Use Rust to create function pointers that Dart cannot.

---

## 🏗️ **Architecture**

```
┌─────────────┐
│   Dart      │
│  (Flutter)  │
└──────┬──────┘
       │ C FFI
       │ (simple void* registration)
┌──────▼──────────────────┐
│  Rust Wrapper           │
│  - Callback registry     │
│  - Function pointer      │
│    creation              │
│  - Type conversion       │
└──────┬──────────────────┘
       │ (function pointers)
┌──────▼──────────┐
│   Dart          │
│  (receives FPs) │
└──────┬──────────┘
       │ (passes FPs to libsignal-ffi)
┌──────▼──────────┐
│ libsignal-ffi   │
│   (C library)   │
└─────────────────┘
```

---

## 📋 **Implementation Details**

### **1. Rust Wrapper Crate**

**Location:** `native/signal_ffi/wrapper_rust/`

**Structure:**
```
wrapper_rust/
├── Cargo.toml          # Rust crate configuration
├── src/
│   └── lib.rs          # Main implementation
├── build.sh            # Build script
└── README.md           # Documentation
```

### **2. Callback Registration Flow**

1. **Dart Side:**
   ```dart
   // Register callback (simple void* - Dart can do this!)
   _rustWrapper.registerLoadSessionCallback(callbackPtr);
   ```

2. **Rust Side:**
   ```rust
   // Store callback in registry
   registry.load_session = Some(callback_fn);
   
   // Create function pointer with libsignal-ffi signature
   pub extern "C" fn spots_rust_load_session_wrapper(...) -> i32 {
       // Call registered Dart callback
   }
   ```

3. **Dart Side:**
   ```dart
   // Get function pointer from Rust
   final fp = _rustWrapper.getLoadSessionWrapperPtr();
   
   // Pass to libsignal-ffi
   store.load_session = fp;
   ```

### **3. Key Functions**

**Registration (Dart → Rust):**
- `spots_rust_register_load_session_callback(void* callback)`
- `spots_rust_register_store_session_callback(void* callback)`
- `spots_rust_register_get_identity_key_pair_callback(void* callback)`
- `spots_rust_register_get_local_registration_id_callback(void* callback)`
- `spots_rust_register_save_identity_key_callback(void* callback)`
- `spots_rust_register_get_identity_key_callback(void* callback)`
- `spots_rust_register_is_trusted_identity_callback(void* callback)`

**Wrapper Functions (Rust → libsignal-ffi):**
- `spots_rust_load_session_wrapper(...)` - Returns function pointer
- `spots_rust_store_session_wrapper(...)` - Returns function pointer
- `spots_rust_get_identity_key_pair_wrapper(...)` - Returns function pointer
- `spots_rust_get_local_registration_id_wrapper(...)` - Returns function pointer
- `spots_rust_save_identity_key_wrapper(...)` - Returns function pointer
- `spots_rust_get_identity_key_wrapper(...)` - Returns function pointer
- `spots_rust_is_trusted_identity_wrapper(...)` - Returns function pointer

---

## ✅ **Advantages**

1. **Solves Dart FFI Limitation** - Rust can create function pointers Dart cannot
2. **Type-Safe** - Rust's type system ensures correctness
3. **Thread-Safe** - Uses Rust's `Mutex` for callback registry
4. **Simple Dart Interface** - Dart only needs to pass `void*` (works!)
5. **Reuses Existing Stack** - We already have Rust toolchain
6. **Maintainable** - Clean separation of concerns

---

## 🔧 **Build Configuration**

### **Cargo.toml**

```toml
[package]
name = "signal_ffi_wrapper"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]  # Dynamic library for FFI

[dependencies]
libc = "0.2"  # C FFI types
```

### **Platform-Specific Builds**

- **macOS:** Universal binary (x86_64 + arm64)
- **iOS:** Framework or static library
- **Android:** `.so` files for each architecture
- **Linux:** `.so` file
- **Windows:** `.dll` file

---

## 📝 **Integration Steps**

1. ✅ Create Rust wrapper crate structure
2. ⏳ Implement callback registry
3. ⏳ Implement wrapper functions
4. ⏳ Build for all platforms
5. ⏳ Update Dart code to use Rust wrapper
6. ⏳ Test callback registration and invocation
7. ⏳ Integrate with libsignal-ffi

---

## 🔗 **Related Documents**

- `PHASE_14_NATIVECALLABLE_LIMITATION.md` - Problem description
- `PHASE_14_CALLBACK_REGISTRATION_LIMITATION.md` - Original limitation
- `PHASE_14_IMPLEMENTATION_PLAN.md` - Overall plan

---

**Last Updated:** December 29, 2025  
**Status:** Architecture Designed - Ready for Implementation
