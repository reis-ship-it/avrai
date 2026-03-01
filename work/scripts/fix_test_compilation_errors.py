#!/usr/bin/env python3
"""
Test Compilation Error Fix Script

Automatically fixes common compilation errors in test files:
- Missing parameters
- Wrong parameter names
- Missing mock file generation
- Import conflicts
- Constant evaluation errors

Usage:
    python scripts/fix_test_compilation_errors.py [--dry-run] [--generate-mocks] [--path PATH]

Options:
    --dry-run          Show what would be fixed without making changes
    --generate-mocks   Generate missing .mocks.dart files
    --path PATH        Specific path to process (default: test/unit/services/)
"""

import os
import re
import sys
import argparse
import subprocess
from pathlib import Path
from typing import List, Tuple, Dict, Optional
from dataclasses import dataclass, field

# Common parameter name mappings
PARAMETER_FIXES = {
    'name': 'displayName',  # UnifiedUser uses displayName, not name
    'location': None,  # Remove if not supported
}

# Common method name fixes
METHOD_FIXES = {
    'getCancellationById': 'getCancellation',
    'createUser': 'createUserWithoutHosting',
    'createExpertiseEvent': 'createTestEvent',
}

# Files that need mock generation
MOCK_FILES_NEEDED = [
    'cancellation_service_test.dart',
    'cross_locality_connection_service_test.dart',
]


@dataclass
class Fix:
    """Represents a fix to be applied"""
    file_path: str
    line_number: int
    old_code: str
    new_code: str
    fix_type: str
    description: str


