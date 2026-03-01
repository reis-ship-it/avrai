#!/bin/bash
# Build Rust library for Android platforms
# Part of Patent #31: Topological Knot Theory for Personality Representation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUST_DIR="$PROJECT_ROOT/native/knot_math"
ANDROID_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"

cd "$RUST_DIR"

echo "🔨 Building Rust library for Android..."

# Check if Rust targets are installed
check_target() {
    local target=$1
    if ! rustup target list --installed | grep -q "^$target$"; then
        echo "⚠️  Target $target not installed. Installing..."
        rustup target add "$target"
    fi
}

# Install targets if needed
check_target aarch64-linux-android
check_target armv7-linux-androideabi
check_target x86_64-linux-android
check_target i686-linux-android

# Build for all Android architectures
echo "📦 Building for aarch64-linux-android (ARM64)..."
cargo build --target aarch64-linux-android --release

echo "📦 Building for armv7-linux-androideabi (ARMv7)..."
cargo build --target armv7-linux-androideabi --release

echo "📦 Building for x86_64-linux-android (x86_64)..."
cargo build --target x86_64-linux-android --release

echo "📦 Building for i686-linux-android (x86)..."
cargo build --target i686-linux-android --release

# Create jniLibs directories
echo "📁 Creating jniLibs directories..."
mkdir -p "$ANDROID_DIR/arm64-v8a"
mkdir -p "$ANDROID_DIR/armeabi-v7a"
mkdir -p "$ANDROID_DIR/x86_64"
mkdir -p "$ANDROID_DIR/x86"

# Copy libraries to Android project
echo "📋 Copying libraries to Android project..."

cp target/aarch64-linux-android/release/libknot_math.so \
   "$ANDROID_DIR/arm64-v8a/" || echo "⚠️  Failed to copy arm64-v8a library"

cp target/armv7-linux-androideabi/release/libknot_math.so \
   "$ANDROID_DIR/armeabi-v7a/" || echo "⚠️  Failed to copy armeabi-v7a library"

cp target/x86_64-linux-android/release/libknot_math.so \
   "$ANDROID_DIR/x86_64/" || echo "⚠️  Failed to copy x86_64 library"

cp target/i686-linux-android/release/libknot_math.so \
   "$ANDROID_DIR/x86/" || echo "⚠️  Failed to copy x86 library"

echo "✅ Android libraries built and copied successfully"
echo "📂 Libraries are in: $ANDROID_DIR"
