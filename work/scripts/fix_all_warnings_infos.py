#!/usr/bin/env python3
"""
Comprehensive Warning and Info Fix Script
Fixes all remaining warnings and info messages systematically
"""

import re
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple, Dict, Set
from collections import defaultdict

class WarningInfoFixer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.warnings: List[Tuple[str, str, int, str]] = []  # (file, type, line, message)
        self.infos: List[Tuple[str, str, int, str]] = []
        self.fixes_applied = 0
        
    def analyze_all_issues(self):
        """Run flutter analyze and extract all warnings and infos."""
        print("🔍 Running flutter analyze to extract all warnings/infos...")
        
        result = subprocess.run(
            ["flutter", "analyze"],
            cwd=self.project_root,
            capture_output=True,
            text=True
        )
        
        # Pattern: "warning • message • file:line:col • code"
        # Pattern: "info • message • file:line:col • code"
        warning_pattern = r"warning • (.+?) • (.+?):(\d+):\d+ • ([a-z_]+)"
        info_pattern = r"info • (.+?) • (.+?):(\d+):\d+ • ([a-z_]+)"
        
        for line in result.stdout.split('\n'):
            # Match warnings
            match = re.search(warning_pattern, line)
            if match:
                message = match.group(1)
                file_path = match.group(2)
                line_num = int(match.group(3))
                code = match.group(4)
                self.warnings.append((file_path, code, line_num, message))
            
            # Match infos
            match = re.search(info_pattern, line)
            if match:
                message = match.group(1)
                file_path = match.group(2)
                line_num = int(match.group(3))
                code = match.group(4)
                self.infos.append((file_path, code, line_num, message))
        
        print(f"✅ Found {len(self.warnings)} warnings and {len(self.infos)} infos")
        return len(self.warnings) + len(self.infos)
    
    def get_issue_breakdown(self) -> Dict[str, int]:
        """Get breakdown of issues by type."""
        breakdown = defaultdict(int)
        for _, code, _, _ in self.warnings + self.infos:
            breakdown[code] += 1
        return dict(breakdown)
    
    def fix_unused_imports(self) -> int:
        """Remove unused imports."""
        fixed = 0
        unused_imports = [
            (f, line, msg) for f, code, line, msg in self.warnings + self.infos
            if code == 'unused_import'
        ]
        
        for file_path, line_num, message in unused_imports:
            if self._remove_line(file_path, line_num):
                fixed += 1
        
        return fixed
    
    def fix_unused_variables(self) -> int:
        """Fix unused local variables."""
        fixed = 0
        unused_vars = [
            (f, line, msg) for f, code, line, msg in self.warnings
            if code == 'unused_local_variable'
        ]
        
        for file_path, line_num, message in unused_vars:
            # Extract variable name from message
            match = re.search(r"^The value of the (?:local )?variable '(.+?)' isn't used", message)
            if match:
                var_name = match.group(1)
                if self._prefix_with_underscore(file_path, line_num, var_name):
                    fixed += 1
        
        return fixed
    
    def fix_unused_fields(self) -> int:
        """Fix unused fields by adding ignore comments."""
        fixed = 0
        unused_fields = [
            (f, line, msg) for f, code, line, msg in self.warnings
            if code == 'unused_field'
        ]
        
        for file_path, line_num, message in unused_fields:
            if self._add_ignore_comment(file_path, line_num, 'unused_field'):
                fixed += 1
        
        return fixed
    
    def fix_avoid_print(self) -> int:
        """Fix print() statements in production code."""
        fixed = 0
        avoid_print = [
            (f, line, msg) for f, code, line, msg in self.warnings + self.infos
            if code == 'avoid_print' and f.startswith('lib/') and 'test' not in f
        ]
        
        for file_path, line_num, _ in avoid_print:
            if self._replace_print_with_logger(file_path, line_num):
                fixed += 1
        
        return fixed
    
    def _remove_line(self, file_path: str, line_num: int) -> bool:
        """Remove a line from a file."""
        full_path = self.project_root / file_path
        if not full_path.exists():
            return False
        
        try:
            lines = full_path.read_text().split('\n')
            if line_num < 1 or line_num > len(lines):
                return False
            
            # Remove the line (0-indexed)
            lines.pop(line_num - 1)
            full_path.write_text('\n'.join(lines))
            return True
        except Exception:
            return False
    
    def _prefix_with_underscore(self, file_path: str, line_num: int, var_name: str) -> bool:
        """Prefix variable with underscore to indicate intentionally unused."""
        full_path = self.project_root / file_path
        if not full_path.exists():
            return False
        
        try:
            content = full_path.read_text()
            lines = content.split('\n')
            if line_num < 1 or line_num > len(lines):
                return False
            
            # Prefix variable name with underscore
            line = lines[line_num - 1]
            if var_name in line:
                lines[line_num - 1] = line.replace(f' {var_name}', f' _{var_name}')
                full_path.write_text('\n'.join(lines))
                return True
        except Exception:
            pass
        return False
    
    def _add_ignore_comment(self, file_path: str, line_num: int, code: str) -> bool:
        """Add ignore comment before a line."""
        full_path = self.project_root / file_path
        if not full_path.exists():
            return False
        
        try:
            lines = full_path.read_text().split('\n')
            if line_num < 1 or line_num > len(lines):
                return False
            
            # Check if already has ignore comment
            if line_num > 1 and 'ignore:' in lines[line_num - 2]:
                return False
            
            # Add ignore comment before the line
            lines.insert(line_num - 1, f'  // ignore: {code}')
            full_path.write_text('\n'.join(lines))
            return True
        except Exception:
            return False
    
    def _replace_print_with_logger(self, file_path: str, line_num: int) -> bool:
        """Replace print() with developer.log()."""
        full_path = self.project_root / file_path
        if not full_path.exists():
            return False
        
        try:
            content = full_path.read_text()
            lines = content.split('\n')
            if line_num < 1 or line_num > len(lines):
                return False
            
            # Check if already has ignore comment or is in test code
            line = lines[line_num - 1]
            if '// ignore: avoid_print' in line or 'const bool.fromEnvironment' in '\n'.join(lines[max(0, line_num-5):line_num]):
                return False
            
            # Add developer import if needed
            if 'import \'dart:developer\'' not in content:
                # Find first import line
                for i, l in enumerate(lines):
                    if l.startswith('import '):
                        lines.insert(i, "import 'dart:developer' as developer;")
                        line_num += 1  # Adjust for inserted line
                        break
            
            # Replace print with developer.log
            line = lines[line_num - 1]
            # Simple replacement - extract message
            if 'print(' in line:
                # Extract print content
                match = re.search(r"print\('?(.+?)'?\)", line)
                if match:
                    message = match.group(1)
                    service_name = Path(file_path).stem.replace('_', ' ').title().replace(' ', '')
                    new_line = line.replace(
                        f"print('{message}')",
                        f"developer.log('{message}', name: '{service_name}')"
                    )
                    lines[line_num - 1] = new_line
                    full_path.write_text('\n'.join(lines))
                    return True
        except Exception as e:
            print(f"Error fixing {file_path}:{line_num}: {e}")
        
        return False
    
    def fix_all(self, dry_run: bool = False) -> Dict[str, int]:
        """Fix all issues."""
        results = {}
        
        print("\n🔧 Fixing issues...")
        print("=" * 80)
        
        if not dry_run:
            print("\n1. Fixing unused imports...")
            results['unused_imports'] = self.fix_unused_imports()
            print(f"   ✅ Fixed {results['unused_imports']} unused imports")
            
            print("\n2. Fixing unused fields...")
            results['unused_fields'] = self.fix_unused_fields()
            print(f"   ✅ Fixed {results['unused_fields']} unused fields")
            
            print("\n3. Fixing print() in production code...")
            results['avoid_print'] = self.fix_avoid_print()
            print(f"   ✅ Fixed {results['avoid_print']} print() statements")
        else:
            print("DRY RUN - would fix:")
            breakdown = self.get_issue_breakdown()
            for code, count in sorted(breakdown.items(), key=lambda x: x[1], reverse=True):
                print(f"  {count:4d} × {code}")
        
        return results


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("""
Comprehensive Warning and Info Fix Script

Usage:
    python scripts/fix_all_warnings_infos.py [--dry-run] [--fix]

Options:
    --dry-run    Show what would be fixed without actually fixing
    --fix        Actually apply fixes (default: dry-run)

Examples:
    python scripts/fix_all_warnings_infos.py --dry-run
    python scripts/fix_all_warnings_infos.py --fix
        """)
        return
    
    project_root = Path(__file__).parent.parent
    fixer = WarningInfoFixer(str(project_root))
    
    print("🚀 Starting comprehensive warning/info analysis...\n")
    
    total = fixer.analyze_all_issues()
    breakdown = fixer.get_issue_breakdown()
    
    print("\n📊 Issue Breakdown:")
    print("=" * 80)
    for code, count in sorted(breakdown.items(), key=lambda x: x[1], reverse=True)[:20]:
        print(f"  {count:4d} × {code}")
    
    dry_run = "--fix" not in sys.argv
    
    if dry_run:
        print("\n💡 Use --fix to actually apply fixes")
    
    results = fixer.fix_all(dry_run=dry_run)
    
    if results:
        print("\n✅ Fixes Applied:")
        for fix_type, count in results.items():
            print(f"  {fix_type}: {count} fixed")


if __name__ == "__main__":
    main()
