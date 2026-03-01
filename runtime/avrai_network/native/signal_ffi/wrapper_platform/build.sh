#!/bin/bash

# Build script for Platform-Specific Callback Bridge
# Phase 14: Signal Protocol Implementation - Option 1

set -euo pipefail

SCRIPT_DIR=$(dirname "$0")
cd "${SCRIPT_DIR}"

BRIDGE_NAME="signal_callback_bridge"
OUTPUT_DIR="../../macos"

echo "Building callback bridge for macOS..."

# Create build directory
mkdir -p build
cd build

# Configure CMake
cmake ..

# Build
cmake --build . --config Release

# Copy to output directory
mkdir -p "${OUTPUT_DIR}"

# Find the built library (CMake outputs to parent directory)
LIB_FILE=""
if [ -f "../lib${BRIDGE_NAME}.dylib" ]; then
    LIB_FILE="../lib${BRIDGE_NAME}.dylib"
elif [ -f "../../lib${BRIDGE_NAME}.dylib" ]; then
    LIB_FILE="../../lib${BRIDGE_NAME}.dylib"
elif [ -f "lib${BRIDGE_NAME}.dylib" ]; then
    LIB_FILE="lib${BRIDGE_NAME}.dylib"
elif [ -f "${BRIDGE_NAME}.dylib" ]; then
    LIB_FILE="${BRIDGE_NAME}.dylib"
fi

if [ -n "$LIB_FILE" ]; then
    cp "$LIB_FILE" "${OUTPUT_DIR}/"
    
    # Fix install_name to use @loader_path (resolves relative to library's directory)
    OUTPUT_LIB="${OUTPUT_DIR}/$(basename $LIB_FILE)"
    echo "🔧 Setting install_name to @loader_path..."
    install_name_tool -id "@loader_path/$(basename $LIB_FILE)" "$OUTPUT_LIB" 2>/dev/null || {
        echo "⚠️  Could not set install_name (install_name_tool may not be available)"
    }
    
    echo "✅ macOS build complete: $OUTPUT_LIB"
else
    echo "❌ Build failed: library not found"
    echo "   Searched for: lib${BRIDGE_NAME}.dylib, ${BRIDGE_NAME}.dylib"
    exit 1
fi
