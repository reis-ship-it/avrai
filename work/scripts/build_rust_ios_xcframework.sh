#!/bin/bash
# Build knot_math Rust library as an iOS XCFramework (static library slices).
#
# Why:
# - iOS devices cannot load a dylib from a developer machine path.
# - For Dart FFI + flutter_rust_bridge on iOS, the most reliable setup is:
#   - build static libs (.a) for device + simulator
#   - package into an .xcframework for Xcode/CocoaPods
#   - link with -force_load so symbols are not dead-stripped (FFI uses dlsym).
#
# Output:
#   native/knot_math/ios/knot_math.xcframework

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUST_DIR="$PROJECT_ROOT/engine/avrai_knot/native/knot_math"
OUT_DIR="$RUST_DIR/ios"
XCFRAMEWORK_PATH="$OUT_DIR/knot_math.xcframework"
HEADERS_DIR="$OUT_DIR/Headers"

cd "$RUST_DIR"

echo "🔨 Building knot_math for iOS (static libs)..."
"$SCRIPT_DIR/build_rust_ios.sh"

# Ensure headers dir exists (xcframework requires a headers directory per slice).
mkdir -p "$HEADERS_DIR"
cat > "$HEADERS_DIR/knot_math.h" <<'EOF'
// knot_math.h
// Intentionally minimal. Dart FFI uses symbol lookup; no headers required.
EOF

DEVICE_LIB="$RUST_DIR/target/aarch64-apple-ios/release/libknot_math.a"
SIM_ARM64_LIB="$RUST_DIR/target/aarch64-apple-ios-sim/release/libknot_math.a"
SIM_X86_64_LIB="$RUST_DIR/target/x86_64-apple-ios/release/libknot_math.a"
SIM_UNIVERSAL_LIB="$OUT_DIR/libknot_math_simulator_universal.a"

for f in "$DEVICE_LIB" "$SIM_ARM64_LIB" "$SIM_X86_64_LIB"; do
  if [ ! -f "$f" ]; then
    echo "❌ Missing expected library: $f"
    exit 1
  fi
done

echo "📦 Creating XCFramework..."
rm -rf "$XCFRAMEWORK_PATH"

# Xcode requires a single "simulator" library definition; create a universal
# simulator .a to avoid "equivalent library definitions" errors.
echo "🧬 Creating universal simulator library (arm64 + x86_64)..."
xcrun lipo -create "$SIM_ARM64_LIB" "$SIM_X86_64_LIB" -output "$SIM_UNIVERSAL_LIB"

# CocoaPods generated xcconfig will look for -lknot_math.
# We need the generated .a files inside the xcframework to match this name.
SIM_UNIVERSAL_RENAMED_LIB="$OUT_DIR/libknot_math.a"
cp "$SIM_UNIVERSAL_LIB" "$SIM_UNIVERSAL_RENAMED_LIB"

xcodebuild -create-xcframework \
  -library "$DEVICE_LIB" -headers "$HEADERS_DIR" \
  -library "$SIM_UNIVERSAL_RENAMED_LIB" -headers "$HEADERS_DIR" \
  -output "$XCFRAMEWORK_PATH"

# cleanup
rm "$SIM_UNIVERSAL_RENAMED_LIB"

echo "✅ XCFramework created at: $XCFRAMEWORK_PATH"

