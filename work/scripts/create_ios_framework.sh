#!/bin/bash
# Create iOS framework from built libsignal-ffi
# Phase 14: Signal Protocol Implementation - Hybrid Approach

set -e

echo "📱 Creating iOS framework for libsignal-ffi"
echo ""

# Configuration
FRAMEWORK_NAME="SignalFFI"
FRAMEWORK_DIR="native/signal_ffi/ios/${FRAMEWORK_NAME}.framework"
LIB_DIR="native/signal_ffi/libsignal/target"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check if libsignal was built
if [ ! -d "${LIB_DIR}" ]; then
    echo "❌ Error: libsignal not built yet"
    echo ""
    echo "Please build libsignal first:"
    echo "1. cd native/signal_ffi/libsignal"
    echo "2. cargo build --release --target aarch64-apple-ios"
    echo "3. cargo build --release --target aarch64-apple-ios-sim  # For Apple Silicon Macs"
    echo "   OR"
    echo "   cargo build --release --target x86_64-apple-ios  # For Intel Macs"
    exit 1
fi

# Create framework structure
echo "Creating framework structure..."
mkdir -p "${FRAMEWORK_DIR}/Headers"
mkdir -p "${FRAMEWORK_DIR}/Modules"

# Determine which architectures are available
DEVICE_LIB="${LIB_DIR}/aarch64-apple-ios/release/libsignal_ffi.a"
SIM_INTEL_LIB="${LIB_DIR}/x86_64-apple-ios/release/libsignal_ffi.a"
SIM_ARM_LIB="${LIB_DIR}/aarch64-apple-ios-sim/release/libsignal_ffi.a"

# Create universal binary if multiple architectures exist
if [ -f "${DEVICE_LIB}" ] && [ -f "${SIM_INTEL_LIB}" ]; then
    echo "Creating universal binary for device and Intel simulator..."
    if command -v lipo &> /dev/null; then
        lipo -create "${DEVICE_LIB}" "${SIM_INTEL_LIB}" -output "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
        echo "✅ Universal binary created (device + Intel simulator)"
    else
        echo "⚠️  Warning: lipo not found. Using device library only."
        cp "${DEVICE_LIB}" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
    fi
elif [ -f "${DEVICE_LIB}" ] && [ -f "${SIM_ARM_LIB}" ]; then
    echo "Note: Device and simulator are both ARM64 (Apple Silicon)"
    echo "Using device library (works on both device and Apple Silicon simulator)"
    cp "${DEVICE_LIB}" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
    echo "✅ Framework created with device library"
elif [ -f "${DEVICE_LIB}" ]; then
    echo "Using device library only"
    cp "${DEVICE_LIB}" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
    echo "✅ Framework created with device library"
else
    echo "❌ Error: No built libraries found"
    echo ""
    echo "Expected locations:"
    echo "  Device: ${DEVICE_LIB}"
    echo "  Simulator (Intel): ${SIM_INTEL_LIB}"
    echo "  Simulator (ARM): ${SIM_ARM_LIB}"
    exit 1
fi

# Create module map
echo "Creating module map..."
cat > "${FRAMEWORK_DIR}/Modules/module.modulemap" << EOF
framework module ${FRAMEWORK_NAME} {
    umbrella header "${FRAMEWORK_NAME}.h"
    export *
    module * { export * }
}
EOF

# Create umbrella header
echo "Creating umbrella header..."
cat > "${FRAMEWORK_DIR}/Headers/${FRAMEWORK_NAME}.h" << EOF
//
//  ${FRAMEWORK_NAME}.h
//  Signal Protocol FFI
//
//  This header is a placeholder. libsignal-ffi provides C bindings
//  that should be included here or accessed via FFI.
//

#ifndef ${FRAMEWORK_NAME}_h
#define ${FRAMEWORK_NAME}_h

// Note: libsignal-ffi functions are accessed via Dart FFI
// This header is for framework compatibility only

#endif /* ${FRAMEWORK_NAME}_h */
EOF

# Create Info.plist
echo "Creating Info.plist..."
cat > "${FRAMEWORK_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>org.signal.${FRAMEWORK_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF

echo ""
echo "✅ iOS framework created at: ${FRAMEWORK_DIR}"
echo ""
echo "Framework structure:"
ls -la "${FRAMEWORK_DIR}/"
echo ""
echo "Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Drag ${FRAMEWORK_DIR} into the project"
echo "3. Add to 'Frameworks, Libraries, and Embedded Content'"
echo "4. Set 'Embed & Sign'"
echo "5. Update signal_ffi_bindings.dart to load framework"
echo "6. Test iOS build: flutter build ios --debug --no-codesign"
