#!/bin/bash
# Test script for Signal Protocol FFI bindings
# Phase 14: Signal Protocol Implementation

set -e

echo "🧪 Testing Signal Protocol FFI Bindings..."
echo ""

# Check if library exists
if [ ! -f "native/signal_ffi/macos/libsignal_ffi.dylib" ]; then
    echo "❌ Error: libsignal_ffi.dylib not found"
    echo "   Expected: native/signal_ffi/macos/libsignal_ffi.dylib"
    echo "   Run: ./scripts/build_signal_ffi_macos.sh"
    exit 1
fi

echo "✅ Found libsignal_ffi.dylib"
echo ""

# Check for other required libraries
if [ ! -f "native/signal_ffi/macos/libsignal_ffi_wrapper.dylib" ]; then
    echo "⚠️  Warning: libsignal_ffi_wrapper.dylib not found"
    echo "   This may be needed for some tests"
fi

if [ ! -f "native/signal_ffi/macos/libsignal_callback_bridge.dylib" ]; then
    echo "⚠️  Warning: libsignal_callback_bridge.dylib not found"
    echo "   This may be needed for some tests"
fi

echo ""
echo "Running Flutter tests..."
echo ""

# Run tests
flutter test test/core/crypto/signal/ --reporter expanded

echo ""
echo "✅ Tests complete!"
