#!/bin/bash
# Repackage SignalFfi.xcframework to contain .framework bundles (not bare dylibs).
#
# Why:
# CocoaPods reliably embeds dynamic frameworks from XCFrameworks into Runner.app.
# Bare dylibs inside an XCFramework may be linked but not copied into the app
# bundle, making Dart FFI `DynamicLibrary.open()` fail at runtime.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SRC_XCFRAMEWORK="$PROJECT_ROOT/native/signal_ffi/ios/SignalFfi.xcframework"
OUT_XCFRAMEWORK="$PROJECT_ROOT/native/signal_ffi/ios/SignalFfi.xcframework"

FRAMEWORK_NAME="SignalFfi"
TMP_ROOT="$PROJECT_ROOT/native/signal_ffi/.tmp_ios_signalffi_framework"
DEVICE_SLICE="$SRC_XCFRAMEWORK/ios-arm64"
SIM_SLICE="$SRC_XCFRAMEWORK/ios-arm64-simulator"

DEVICE_DYLIB="$DEVICE_SLICE/libsignal_ffi.dylib"
SIM_DYLIB="$SIM_SLICE/libsignal_ffi.dylib"
HEADERS_DIR="$DEVICE_SLICE/Headers"

if [ ! -f "$DEVICE_DYLIB" ] || [ ! -f "$SIM_DYLIB" ]; then
  echo "❌ Missing libsignal_ffi dylib slices in $SRC_XCFRAMEWORK"
  exit 1
fi

echo "📦 Repackaging SignalFfi.xcframework as frameworks..."
rm -rf "$TMP_ROOT"
mkdir -p "$TMP_ROOT/device/$FRAMEWORK_NAME.framework/Headers"
mkdir -p "$TMP_ROOT/sim/$FRAMEWORK_NAME.framework/Headers"

cp "$DEVICE_DYLIB" "$TMP_ROOT/device/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"
cp "$SIM_DYLIB" "$TMP_ROOT/sim/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"
cp -R "$HEADERS_DIR/"* "$TMP_ROOT/device/$FRAMEWORK_NAME.framework/Headers/"
cp -R "$HEADERS_DIR/"* "$TMP_ROOT/sim/$FRAMEWORK_NAME.framework/Headers/"

cat > "$TMP_ROOT/device/$FRAMEWORK_NAME.framework/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleIdentifier</key>
  <string>com.spots.SignalFfi</string>
  <key>CFBundleName</key>
  <string>SignalFfi</string>
  <key>CFBundleExecutable</key>
  <string>SignalFfi</string>
</dict>
</plist>
EOF
cp "$TMP_ROOT/device/$FRAMEWORK_NAME.framework/Info.plist" \
   "$TMP_ROOT/sim/$FRAMEWORK_NAME.framework/Info.plist"

install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
  "$TMP_ROOT/device/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" 2>/dev/null || true
install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
  "$TMP_ROOT/sim/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" 2>/dev/null || true

rm -rf "$OUT_XCFRAMEWORK"

xcodebuild -create-xcframework \
  -framework "$TMP_ROOT/device/$FRAMEWORK_NAME.framework" \
  -framework "$TMP_ROOT/sim/$FRAMEWORK_NAME.framework" \
  -output "$OUT_XCFRAMEWORK"

rm -rf "$TMP_ROOT"

echo "✅ Repackaged: $OUT_XCFRAMEWORK"

