# Import Migration Script Guide

**Date:** January 2025  
**Purpose:** Guide for using the import migration script  
**Script:** `scripts/update_package_imports.py`

---

## 🎯 **OVERVIEW**

The import migration script safely updates imports from `lib/core/services/quantum` and `lib/core/services/knot` to use the new `spots_quantum` and `spots_knot` packages.

**Features:**
- ✅ Dry-run mode (show changes before applying)
- ✅ Automatic backup creation
- ✅ Incremental application (one package at a time)
- ✅ Edge case reporting
- ✅ Manual review step

---

## 🚀 **USAGE**

### **Step 1: Dry Run (Review Changes)**

```bash
# Review quantum package imports
python3 scripts/update_package_imports.py --package quantum

# Review knot package imports
python3 scripts/update_package_imports.py --package knot

# Review both packages
python3 scripts/update_package_imports.py --package both
```

**What it does:**
- Scans all Dart files
- Identifies imports that need updating
- Shows what will change
- Reports edge cases
- **Does NOT modify files**

### **Step 2: Review Output**

The script will show:
1. **Summary:** Total files and changes
2. **Detailed Changes:** First 10 files with line-by-line changes
3. **Edge Cases:** Imports that need manual review

**Review carefully:**
- ✅ Check that changes look correct
- ✅ Note any edge cases
- ✅ Verify file paths are correct

### **Step 3: Apply Changes**

```bash
# Apply quantum package imports
python3 scripts/update_package_imports.py --package quantum --apply

# Apply knot package imports
python3 scripts/update_package_imports.py --package knot --apply

# Apply both (not recommended - do one at a time)
python3 scripts/update_package_imports.py --package both --apply
```

**What it does:**
- Creates backups in `review_before_deletion/import_migration_backup/`
- Applies changes to files
- Shows progress
- Reports success/failure

**Safety:**
- Asks for confirmation before applying
- Creates backups automatically
- Can restore from backup if needed

---

## 📋 **RECOMMENDED WORKFLOW**

### **Phase 1: Quantum Package (2-3 hours)**

1. **Dry Run:**
   ```bash
   python3 scripts/update_package_imports.py --package quantum
   ```

2. **Review Output:**
   - Check summary
   - Review detailed changes
   - Note edge cases

3. **Apply Changes:**
   ```bash
   python3 scripts/update_package_imports.py --package quantum --apply
   ```

4. **Test:**
   ```bash
   cd packages/spots_quantum
   flutter pub get
   flutter analyze
   ```

5. **Update Main App:**
   - Update `pubspec.yaml` to include `spots_quantum`
   - Run `melos bootstrap`
   - Test compilation

### **Phase 2: Knot Package (2-3 hours)**

1. **Dry Run:**
   ```bash
   python3 scripts/update_package_imports.py --package knot
   ```

2. **Review Output:**
   - Check summary
   - Review detailed changes
   - Note edge cases

3. **Apply Changes:**
   ```bash
   python3 scripts/update_package_imports.py --package knot --apply
   ```

4. **Test:**
   ```bash
   cd packages/spots_knot
   flutter pub get
   flutter analyze
   ```

5. **Update Main App:**
   - Update `pubspec.yaml` to include `spots_knot`
   - Run `melos bootstrap`
   - Test compilation

### **Phase 3: Manual Edge Cases (1-2 hours)**

1. **Review Edge Cases:**
   - Check script output for edge cases
   - Manually update each one
   - Test after each update

2. **Common Edge Cases:**
   - Bridge imports (`package:spots/core/services/knot/bridge/...`)
   - Model imports (if models moved)
   - Relative imports within packages
   - Other `package:spots/core/...` imports

---

## 🔍 **WHAT THE SCRIPT DOES**

### **Automatic Updates:**

1. **Quantum Service Imports:**
   ```dart
   // Before
   import 'package:spots/core/services/quantum/quantum_entanglement_service.dart';
   
   // After
   import 'package:spots_quantum/services/quantum/quantum_entanglement_service.dart';
   ```

2. **Knot Service Imports:**
   ```dart
   // Before
   import 'package:spots/core/services/knot/personality_knot_service.dart';
   
   // After
   import 'package:spots_knot/services/knot/personality_knot_service.dart';
   ```

3. **Bridge Imports:**
   ```dart
   // Before
   import 'package:spots/core/services/knot/bridge/knot_math_bridge.dart/api.dart';
   
   // After
   import 'package:spots_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
   ```

4. **Cross-Package Imports:**
   - Quantum services importing knot services
   - Updated to use `package:spots_knot/...`

### **Edge Cases (Manual Review):**

- Other `package:spots/core/...` imports with "quantum" or "knot" in path
- Relative imports
- Model imports (if models moved)
- Test file imports (may need different handling)

---

## ⚠️ **IMPORTANT NOTES**

1. **Always Run Dry-Run First:**
   - Review changes before applying
   - Catch any issues early

2. **One Package at a Time:**
   - Do quantum first
   - Test thoroughly
   - Then do knot

3. **Backup Location:**
   - Backups in `.import_migration_backup/`
   - Can restore if needed
   - Backup info file created with timestamp

4. **Test After Each Batch:**
   - Run `flutter analyze`
   - Run `flutter test`
   - Fix any errors before continuing

5. **Edge Cases:**
   - Script reports edge cases
   - Review and update manually
   - Test after each manual update

---

## 🐛 **TROUBLESHOOTING**

### **Script Fails:**
- Check Python version (requires Python 3.6+)
- Check file permissions
- Check project root path

### **Changes Look Wrong:**
- Review dry-run output carefully
- Check edge cases
- Restore from backup if needed

### **Build Errors After Migration:**
- Check that packages are in `pubspec.yaml`
- Run `melos bootstrap`
- Check for missed imports
- Review edge cases

### **Restore from Backup:**
```bash
# Find backup directory
ls -la .import_migration_backup/

# Restore specific file
cp .import_migration_backup/path/to/file lib/path/to/file

# Or restore all
# (manual process - check backup_info file)
```

---

## 📊 **EXPECTED RESULTS**

### **Quantum Package:**
- ~10-15 files updated in package
- ~5-10 files updated in main app
- ~20-30 import changes total

### **Knot Package:**
- ~20-25 files updated in package
- ~10-15 files updated in main app
- ~40-50 import changes total

### **Edge Cases:**
- ~5-10 edge cases needing manual review
- Mostly bridge imports and model imports

---

## ✅ **SUCCESS CRITERIA**

After running script:
- ✅ All quantum imports use `package:spots_quantum/...`
- ✅ All knot imports use `package:spots_knot/...`
- ✅ Packages build successfully
- ✅ Main app builds successfully
- ✅ All tests pass
- ✅ No linter errors

---

**Last Updated:** January 2025  
**Status:** Ready to Use
