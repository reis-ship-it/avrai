#!/bin/bash
# Build script for Signal FFI Wrapper (iOS/macOS)
# Phase 14: Signal Protocol Implementation - Option 1
#
# Builds the C wrapper library for iOS and macOS using Xcode

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WRAPPER_DIR="$SCRIPT_DIR"

cd "$WRAPPER_DIR"

echo "🔨 Building Signal FFI Wrapper for iOS/macOS..."

# ============================================================================
# macOS Build
# ============================================================================
if [ "$(uname)" = "Darwin" ]; then
    echo "🍎 Building for macOS..."
    
    # Create Xcode project
    mkdir -p build/macos
    cd build/macos
    
    cmake "$WRAPPER_DIR" \
        -G Xcode \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"
    
    xcodebuild -project signal_ffi_wrapper.xcodeproj \
        -scheme signal_ffi_wrapper \
        -configuration Release \
        -arch x86_64 -arch arm64 \
        build
    
    # Copy library to platform directory
    mkdir -p "$PROJECT_ROOT/native/signal_ffi/macos"
    cp Release/libsignal_ffi_wrapper.dylib "$PROJECT_ROOT/native/signal_ffi/macos/" || true
    
    cd "$WRAPPER_DIR"
    
    # ============================================================================
    # iOS Build
    # ============================================================================
    echo "📱 Building for iOS..."
    
    mkdir -p build/ios
    cd build/ios
    
    # Build for iOS device (arm64)
    cmake "$WRAPPER_DIR" \
        -G Xcode \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
        -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
    
    xcodebuild -project signal_ffi_wrapper.xcodeproj \
        -scheme signal_ffi_wrapper \
        -configuration Release \
        -sdk iphoneos \
        -arch arm64 \
        build
    
    # Build for iOS simulator (arm64 for Apple Silicon, x86_64 for Intel)
    if [ "$(uname -m)" = "arm64" ]; then
        SIM_ARCH="arm64"
    else
        SIM_ARCH="x86_64"
    fi
    
    xcodebuild -project signal_ffi_wrapper.xcodeproj \
        -scheme signal_ffi_wrapper \
        -configuration Release \
        -sdk iphonesimulator \
        -arch "$SIM_ARCH" \
        build
    
    # Create universal framework (if needed)
    # For now, we'll use the device library which works on both device and Apple Silicon simulators
    mkdir -p "$PROJECT_ROOT/native/signal_ffi/ios"
    cp Release-iphoneos/libsignal_ffi_wrapper.a "$PROJECT_ROOT/native/signal_ffi/ios/libsignal_ffi_wrapper.a" || true
    
    cd "$WRAPPER_DIR"
fi

echo "✅ Signal FFI Wrapper iOS/macOS build complete!"
