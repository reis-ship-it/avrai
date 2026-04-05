#!/usr/bin/env python3
"""
StorageService Mock Setup Fix Script
Purpose: Automatically add StorageService mock setup to test files that need it
Date: December 7, 2025
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass

@dataclass
class TestFile:
    """Represents a test file that needs fixing"""
    path: Path
    has_storage_error: bool = False
    has_setup: bool = False
    has_import: bool = False
    needs_fix: bool = False

class StorageServiceFixer:
    """Fixes StorageService initialization in test files"""
    
    def __init__(self, project_dir: str = "/Users/reisgordon/SPOTS"):
        self.project_dir = Path(project_dir)
        self.test_dir = self.project_dir / "test"
        self.fixed_files: List[Path] = []
        self.skipped_files: List[Path] = []
        
        # Patterns to detect StorageService usage
        self.storage_patterns = [
            r"StorageService\.instance",
            r"StorageService not initialized",
            r"_saveBoundaryToStorage",
            r"_getStorageForBox",
            r"NeighborhoodBoundaryService",  # Uses StorageService internally
            r"saveBoundary",  # Method that uses storage
        ]
        
        # Services known to use StorageService internally
        self.services_using_storage = [
            "NeighborhoodBoundaryService",
            "ActionHistoryService",
            "UserAnonymizationService",
        ]
        
        # Required imports
        self.required_imports = [
            "import '../../helpers/platform_channel_helper.dart';",
            "import '../../mocks/mock_storage_service.dart';",
        ]
        
        # Setup code template
        self.setup_code = """  setUpAll(() async {
    await setupTestStorage();
  });"""
        
        # Alternative: For services that need storage in setUp
        self.setup_with_mock_storage = """  setUp(() {
    // Initialize mock storage for this test
    MockGetStorage.reset();
    final mockStorage = MockGetStorage.getInstance();
  });"""
        
        # Alternative setup for services that accept storage dependency
        self.setup_with_mock = """  setUp(() {
    // Initialize mock storage
    final mockStorage = MockGetStorage.getInstance();
    MockGetStorage.reset();
  });"""
    
    def find_test_files_with_storage_errors(self) -> List[TestFile]:
        """Find test files that have StorageService errors"""
        test_files = []
        
        # Find all test files
        for test_file in self.test_dir.rglob("*.dart"):
            if not test_file.name.endswith("_test.dart"):
                continue
            
            content = test_file.read_text()
            
            # Check if file uses StorageService directly
            uses_storage_direct = any(
                re.search(pattern, content, re.IGNORECASE)
                for pattern in self.storage_patterns
            )
            
            # Check if file tests services that use StorageService
            uses_storage_via_service = any(
                service in content
                for service in self.services_using_storage
            )
            
            uses_storage = uses_storage_direct or uses_storage_via_service
            
            if not uses_storage:
                continue
            
            # Check if already has setup
            has_setup = (
                "setupTestStorage" in content or
                "MockGetStorage.getInstance" in content or
                "setUpAll" in content and "setupTestStorage" in content
            )
            
            # Check if has required imports
            has_import = (
                "platform_channel_helper" in content or
                "mock_storage_service" in content
            )
            
            test_file_obj = TestFile(
                path=test_file,
                has_storage_error=True,
                has_setup=has_setup,
                has_import=has_import,
                needs_fix=uses_storage and not has_setup
            )
            
            test_files.append(test_file_obj)
        
        return test_files
    
    def analyze_file(self, file_path: Path) -> dict:
        """Analyze a test file to determine what needs to be added"""
        content = file_path.read_text()
        lines = content.split('\n')
        
        analysis = {
            'needs_import': False,
            'needs_setup': False,
            'has_main': False,
            'has_setupAll': False,
            'has_setUp': False,
            'import_line': 0,
            'main_line': 0,
            'setup_line': 0,
        }
        
        # Find main() function
        for i, line in enumerate(lines):
            if re.match(r'^\s*void\s+main\(\)', line):
                analysis['has_main'] = True
                analysis['main_line'] = i
                break
        
        # Check for existing imports
        has_platform_helper = any("platform_channel_helper" in line for line in lines)
        has_mock_storage = any("mock_storage_service" in line for line in lines)
        analysis['needs_import'] = not (has_platform_helper or has_mock_storage)
        
        # Check for existing setup
        has_setup = any("setupTestStorage" in line for line in lines)
        has_mock_setup = any("MockGetStorage.getInstance" in line for line in lines)
        analysis['needs_setup'] = not (has_setup or has_mock_setup)
        
        # Find existing setUpAll or setUp
        for i, line in enumerate(lines):
            if re.search(r'setUpAll\s*\(', line):
                analysis['has_setupAll'] = True
                analysis['setup_line'] = i
            elif re.search(r'setUp\s*\(', line) and not analysis['has_setUp']:
                analysis['has_setUp'] = True
                if analysis['setup_line'] == 0:
                    analysis['setup_line'] = i
        
        # Find last import line
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                analysis['import_line'] = i
        
        return analysis
    
    def add_imports(self, lines: List[str], import_line: int, relative_path: Path) -> List[str]:
        """Add required imports to the file"""
        # Calculate relative path from test file to helpers
        test_file_dir = relative_path.parent
        
        # Determine relative import path
        if "unit" in str(relative_path):
            import_path = "../../helpers/platform_channel_helper.dart"
        elif "integration" in str(relative_path):
            import_path = "../helpers/platform_channel_helper.dart"
        else:
            import_path = "helpers/platform_channel_helper.dart"
        
        import_statement = f"import '{import_path}';"
        
        # Check if import already exists
        if any(import_statement in line for line in lines):
            return lines
        
        # Insert after last import
        new_lines = lines[:import_line + 1]
        new_lines.append(import_statement)
        new_lines.extend(lines[import_line + 1:])
        
        return new_lines
    
    def add_setup(self, lines: List[str], main_line: int, has_setupAll: bool, has_setUp: bool) -> List[str]:
        """Add setup code to the file"""
        # Find where to insert setup (after main() opening brace)
        insert_line = main_line + 1
        
        # Skip to first group() or setUp
        for i in range(main_line + 1, min(main_line + 10, len(lines))):
            if 'group(' in lines[i] or 'setUp' in lines[i]:
                insert_line = i
                break
        
        # If setUpAll exists, add to it
        if has_setupAll:
            # Find the setUpAll block and add to it
            for i in range(insert_line, len(lines)):
                if 'setUpAll' in lines[i]:
                    # Find the opening brace
                    for j in range(i, min(i + 5, len(lines))):
                        if '{' in lines[j]:
                            # Insert setup code after opening brace
                            indent = len(lines[j]) - len(lines[j].lstrip())
                            setup_lines = [
                                ' ' * (indent + 2) + 'await setupTestStorage();',
                            ]
                            new_lines = lines[:j + 1]
                            new_lines.extend(setup_lines)
                            new_lines.extend(lines[j + 1:])
                            return new_lines
                    break
        
        # Add new setUpAll block
        indent = len(lines[insert_line]) - len(lines[insert_line].lstrip())
        setup_lines = [
            '',
            ' ' * indent + 'setUpAll(() async {',
            ' ' * (indent + 2) + 'await setupTestStorage();',
            ' ' * indent + '});',
        ]
        
        new_lines = lines[:insert_line]
        new_lines.extend(setup_lines)
        new_lines.extend(lines[insert_line:])
        
        return new_lines
    
    def fix_file(self, file_path: Path, dry_run: bool = False) -> bool:
        """Fix a single test file"""
        try:
            analysis = self.analyze_file(file_path)
            
            if not analysis['needs_setup'] and not analysis['needs_import']:
                return False  # Already fixed
            
            content = file_path.read_text()
            lines = content.split('\n')
            
            # Add imports if needed
            if analysis['needs_import']:
                lines = self.add_imports(lines, analysis['import_line'], file_path.relative_to(self.project_dir))
            
            # Add setup if needed
            if analysis['needs_setup']:
                lines = self.add_setup(
                    lines,
                    analysis['main_line'],
                    analysis['has_setupAll'],
                    analysis['has_setUp']
                )
            
            if not dry_run:
                # Create backup
                backup_path = file_path.with_suffix('.dart.bak')
                file_path.rename(backup_path)
                
                # Write fixed content
                file_path.write_text('\n'.join(lines))
                
                # Remove backup if successful
                backup_path.unlink()
            
            return True
            
        except Exception as e:
            print(f"  ❌ Error fixing {file_path}: {e}")
            return False
    
    def run(self, dry_run: bool = False, specific_files: Optional[List[str]] = None) -> dict:
        """Run the fixer on all test files"""
        print("=" * 60)
        print("StorageService Mock Setup Fixer")
        print("=" * 60)
        print()
        
        if dry_run:
            print("🔍 DRY RUN MODE - No files will be modified")
            print()
        
        # Find files that need fixing
        print("Finding test files with StorageService usage...")
        test_files = self.find_test_files_with_storage_errors()
        
        if specific_files:
            # Filter to specific files
            specific_paths = [Path(f) for f in specific_files]
            test_files = [tf for tf in test_files if tf.path in specific_paths]
        
        files_needing_fix = [tf for tf in test_files if tf.needs_fix]
        
        print(f"Found {len(test_files)} test files using StorageService")
        print(f"  - {len(files_needing_fix)} need fixes")
        print(f"  - {len(test_files) - len(files_needing_fix)} already have setup")
        print()
        
        if not files_needing_fix:
            print("✅ All files already have StorageService setup!")
            return {
                'total': len(test_files),
                'fixed': 0,
                'skipped': len(test_files),
                'errors': 0
            }
        
        # Show files that will be fixed
        print("Files that will be fixed:")
        for tf in files_needing_fix[:10]:  # Show first 10
            print(f"  - {tf.path.relative_to(self.project_dir)}")
        if len(files_needing_fix) > 10:
            print(f"  ... and {len(files_needing_fix) - 10} more")
        print()
        
        if not dry_run:
            # Auto-confirm in non-interactive mode (when stdin is not a TTY)
            import sys
            if sys.stdin.isatty():
                response = input("Continue with fixes? (y/n): ")
                if response.lower() != 'y':
                    print("Cancelled.")
                    return {
                        'total': len(test_files),
                        'fixed': 0,
                        'skipped': len(test_files),
                        'errors': 0
                    }
            else:
                print("Auto-confirming fixes (non-interactive mode)...")
        
        # Fix files
        print("\nFixing files...")
        fixed_count = 0
        error_count = 0
        
        for tf in files_needing_fix:
            print(f"  Fixing: {tf.path.relative_to(self.project_dir)}")
            if self.fix_file(tf.path, dry_run=dry_run):
                fixed_count += 1
                self.fixed_files.append(tf.path)
                print(f"    ✅ Fixed")
            else:
                error_count += 1
                self.skipped_files.append(tf.path)
                print(f"    ⚠️  Skipped (already fixed or error)")
        
        print()
        print("=" * 60)
        print("Summary")
        print("=" * 60)
        print(f"Total files analyzed: {len(test_files)}")
        print(f"Files fixed: {fixed_count}")
        print(f"Files skipped: {len(test_files) - len(files_needing_fix)}")
        print(f"Errors: {error_count}")
        
        if dry_run:
            print("\n🔍 This was a dry run. Use without --dry-run to apply fixes.")
        
        return {
            'total': len(test_files),
            'fixed': fixed_count,
            'skipped': len(test_files) - len(files_needing_fix),
            'errors': error_count
        }

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Fix StorageService mock setup in test files"
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be fixed without making changes'
    )
    parser.add_argument(
        '--files',
        nargs='+',
        help='Specific test files to fix (paths relative to project root)'
    )
    parser.add_argument(
        '--project-dir',
        default='/Users/reisgordon/SPOTS',
        help='Project directory path'
    )
    
    args = parser.parse_args()
    
    fixer = StorageServiceFixer(project_dir=args.project_dir)
    result = fixer.run(dry_run=args.dry_run, specific_files=args.files)
    
    sys.exit(0 if result['errors'] == 0 else 1)

if __name__ == "__main__":
    main()

