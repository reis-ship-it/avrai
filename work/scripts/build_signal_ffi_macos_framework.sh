#!/bin/bash
# Build script for SignalFFI macOS Framework
# Phase 14: Unified Library Manager - Phase 1
# Builds libsignal-ffi as a macOS framework for process-level loading

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBSIGNAL_DIR="$PROJECT_ROOT/native/signal_ffi/libsignal"
FRAMEWORK_DIR="$PROJECT_ROOT/native/signal_ffi/macos/SignalFFI.framework"
OUTPUT_DIR="$PROJECT_ROOT/native/signal_ffi/macos"

echo "🔨 Building SignalFFI macOS Framework..."
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
echo "Building libsignal-ffi..."
echo "This may take 20-40 minutes on first build (compiles all dependencies)..."
echo ""

# Set RUSTFLAGS to use @rpath for install_name (framework-compatible)
export RUSTFLAGS="-C link-args=-Wl,-install_name,@rpath/SignalFFI.framework/SignalFFI"

# Build only the FFI bridge package
cargo build --release --target "$TARGET" -p libsignal-ffi 2>&1 | tee /tmp/signal_ffi_framework_build.log | grep -E "(Compiling|Finished|error|warning|Updating)" || {
    echo ""
    echo "❌ Build failed. Check /tmp/signal_ffi_framework_build.log for details"
    exit 1
}

echo ""
echo "✅ Build complete!"
echo ""

# Find the built library
BUILD_DIR="$LIBSIGNAL_DIR/target/$TARGET/release"
DYNAMIC_LIB="libsignal_ffi.dylib"

# Check for the dynamic library
if [ -f "$BUILD_DIR/$DYNAMIC_LIB" ]; then
    FOUND_LIB="$BUILD_DIR/$DYNAMIC_LIB"
    echo "✅ Found dynamic library: $FOUND_LIB"
elif [ -f "$BUILD_DIR/deps/$DYNAMIC_LIB" ]; then
    FOUND_LIB="$BUILD_DIR/deps/$DYNAMIC_LIB"
    echo "✅ Found dynamic library in deps: $FOUND_LIB"
else
    echo "❌ Dynamic library not found in expected location"
    echo "   Searching for signal_ffi libraries..."
    find "$BUILD_DIR" -name "*signal*ffi*" -o -name "*signal_ffi*" 2>/dev/null | head -10
    exit 1
fi

echo ""

# Create framework structure
echo "Creating framework structure..."
mkdir -p "$FRAMEWORK_DIR/Headers"
mkdir -p "$FRAMEWORK_DIR/Modules"
mkdir -p "$FRAMEWORK_DIR/Resources"

# Copy library to framework (rename to SignalFFI)
cp "$FOUND_LIB" "$FRAMEWORK_DIR/SignalFFI"
echo "✅ Copied library to framework"

# Fix install_name for framework
install_name_tool -id "@rpath/SignalFFI.framework/SignalFFI" "$FRAMEWORK_DIR/SignalFFI" 2>/dev/null || {
    echo "⚠️  Could not set install_name (install_name_tool may not be available)"
}

# Create module map
cat > "$FRAMEWORK_DIR/Modules/module.modulemap" << 'EOF'
framework module SignalFFI {
    umbrella header "SignalFFI.h"
    export *
    module * { export * }
}
EOF
echo "✅ Created module.modulemap"

# Create header file
cat > "$FRAMEWORK_DIR/Headers/SignalFFI.h" << 'EOF'
//
//  SignalFFI.h
//  Signal Protocol FFI
//
//  This header is a placeholder. libsignal-ffi provides C bindings
//  that should be included here or accessed via FFI.
//

#ifndef SignalFFI_h
#define SignalFFI_h

// Note: libsignal-ffi functions are accessed via Dart FFI
// This header is for framework compatibility only

#endif /* SignalFFI_h */
EOF
echo "✅ Created SignalFFI.h header"

# Create Info.plist
cat > "$FRAMEWORK_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>SignalFFI</string>
    <key>CFBundleIdentifier</key>
    <string>com.spots.SignalFFI</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>SignalFFI</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>11.0</string>
</dict>
</plist>
EOF
echo "✅ Created Info.plist"

# Verify framework structure
echo ""
echo "📦 Framework structure:"
ls -lh "$FRAMEWORK_DIR"
echo ""
echo "📁 Framework contents:"
find "$FRAMEWORK_DIR" -type f | sort

# Verify library type
echo ""
echo "🔍 Verifying library type:"
file "$FRAMEWORK_DIR/SignalFFI"
otool -L "$FRAMEWORK_DIR/SignalFFI" | head -5

echo ""
echo "✅ SignalFFI.framework created successfully!"
echo ""
echo "Framework location: $FRAMEWORK_DIR"
echo ""
echo "Next steps:"
echo "1. Embed framework in Xcode project"
echo "2. Test framework loading: flutter run -d macos"
echo "3. Update SignalLibraryManager to use framework"
