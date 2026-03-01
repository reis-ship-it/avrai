#!/bin/bash
# Build Rust library for macOS platforms
# Part of Patent #31: Topological Knot Theory for Personality Representation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUST_DIR="$PROJECT_ROOT/native/knot_math"

cd "$RUST_DIR"

echo "🔨 Building Rust library for macOS..."

# Detect architecture
ARCH=$(uname -m)

# Check if Rust targets are installed
check_target() {
    local target=$1
    if ! rustup target list --installed | grep -q "^$target$"; then
        echo "⚠️  Target $target not installed. Installing..."
        rustup target add "$target"
    fi
}

# Install targets if needed
check_target x86_64-apple-darwin
check_target aarch64-apple-darwin

if [ "$ARCH" = "arm64" ]; then
    # Apple Silicon
    echo "📦 Building for aarch64-apple-darwin (Apple Silicon)..."
    cargo build --target aarch64-apple-darwin --release
    LIB_PATH="target/aarch64-apple-darwin/release/libknot_math.dylib"
else
    # Intel
    echo "📦 Building for x86_64-apple-darwin (Intel)..."
    cargo build --target x86_64-apple-darwin --release
    LIB_PATH="target/x86_64-apple-darwin/release/libknot_math.dylib"
fi

echo "✅ macOS library built successfully"
echo "📂 Library is in: $LIB_PATH"
