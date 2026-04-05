#!/bin/bash
# cleanup_name_change_artifacts.sh
# Removes old migration backups and obsolete scripts from name changes
#
# This script removes:
# 1. Old import migration backups (review_before_deletion/import_migration_backup/)
# 2. Obsolete migration scripts (fix_avra_imports.sh, update_pubspecs_temp.py)
# 3. Archives RENAME_SUMMARY.md to docs/_archive/rename_history/
#
# WARNING: This script permanently deletes files. Review before running.

set -e  # Exit on error

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning up name change artifacts...${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

# 1. Remove old import migration backup
echo "1. Removing old import migration backup..."
IMPORT_BACKUP="review_before_deletion/import_migration_backup"
if [ -d "$IMPORT_BACKUP" ]; then
    FILE_COUNT=$(find "$IMPORT_BACKUP" -type f 2>/dev/null | wc -l | tr -d ' ')
    print_info "Found $FILE_COUNT files in import migration backup"
    rm -rf "$IMPORT_BACKUP"
    print_status "Deleted: $IMPORT_BACKUP"
else
    print_info "Import migration backup not found (may already be deleted)"
fi

# 2. Remove old migration scripts
echo ""
echo "2. Removing obsolete migration scripts..."

# Remove fix_avra_imports.sh (superseded by fix_package_references.sh)
if [ -f "fix_avra_imports.sh" ]; then
    rm "fix_avra_imports.sh"
    print_status "Deleted: fix_avra_imports.sh (obsolete - superseded by fix_package_references.sh)"
else
    print_info "fix_avra_imports.sh not found (may already be deleted)"
fi

# Remove update_pubspecs_temp.py (temporary migration script)
if [ -f "update_pubspecs_temp.py" ]; then
    rm "update_pubspecs_temp.py"
    print_status "Deleted: update_pubspecs_temp.py (temporary migration script)"
else
    print_info "update_pubspecs_temp.py not found (may already be deleted)"
fi

# 3. Archive RENAME_SUMMARY.md (optional - preserves history)
echo ""
echo "3. Archiving RENAME_SUMMARY.md..."
if [ -f "RENAME_SUMMARY.md" ]; then
    ARCHIVE_DIR="docs/_archive/rename_history"
    mkdir -p "$ARCHIVE_DIR"
    mv "RENAME_SUMMARY.md" "$ARCHIVE_DIR/"
    print_status "Archived RENAME_SUMMARY.md to $ARCHIVE_DIR/"
else
    print_info "RENAME_SUMMARY.md not found (may already be archived or deleted)"
fi

# 4. Check for review_before_deletion/_root/ (build artifacts - manual review needed)
echo ""
echo "4. Checking for build artifacts..."
ROOT_DIR="review_before_deletion/_root"
if [ -d "$ROOT_DIR" ]; then
    SIZE=$(du -sh "$ROOT_DIR" 2>/dev/null | cut -f1)
    print_warning "Found build artifacts directory: $ROOT_DIR ($SIZE)"
    print_warning "This contains build/, coverage/, logs/, temp/, Pods/ - review manually"
    print_info "To delete after review: rm -rf $ROOT_DIR"
else
    print_info "No build artifacts directory found"
fi

# 5. Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Cleanup complete!${NC}"
echo ""
echo "Items removed:"
echo "  • Old import migration backup (review_before_deletion/import_migration_backup/)"
echo "  • Obsolete fix_avra_imports.sh script"
echo "  • Temporary update_pubspecs_temp.py script"
echo "  • RENAME_SUMMARY.md (archived to docs/_archive/rename_history/)"
echo ""
echo "Items requiring manual review:"
echo "  • review_before_deletion/_root/ (build artifacts - review before deleting)"
echo "  • docs/plans/methodology/*MIGRATION*.md (update references or archive)"
echo ""
echo "Next steps:"
echo "  1. Review remaining items in review_before_deletion/"
echo "  2. Update or archive migration docs in docs/plans/methodology/"
echo "  3. Run: git status (to see what was deleted)"
echo "  4. Commit cleanup: git add -A && git commit -m 'chore: cleanup name change artifacts'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
