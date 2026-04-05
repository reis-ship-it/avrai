#!/usr/bin/env python3
"""
Runtime Error Fix Script

Automatically fixes common runtime errors in test files:
- Adds platform channel helpers (setupTestStorage, cleanupTestStorage)
- Adds missing mock stubs
- Wraps tests that need platform channel handling
- Adds missing imports

Usage:
    python scripts/fix_runtime_errors.py [--dry-run] [--path PATH]

Options:
    --dry-run          Show what would be fixed without making changes
    --path PATH        Specific path to process (default: test/unit/services/)
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import List, Tuple, Dict, Optional
from dataclasses import dataclass, field

@dataclass
class RuntimeFix:
    """Represents a runtime fix to be applied"""
    file_path: str
    line_number: int
    old_code: str
    new_code: str
    fix_type: str
    description: str


class RuntimeErrorFixer:
    """Fixes runtime errors in test files"""
    
    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run
        self.fixes: List[RuntimeFix] = []
        self.stats = {
            'files_processed': 0,
            'files_modified': 0,
            'fixes_applied': 0,
        }
    
    def add_platform_channel_setup(self, file_path: Path) -> List[RuntimeFix]:
        """Add platform channel setup/cleanup to test files"""
        fixes = []
        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')
            modified = False
            new_lines = lines.copy()
            
            # Check if already has platform channel setup
            has_setup = 'setupTestStorage' in content or 'platform_channel_helper' in content
            has_import = 'platform_channel_helper' in content or 'test/helpers/platform_channel_helper.dart' in content
            
            # Find main() function
            main_idx = None
            for i, line in enumerate(lines):
                if line.strip() == 'void main() {' or line.strip().startswith('void main()'):
                    main_idx = i
                    break
            
            if main_idx is None:
                return fixes
            
            # Find first group() or test() after main
            setup_all_idx = None
            for i in range(main_idx, min(main_idx + 20, len(lines))):
                if 'setUpAll' in lines[i] or 'setUp(()' in lines[i]:
                    setup_all_idx = i
                    break
            
            # Add import if needed
            if not has_import:
                # Find last import
                last_import_idx = None
                for i in range(len(lines)):
                    if lines[i].strip().startswith('import '):
                        last_import_idx = i
                
                if last_import_idx is not None:
                    new_import = "import '../../helpers/platform_channel_helper.dart';"
                    # Check if it's a relative import path
                    if 'test/unit/services/' in str(file_path):
                        new_import = "import '../../helpers/platform_channel_helper.dart';"
                    elif 'test/unit/' in str(file_path):
                        new_import = "import '../helpers/platform_channel_helper.dart';"
                    
                    if new_import not in content:
                        fixes.append(RuntimeFix(
                            file_path=str(file_path),
                            line_number=last_import_idx + 1,
                            old_code='',
                            new_code=new_import,
                            fix_type='add_import',
                            description="Added platform_channel_helper import"
                        ))
                        new_lines.insert(last_import_idx + 1, new_import)
                        modified = True
            
            # Add setUpAll if needed
            if not has_setup and setup_all_idx is None:
                # Find where to insert (after first group or test)
                insert_idx = main_idx + 2
                for i in range(main_idx, min(main_idx + 10, len(lines))):
                    if 'group(' in lines[i] or 'test(' in lines[i]:
                        insert_idx = i + 1
                        break
                
                indent = '  '  # Standard Dart indent
                setup_code = [
                    '',
                    f'{indent}setUpAll(() async {{',
                    f'{indent}  await setupTestStorage();',
                    f'{indent}}});',
                    '',
                ]
                
                fixes.append(RuntimeFix(
                    file_path=str(file_path),
                    line_number=insert_idx,
                    old_code='',
                    new_code='\n'.join(setup_code),
                    fix_type='add_setup',
                    description="Added platform channel setup in setUpAll"
                ))
                
                for i, line in enumerate(setup_code):
                    new_lines.insert(insert_idx + i, line)
                modified = True
            
            # Add tearDownAll if needed
            if not has_setup and 'tearDownAll' not in content:
                # Find end of main function or last test
                tear_down_idx = None
                for i in range(len(lines) - 1, max(0, len(lines) - 50), -1):
                    if lines[i].strip() == '}' and i > main_idx:
                        # Check if this is the closing brace of main
                        brace_count = 0
                        for j in range(i, len(lines)):
                            if '{' in lines[j]:
                                brace_count += lines[j].count('{')
                            if '}' in lines[j]:
                                brace_count -= lines[j].count('}')
                            if brace_count == 0 and j > i:
                                tear_down_idx = j - 1
                                break
                        if tear_down_idx:
                            break
                
                if tear_down_idx is None:
                    # Find last test or group closing
                    for i in range(len(lines) - 1, max(0, len(lines) - 30), -1):
                        if lines[i].strip() == '  });' or lines[i].strip() == '});':
                            tear_down_idx = i + 1
                            break
                
                if tear_down_idx:
                    indent = '  '
                    tear_down_code = [
                        '',
                        f'{indent}tearDownAll(() async {{',
                        f'{indent}  await cleanupTestStorage();',
                        f'{indent}}});',
                    ]
                    
                    fixes.append(RuntimeFix(
                        file_path=str(file_path),
                        line_number=tear_down_idx,
                        old_code='',
                        new_code='\n'.join(tear_down_code),
                        fix_type='add_teardown',
                        description="Added platform channel cleanup in tearDownAll"
                    ))
                    
                    for i, line in enumerate(tear_down_code):
                        new_lines.insert(tear_down_idx + i, line)
                    modified = True
            
            if modified and not self.dry_run:
                file_path.write_text('\n'.join(new_lines), encoding='utf-8')
                self.stats['files_modified'] += 1
            
            if modified:
                self.stats['fixes_applied'] += len(fixes)
            
        except Exception as e:
            print(f"Error fixing {file_path}: {e}")
        
        return fixes
    
    def detect_missing_stubs(self, file_path: Path) -> List[RuntimeFix]:
        """Detect and fix missing mock stubs"""
        fixes = []
        try:
            content = file_path.read_text(encoding='utf-8')
            
            # Look for MissingStubError patterns in comments or error messages
            # This would need test execution output to detect
            
            # For now, we'll focus on platform channel setup
            pass
            
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
        
        return fixes
    
    def process_file(self, file_path: Path) -> List[RuntimeFix]:
        """Process a single test file and apply all fixes"""
        if file_path.suffix != '.dart' or '_test.dart' not in file_path.name:
            return []
        
        all_fixes = []
        
        # Apply all fixers
        all_fixes.extend(self.add_platform_channel_setup(file_path))
        all_fixes.extend(self.detect_missing_stubs(file_path))
        
        self.stats['files_processed'] += 1
        
        return all_fixes
    
    def process_directory(self, root_path: Path):
        """Process all test files in directory"""
        print(f"Processing directory: {root_path}")
        print(f"Mode: {'DRY RUN (no changes will be made)' if self.dry_run else 'LIVE (changes will be made)'}")
        print("-" * 80)
        
        test_files = list(root_path.rglob('*_test.dart'))
        total_files = len(test_files)
        
        print(f"Found {total_files} test files to process\n")
        
        for i, file_path in enumerate(test_files, 1):
            if i % 10 == 0:
                print(f"Progress: {i}/{total_files} files processed...")
            
            fixes = self.process_file(file_path)
            self.fixes.extend(fixes)
        
        print(f"\nProcessed {total_files} files")
    
    def print_summary(self):
        """Print summary of fixes"""
        print("\n" + "=" * 80)
        print("SUMMARY")
        print("=" * 80)
        print(f"Files processed:    {self.stats['files_processed']}")
        print(f"Files modified:     {self.stats['files_modified']}")
        print(f"Fixes applied:      {self.stats['fixes_applied']}")
        
        if self.fixes:
            print(f"\nFixes by type:")
            fix_types = {}
            for fix in self.fixes:
                fix_types[fix.fix_type] = fix_types.get(fix.fix_type, 0) + 1
            
            for fix_type, count in sorted(fix_types.items()):
                print(f"  - {fix_type}: {count}")
        
        if self.dry_run:
            print("\n⚠️  DRY RUN MODE - No files were actually modified")
            print("Run without --dry-run to apply changes")


def main():
    parser = argparse.ArgumentParser(
        description='Fix common runtime errors in test files',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be fixed without making changes'
    )
    parser.add_argument(
        '--path',
        type=str,
        default='test/unit/services/',
        help='Path to process (default: test/unit/services/)'
    )
    
    args = parser.parse_args()
    
    # Validate path
    root_path = Path(args.path)
    if not root_path.exists():
        print(f"Error: Path does not exist: {root_path}")
        sys.exit(1)
    
    # Create fixer and process
    fixer = RuntimeErrorFixer(dry_run=args.dry_run)
    fixer.process_directory(root_path)
    fixer.print_summary()


if __name__ == '__main__':
    main()

