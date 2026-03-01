#!/bin/bash
# Build script for Signal FFI Rust Wrapper
# Phase 14: Signal Protocol Implementation - Option 1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build for macOS
echo "Building Rust wrapper for macOS..."

# Set RUSTFLAGS to use @loader_path for install_name (fixes hardcoded absolute paths)
# @loader_path resolves relative to the library's directory, making it portable
export RUSTFLAGS_X86_64="-C link-args=-Wl,-install_name,@loader_path/libsignal_ffi_wrapper.dylib"
export RUSTFLAGS_AARCH64="-C link-args=-Wl,-install_name,@loader_path/libsignal_ffi_wrapper.dylib"

# Build for x86_64
echo "  Building for x86_64..."
RUSTFLAGS="$RUSTFLAGS_X86_64" cargo build --release --target x86_64-apple-darwin

# Build for arm64
echo "  Building for arm64..."
RUSTFLAGS="$RUSTFLAGS_AARCH64" cargo build --release --target aarch64-apple-darwin

# Create universal binary for macOS
echo "Creating universal binary..."
mkdir -p ../macos
lipo -create \
    target/x86_64-apple-darwin/release/libsignal_ffi_wrapper.dylib \
    target/aarch64-apple-darwin/release/libsignal_ffi_wrapper.dylib \
    -output ../macos/libsignal_ffi_wrapper.dylib

# Fix install_name to use @loader_path (in case RUSTFLAGS didn't take effect)
# @loader_path resolves relative to the library's directory, making it portable
echo "Fixing install_name to use @loader_path..."
install_name_tool -id "@loader_path/libsignal_ffi_wrapper.dylib" ../macos/libsignal_ffi_wrapper.dylib 2>/dev/null || {
    echo "⚠️  Could not set install_name (install_name_tool may not be available)"
}

# Fix any hardcoded absolute paths in dependencies
# Check if the library has hardcoded paths to build directories
if otool -L ../macos/libsignal_ffi_wrapper.dylib | grep -q "$SCRIPT_DIR/target"; then
    echo "🔧 Fixing hardcoded dependency paths..."
    # Get the actual dependency paths from otool (check both architectures)
    for DEP_PATH in $(otool -L ../macos/libsignal_ffi_wrapper.dylib | grep "$SCRIPT_DIR/target" | awk '{print $1}' | sort -u); do
        if [ -n "$DEP_PATH" ]; then
            install_name_tool -change "$DEP_PATH" "@loader_path/libsignal_ffi_wrapper.dylib" ../macos/libsignal_ffi_wrapper.dylib 2>/dev/null || {
                echo "⚠️  Could not fix dependency path: $DEP_PATH"
            }
        fi
    done
fi

echo "✅ macOS build complete: ../macos/libsignal_ffi_wrapper.dylib"
