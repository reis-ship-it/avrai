#!/bin/bash

# fix_package_references.sh
# Fixes old package references (spots_* -> avrai_*) and cleans up empty directories
#
# This script:
# 1. Updates Rust bridge configuration (frb.yaml)
# 2. Updates compatibility export comments
# 3. Removes unused avrai_ml dependency
# 4. Deletes empty old package directories
# 5. Updates documentation comments

set -e  # Exit on error

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔧 Fixing package references and cleaning up old directories..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# 1. Update Rust bridge configuration
echo "1. Updating Rust bridge configuration..."
FRB_YAML="$PROJECT_ROOT/native/knot_math/frb.yaml"
if [ -f "$FRB_YAML" ]; then
    # Replace spots_knot with avrai_knot in frb.yaml
    sed -i '' 's|packages/spots_knot|packages/avrai_knot|g' "$FRB_YAML"
    print_status "Updated frb.yaml: spots_knot -> avrai_knot"
else
    print_warning "frb.yaml not found at $FRB_YAML"
fi

# 2. Update compatibility export comments
echo ""
echo "2. Updating compatibility export comments..."

# Update entanglement_coefficient_optimizer.dart
FILE="$PROJECT_ROOT/lib/core/services/quantum/entanglement_coefficient_optimizer.dart"
if [ -f "$FILE" ]; then
    sed -i '' 's/migrated to `spots_quantum`/migrated to `avrai_quantum`/g' "$FILE"
    print_status "Updated entanglement_coefficient_optimizer.dart"
fi

# Update quantum_entanglement_service.dart
FILE="$PROJECT_ROOT/lib/core/services/quantum/quantum_entanglement_service.dart"
if [ -f "$FILE" ]; then
    sed -i '' 's/migrated to `spots_quantum`/migrated to `avrai_quantum`/g' "$FILE"
    print_status "Updated quantum_entanglement_service.dart"
fi

# Update location_timing_quantum_state_service.dart
FILE="$PROJECT_ROOT/lib/core/services/quantum/location_timing_quantum_state_service.dart"
if [ -f "$FILE" ]; then
    sed -i '' 's/migrated into the `spots_quantum` package/migrated into the `avrai_quantum` package/g' "$FILE"
    print_status "Updated location_timing_quantum_state_service.dart"
fi

# 3. Remove unused avrai_ml dependency from avrai_quantum/pubspec.yaml
echo ""
echo "3. Removing unused avrai_ml dependency..."
QUANTUM_PUBSPEC="$PROJECT_ROOT/packages/avrai_quantum/pubspec.yaml"
if [ -f "$QUANTUM_PUBSPEC" ]; then
    # Remove the avrai_ml dependency block (lines with avrai_ml: and path: ../avrai_ml)
    # This is a bit tricky with sed, so we'll use a more robust approach
    if grep -q "avrai_ml:" "$QUANTUM_PUBSPEC"; then
        # Use awk to remove the avrai_ml dependency block
        awk '
            /^  avrai_ml:/ { skip=1; next }
            skip && /^    path: \.\.\/avrai_ml/ { skip=0; next }
            skip && /^[[:space:]]*$/ { skip=0; print; next }
            !skip { print }
        ' "$QUANTUM_PUBSPEC" > "$QUANTUM_PUBSPEC.tmp" && mv "$QUANTUM_PUBSPEC.tmp" "$QUANTUM_PUBSPEC"
        print_status "Removed avrai_ml dependency from avrai_quantum/pubspec.yaml"
    else
        print_warning "avrai_ml dependency not found in avrai_quantum/pubspec.yaml (may already be removed)"
    fi
else
    print_warning "avrai_quantum/pubspec.yaml not found"
fi

# 4. Update personality_profile.dart comment
echo ""
echo "4. Updating documentation comments..."
PERSONALITY_FILE="$PROJECT_ROOT/lib/core/models/personality_profile.dart"
if [ -f "$PERSONALITY_FILE" ]; then
    sed -i '' 's/sibling packages like `spots_knot`/sibling packages like `avrai_knot`/g' "$PERSONALITY_FILE"
    print_status "Updated personality_profile.dart comment"
fi

# 5. Delete empty old package directories
echo ""
echo "5. Cleaning up empty old package directories..."

OLD_KNOT_DIR="$PROJECT_ROOT/packages/packages/spots_knot"
OLD_QUANTUM_DIR="$PROJECT_ROOT/packages/packages/spots_quantum"
OLD_PACKAGES_DIR="$PROJECT_ROOT/packages/packages"

# Check if directories exist and are empty
if [ -d "$OLD_KNOT_DIR" ]; then
    if [ -z "$(find "$OLD_KNOT_DIR" -type f 2>/dev/null)" ]; then
        rm -rf "$OLD_KNOT_DIR"
        print_status "Deleted empty directory: packages/packages/spots_knot"
    else
        print_warning "Directory not empty, skipping: packages/packages/spots_knot"
    fi
fi

if [ -d "$OLD_QUANTUM_DIR" ]; then
    if [ -z "$(find "$OLD_QUANTUM_DIR" -type f 2>/dev/null)" ]; then
        rm -rf "$OLD_QUANTUM_DIR"
        print_status "Deleted empty directory: packages/packages/spots_quantum"
    else
        print_warning "Directory not empty, skipping: packages/packages/spots_quantum"
    fi
fi

# Remove packages/packages directory if it's now empty
if [ -d "$OLD_PACKAGES_DIR" ]; then
    if [ -z "$(find "$OLD_PACKAGES_DIR" -mindepth 1 2>/dev/null)" ]; then
        rmdir "$OLD_PACKAGES_DIR" 2>/dev/null && print_status "Deleted empty directory: packages/packages" || true
    fi
fi

# 6. Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Package reference fixes complete!"
echo ""
echo "Changes made:"
echo "  • Updated Rust bridge configuration (frb.yaml)"
echo "  • Updated compatibility export comments (spots_quantum -> avrai_quantum)"
echo "  • Removed unused avrai_ml dependency from avrai_quantum"
echo "  • Updated documentation comments (spots_knot -> avrai_knot)"
echo "  • Deleted empty old package directories"
echo ""
echo "Next steps:"
echo "  1. Review the changes with: git diff"
echo "  2. Test the Rust bridge generation if applicable"
echo "  3. Run: flutter pub get (to update dependencies)"
echo "  4. Verify imports are correct: grep -r 'spots_' lib/ packages/ test/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