class TestCompilationFixer:
    """Fixes compilation errors in test files"""
    
    def __init__(self, dry_run: bool = False, generate_mocks: bool = False):
        self.dry_run = dry_run
        self.generate_mocks = generate_mocks
        self.fixes: List[Fix] = []
        self.stats = {
            'files_processed': 0,
            'files_modified': 0,
            'fixes_applied': 0,
        }
    
    def fix_unified_user_name_parameter(self, file_path: Path) -> List[Fix]:
        """Fix UnifiedUser constructor - 'name' -> 'displayName'"""
        fixes = []
        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')
            modified = False
            new_lines = lines.copy()
            
            for i, line in enumerate(lines):
                # Pattern: UnifiedUser(..., name: ..., ...)
                if 'UnifiedUser(' in line and 'name:' in line:
                    new_line = line.replace('name:', 'displayName:')
                    if new_line != line:
                        fixes.append(Fix(
                            file_path=str(file_path),
                            line_number=i + 1,
                            old_code=line.strip(),
                            new_code=new_line.strip(),
                            fix_type='parameter_name',
                            description="Fixed UnifiedUser parameter: name -> displayName"
                        ))
                        new_lines[i] = new_line
                        modified = True
                # Multi-line UnifiedUser constructor
                elif 'UnifiedUser(' in line:
                    # Check next few lines for 'name:'
                    for j in range(i, min(i + 10, len(lines))):
                        if 'name:' in lines[j] and not lines[j].strip().startswith('//'):
                            new_line = lines[j].replace('name:', 'displayName:')
                            if new_line != lines[j]:
                                fixes.append(Fix(
                                    file_path=str(file_path),
                                    line_number=j + 1,
                                    old_code=lines[j].strip(),
                                    new_code=new_line.strip(),
                                    fix_type='parameter_name',
                                    description="Fixed UnifiedUser parameter: name -> displayName"
                                ))
                                new_lines[j] = new_line
                                modified = True
                                break
            
            if modified and not self.dry_run:
                file_path.write_text('\n'.join(new_lines), encoding='utf-8')
                self.stats['files_modified'] += 1
            
            if modified:
                self.stats['fixes_applied'] += len(fixes)
            
        except Exception as e:
            print(f"Error fixing {file_path}: {e}")
        
        return fixes
    
    def fix_expertise_event_category(self, file_path: Path) -> List[Fix]:
        """Fix ExpertiseEvent constructor - ensure 'category' parameter exists"""
        fixes = []
        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')
            modified = False
            new_lines = lines.copy()
            
            for i, line in enumerate(lines):
                # Check if ExpertiseEvent is being constructed
                if 'ExpertiseEvent(' in line:
                    # Check if category is missing in the next 15 lines
                    has_category = False
                    event_start = i
                    event_end = min(i + 20, len(lines))
                    
                    for j in range(i, event_end):
                        if 'category:' in lines[j]:
                            has_category = True
                            break
                        # Check if we've reached the end of constructor
                        if j > i and ')' in lines[j] and lines[j].strip().count('(') < lines[j].strip().count(')'):
                            break
                    
                    # If category is missing, add it after title or description
                    if not has_category:
                        for j in range(i, event_end):
                            if 'title:' in lines[j] or 'description:' in lines[j]:
                                indent = len(lines[j]) - len(lines[j].lstrip())
                                new_line = ' ' * indent + "category: 'General',"
                                new_lines.insert(j + 1, new_line)
                                fixes.append(Fix(
                                    file_path=str(file_path),
                                    line_number=j + 1,
                                    old_code='',
                                    new_code=new_line.strip(),
                                    fix_type='missing_parameter',
                                    description="Added missing 'category' parameter to ExpertiseEvent"
                                ))
                                modified = True
                                break
            
            if modified and not self.dry_run:
                file_path.write_text('\n'.join(new_lines), encoding='utf-8')
                self.stats['files_modified'] += 1
            
            if modified:
                self.stats['fixes_applied'] += len(fixes)
            
        except Exception as e:
            print(f"Error fixing {file_path}: {e}")
        
        return fixes
    
    def fix_constant_evaluation_error(self, file_path: Path) -> List[Fix]:
        """Fix constant evaluation errors (e.g., 'A' * 1000 in const)"""
        fixes = []
        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')
            modified = False
            new_lines = lines.copy()
            
            for i, line in enumerate(lines):
                # Pattern: const content = 'A' * 1000;
                if 'const ' in line and " * " in line and "'" in line:
                    # Remove 'const' keyword
                    new_line = line.replace('const ', '')
                    if new_line != line:
                        fixes.append(Fix(
                            file_path=str(file_path),
                            line_number=i + 1,
                            old_code=line.strip(),
                            new_code=new_line.strip(),
                            fix_type='constant_error',
                            description="Removed 'const' from string multiplication (not allowed in const)"
                        ))
                        new_lines[i] = new_line
                        modified = True
            
            if modified and not self.dry_run:
                file_path.write_text('\n'.join(new_lines), encoding='utf-8')
                self.stats['files_modified'] += 1
            
            if modified:
                self.stats['fixes_applied'] += len(fixes)
            
        except Exception as e:
            print(f"Error fixing {file_path}: {e}")
        
        return fixes
    
    def fix_location_parameter(self, file_path: Path) -> List[Fix]:
        """Remove 'location' parameter from ModelFactories.createTestUser if not supported"""
        fixes = []
        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')
            modified = False
            new_lines = lines.copy()
            
            for i, line in enumerate(lines):
                # Pattern: ModelFactories.createTestUser(..., location: null, ...)
                if 'ModelFactories.createTestUser' in line and 'location:' in line:
                    # Remove location parameter line
                    if 'location:' in lines[i]:
                        # Single line case
                        new_line = re.sub(r',\s*location:\s*\w+,?', '', line)
                        new_line = re.sub(r'location:\s*\w+,?\s*', '', new_line)
                        if new_line != line:
                            fixes.append(Fix(
                                file_path=str(file_path),
                                line_number=i + 1,
                                old_code=line.strip(),
                                new_code=new_line.strip(),
                                fix_type='remove_parameter',
                                description="Removed unsupported 'location' parameter"
                            ))
                            new_lines[i] = new_line
                            modified = True
                # Multi-line case
                elif 'ModelFactories.createTestUser' in line:
                    for j in range(i, min(i + 10, len(lines))):
                        if 'location:' in lines[j] and not lines[j].strip().startswith('//'):
                            # Remove this line
                            fixes.append(Fix(
                                file_path=str(file_path),
                                line_number=j + 1,
                                old_code=lines[j].strip(),
                                new_code='',
                                fix_type='remove_parameter',
                                description="Removed unsupported 'location' parameter"
                            ))
                            new_lines[j] = ''
                            modified = True
                            break
            
            if modified and not self.dry_run:
                # Remove empty lines
                new_lines = [l for l in new_lines if l.strip() != '' or l.strip() == '']
                file_path.write_text('\n'.join(new_lines), encoding='utf-8')
                self.stats['files_modified'] += 1
            
            if modified:
                self.stats['fixes_applied'] += len(fixes)
            
        except Exception as e:
            print(f"Error fixing {file_path}: {e}")
        
        return fixes
    
    def fix_personality_profile_initial(self, file_path: Path) -> List[Fix]:
        """Fix PersonalityProfile.initial() - remove named parameter, use positional"""
        fixes = []
        try:
            content = file_path.read_text(encoding='utf-8')
            lines = content.split('\n')
            modified = False
            new_lines = lines.copy()
            
            for i, line in enumerate(lines):
                # Pattern: PersonalityProfile.initial(agentId: 'agent-123')
                if 'PersonalityProfile.initial(' in line and 'agentId:' in line:
                    # Extract the userId value
                    match = re.search(r"agentId:\s*['\"]([^'\"]+)['\"]", line)
                    if match:
                        user_id = match.group(1)
                        new_line = re.sub(
                            r"PersonalityProfile\.initial\(agentId:\s*['\"][^'\"]+['\"]\)",
                            f"PersonalityProfile.initial('{user_id}')",
                            line
                        )
                        if new_line != line:
                            fixes.append(Fix(
                                file_path=str(file_path),
                                line_number=i + 1,
                                old_code=line.strip(),
                                new_code=new_line.strip(),
                                fix_type='parameter_fix',
                                description="Fixed PersonalityProfile.initial() to use positional parameter"
                            ))
                            new_lines[i] = new_line
                            modified = True
            
            if modified and not self.dry_run:
                file_path.write_text('\n'.join(new_lines), encoding='utf-8')
                self.stats['files_modified'] += 1
            
            if modified:
                self.stats['fixes_applied'] += len(fixes)
            
        except Exception as e:
            print(f"Error fixing {file_path}: {e}")
        
        return fixes
    
    def generate_mock_file(self, test_file: Path) -> bool:
        """Generate mock file using build_runner"""
        if not self.generate_mocks:
            return False
        
        print(f"Generating mocks for: {test_file}")
        
        try:
            # Run build_runner to generate mocks
            result = subprocess.run(
                ['dart', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
                capture_output=True,
                text=True,
                cwd=Path.cwd(),
                timeout=60
            )
            
            if result.returncode == 0:
                print(f"✅ Generated mocks for {test_file.name}")
                return True
            else:
                print(f"⚠️  Mock generation may have failed for {test_file.name}")
                print(result.stderr[:200])
                return False
        
        except Exception as e:
            print(f"Error generating mocks: {e}")
            return False
    
    def process_file(self, file_path: Path) -> List[Fix]:
        """Process a single test file and apply all fixes"""
        if file_path.suffix != '.dart' or '_test.dart' not in file_path.name:
            return []
        
        all_fixes = []
        
        # Apply all fixers
        all_fixes.extend(self.fix_unified_user_name_parameter(file_path))
        all_fixes.extend(self.fix_expertise_event_category(file_path))
        all_fixes.extend(self.fix_constant_evaluation_error(file_path))
        all_fixes.extend(self.fix_location_parameter(file_path))
        all_fixes.extend(self.fix_personality_profile_initial(file_path))
        
        self.stats['files_processed'] += 1
        
        return all_fixes
    
    def process_directory(self, root_path: Path):
        """Process all test files in directory"""
        print(f"Processing directory: {root_path}")
        print(f"Mode: {'DRY RUN (no changes will be made)' if self.dry_run else 'LIVE (changes will be made)'}")
        if self.generate_mocks:
            print("Mock generation: ENABLED")
        print("-" * 80)
        
        test_files = list(root_path.rglob('*_test.dart'))
        total_files = len(test_files)
        
        print(f"Found {total_files} test files to process\n")
        
        for i, file_path in enumerate(test_files, 1):
            if i % 10 == 0:
                print(f"Progress: {i}/{total_files} files processed...")
            
            fixes = self.process_file(file_path)
            self.fixes.extend(fixes)
        
        # Generate missing mock files if requested
        if self.generate_mocks:
            print("\nGenerating missing mock files...")
            for file_path in test_files:
                mock_file = file_path.parent / f"{file_path.stem}.mocks.dart"
                if not mock_file.exists() and file_path.name in MOCK_FILES_NEEDED:
                    self.generate_mock_file(file_path)
    
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
            
            print(f"\nFiles modified ({len(set(f.file_path for f in self.fixes))}):")
            for file_path in sorted(set(f.file_path for f in self.fixes)):
                file_fixes = [f for f in self.fixes if f.file_path == file_path]
                print(f"  - {file_path} ({len(file_fixes)} fixes)")
                for fix in file_fixes[:3]:  # Show first 3
                    print(f"    Line {fix.line_number}: {fix.description}")
                if len(file_fixes) > 3:
                    print(f"    ... and {len(file_fixes) - 3} more")
        
        if self.dry_run:
            print("\n⚠️  DRY RUN MODE - No files were actually modified")
            print("Run without --dry-run to apply changes")


def main():
    parser = argparse.ArgumentParser(
        description='Fix common compilation errors in test files',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be fixed without making changes'
    )
    parser.add_argument(
        '--generate-mocks',
        action='store_true',
        help='Generate missing .mocks.dart files using build_runner'
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
    fixer = TestCompilationFixer(dry_run=args.dry_run, generate_mocks=args.generate_mocks)
    fixer.process_directory(root_path)
    fixer.print_summary()


if __name__ == '__main__':
    main()

