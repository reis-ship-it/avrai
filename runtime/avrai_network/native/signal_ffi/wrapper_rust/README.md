# Signal FFI Rust Wrapper

**Phase 14: Signal Protocol Implementation - Option 1**

This Rust wrapper solves the Dart FFI callback registration limitation by creating function pointers that Dart cannot create.

## Architecture

```
Dart Code
    ↓ (C FFI - simple function pointer registration)
Rust Wrapper (this crate)
    ↓ (creates function pointers with libsignal-ffi signatures)
Dart Code (receives function pointers)
    ↓ (passes function pointers to libsignal-ffi)
libsignal-ffi (C library)
    ↓
Signal Protocol
```

## Why Rust?

Dart FFI has limitations creating function pointers for callbacks with multiple parameters:
- `Pointer.fromFunction` fails with `int Function(int, int, int)`
- `NativeCallable.isolateLocal` has the same limitation

Rust can create these function pointers easily, so we use Rust as a bridge.

## How It Works

1. **Dart registers callbacks** via simple C FFI (single `void*` parameter)
2. **Rust stores callbacks** in a thread-safe registry
3. **Rust creates function pointers** with libsignal-ffi's expected signatures
4. **Dart receives function pointers** and passes them to libsignal-ffi

## Building

### macOS

```bash
cd native/signal_ffi/wrapper_rust
./build.sh
```

### Other Platforms

```bash
# Android
cargo build --release --target aarch64-linux-android

# iOS
cargo build --release --target aarch64-apple-ios

# Linux
cargo build --release --target x86_64-unknown-linux-gnu
```

## Usage

The Rust wrapper exposes C-compatible functions that Dart can call:

```c
// Register a Dart callback
void spots_rust_register_load_session_callback(void* callback);

// Get function pointer for libsignal-ffi
extern "C" fn(*mut c_void, *mut SessionRecord, *const ProtocolAddress) -> i32
spots_rust_load_session_wrapper;
```

## Dependencies

- `libc` - For C FFI types
- No direct dependency on libsignal-ffi (it's a C library we link against)

## Thread Safety

All callback registrations are thread-safe using Rust's `Mutex`.
