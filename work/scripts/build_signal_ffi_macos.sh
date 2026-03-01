#!/bin/bash
# Build script for libsignal-ffi (macOS)
# Phase 14: Signal Protocol Implementation - Option 1
# Builds libsignal-ffi from source for macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBSIGNAL_DIR="$PROJECT_ROOT/native/signal_ffi/libsignal"
OUTPUT_DIR="$PROJECT_ROOT/native/signal_ffi/macos"

echo "🔨 Building libsignal-ffi for macOS..."
echo ""

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust is not installed"
    echo "Please install Rust from: https://rustup.rs/"
    exit 1
fi

echo "✅ Rust toolchain found: $(rustc --version)"
echo "✅ Cargo found: $(cargo --version)"
echo ""

# Check if libsignal source exists
if [ ! -d "$LIBSIGNAL_DIR" ]; then
    echo "❌ libsignal source not found at: $LIBSIGNAL_DIR"
    echo ""
    echo "Please clone the libsignal repository first:"
    echo "  git clone https://github.com/signalapp/libsignal.git $LIBSIGNAL_DIR"
    exit 1
fi

echo "✅ libsignal source found"
echo ""

# Check for required tools
if ! command -v protoc &> /dev/null; then
    echo "⚠️  Warning: protoc (Protocol Buffers compiler) not found"
    echo "   Install with: brew install protobuf"
    echo "   Build may fail without it"
    echo ""
fi

if ! command -v cmake &> /dev/null; then
    echo "⚠️  Warning: cmake not found"
    echo "   Install with: brew install cmake"
    echo "   Build may fail without it"
    echo ""
fi

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="aarch64-apple-darwin"
    echo "📱 Detected architecture: ARM64 (Apple Silicon)"
else
    TARGET="x86_64-apple-darwin"
    echo "📱 Detected architecture: x86_64 (Intel)"
fi

echo "🎯 Building for target: $TARGET"
echo ""

# Change to libsignal directory
cd "$LIBSIGNAL_DIR"

# Build the FFI bridge library
echo "Building libsignal-ffi bridge..."
echo "This may take 20-40 minutes on first build (compiles all dependencies)..."
echo ""

# Set RUSTFLAGS to use @loader_path for install_name (fixes hardcoded absolute paths)
# @loader_path resolves relative to the library's directory, making it portable
export RUSTFLAGS="-C link-args=-Wl,-install_name,@loader_path/libsignal_ffi.dylib"

# Build only the FFI bridge package
# Note: This will build all dependencies too, which is why it takes time
cargo build --release --target "$TARGET" -p libsignal-ffi 2>&1 | tee /tmp/signal_ffi_build.log | grep -E "(Compiling|Finished|error|warning|Updating)" || {
    echo ""
    echo "❌ Build failed. Check /tmp/signal_ffi_build.log for details"
    echo ""
    echo "Common issues:"
    echo "  - Missing protoc: brew install protobuf"
    echo "  - Missing cmake: brew install cmake"
    echo "  - Rust toolchain issues: rustup update"
    exit 1
}

echo ""
echo "✅ Build complete!"
echo ""

# Find the built library
BUILD_DIR="$LIBSIGNAL_DIR/target/$TARGET/release"
STATIC_LIB="libsignal_ffi.a"
DYNAMIC_LIB="libsignal_ffi.dylib"

# libsignal-ffi should build as a dynamic library for macOS (cdylib)
# Check what was actually built
if [ -f "$BUILD_DIR/$DYNAMIC_LIB" ]; then
    FOUND_LIB="$BUILD_DIR/$DYNAMIC_LIB"
    echo "✅ Found dynamic library: $FOUND_LIB"
elif [ -f "$BUILD_DIR/deps/$DYNAMIC_LIB" ]; then
    FOUND_LIB="$BUILD_DIR/deps/$DYNAMIC_LIB"
    echo "✅ Found dynamic library in deps: $FOUND_LIB"
