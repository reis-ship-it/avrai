#!/usr/bin/env python3
"""
Design Token Compliance Fix Script

Automatically replaces Colors.* usage with AppColors.* equivalents across the codebase.
Handles Colors.white, Colors.black, and preserves Colors.transparent (acceptable exception).

Usage:
    python scripts/fix_design_tokens.py [--dry-run] [--backup] [--path PATH]

Options:
    --dry-run    Show what would be changed without making changes
    --backup     Create backup files before modifying
    --path PATH  Specific path to process (default: lib/)
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import List, Tuple, Dict
from dataclasses import dataclass, field

# Color replacement mappings
COLOR_REPLACEMENTS = {
    'Colors.white': 'AppColors.white',
    'Colors.black': 'AppColors.black',
    # Colors.transparent is acceptable and should NOT be replaced
}

# AppColors import statement
APP_COLORS_IMPORT = "import 'package:avrai/core/theme/colors.dart';"

# Files/directories to skip
SKIP_PATTERNS = [
    '.git',
    'build',
    '.dart_tool',
    'packages',
    'test',
    'node_modules',
    '__pycache__',
    '.pub-cache',
]

# Files that use PdfColors (acceptable, different library)
PDF_COLORS_FILES = [
    'pdf_generation_service.dart',
]


@dataclass
class FileChange:
    """Represents a change made to a file"""
    file_path: str
    line_number: int
    old_text: str
    new_text: str
    change_type: str  # 'replacement' or 'import_added'


@dataclass
class FileReport:
    """Report for a single file"""
    file_path: str
    changes: List[FileChange] = field(default_factory=list)
    import_added: bool = False
    skipped: bool = False
    skip_reason: str = ""


class DesignTokenFixer:
    """Main class for fixing design token compliance"""
    
    def __init__(self, dry_run: bool = False, create_backup: bool = False):
        self.dry_run = dry_run
        self.create_backup = create_backup
        self.reports: Dict[str, FileReport] = {}
        self.stats = {
            'files_processed': 0,
            'files_modified': 0,
            'replacements_made': 0,
            'imports_added': 0,
            'files_skipped': 0,
        }
    
    def should_skip_file(self, file_path: Path) -> Tuple[bool, str]:
        """Check if file should be skipped"""
        # Skip non-Dart files
        if file_path.suffix != '.dart':
            return True, "Not a Dart file"
        
        # Skip test files (as per user requirement to focus on lib/)
        if 'test' in file_path.parts:
            return True, "Test file (skipping)"
        
        # Skip files in skip patterns
        for pattern in SKIP_PATTERNS:
            if pattern in file_path.parts:
                return True, f"Matches skip pattern: {pattern}"
        
        # Check for PdfColors files (acceptable)
        if any(pdf_file in file_path.name for pdf_file in PDF_COLORS_FILES):
            return True, "PdfColors file (acceptable exception)"
        
        return False, ""
    
    def find_color_usage(self, content: str) -> List[Tuple[int, str, str]]:
        """Find all Colors.* usage that needs replacement"""
        matches = []
        lines = content.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            # Skip comments and imports
            stripped = line.strip()
            if stripped.startswith('//') or stripped.startswith('import'):
                continue
            
            # Find Colors.white and Colors.black (but not Colors.transparent)
            for old_color, new_color in COLOR_REPLACEMENTS.items():
                # Pattern to match Colors.white or Colors.black but not in comments
                pattern = re.compile(r'\b' + re.escape(old_color) + r'\b')
                
                for match in pattern.finditer(line):
                    # Check if it's in a comment
                    comment_start = line.find('//')
                    if comment_start != -1 and match.start() > comment_start:
                        continue
                    
                    matches.append((line_num, old_color, new_color))
        
        return matches
    
    def needs_import(self, content: str) -> bool:
        """Check if file needs AppColors import"""
        # Check if AppColors is already imported
        if 'package:avrai/core/theme/colors.dart' in content:
            return False
        
        # Check if file uses Colors.* that we're replacing
        has_color_usage = any(
            f'Colors.{color}' in content 
            for color in ['white', 'black']
        )

        # Check if AppColors is used (e.g. from manual fixes or regex passes)
        has_app_colors = 'AppColors.' in content
        
        return has_color_usage or has_app_colors
    
    def find_import_position(self, content: str) -> int:
        """Find the best position to insert the import"""
        lines = content.split('\n')
        
        # Look for existing Flutter imports
        for i, line in enumerate(lines):
            if line.strip().startswith('import ') and 'package:flutter' in line:
                # Insert after the last Flutter import
                j = i + 1
                while j < len(lines) and lines[j].strip().startswith('import ') and 'package:flutter' in lines[j]:
                    j += 1
                return j
        
        # Look for any import section
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                # Find end of import section
                j = i + 1
                while j < len(lines) and (lines[j].strip().startswith('import ') or lines[j].strip() == ''):
                    if lines[j].strip().startswith('import '):
                        j += 1
                    elif lines[j].strip() == '' and j < len(lines) - 1:
                        j += 1
                    else:
                        break
                return j
        
        # Default: insert at the beginning
        return 0
    
    def fix_file(self, file_path: Path) -> FileReport:
        """Fix design token compliance in a single file"""
        report = FileReport(file_path=str(file_path))
        
        # Check if should skip
        should_skip, reason = self.should_skip_file(file_path)
        if should_skip:
            report.skipped = True
            report.skip_reason = reason
            return report
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            report.skipped = True
            report.skip_reason = f"Error reading file: {e}"
            return report
        
        original_content = content
        modified = False
        
        # Find and replace color usage
        color_matches = self.find_color_usage(content)
        for line_num, old_color, new_color in color_matches:
            lines = content.split('\n')
            if line_num <= len(lines):
                line = lines[line_num - 1]
                new_line = line.replace(old_color, new_color)
                if new_line != line:
                    lines[line_num - 1] = new_line
                    content = '\n'.join(lines)
                    report.changes.append(FileChange(
                        file_path=str(file_path),
                        line_number=line_num,
                        old_text=line.strip(),
                        new_text=new_line.strip(),
                        change_type='replacement'
                    ))
                    modified = True
                    self.stats['replacements_made'] += 1
        
        # Add import if needed
        if self.needs_import(content):
            import_pos = self.find_import_position(content)
            lines = content.split('\n')
            
            # Insert import
            lines.insert(import_pos, APP_COLORS_IMPORT)
            # Add blank line after import if not present
            if import_pos + 1 < len(lines) and lines[import_pos + 1].strip() != '':
                lines.insert(import_pos + 1, '')
            
            content = '\n'.join(lines)
            report.import_added = True
            report.changes.append(FileChange(
                file_path=str(file_path),
                line_number=import_pos + 1,
                old_text='',
                new_text=APP_COLORS_IMPORT,
                change_type='import_added'
            ))
            modified = True
            self.stats['imports_added'] += 1
        
        # Write changes if any were made
        if modified and not self.dry_run:
            # Create backup if requested
            if self.create_backup:
                backup_path = file_path.with_suffix(file_path.suffix + '.bak')
                with open(backup_path, 'w', encoding='utf-8') as f:
                    f.write(original_content)
            
            # Write modified content
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            self.stats['files_modified'] += 1
        
        self.stats['files_processed'] += 1
        if modified:
            self.reports[str(file_path)] = report
        
        return report
    
    def process_directory(self, root_path: Path):
        """Process all Dart files in directory"""
        print(f"Processing directory: {root_path}")
        print(f"Mode: {'DRY RUN (no changes will be made)' if self.dry_run else 'LIVE (changes will be made)'}")
        if self.create_backup:
            print("Backups will be created for modified files")
        print("-" * 80)
        
        dart_files = list(root_path.rglob('*.dart'))
        total_files = len(dart_files)
        
        print(f"Found {total_files} Dart files to process\n")
        
        for i, file_path in enumerate(dart_files, 1):
            if i % 50 == 0:
                print(f"Progress: {i}/{total_files} files processed...")
            
            report = self.fix_file(file_path)
            
            if report.skipped:
                self.stats['files_skipped'] += 1
            elif report.changes:
                self.reports[str(file_path)] = report
    
    def print_summary(self):
        """Print summary of changes"""
        print("\n" + "=" * 80)
        print("SUMMARY")
        print("=" * 80)
        print(f"Files processed:    {self.stats['files_processed']}")
        print(f"Files modified:     {self.stats['files_modified']}")
        print(f"Files skipped:      {self.stats['files_skipped']}")
        print(f"Replacements made:  {self.stats['replacements_made']}")
        print(f"Imports added:      {self.stats['imports_added']}")
        
        if self.reports:
            print(f"\nModified files ({len(self.reports)}):")
            for file_path, report in sorted(self.reports.items()):
                print(f"  - {file_path}")
                for change in report.changes:
                    if change.change_type == 'replacement':
                        print(f"    Line {change.line_number}: {change.old_text} → {change.new_text}")
                    elif change.change_type == 'import_added':
                        print(f"    Added import: {APP_COLORS_IMPORT}")
        
        if self.dry_run:
            print("\n⚠️  DRY RUN MODE - No files were actually modified")
            print("Run without --dry-run to apply changes")


def main():
    parser = argparse.ArgumentParser(
        description='Fix design token compliance across the codebase',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Dry run to see what would change
  python scripts/fix_design_tokens.py --dry-run
  
  # Apply changes with backups
  python scripts/fix_design_tokens.py --backup
  
  # Process specific directory
  python scripts/fix_design_tokens.py --path lib/presentation/pages
        """
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be changed without making changes'
    )
    parser.add_argument(
        '--backup',
        action='store_true',
        help='Create backup files before modifying'
    )
    parser.add_argument(
        '--path',
        type=str,
        default='lib/',
        help='Path to process (default: lib/)'
    )
    
    args = parser.parse_args()
    
    # Validate path
    root_path = Path(args.path)
    if not root_path.exists():
        print(f"Error: Path does not exist: {root_path}")
        sys.exit(1)
    
    # Create fixer and process
    fixer = DesignTokenFixer(dry_run=args.dry_run, create_backup=args.backup)
    fixer.process_directory(root_path)
    fixer.print_summary()


if __name__ == '__main__':
    main()

