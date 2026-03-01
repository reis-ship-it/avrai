#!/bin/bash
# Fix library paths for existing Signal Protocol libraries
# Phase 14: Signal Protocol Implementation - Option 1
#
# This script fixes hardcoded absolute paths in already-built libraries
# by changing them to use @rpath. This is a one-time fix for existing builds.
# Future builds should use the updated build scripts with @rpath support.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/native/signal_ffi/macos"

echo "🔧 Fixing Signal Protocol Library Paths"
echo "========================================"
echo ""

# Check if install_name_tool is available
if ! command -v install_name_tool &> /dev/null; then
    echo "❌ install_name_tool not found"
    echo "   This tool is required to fix library paths"
    echo "   It should be available with Xcode Command Line Tools"
    exit 1
fi

# Fix libsignal_ffi.dylib
if [ -f "$LIB_DIR/libsignal_ffi.dylib" ]; then
    echo "📚 Fixing libsignal_ffi.dylib..."
    
    # Set install_name to @loader_path (resolves relative to library's directory)
    install_name_tool -id "@loader_path/libsignal_ffi.dylib" "$LIB_DIR/libsignal_ffi.dylib" || {
        echo "⚠️  Could not set install_name for libsignal_ffi.dylib"
    }
    
    # Fix hardcoded dependency paths
    LIBSIGNAL_DIR="$PROJECT_ROOT/native/signal_ffi/libsignal"
    for DEP_PATH in $(otool -L "$LIB_DIR/libsignal_ffi.dylib" | grep "$LIBSIGNAL_DIR/target" | awk '{print $1}'); do
        if [ -n "$DEP_PATH" ]; then
            echo "  Fixing dependency: $DEP_PATH -> @loader_path/libsignal_ffi.dylib"
            install_name_tool -change "$DEP_PATH" "@loader_path/libsignal_ffi.dylib" "$LIB_DIR/libsignal_ffi.dylib" || {
                echo "⚠️  Could not fix dependency path: $DEP_PATH"
            }
        fi
    done
    
    echo "  ✅ libsignal_ffi.dylib fixed"
else
    echo "⚠️  libsignal_ffi.dylib not found at $LIB_DIR/libsignal_ffi.dylib"
fi
echo ""

# Fix libsignal_ffi_wrapper.dylib
if [ -f "$LIB_DIR/libsignal_ffi_wrapper.dylib" ]; then
    echo "📚 Fixing libsignal_ffi_wrapper.dylib..."
    
    # Set install_name to @loader_path (resolves relative to library's directory)
    install_name_tool -id "@loader_path/libsignal_ffi_wrapper.dylib" "$LIB_DIR/libsignal_ffi_wrapper.dylib" || {
        echo "⚠️  Could not set install_name for libsignal_ffi_wrapper.dylib"
    }
    
    # Fix hardcoded dependency paths (check both architectures)
    WRAPPER_DIR="$PROJECT_ROOT/native/signal_ffi/wrapper_rust"
    for DEP_PATH in $(otool -L "$LIB_DIR/libsignal_ffi_wrapper.dylib" | grep "$WRAPPER_DIR/target" | awk '{print $1}' | sort -u); do
        if [ -n "$DEP_PATH" ]; then
            echo "  Fixing dependency: $DEP_PATH -> @loader_path/libsignal_ffi_wrapper.dylib"
            install_name_tool -change "$DEP_PATH" "@loader_path/libsignal_ffi_wrapper.dylib" "$LIB_DIR/libsignal_ffi_wrapper.dylib" || {
                echo "⚠️  Could not fix dependency path: $DEP_PATH"
            }
        fi
    done
    
    echo "  ✅ libsignal_ffi_wrapper.dylib fixed"
else
    echo "⚠️  libsignal_ffi_wrapper.dylib not found at $LIB_DIR/libsignal_ffi_wrapper.dylib"
fi
echo ""

# Fix libsignal_callback_bridge.dylib
if [ -f "$LIB_DIR/libsignal_callback_bridge.dylib" ]; then
    echo "📚 Fixing libsignal_callback_bridge.dylib..."
    
    # Set install_name to @loader_path (resolves relative to library's directory)
    install_name_tool -id "@loader_path/libsignal_callback_bridge.dylib" "$LIB_DIR/libsignal_callback_bridge.dylib" || {
        echo "⚠️  Could not set install_name for libsignal_callback_bridge.dylib"
    }
    
    echo "  ✅ libsignal_callback_bridge.dylib fixed"
else
    echo "⚠️  libsignal_callback_bridge.dylib not found at $LIB_DIR/libsignal_callback_bridge.dylib"
fi
echo ""

echo "✅ Library path fixes complete!"
echo ""
echo "Next steps:"
echo "1. Rebuild libraries using updated build scripts for permanent fix"
echo "2. Test: flutter test test/core/crypto/signal/"
echo ""
