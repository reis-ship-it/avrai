#!/bin/bash
# Diagnostic script for Signal Protocol native libraries
# Checks library compatibility, architecture, and dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/native/signal_ffi/macos"

echo "🔍 Signal Protocol Library Diagnostics"
echo "========================================"
echo ""

# Check system info
echo "📱 System Information:"
echo "  Architecture: $(uname -m)"
echo "  macOS Version: $(sw_vers -productVersion)"
echo "  Build: $(sw_vers -buildVersion)"
echo ""

# Check if libraries exist
echo "📚 Library Files:"
for lib in libsignal_ffi.dylib libsignal_ffi_wrapper.dylib libsignal_callback_bridge.dylib; do
    lib_path="$LIB_DIR/$lib"
    if [ -f "$lib_path" ]; then
        echo "  ✅ $lib exists"
        ls -lh "$lib_path" | awk '{print "    Size: " $5 "  Modified: " $6 " " $7 " " $8}'
    else
        echo "  ❌ $lib NOT FOUND"
    fi
done
echo ""

# Check library architecture
echo "🏗️  Library Architecture:"
for lib in libsignal_ffi.dylib libsignal_ffi_wrapper.dylib libsignal_callback_bridge.dylib; do
    lib_path="$LIB_DIR/$lib"
    if [ -f "$lib_path" ]; then
        echo "  $lib:"
        file_output=$(file "$lib_path")
        echo "    $file_output"
        
        # Check if architecture matches system
        system_arch=$(uname -m)
        if [[ "$file_output" == *"$system_arch"* ]] || [[ "$file_output" == *"universal"* ]]; then
            echo "    ✅ Architecture compatible"
        else
            echo "    ⚠️  Architecture mismatch! Expected: $system_arch"
        fi
    fi
done
echo ""

# Check library dependencies
echo "🔗 Library Dependencies:"
for lib in libsignal_ffi.dylib libsignal_ffi_wrapper.dylib libsignal_callback_bridge.dylib; do
    lib_path="$LIB_DIR/$lib"
    if [ -f "$lib_path" ]; then
        echo "  $lib:"
        otool -L "$lib_path" | head -15 | sed 's/^/    /'
        
        # Check for missing dependencies
        missing_deps=$(otool -L "$lib_path" | grep -v ":" | grep -v "^$" | awk '{print $1}' | while read dep; do
            if [[ "$dep" == /* ]]; then
                if [ ! -f "$dep" ]; then
                    echo "$dep"
                fi
            fi
        done)
        
        if [ -n "$missing_deps" ]; then
            echo "    ⚠️  Missing dependencies:"
            echo "$missing_deps" | sed 's/^/      /'
        else
            echo "    ✅ All dependencies found"
        fi
    fi
    echo ""
done

# Check for symbols
echo "🔤 Library Symbols (sample):"
for lib in libsignal_ffi.dylib libsignal_ffi_wrapper.dylib libsignal_callback_bridge.dylib; do
    lib_path="$LIB_DIR/$lib"
    if [ -f "$lib_path" ]; then
        echo "  $lib:"
        nm -gU "$lib_path" 2>/dev/null | head -10 | sed 's/^/    /' || echo "    (Could not read symbols)"
    fi
    echo ""
done

# Check for Rust symbols (indicates if it's a Rust library)
echo "🦀 Rust Library Check:"
for lib in libsignal_ffi.dylib libsignal_ffi_wrapper.dylib; do
    lib_path="$LIB_DIR/$lib"
    if [ -f "$lib_path" ]; then
        rust_symbols=$(nm -gU "$lib_path" 2>/dev/null | grep -c "__rust" || echo "0")
        if [ "$rust_symbols" -gt 0 ]; then
            echo "  ✅ $lib contains Rust symbols (likely built from Rust)"
        else
            echo "  ⚠️  $lib has no Rust symbols (may not be a Rust library)"
        fi
    fi
done
echo ""

# Summary
echo "📊 Summary:"
echo "  If all libraries show ✅, they should be compatible"
echo "  If you see ⚠️  warnings, those may indicate issues"
echo "  Architecture mismatches will cause SIGABRT crashes"
echo "  Missing dependencies will cause load failures"
echo ""
