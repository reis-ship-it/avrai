#!/bin/bash
# Comprehensive verification and fix script for Signal Protocol library paths
# Phase 14: Signal Protocol Implementation - Option 1
#
# This script:
# 1. Verifies current library path state
# 2. Fixes all hardcoded paths to use @loader_path
# 3. Fixes inter-library dependencies
# 4. Verifies all fixes were applied correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$PROJECT_ROOT/native/signal_ffi/macos"

echo "🔍 Signal Protocol Library Path Verification & Fix"
echo "==================================================="
echo ""

# Check if install_name_tool is available
if ! command -v install_name_tool &> /dev/null; then
    echo "❌ install_name_tool not found"
    echo "   This tool is required to fix library paths"
    echo "   It should be available with Xcode Command Line Tools"
    exit 1
fi

# Function to check and fix a library
fix_library() {
    local lib_name=$1
    local lib_path="$LIB_DIR/$lib_name"
    
    if [ ! -f "$lib_path" ]; then
        echo "⚠️  $lib_name not found at $lib_path"
        return 1
    fi
    
    echo "📚 Checking $lib_name..."
    
    # Get current install_name
    local current_id=$(otool -D "$lib_path" | tail -n +2 | head -1)
    local expected_id="@loader_path/$lib_name"
    
    # Check if install_name needs fixing
    if [ "$current_id" != "$expected_id" ]; then
        echo "  🔧 Fixing install_name: $current_id -> $expected_id"
        install_name_tool -id "$expected_id" "$lib_path" || {
            echo "  ❌ Failed to set install_name"
            return 1
        }
    else
        echo "  ✅ install_name already correct: $expected_id"
    fi
    
    # Check and fix all dependencies
    local deps_fixed=0
    while IFS= read -r line; do
        # Skip empty lines and header
        if [[ -z "$line" ]] || [[ "$line" == *":" ]]; then
            continue
        fi
        
        # Extract dependency path (first field)
        local dep_path=$(echo "$line" | awk '{print $1}')
        
        # Skip if it's the install_name itself or system libraries
        if [[ "$dep_path" == "$current_id" ]] || \
           [[ "$dep_path" == "$expected_id" ]] || \
           [[ "$dep_path" == @loader_path* ]] || \
           [[ "$dep_path" == @rpath* ]] || \
           [[ "$dep_path" == /System/* ]] || \
           [[ "$dep_path" == /usr/lib/* ]]; then
            continue
        fi
        
        # Check if it's a hardcoded absolute path that needs fixing
        if [[ "$dep_path" == /* ]]; then
            # Determine what it should be
            local dep_name=$(basename "$dep_path")
            local new_path="@loader_path/$dep_name"
            
            echo "  🔧 Fixing dependency: $dep_path -> $new_path"
            install_name_tool -change "$dep_path" "$new_path" "$lib_path" || {
                echo "  ⚠️  Could not fix dependency: $dep_path"
            }
            deps_fixed=$((deps_fixed + 1))
        fi
    done < <(otool -L "$lib_path")
    
    if [ $deps_fixed -gt 0 ]; then
        echo "  ✅ Fixed $deps_fixed dependencies"
    else
        echo "  ✅ No dependencies need fixing"
    fi
    
    echo ""
    return 0
}

# Fix each library
echo "🔧 Fixing library paths..."
echo ""

fix_library "libsignal_ffi.dylib"
fix_library "libsignal_ffi_wrapper.dylib"
fix_library "libsignal_callback_bridge.dylib"

echo "✅ Library path fixes complete!"
echo ""

# Verify all fixes
echo "🔍 Verifying fixes..."
echo ""

verify_library() {
    local lib_name=$1
    local lib_path="$LIB_DIR/$lib_name"
    
    if [ ! -f "$lib_path" ]; then
        return 1
    fi
    
    echo "📋 $lib_name dependencies:"
    otool -L "$lib_path" | grep -E "(libsignal|@loader_path|@rpath)" | sed 's/^/  /' || echo "  (none found)"
    
    # Check for any remaining hardcoded paths
    local hardcoded=$(otool -L "$lib_path" | grep -E "^[[:space:]]+/.*/.*signal" | grep -v "@loader_path" | grep -v "@rpath" || true)
    if [ -n "$hardcoded" ]; then
        echo "  ⚠️  WARNING: Found hardcoded paths:"
        echo "$hardcoded" | sed 's/^/    /'
    else
        echo "  ✅ No hardcoded paths found"
    fi
    echo ""
}

verify_library "libsignal_ffi.dylib"
verify_library "libsignal_ffi_wrapper.dylib"
verify_library "libsignal_callback_bridge.dylib"

echo "✅ Verification complete!"
echo ""
echo "Next steps:"
echo "1. Test: flutter test test/core/crypto/signal/"
echo "2. If issues persist, check library loading order"
echo ""
