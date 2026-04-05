# FFI Setup Guide - flutter_rust_bridge Integration

**Date:** December 27, 2025  
**Status:** ⏳ Codegen Tool Installation Pending  
**Progress:** ✅ Rust API Complete, ⏳ Codegen Setup

---

## ✅ Current Status

### Rust Library:
- ✅ **All 13 FFI API functions** implemented and tested
- ✅ **All functions marked** with `#[frb(sync)]` for codegen
- ✅ **All 13 API tests passing**
- ✅ **Library compiles successfully** (warnings about `frb` macro are expected until codegen runs)
- ✅ **Cargo.toml configured** with `crate-type = ["cdylib", "rlib"]`

### Dart Integration:
- ✅ **Dart models** complete
- ✅ **Service layer** ready for FFI calls
- ✅ **Storage service** complete
- ✅ **PersonalityProfile integration** complete

### FFI Codegen:
- ⏳ **flutter_rust_bridge_codegen** installation pending (dependency conflict)
- ⏳ **Dart bindings** not yet generated
- ⏳ **Platform-specific setup** pending

---

## 🔧 Setup Steps

### Step 1: Install flutter_rust_bridge_codegen

**Current Issue:** Version 2.0.0 has a dependency conflict with `indicatif`.

**Options:**

#### Option A: Use Latest Version (Recommended)
```bash
cargo install flutter_rust_bridge_codegen --locked
```

#### Option B: Use Version 1.x (If 2.0 issues persist)
```bash
cargo install flutter_rust_bridge_codegen --version 1.82.0
```

**Note:** If installation fails, check for dependency conflicts and try:
```bash
cargo update
cargo install flutter_rust_bridge_codegen --force
```

---

### Step 2: Add Flutter Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_rust_bridge: ^2.0.0
  ffi: ^2.0.1
```

**Note:** flutter_rust_bridge 2.0.0 may not be available yet. If not, use:
```yaml
dependencies:
  flutter_rust_bridge: ^1.82.0
  ffi: ^2.0.1
```

---

### Step 3: Generate Dart Bindings

Once `flutter_rust_bridge_codegen` is installed, run:

```bash
cd native/knot_math
flutter_rust_bridge_codegen \
  -r src/api.rs \
  -d ../../lib/core/services/knot/bridge/knot_math_bridge.dart \
  -c ../../ios/Runner/knot_math_bridge.h \
  -e ../../macos/Runner/
```

**Or use the frb.yaml configuration:**

```bash
cd native/knot_math
flutter_rust_bridge_codegen generate
```

This will read `frb.yaml` and generate bindings accordingly.

---

### Step 4: Update build.rs

Once codegen is working, update `native/knot_math/build.rs`:

```rust
use flutter_rust_bridge_codegen::{config_parse, frb_codegen, RawOpts};

fn main() {
    println!("cargo:rerun-if-changed=src/api.rs");
    
    let raw_opts = RawOpts {
        rust_input: vec!["src/api.rs".into()],
        dart_output: vec!["../../lib/core/services/knot/bridge/knot_math_bridge.dart".into()],
        c_output: Some(vec!["../../ios/Runner/knot_math_bridge.h".into()]),
        extra_c_output_paths: Some(vec!["../../macos/Runner/knot_math_bridge.c".into()]),
        ..Default::default()
    };
    
    frb_codegen(raw_opts).unwrap();
}
```

**Note:** This will generate bindings automatically during `cargo build`.

---

### Step 5: Update PersonalityKnotService

Once bindings are generated, update `lib/core/services/knot/personality_knot_service.dart`:

```dart
import 'package:spots/core/services/knot/bridge/knot_math_bridge.dart';
import 'dart:ffi';
import 'dart:io';

class PersonalityKnotService {
  // ... existing code ...
  
  late final Native _native;
  
  PersonalityKnotService({QuantumVibeEngine? quantumEngine})
      : _quantumEngine = quantumEngine ?? QuantumVibeEngine() {
    // Load the native library
    final dylib = Platform.isAndroid
        ? DynamicLibrary.open("libknot_math.so")
        : Platform.isIOS
            ? DynamicLibrary.process()
            : DynamicLibrary.open("libknot_math.dylib");
    
    _native = NativeImpl(dylib);
  }
  
  Future<PersonalityKnot> generateKnot(PersonalityProfile profile) async {
    // ... existing correlation extraction ...
    
    // Call Rust FFI
    final rustResult = _native.generateKnotFromBraid(braidData: braidData);
    
    // Convert to Dart model
    return PersonalityKnot(
      agentId: profile.agentId,
      invariants: KnotInvariants(
        jonesPolynomial: rustResult.jonesPolynomial,
        alexanderPolynomial: rustResult.alexanderPolynomial,
        crossingNumber: rustResult.crossingNumber,
        writhe: rustResult.writhe,
      ),
      // ... rest of construction ...
    );
  }
  