elif [ -f "$BUILD_DIR/$STATIC_LIB" ]; then
    echo "⚠️  Found static library instead of dynamic library"
    echo "   This means the Cargo.toml change didn't take effect"
    echo "   Checking if we need to rebuild..."
    FOUND_LIB="$BUILD_DIR/$STATIC_LIB"
    echo "   Static library found: $FOUND_LIB"
    echo "   You may need to:"
    echo "   1. Clean build: cargo clean -p libsignal-ffi"
    echo "   2. Rebuild: cargo build --release --target $TARGET -p libsignal-ffi"
    echo ""
elif [ -f "$BUILD_DIR/$DYNAMIC_LIB" ]; then
    FOUND_LIB="$BUILD_DIR/$DYNAMIC_LIB"
    echo "✅ Found dynamic library: $FOUND_LIB"
elif [ -f "$BUILD_DIR/deps/$DYNAMIC_LIB" ]; then
    FOUND_LIB="$BUILD_DIR/deps/$DYNAMIC_LIB"
    echo "✅ Found dynamic library in deps: $FOUND_LIB"
else
    echo "⚠️  Library not found in expected location"
    echo "   Searching for signal_ffi libraries..."
    find "$BUILD_DIR" -name "*signal*ffi*" -o -name "*signal_ffi*" 2>/dev/null | head -10
    echo ""
    echo "Please check the build output and locate the library manually"
    exit 1
fi

echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy library to output directory
if [ -f "$FOUND_LIB" ]; then
    if [[ "$FOUND_LIB" == *.a ]]; then
        # Static library - this shouldn't happen for macOS, but handle it gracefully
        cp "$FOUND_LIB" "$OUTPUT_DIR/$STATIC_LIB"
        echo "✅ Copied static library to: $OUTPUT_DIR/$STATIC_LIB"
        ls -lh "$OUTPUT_DIR/$STATIC_LIB"
        echo ""
        echo "⚠️  WARNING: Got static library instead of dynamic library!"
        echo "   The Cargo.toml target-specific configuration may not be working."
        echo "   Try: cargo clean -p libsignal-ffi && rebuild"
    else
        # Dynamic library - this is what we want
        cp "$FOUND_LIB" "$OUTPUT_DIR/$DYNAMIC_LIB"
        echo "✅ Copied dynamic library to: $OUTPUT_DIR/$DYNAMIC_LIB"
        
        # Fix install_name to use @loader_path (in case RUSTFLAGS didn't take effect)
        # @loader_path resolves relative to the library's directory, making it portable
        install_name_tool -id "@loader_path/libsignal_ffi.dylib" "$OUTPUT_DIR/$DYNAMIC_LIB" 2>/dev/null || {
            echo "⚠️  Could not set install_name (install_name_tool may not be available)"
        }
        
        # Fix any hardcoded absolute paths in dependencies
        # Check if the library has hardcoded paths to build directories
        if otool -L "$OUTPUT_DIR/$DYNAMIC_LIB" | grep -q "$LIBSIGNAL_DIR/target"; then
            echo "🔧 Fixing hardcoded dependency paths..."
            # Get the actual dependency path from otool
            DEP_PATH=$(otool -L "$OUTPUT_DIR/$DYNAMIC_LIB" | grep "$LIBSIGNAL_DIR/target" | head -1 | awk '{print $1}')
            if [ -n "$DEP_PATH" ]; then
                install_name_tool -change "$DEP_PATH" "@loader_path/libsignal_ffi.dylib" "$OUTPUT_DIR/$DYNAMIC_LIB" 2>/dev/null || {
                    echo "⚠️  Could not fix dependency path (install_name_tool may not be available)"
                }
            fi
        fi
        
        ls -lh "$OUTPUT_DIR/$DYNAMIC_LIB"
        echo ""
        echo "✅ Perfect! Dynamic library ready for Dart FFI (with @loader_path)"
    fi
    
    # Clean up wrapper directory if it exists
    rm -rf "$WRAPPER_DIR" 2>/dev/null || true
else
    echo "❌ Library file not found: $FOUND_LIB"
    exit 1
fi

echo ""
echo "✅ libsignal-ffi build complete!"
echo ""
echo "Library location: $OUTPUT_DIR/$LIB_NAME"
echo ""
echo "Next steps:"
echo "1. Verify library: ls -lh $OUTPUT_DIR/$LIB_NAME"
echo "2. Test FFI bindings: flutter test test/core/crypto/signal/"
echo "3. Run app: flutter run -d macos"
