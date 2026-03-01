#!/bin/bash
# Build script for Signal FFI Rust Wrapper (iOS XCFramework)
# Phase 14: Signal Protocol Implementation - Option 1
#
# Produces:
#   native/signal_ffi/ios/SignalFfiWrapper.xcframework
#
# This XCFramework is vendored via:
#   ios/SignalNative/SignalNative.podspec

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

cd "$SCRIPT_DIR"

OUT_DIR="$PROJECT_ROOT/native/signal_ffi/ios/SignalFfiWrapper.xcframework"
HEADER_DIR="$SCRIPT_DIR/include"

DEVICE_LIB="$SCRIPT_DIR/target/aarch64-apple-ios/release/libsignal_ffi_wrapper.dylib"
SIM_LIB_ARM64="$SCRIPT_DIR/target/aarch64-apple-ios-sim/release/libsignal_ffi_wrapper.dylib"
SIM_LIB_X86_64="$SCRIPT_DIR/target/x86_64-apple-ios/release/libsignal_ffi_wrapper.dylib"
SIM_UNIVERSAL_DIR="$SCRIPT_DIR/target/ios-sim-universal/release"
SIM_LIB_UNIVERSAL="$SIM_UNIVERSAL_DIR/libsignal_ffi_wrapper.dylib"

echo "🔨 Building Rust wrapper dylibs for iOS..."

# iOS toolchains can choke on Rust-produced LLVM sections when LTO/bitcode is enabled.
# For app-embedded staticlibs used via Dart FFI, we don't need bitcode or LTO.
export RUSTFLAGS="-Cembed-bitcode=no"
export CARGO_PROFILE_RELEASE_LTO="off"

echo "  - Building ios-arm64 (device)..."
cargo rustc --release --target aarch64-apple-ios --crate-type cdylib

echo "  - Building ios-arm64-simulator..."
cargo rustc --release --target aarch64-apple-ios-sim --crate-type cdylib

echo "  - Building ios-x86_64-simulator..."
cargo rustc --release --target x86_64-apple-ios --crate-type cdylib

if [ ! -f "$DEVICE_LIB" ]; then
  echo "❌ Missing device dylib: $DEVICE_LIB"
  exit 1
fi
if [ ! -f "$SIM_LIB_ARM64" ]; then
  echo "❌ Missing simulator dylib: $SIM_LIB_ARM64"
  exit 1
fi
if [ ! -f "$SIM_LIB_X86_64" ]; then
  echo "❌ Missing x86_64 simulator dylib: $SIM_LIB_X86_64"
  exit 1
fi

echo "  - Creating universal simulator dylib (arm64 + x86_64)..."
mkdir -p "$SIM_UNIVERSAL_DIR"
lipo -create "$SIM_LIB_ARM64" "$SIM_LIB_X86_64" -output "$SIM_LIB_UNIVERSAL"

FRAMEWORK_NAME="SignalFfiWrapper"
DEVICE_FW_ROOT="$SCRIPT_DIR/target/ios-fw-device"
SIM_FW_ROOT="$SCRIPT_DIR/target/ios-fw-sim"
DEVICE_FW="$DEVICE_FW_ROOT/$FRAMEWORK_NAME.framework"
SIM_FW="$SIM_FW_ROOT/$FRAMEWORK_NAME.framework"

echo "📦 Building framework bundles (for CocoaPods embedding)..."
rm -rf "$DEVICE_FW_ROOT" "$SIM_FW_ROOT"
mkdir -p "$DEVICE_FW/Headers" "$SIM_FW/Headers"

# Copy and rename binaries to match framework conventions.
cp "$DEVICE_LIB" "$DEVICE_FW/$FRAMEWORK_NAME"
cp "$SIM_LIB_UNIVERSAL" "$SIM_FW/$FRAMEWORK_NAME"

# Headers
cp -R "$HEADER_DIR/"* "$DEVICE_FW/Headers/"
cp -R "$HEADER_DIR/"* "$SIM_FW/Headers/"

# Minimal Info.plist (required by some tooling)
cat > "$DEVICE_FW/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleIdentifier</key>
  <string>com.spots.SignalFfiWrapper</string>
  <key>CFBundleName</key>
  <string>SignalFfiWrapper</string>
  <key>CFBundleExecutable</key>
  <string>SignalFfiWrapper</string>
</dict>
</plist>
EOF
cp "$DEVICE_FW/Info.plist" "$SIM_FW/Info.plist"

echo "  - Setting install_name to @rpath for framework binaries..."
install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" "$DEVICE_FW/$FRAMEWORK_NAME" 2>/dev/null || true
install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" "$SIM_FW/$FRAMEWORK_NAME" 2>/dev/null || true

echo "📦 Creating XCFramework..."
rm -rf "$OUT_DIR"

xcodebuild -create-xcframework \
  -framework "$DEVICE_FW" \
  -framework "$SIM_FW" \
  -output "$OUT_DIR"

echo "✅ iOS XCFramework ready: $OUT_DIR"

