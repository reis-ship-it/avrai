#!/bin/bash
# Copy Signal FFI Wrapper library to macOS app bundle
# Phase 14: Signal Protocol Implementation - Option 1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WRAPPER_LIB="$PROJECT_ROOT/native/signal_ffi/macos/libsignal_ffi_wrapper.dylib"
BUILD_DIR="$PROJECT_ROOT/build/macos/Build/Products"

echo "📦 Copying Signal FFI Wrapper library to macOS app bundle..."

# Find the app bundle
APP_BUNDLE=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)

if [ -z "$APP_BUNDLE" ]; then
    echo "⚠️  App bundle not found in $BUILD_DIR"
    echo "   Run 'flutter build macos' first, or copy manually:"
    echo "   cp $WRAPPER_LIB <app_bundle>/Contents/Frameworks/"
    exit 1
fi

FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
mkdir -p "$FRAMEWORKS_DIR"

if [ ! -f "$WRAPPER_LIB" ]; then
    echo "⚠️  Wrapper library not found: $WRAPPER_LIB"
    echo "   Build it first: cd native/signal_ffi/wrapper && ./build.sh"
    exit 1
fi

cp "$WRAPPER_LIB" "$FRAMEWORKS_DIR/"
echo "✅ Copied $WRAPPER_LIB to $FRAMEWORKS_DIR/"

# Update library install name to use @rpath
install_name_tool -id "@rpath/libsignal_ffi_wrapper.dylib" "$FRAMEWORKS_DIR/libsignal_ffi_wrapper.dylib" 2>/dev/null || true

echo "✅ Signal FFI Wrapper library ready in app bundle"
