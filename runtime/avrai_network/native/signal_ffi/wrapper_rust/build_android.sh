#!/bin/bash
# Build script for Signal FFI Rust Wrapper (Android .so)
# Phase 14: Signal Protocol Implementation - Option 1
#
# Produces (via cargo-ndk):
#   native/signal_ffi/android/<abi>/libsignal_ffi_wrapper.so
#
# These are picked up by Gradle via:
#   android/app/build.gradle -> main.jniLibs.srcDirs includes ../../native/signal_ffi/android

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$SCRIPT_DIR"

ANDROID_OUT_DIR="$PROJECT_ROOT/native/signal_ffi/android"

if ! command -v cargo >/dev/null 2>&1; then
  echo "❌ cargo not found"
  exit 1
fi

if ! cargo ndk -V >/dev/null 2>&1; then
  echo "❌ cargo-ndk not available. Install with: cargo install cargo-ndk"
  exit 1
fi

echo "🔨 Building Rust wrapper for Android (all ABIs)..."
mkdir -p "$ANDROID_OUT_DIR"

# cargo-ndk will place output into $ANDROID_OUT_DIR/<abi>/ by default.
cargo ndk \
  -o "$ANDROID_OUT_DIR" \
  -t arm64-v8a \
  -t armeabi-v7a \
  -t x86 \
  -t x86_64 \
  build --release

echo "✅ Android build complete. Outputs:"
for ABI in arm64-v8a armeabi-v7a x86 x86_64; do
  echo "  - $ANDROID_OUT_DIR/$ABI/libsignal_ffi_wrapper.so"
done

