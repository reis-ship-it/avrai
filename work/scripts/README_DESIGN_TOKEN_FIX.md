# Design Token Compliance Fix Script

Automated script to fix design token compliance across the SPOTS codebase by replacing `Colors.*` usage with `AppColors.*` equivalents.

## Overview

This script automatically:
- ✅ Replaces `Colors.white` → `AppColors.white`
- ✅ Replaces `Colors.black` → `AppColors.black`
- ✅ Preserves `Colors.transparent` (acceptable exception per project rules)
- ✅ Adds missing `import 'package:spots/core/theme/colors.dart';` statements
- ✅ Creates backups before modifying files (optional)
- ✅ Provides detailed reporting of all changes

## Usage

### Quick Start

```bash
# Dry run - see what would change without making changes
./scripts/fix_design_tokens.sh --dry-run

# Apply changes with backups
./scripts/fix_design_tokens.sh --backup

# Process specific directory
./scripts/fix_design_tokens.sh --path lib/presentation/pages
```

### Python Script Direct Usage

```bash
# Dry run
python3 scripts/fix_design_tokens.py --dry-run

# Apply changes
python3 scripts/fix_design_tokens.py --backup

# Process specific path
python3 scripts/fix_design_tokens.py --path lib/presentation/widgets
```

### Options

- `--dry-run`: Show what would be changed without making actual changes
- `--backup`: Create `.bak` backup files before modifying (recommended for first run)
- `--path PATH`: Process specific directory (default: `lib/`)
- `--help`: Show help message

## What Gets Fixed

### Replacements

| Original | Replacement | Notes |
|----------|-------------|-------|
| `Colors.white` | `AppColors.white` | Direct mapping |
| `Colors.black` | `AppColors.black` | Direct mapping |
| `Colors.transparent` | `Colors.transparent` | ✅ Preserved (acceptable exception) |

### Import Management

The script automatically adds the required import:
```dart
import 'package:spots/core/theme/colors.dart';
```

Imports are inserted:
- After Flutter imports (if present)
- In the import section (if present)
- At the top of the file (if no imports exist)

## What Gets Skipped

The script automatically skips:
- ✅ Test files (in `test/` directories)
- ✅ Build artifacts (`.dart_tool/`, `build/`, etc.)
- ✅ Files using `PdfColors.*` (different library, acceptable)
- ✅ Comments (won't replace `Colors.*` in comments)

## Examples

### Example 1: Dry Run on All Files

```bash
./scripts/fix_design_tokens.sh --dry-run
```

Output:
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

### Example 2: Apply Changes with Backups

```bash
./scripts/fix_design_tokens.sh --backup
```

This will:
1. Create `.bak` backup files for all modified files
2. Apply the replacements
3. Add missing imports
4. Show detailed summary

### Example 3: Process Specific Directory

```bash
./scripts/fix_design_tokens.sh --path lib/presentation/pages --dry-run
```

Process only files in `lib/presentation/pages/` and subdirectories.

## Verification

After running the script, verify the changes:

```bash
# Check for remaining Colors.white/black usage (should be minimal)
grep -r "Colors\.\(white\|black\)" lib/ --include="*.dart" | grep -v "AppColors" | grep -v "//" | grep -v "import"

# Check for missing AppColors imports (should be none)
grep -r "AppColors\." lib/ --include="*.dart" -L | xargs grep -L "package:spots/core/theme/colors.dart"
```

## Safety Features

1. **Dry Run Mode**: Always test with `--dry-run` first
2. **Backups**: Use `--backup` to create `.bak` files
3. **Skip Patterns**: Automatically skips test files and build artifacts
4. **Comment Preservation**: Won't modify `Colors.*` in comments
5. **Exception Handling**: Skips files that can't be read

## Troubleshooting

### Script doesn't find any files

- Check that you're running from the project root
- Verify the path exists: `ls -la lib/`

### Some files weren't modified

- Check the summary output - they may be in skip patterns
- Test files are intentionally skipped
- PdfColors files are intentionally skipped (different library)

### Need to revert changes

If you used `--backup`, restore from backup files:
```bash
find lib/ -name "*.dart.bak" -exec sh -c 'mv "$1" "${1%.bak}"' _ {} \;
```

## Project Rules Reference

Per SPOTS project rules:
- ✅ **100% adherence required** - All `Colors.*` must be replaced with `AppColors.*` or `AppTheme.*`
- ✅ **Colors.transparent is acceptable** - Flutter constant, can be used directly
- ✅ **PdfColors is acceptable** - Different library, not Flutter Colors

## Related Files

- `lib/core/theme/colors.dart` - AppColors definition
- `lib/core/theme/app_theme.dart` - AppTheme definition
- Documentation: `docs/agents/reports/agent_2/phase_7/design_token_compliance_fix_summary.md`

## Status

**Current Status:** 201 files need design token compliance fixes

**Target:** 100% compliance (0 violations, excluding acceptable exceptions)

**Last Updated:** December 7, 2025