  Future<double> calculateTopologicalCompatibility(
      PersonalityKnot knotA, PersonalityKnot knotB) async {
    // Call Rust FFI
    return _native.calculateTopologicalCompatibility(
      braidDataA: knotA.braidData,
      braidDataB: knotB.braidData,
    );
  }
}
```

---

### Step 6: Platform-Specific Setup

#### Android

1. **Build Rust library for Android:**
   ```bash
   cd native/knot_math
   cargo build --target aarch64-linux-android --release
   cargo build --target armv7-linux-androideabi --release
   cargo build --target x86_64-linux-android --release
   cargo build --target i686-linux-android --release
   ```

2. **Copy libraries to Android project:**
   ```bash
   mkdir -p android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64,x86}
   cp target/aarch64-linux-android/release/libknot_math.so android/app/src/main/jniLibs/arm64-v8a/
   cp target/armv7-linux-androideabi/release/libknot_math.so android/app/src/main/jniLibs/armeabi-v7a/
   cp target/x86_64-linux-android/release/libknot_math.so android/app/src/main/jniLibs/x86_64/
   cp target/i686-linux-android/release/libknot_math.so android/app/src/main/jniLibs/x86/
   ```

#### iOS

1. **Build Rust library for iOS:**
   ```bash
   cd native/knot_math
   cargo build --target aarch64-apple-ios --release
   cargo build --target x86_64-apple-ios --release  # For simulator
   ```

2. **Create Xcode framework:**
   ```bash
   # Use cargo-xcode or create framework manually
   cargo install cargo-xcode
   cargo xcode
   ```

3. **Add to Xcode project:**
   - Add `knot_math_bridge.h` to Xcode project
   - Link against `libknot_math.a`
   - Configure build settings

#### macOS

1. **Build Rust library:**
   ```bash
   cd native/knot_math
   cargo build --target x86_64-apple-darwin --release
   cargo build --target aarch64-apple-darwin --release  # For Apple Silicon
   ```

2. **Add to Xcode project:**
   - Add generated files to Xcode project
   - Link against `libknot_math.dylib`

---

## 🧪 Testing

### Unit Tests (Rust)
```bash
cd native/knot_math
cargo test
```

**Expected:** All 48 tests pass (35 existing + 13 API tests)

### Integration Tests (Dart)
```bash
flutter test test/core/services/knot/
```

**Note:** Integration tests require FFI bindings to be generated first.

---

## 📊 Current Test Results

### Rust Tests:
- ✅ **48/48 tests passing**
- ✅ **13 API tests passing**
- ✅ **All modules tested**

### Dart Tests:
- ⏳ **Pending FFI bindings**

---

## 🔗 Files Reference

### Rust:
- `native/knot_math/src/api.rs` - FFI API (13 functions)
- `native/knot_math/build.rs` - Build script (needs codegen)
- `native/knot_math/Cargo.toml` - Dependencies configured
- `native/knot_math/frb.yaml` - Codegen configuration

### Dart:
- `lib/core/services/knot/personality_knot_service.dart` - Service (ready for FFI)
- `lib/core/models/personality_knot.dart` - Models (complete)
- `lib/core/services/knot/knot_storage_service.dart` - Storage (complete)

### Generated (Pending):
- `lib/core/services/knot/bridge/knot_math_bridge.dart` - Dart bindings
- `ios/Runner/knot_math_bridge.h` - iOS header
- `macos/Runner/knot_math_bridge.c` - macOS C bindings

---

## ⚠️ Known Issues

1. **flutter_rust_bridge_codegen 2.0.0 dependency conflict:**
   - Issue: `indicatif` version conflict
   - Workaround: Try version 1.x or wait for fix
   - Status: ⏳ Pending

2. **frb macro warnings:**
   - Issue: `cfg` condition warnings during build
   - Impact: None (warnings only, code compiles)
   - Status: ✅ Expected until codegen runs

---

## 🎯 Next Steps

1. **Resolve codegen installation:**
   - Try latest version: `cargo install flutter_rust_bridge_codegen --locked`
   - Or use version 1.x if 2.0 issues persist

2. **Generate bindings:**
   - Run codegen tool
   - Verify generated files

3. **Update service:**
   - Replace placeholder implementations
   - Test FFI calls

4. **Platform setup:**
   - Configure Android/iOS/macOS
   - Build and test on each platform

5. **Integration tests:**
   - Write end-to-end tests
   - Verify full workflow

---

**Status:** ✅ Rust API Complete, ⏳ Codegen Setup Pending

**The Rust library is ready. Once flutter_rust_bridge_codegen is installed, bindings can be generated and the system will be fully functional.**
