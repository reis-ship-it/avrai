#!/bin/bash
# Setup iOS Signal Protocol FFI (build from source)
# Phase 14: Signal Protocol Implementation - Hybrid Approach
# Option B: Build from source for iOS

set -e

echo "📱 Setting up Signal Protocol FFI for iOS (build from source)"
echo ""

# Check Rust installation
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust is not installed"
    echo ""
    echo "Please install Rust:"
    echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "  source \$HOME/.cargo/env"
    echo ""
    exit 1
fi

echo "✅ Rust toolchain found: $(rustc --version)"
echo "✅ Cargo found: $(cargo --version)"
echo ""

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "⚠️  Warning: Xcode Command Line Tools not found"
    echo "Please install: xcode-select --install"
    echo ""
fi

# Check protoc (Protocol Buffers compiler)
if ! command -v protoc &> /dev/null; then
    echo "❌ protoc (Protocol Buffers compiler) is not installed"
    echo ""
    echo "Please install protoc:"
    echo "  brew install protobuf"
    echo ""
    exit 1
fi

echo "✅ protoc found: $(protoc --version)"

# Check cmake (needed for boring-sys)
if ! command -v cmake &> /dev/null; then
    echo "❌ cmake is not installed"
    echo ""
    echo "Please install cmake:"
    echo "  brew install cmake"
    echo ""
    exit 1
fi

echo "✅ cmake found: $(cmake --version | head -1)"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p native/signal_ffi/ios

# Check if libsignal is already cloned
if [ -d "native/signal_ffi/libsignal" ]; then
    echo "✅ libsignal repository already exists"
    cd native/signal_ffi/libsignal
    echo "Updating repository..."
    git pull || echo "⚠️  Could not update (may be on specific commit)"
else
    echo "Cloning libsignal repository..."
    cd native/signal_ffi
    git clone https://github.com/signalapp/libsignal.git libsignal
    cd libsignal
    echo "✅ Repository cloned"
fi

echo ""
echo "Adding iOS targets..."

# Add iOS targets
rustup target add aarch64-apple-ios        # iOS devices (ARM64)
rustup target add aarch64-apple-ios-sim    # iOS simulator (Apple Silicon)
# Also add Intel simulator for compatibility
rustup target add x86_64-apple-ios 2>/dev/null || echo "⚠️  x86_64-apple-ios target may not be available on Apple Silicon"

echo "✅ iOS targets added"
echo ""

# Detect Mac architecture
MAC_ARCH=$(uname -m)
if [ "$MAC_ARCH" = "arm64" ]; then
    echo "Detected: Apple Silicon Mac"
    SIM_TARGET="aarch64-apple-ios-sim"
else
    echo "Detected: Intel Mac"
    SIM_TARGET="x86_64-apple-ios"
fi

echo ""
echo "Building libsignal-ffi for iOS..."
echo "This may take 10-30 minutes on first build..."
echo ""

# Build for iOS devices
echo "Building for iOS devices (aarch64-apple-ios)..."
cargo build --release --target aarch64-apple-ios 2>&1 | grep -E "(Compiling|Finished|error)" || true

# Build for iOS simulator
echo ""
echo "Building for iOS simulator (${SIM_TARGET})..."
cargo build --release --target ${SIM_TARGET} 2>&1 | grep -E "(Compiling|Finished|error)" || true

echo ""
echo "✅ Build complete!"
echo ""

# Check if libraries were built
DEVICE_LIB="target/aarch64-apple-ios/release/libsignal_ffi.a"
SIM_LIB="target/${SIM_TARGET}/release/libsignal_ffi.a"

if [ -f "$DEVICE_LIB" ]; then
    echo "✅ Device library built: $DEVICE_LIB"
    ls -lh "$DEVICE_LIB"
else
    echo "❌ Device library not found: $DEVICE_LIB"
fi

if [ -f "$SIM_LIB" ]; then
    echo "✅ Simulator library built: $SIM_LIB"
    ls -lh "$SIM_LIB"
else
    echo "⚠️  Simulator library not found: $SIM_LIB"
fi

echo ""
echo "Next steps:"
echo "1. Create iOS framework: ./scripts/create_ios_framework.sh"
echo "2. Add framework to Xcode project"
echo "3. Test iOS build: flutter build ios --debug --no-codesign"
