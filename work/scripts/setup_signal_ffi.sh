#!/bin/bash
# Setup script for libsignal-ffi integration
# Phase 14: Signal Protocol Implementation - Option 1

set -e

echo "🔧 Setting up libsignal-ffi for Phase 14"
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

# Check platform
PLATFORM=$(uname -s)
echo "Platform: $PLATFORM"

# Create directory structure
echo "Creating directory structure..."
mkdir -p native/signal_ffi/{android,ios,macos,linux,windows}
echo "✅ Directory structure created"
echo ""

# Check for libsignal-ffi
if [ -d "native/signal_ffi/libsignal" ]; then
    echo "✅ libsignal repository found"
    echo "To build: cd native/signal_ffi/libsignal && cargo build --release"
else
    echo "⚠️  libsignal repository not found"
    echo "Options:"
    echo "  1. Clone: git clone https://github.com/signalapp/libsignal.git native/signal_ffi/libsignal"
    echo "  2. Download pre-built binaries from: https://github.com/signalapp/libsignal/releases"
    echo ""
    read -p "Clone libsignal repository now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Cloning libsignal repository..."
        git clone https://github.com/signalapp/libsignal.git native/signal_ffi/libsignal
        echo "✅ Repository cloned"
        echo ""
        echo "Next steps:"
        echo "  1. cd native/signal_ffi/libsignal"
        echo "  2. cargo build --release"
        echo "  3. Copy built libraries to platform-specific directories"
    fi
fi

echo ""
echo "📋 Next Steps:"
echo "  1. Build or obtain libsignal-ffi libraries"
echo "  2. Place libraries in native/signal_ffi/{platform}/"
echo "  3. Update FFI bindings in lib/core/crypto/signal/signal_ffi_bindings.dart"
echo "  4. Configure platform-specific build settings"
echo "  5. Test FFI bindings"
echo ""
echo "See: docs/plans/security_implementation/PHASE_14_FFI_IMPLEMENTATION_GUIDE.md"
