#!/usr/bin/env python3
"""
Package Import Migration Script

Updates imports from lib/core/services/quantum and lib/core/services/knot
to use the new spots_quantum and spots_knot packages.

Features:
- Dry-run mode (show changes before applying)
- Backup creation
- Incremental application (one package at a time)
- Edge case reporting
- Manual review step
"""

import os
import re
import shutil
import sys
from pathlib import Path
from typing import List, Tuple, Dict
from dataclasses import dataclass
from datetime import datetime

# Color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

@dataclass
class ImportChange:
    """Represents a single import change"""
    file_path: Path
    line_number: int
    old_import: str
    new_import: str
    reason: str

@dataclass
class FileChanges:
    """All changes for a single file"""
    file_path: Path
    changes: List[ImportChange]
    edge_cases: List[str]  # Lines that need manual review

class ImportMigrator:
    """Handles import migration with safeguards"""
    
    def __init__(self, project_root: Path, dry_run: bool = True):
        self.project_root = project_root
        self.dry_run = dry_run
        # Keep backups out of the repo root "product surface".
        # This directory is intended as a quarantine/review area (see repo hygiene plan).
        self.backup_dir = project_root / 'review_before_deletion' / 'import_migration_backup'
        self.changes: Dict[Path, FileChanges] = {}
        
    def find_dart_files(self, directory: Path) -> List[Path]:
        """Find all Dart files in directory"""
        dart_files = []
        for root, dirs, files in os.walk(directory):
            # Skip hidden directories and build directories
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'build']
            
            for file in files:
                if file.endswith('.dart'):
                    dart_files.append(Path(root) / file)
        return dart_files
    
    def should_update_file(self, file_path: Path) -> bool:
        """Determine if file should be updated"""
        # Skip test files for now (can add later)
        if 'test' in str(file_path):
            return False
        
        # Skip backup/quarantine directory
        if 'review_before_deletion/import_migration_backup' in str(file_path):
            return False
            
        # Skip generated files
        if 'generated' in str(file_path) or '.g.dart' in str(file_path):
            return False
            
        return True
    
    def update_import_line(self, line: str, file_path: Path) -> Tuple[str, str]:
        """
        Update a single import line.
        Returns: (updated_line, reason) or (original_line, None) if no change
        """
        original_line = line
        
        # Pattern 1: Quantum service imports
        # package:spots/core/services/quantum/* → package:spots_quantum/services/quantum/*
        quantum_pattern = r"import\s+['\"]package:spots/core/services/quantum/([^'\"]+)['\"];"
        match = re.search(quantum_pattern, line)
        if match:
            service_name = match.group(1)
            new_import = f"import 'package:spots_quantum/services/quantum/{service_name}';"
            return new_import, "Quantum service import"
        
        # Pattern 2: Knot service imports
        # package:spots/core/services/knot/* → package:spots_knot/services/knot/*
        knot_pattern = r"import\s+['\"]package:spots/core/services/knot/([^'\"]+)['\"];"
        match = re.search(knot_pattern, line)
        if match:
            service_name = match.group(1)
            new_import = f"import 'package:spots_knot/services/knot/{service_name}';"
            return new_import, "Knot service import"
        
        # Pattern 3: Bridge imports (in knot package)
        # package:spots/core/services/knot/bridge/* → package:spots_knot/services/knot/bridge/*
        bridge_pattern = r"import\s+['\"]package:spots/core/services/knot/bridge/([^'\"]+)['\"];"
        match = re.search(bridge_pattern, line)
        if match:
            bridge_path = match.group(1)
            new_import = f"import 'package:spots_knot/services/knot/bridge/{bridge_path}';"
            return new_import, "Knot bridge import"
        
        # Edge case: Other quantum/knot imports that might need manual review
        if 'quantum' in line.lower() or 'knot' in line.lower():
            if 'package:spots/core' in line:
                # This might need manual review
                return line, None  # Return original, will be flagged as edge case
        
        return line, None
    
    def analyze_file(self, file_path: Path) -> FileChanges:
        """Analyze a file and return all changes needed"""
        changes = []
        edge_cases = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            for line_num, line in enumerate(lines, 1):
                updated_line, reason = self.update_import_line(line, file_path)
                
                if updated_line != line:
                    changes.append(ImportChange(
                        file_path=file_path,
                        line_number=line_num,
                        old_import=line.rstrip(),
                        new_import=updated_line.rstrip(),
                        reason=reason
                    ))
                elif reason is None and ('quantum' in line.lower() or 'knot' in line.lower()):
                    # Potential edge case
                    if 'package:spots/core' in line:
                        edge_cases.append(f"Line {line_num}: {line.rstrip()}")
        
        except Exception as e:
            print(f"{Colors.RED}Error reading {file_path}: {e}{Colors.RESET}")
        
        return FileChanges(file_path=file_path, changes=changes, edge_cases=edge_cases)
    
    def create_backup(self, file_path: Path) -> Path:
        """Create backup of a file"""
        relative_path = file_path.relative_to(self.project_root)
        backup_path = self.backup_dir / relative_path
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(file_path, backup_path)
        return backup_path
    
    def apply_changes_to_file(self, file_changes: FileChanges) -> bool:
        """Apply changes to a single file"""
        if not file_changes.changes:
            return False
        
        # Create backup
        backup_path = self.create_backup(file_changes.file_path)
        
        try:
            # Read file
            with open(file_changes.file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Apply changes (in reverse order to preserve line numbers)
            for change in reversed(file_changes.changes):
                lines[change.line_number - 1] = change.new_import + '\n'
            
            # Write file
            with open(file_changes.file_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
            
            return True
        except Exception as e:
            print(f"{Colors.RED}Error applying changes to {file_changes.file_path}: {e}{Colors.RESET}")
            # Restore from backup
            shutil.copy2(backup_path, file_changes.file_path)
            return False
    
    def scan_directory(self, directory: Path, description: str):
        """Scan a directory for files that need updates"""
        print(f"\n{Colors.BOLD}{Colors.BLUE}Scanning {description}...{Colors.RESET}")
        
        dart_files = self.find_dart_files(directory)
        total_files = 0
        files_with_changes = 0
        total_changes = 0
        total_edge_cases = 0
        
        for file_path in dart_files:
            if not self.should_update_file(file_path):
                continue
            
            total_files += 1
            file_changes = self.analyze_file(file_path)
            
            if file_changes.changes or file_changes.edge_cases:
                self.changes[file_path] = file_changes
                if file_changes.changes:
                    files_with_changes += 1
                    total_changes += len(file_changes.changes)
                if file_changes.edge_cases:
                    total_edge_cases += len(file_changes.edge_cases)
        
        print(f"  Scanned {total_files} files")
        print(f"  {Colors.GREEN}Files with changes: {files_with_changes}{Colors.RESET}")
        print(f"  {Colors.GREEN}Total import changes: {total_changes}{Colors.RESET}")
        if total_edge_cases > 0:
            print(f"  {Colors.YELLOW}Edge cases needing review: {total_edge_cases}{Colors.RESET}")
    
    def print_changes_summary(self):
        """Print summary of all changes"""
        print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.RESET}")
        print(f"{Colors.BOLD}CHANGES SUMMARY{Colors.RESET}")
        print(f"{Colors.BOLD}{'='*80}{Colors.RESET}\n")
        
        total_changes = sum(len(fc.changes) for fc in self.changes.values())
        total_edge_cases = sum(len(fc.edge_cases) for fc in self.changes.values())
        
        print(f"Total files to update: {len(self.changes)}")
        print(f"Total import changes: {total_changes}")
        print(f"Total edge cases: {total_edge_cases}")
        
        if self.dry_run:
            print(f"\n{Colors.YELLOW}DRY RUN MODE - No files will be modified{Colors.RESET}")
        else:
            print(f"\n{Colors.RED}LIVE MODE - Files will be modified{Colors.RESET}")
    
    def print_detailed_changes(self, max_files: int = 10):
        """Print detailed changes for review"""
        print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.RESET}")
        print(f"{Colors.BOLD}DETAILED CHANGES (showing first {max_files} files){Colors.RESET}")
        print(f"{Colors.BOLD}{'='*80}{Colors.RESET}\n")
        
        files_shown = 0
        for file_path, file_changes in self.changes.items():
            if files_shown >= max_files:
                remaining = len(self.changes) - files_shown
                print(f"\n{Colors.YELLOW}... and {remaining} more files{Colors.RESET}")
                break
            
            if file_changes.changes:
                files_shown += 1
                rel_path = file_path.relative_to(self.project_root)
                print(f"\n{Colors.BOLD}{rel_path}{Colors.RESET}")
                
                for change in file_changes.changes:
                    print(f"  Line {change.line_number}: {Colors.RED}-{change.old_import}{Colors.RESET}")
                    print(f"            {Colors.GREEN}+{change.new_import}{Colors.RESET}")
                    print(f"            {Colors.BLUE}({change.reason}){Colors.RESET}")
                
                if file_changes.edge_cases:
                    print(f"  {Colors.YELLOW}Edge cases needing review:{Colors.RESET}")
                    for edge_case in file_changes.edge_cases:
                        print(f"    {edge_case}")
    
    def print_edge_cases(self):
        """Print all edge cases that need manual review"""
        all_edge_cases = []
        for file_path, file_changes in self.changes.items():
            if file_changes.edge_cases:
                rel_path = file_path.relative_to(self.project_root)
                for edge_case in file_changes.edge_cases:
                    all_edge_cases.append(f"{rel_path}: {edge_case}")
        
        if all_edge_cases:
            print(f"\n{Colors.BOLD}{Colors.YELLOW}{'='*80}{Colors.RESET}")
            print(f"{Colors.BOLD}EDGE CASES NEEDING MANUAL REVIEW{Colors.RESET}")
            print(f"{Colors.BOLD}{'='*80}{Colors.RESET}\n")
            
            for edge_case in all_edge_cases:
                print(f"  {edge_case}")
        else:
            print(f"\n{Colors.GREEN}No edge cases found!{Colors.RESET}")
    
    def apply_changes(self) -> bool:
        """Apply all changes"""
        if self.dry_run:
            print(f"\n{Colors.YELLOW}DRY RUN - Not applying changes{Colors.RESET}")
            return False
        
        # Create backup directory
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_info_file = self.backup_dir / f"backup_info_{timestamp}.txt"
        
        print(f"\n{Colors.BOLD}{Colors.BLUE}Applying changes...{Colors.RESET}")
        print(f"Backup directory: {self.backup_dir}")
        
        applied = 0
        failed = 0
        
        with open(backup_info_file, 'w') as f:
            f.write(f"Backup created: {timestamp}\n")
            f.write(f"Total files: {len(self.changes)}\n\n")
            
            for file_path, file_changes in self.changes.items():
                if file_changes.changes:
                    rel_path = file_path.relative_to(self.project_root)
                    backup_path = self.create_backup(file_path)
                    f.write(f"{rel_path} -> {backup_path}\n")
                    
                    if self.apply_changes_to_file(file_changes):
                        applied += 1
                        print(f"  {Colors.GREEN}✓{Colors.RESET} {rel_path}")
                    else:
                        failed += 1
                        print(f"  {Colors.RED}✗{Colors.RESET} {rel_path}")
        
        print(f"\n{Colors.GREEN}Applied: {applied}{Colors.RESET}")
        if failed > 0:
            print(f"{Colors.RED}Failed: {failed}{Colors.RESET}")
        
        return failed == 0

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Migrate imports from lib/core/services to new packages'
    )
    parser.add_argument(
        '--apply',
        action='store_true',
        help='Apply changes (default is dry-run)'
    )
    parser.add_argument(
        '--package',
        choices=['quantum', 'knot', 'both'],
        default='both',
        help='Which package to migrate (default: both)'
    )
    parser.add_argument(
        '--project-root',
        type=Path,
        default=Path.cwd(),
        help='Project root directory (default: current directory)'
    )
    
    args = parser.parse_args()
    
    project_root = args.project_root.resolve()
    
    if not (project_root / 'pubspec.yaml').exists():
        print(f"{Colors.RED}Error: pubspec.yaml not found. Are you in the project root?{Colors.RESET}")
        sys.exit(1)
    
    migrator = ImportMigrator(project_root, dry_run=not args.apply)
    
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*80}{Colors.RESET}")
    print(f"{Colors.BOLD}Package Import Migration Script{Colors.RESET}")
    print(f"{Colors.BOLD}{'='*80}{Colors.RESET}")
    print(f"Project root: {project_root}")
    print(f"Mode: {Colors.YELLOW if migrator.dry_run else Colors.RED}{'DRY RUN' if migrator.dry_run else 'LIVE'}{Colors.RESET}")
    print(f"Package: {args.package}")
    
    # Scan directories
    if args.package in ['quantum', 'both']:
        # Scan package files
        quantum_package = project_root / 'packages' / 'spots_quantum'
        if quantum_package.exists():
            migrator.scan_directory(quantum_package, "spots_quantum package")
        
        # Scan main app files
        lib_dir = project_root / 'lib'
        if lib_dir.exists():
            migrator.scan_directory(lib_dir, "main app (quantum imports)")
    
    if args.package in ['knot', 'both']:
        # Scan package files
        knot_package = project_root / 'packages' / 'spots_knot'
        if knot_package.exists():
            migrator.scan_directory(knot_package, "spots_knot package")
        
        # Scan main app files
        lib_dir = project_root / 'lib'
        if lib_dir.exists():
            migrator.scan_directory(lib_dir, "main app (knot imports)")
    
    # Print summary
    migrator.print_changes_summary()
    
    # Print detailed changes
    migrator.print_detailed_changes(max_files=10)
    
    # Print edge cases
    migrator.print_edge_cases()
    
    # Apply changes if not dry-run
    if args.apply:
        print(f"\n{Colors.BOLD}{Colors.RED}Are you sure you want to apply these changes? (yes/no): {Colors.RESET}", end='')
        confirmation = input().strip().lower()
        
        if confirmation == 'yes':
            success = migrator.apply_changes()
            if success:
                print(f"\n{Colors.GREEN}✓ All changes applied successfully!{Colors.RESET}")
                print(f"Backup location: {migrator.backup_dir}")
            else:
                print(f"\n{Colors.RED}✗ Some changes failed. Check backup directory.{Colors.RESET}")
                sys.exit(1)
        else:
            print(f"{Colors.YELLOW}Cancelled.{Colors.RESET}")
    else:
        print(f"\n{Colors.BOLD}To apply changes, run with --apply flag{Colors.RESET}")
        print(f"Example: python {sys.argv[0]} --apply")

if __name__ == '__main__':
    main()
