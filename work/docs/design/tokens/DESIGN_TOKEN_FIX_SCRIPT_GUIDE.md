# Design Token Fix Script - User Guide

**Created:** December 7, 2025  
**Purpose:** Automate design token compliance fixes across 201 files

## Quick Start

### Step 1: Dry Run (Recommended First Step)

```bash
./scripts/fix_design_tokens.sh --dry-run
```

This will show you exactly what would be changed without making any modifications.

### Step 2: Apply Changes with Backups

```bash
./scripts/fix_design_tokens.sh --backup
```

This creates `.bak` backup files before modifying, so you can easily revert if needed.

### Step 3: Verify Changes

```bash
# Check for remaining violations
grep -r "Colors\.\(white\|black\)" lib/ --include="*.dart" | grep -v "AppColors" | grep -v "//" | grep -v "import"
```

## What the Script Does

### ✅ Automatic Replacements

- `Colors.white` → `AppColors.white`
- `Colors.black` → `AppColors.black`
- `Colors.transparent` → **Preserved** (acceptable exception)

### ✅ Import Management

Automatically adds missing imports:
```dart
import 'package:spots/core/theme/colors.dart';
```

Imports are smartly placed:
- After Flutter imports (if present)
- In the import section
- Before other package imports

### ✅ Safety Features

- **Skip test files** - Only processes `lib/` directory
- **Skip build artifacts** - Ignores `.dart_tool/`, `build/`, etc.
- **Skip PdfColors** - Acceptable exception (different library)
- **Preserve comments** - Won't modify Colors.* in comments
- **Backup support** - Optional `.bak` file creation

## Usage Examples

### Process All Files

```bash
# Dry run first
./scripts/fix_design_tokens.sh --dry-run

# Apply with backups
./scripts/fix_design_tokens.sh --backup

# Apply without backups (after verification)
./scripts/fix_design_tokens.sh
```

### Process Specific Directory

```bash
# Fix only presentation pages
./scripts/fix_design_tokens.sh --path lib/presentation/pages --dry-run

# Fix only widgets
./scripts/fix_design_tokens.sh --path lib/presentation/widgets --backup
```

### Python Script Direct Usage

```bash
# Direct Python execution
python3 scripts/fix_design_tokens.py --dry-run
python3 scripts/fix_design_tokens.py --backup --path lib/presentation
```

## Expected Output

### Dry Run Output

```
Processing directory: lib/
Mode: DRY RUN (no changes will be made)
--------------------------------------------------------------------------------
Found 1250 Dart files to process

Progress: 50/1250 files processed...
Progress: 100/1250 files processed...
...

================================================================================
SUMMARY
================================================================================
Files processed:    1250
Files modified:     201
Files skipped:      1049
Replacements made:  387
Imports added:      45

Modified files (201):
  - lib/presentation/pages/auth/login_page.dart
    Line 42: color: Colors.white → color: AppColors.white
    Added import: import 'package:spots/core/theme/colors.dart';
  ...

⚠️  DRY RUN MODE - No files were actually modified
Run without --dry-run to apply changes
```

## File Processing Details

### What Gets Modified

The script processes all `.dart` files in the specified path and:

1. **Searches for color usage patterns:**
   - `Colors.white`
   - `Colors.black`
   - `Colors.transparent` (detected but preserved)

2. **Replaces matches** with AppColors equivalents

3. **Adds imports** if missing

4. **Creates backups** (if `--backup` flag used)

### What Gets Skipped

- ✅ Test files (`test/` directories)
- ✅ Build artifacts (`.dart_tool/`, `build/`, etc.)
- ✅ Files with `PdfColors.*` (different library)
- ✅ Comments (won't modify `Colors.*` in comments)
- ✅ Import statements (won't replace in imports)

## Verification Steps

After running the script:

### 1. Check Remaining Violations

```bash
grep -r "Colors\.\(white\|black\)" lib/ --include="*.dart" | \
  grep -v "AppColors" | \
  grep -v "//" | \
  grep -v "import" | \
  wc -l
```

Should return `0` or minimal matches (only in acceptable exceptions).

### 2. Verify Imports

```bash
# Find files using AppColors without import
grep -r "AppColors\." lib/ --include="*.dart" -l | \
  xargs grep -L "package:spots/core/theme/colors.dart"
```

Should return no files.

### 3. Test Compilation

```bash
flutter analyze lib/
```

Should show no errors related to missing imports.

## Troubleshooting

### Script Not Working

**Issue:** "python3 not found"

**Solution:**
```bash
# Check Python installation
which python3
python3 --version

# Or use Python directly
python scripts/fix_design_tokens.py --dry-run
```

### No Files Modified

**Issue:** Script reports 0 files modified

**Possible reasons:**
1. Files already use AppColors (already compliant)
2. Files are in skip patterns (test files, etc.)
3. Path is incorrect

**Solution:**
```bash
# Check what files need fixing
grep -r "Colors\.\(white\|black\)" lib/ --include="*.dart" | head -10

# Run with verbose output to see skip reasons
python3 scripts/fix_design_tokens.py --dry-run --path lib/presentation
```

### Need to Revert Changes

If you used `--backup`:

```bash
# Restore all backups
find lib/ -name "*.dart.bak" -exec sh -c 'mv "$1" "${1%.bak}"' _ {} \;
```

### Import Placement Issues

If imports are placed incorrectly:

1. The script places imports after Flutter imports
2. If issues occur, manually adjust import order
3. Standard Dart import order:
   - Dart SDK imports
   - Flutter imports
   - Package imports
   - Local imports

## Integration with Project Workflow

### Before Committing

1. Run dry run to see changes
2. Review the summary
3. Apply changes with backups
4. Verify with `flutter analyze`
5. Test affected features
6. Commit changes

### CI/CD Integration

The script can be integrated into CI/CD:

```yaml
# Example GitHub Actions step
- name: Verify Design Token Compliance
  run: |
    ./scripts/fix_design_tokens.sh --dry-run
    # Fail if violations found
    if grep -r "Colors\.\(white\|black\)" lib/ --include="*.dart" | \
       grep -v "AppColors" | grep -v "//" | grep -v "import"; then
      echo "Design token violations found!"
      exit 1
    fi
```

## Project Rules Reference

Per SPOTS project rules:
- ✅ **100% adherence required** - All `Colors.*` must be `AppColors.*` or `AppTheme.*`
- ✅ **Colors.transparent is acceptable** - Flutter constant, can be used directly
- ✅ **PdfColors is acceptable** - Different library, not Flutter Colors
- ✅ **Comments are preserved** - Won't modify `Colors.*` in comments

## Script Files

- **Main Script:** `scripts/fix_design_tokens.py`
- **Bash Wrapper:** `scripts/fix_design_tokens.sh`
- **Documentation:** `scripts/README_DESIGN_TOKEN_FIX.md`

## Status

**Current:** 201 files need design token compliance fixes  
**Target:** 100% compliance (0 violations, excluding acceptable exceptions)  
**Script Status:** ✅ Ready for use

## Support

For issues or questions:
1. Check this guide first
2. Review `scripts/README_DESIGN_TOKEN_FIX.md`
3. Run with `--dry-run` to diagnose
4. Check project documentation: `docs/agents/reports/agent_2/phase_7/design_token_compliance_fix_summary.md`

