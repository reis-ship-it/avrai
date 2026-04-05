#!/bin/bash
# Build script for Signal FFI Wrapper
# Phase 14: Signal Protocol Implementation - Option 1
#
# Builds the C wrapper library for all supported platforms

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WRAPPER_DIR="$SCRIPT_DIR"

cd "$WRAPPER_DIR"

echo "🔨 Building Signal FFI Wrapper..."

# ============================================================================
# Android Build
# ============================================================================
if [ -d "$PROJECT_ROOT/android" ]; then
    echo "📱 Building for Android..."
    
    # Check if NDK is available
    if [ -z "$ANDROID_NDK" ]; then
        echo "⚠️  ANDROID_NDK not set. Skipping Android build."
        echo "   Set ANDROID_NDK environment variable to build for Android."
    else
        # Create build directory
        mkdir -p build/android
        cd build/android
        
        # Build for each Android ABI
        for ABI in arm64-v8a armeabi-v7a x86 x86_64; do
            echo "  Building for $ABI..."
            
            cmake "$WRAPPER_DIR" \
                -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
                -DANDROID_ABI="$ABI" \
                -DANDROID_PLATFORM=android-21 \
                -DCMAKE_BUILD_TYPE=Release
            
            cmake --build . --config Release
            
            # Copy library to platform directory
            mkdir -p "$PROJECT_ROOT/native/signal_ffi/android/$ABI"
            cp libsignal_ffi_wrapper.so "$PROJECT_ROOT/native/signal_ffi/android/$ABI/" || true
        done
        
        cd "$WRAPPER_DIR"
    fi
fi

# ============================================================================
# Linux Build
# ============================================================================
if [ "$(uname)" = "Linux" ]; then
    echo "🐧 Building for Linux..."
    
    mkdir -p build/linux
    cd build/linux
    
    cmake "$WRAPPER_DIR" -DCMAKE_BUILD_TYPE=Release
    cmake --build . --config Release
    
    # Copy library to platform directory
    mkdir -p "$PROJECT_ROOT/native/signal_ffi/linux"
    cp libsignal_ffi_wrapper.so "$PROJECT_ROOT/native/signal_ffi/linux/" || true
    
    cd "$WRAPPER_DIR"
fi

# ============================================================================
# macOS Build
# ============================================================================
if [ "$(uname)" = "Darwin" ]; then
    echo "🍎 Building for macOS..."
    
    mkdir -p build/macos
    cd build/macos
    
    cmake "$WRAPPER_DIR" -DCMAKE_BUILD_TYPE=Release
    cmake --build . --config Release
    
    # Copy library to platform directory
    mkdir -p "$PROJECT_ROOT/native/signal_ffi/macos"
    cp libsignal_ffi_wrapper.dylib "$PROJECT_ROOT/native/signal_ffi/macos/" || true
    
    cd "$WRAPPER_DIR"
fi

echo "✅ Signal FFI Wrapper build complete!"
