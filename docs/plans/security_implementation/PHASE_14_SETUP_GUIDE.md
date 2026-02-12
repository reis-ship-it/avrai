# Phase 14: Signal Protocol Setup Guide

**Date:** December 28, 2025  
**Option:** Option 1 - libsignal-ffi via FFI  
**Status:** Setup Instructions

---

## 🚀 **Setup Steps**

### **Step 1: Install Rust Toolchain**

**macOS/Linux:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

**Windows:**
Download and run: https://rustup.rs/

**Verify:**
```bash
rustc --version
cargo --version
```

### **Step 2: Add libsignal-ffi to Project**

**Option A: Use Pre-built Binaries (Recommended)**
- Download pre-built libsignal-ffi for your platforms
- Place in `native/signal_ffi/` directory
- Reference in FFI bindings

**Option B: Build from Source**
```bash
# Clone libsignal-ffi
git clone https://github.com/signalapp/libsignal-ffi.git native/signal_ffi
cd native/signal_ffi

# Build for your platforms
cargo build --release
```

### **Step 3: Create FFI Bindings**

1. **Define Function Signatures**
   - Create `signal_ffi_bindings.dart` with function signatures
   - Map Rust functions to Dart functions

2. **Load Native Library**
   - Platform-specific library loading
   - Error handling for missing libraries

3. **Create Dart Wrappers**
   - High-level Dart API
   - Type conversions (Rust ↔ Dart)
   - Memory management

### **Step 4: Build Configuration**

**Android (`android/app/build.gradle`):**
```gradle
android {
    // Add native library
    sourceSets {
        main {
            jniLibs.srcDirs = ['../native/signal_ffi/android']
        }
    }
}
```

**iOS (`ios/Podfile`):**
```ruby
# Add libsignal-ffi framework
pod 'SignalFFI', :path => '../native/signal_ffi/ios'
```

**macOS/Linux/Windows:**
- Link native library in build configuration
- Set library search paths

---

## 📦 **Project Structure**

```
SPOTS/
├── native/
│   └── signal_ffi/          # libsignal-ffi integration
│       ├── android/         # Android .so files
│       ├── ios/             # iOS framework
│       ├── macos/            # macOS .dylib
│       ├── linux/            # Linux .so
│       └── windows/          # Windows .dll
├── lib/
│   └── core/
│       └── crypto/
│           └── signal/
│               ├── signal_types.dart
│               ├── signal_ffi_bindings.dart
│               ├── signal_key_manager.dart
│               ├── signal_session_manager.dart
│               └── signal_protocol_service.dart
```

---

## 🔧 **Next Steps After Setup**

1. ✅ Rust toolchain installed
2. ✅ libsignal-ffi added to project
3. ⏳ Create actual FFI bindings
4. ⏳ Test FFI connectivity
5. ⏳ Implement key management
6. ⏳ Integrate with existing systems

---

**Last Updated:** December 28, 2025  
**Status:** Setup Instructions Ready
