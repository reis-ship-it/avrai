#!/usr/bin/env python3
"""
Fix all use_build_context_synchronously warnings by adding mounted checks
"""

import re
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

class BuildContextFixer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.issues: List[Tuple[str, int]] = []
        
    def find_issues(self):
        """Find all use_build_context_synchronously issues."""
        result = subprocess.run(
            ["flutter", "analyze"],
            cwd=self.project_root,
            capture_output=True,
            text=True
        )
        
        pattern = r"use_build_context_synchronously.*?(\S+):(\d+):"
        
        for line in result.stdout.split('\n'):
            match = re.search(pattern, line)
            if match:
                file_path = match.group(1)
                line_num = int(match.group(2))
                if file_path.startswith('lib/'):
                    self.issues.append((file_path, line_num))
        
        return len(self.issues)
    
    def fix_file(self, file_path: str, line_num: int) -> bool:
        """Fix a specific use_build_context_synchronously warning."""
        full_path = self.project_root / file_path
        if not full_path.exists():
            return False
        
        try:
            content = full_path.read_text()
            lines = content.split('\n')
            
            if line_num < 1 or line_num > len(lines):
                return False
            
            # Look backwards for async gap (await keyword)
            # Then check if mounted check exists before context usage
            target_line_idx = line_num - 1
            line = lines[target_line_idx]
            
            # Check if this line uses context
            if 'context.' not in line and 'context,' not in line and 'context)' not in line:
                # Context usage might be on a different line, check nearby
                for i in range(max(0, target_line_idx - 2), min(len(lines), target_line_idx + 3)):
                    if 'context.' in lines[i] or 'context,' in lines[i] or 'context)' in lines[i]:
                        target_line_idx = i
                        break
                else:
                    return False
            
            # Look backwards for await
            found_await = False
            await_line_idx = -1
            for i in range(target_line_idx - 1, max(-1, target_line_idx - 20), -1):
                if 'await ' in lines[i] and 'await _' not in lines[i]:  # Not await in comments
                    found_await = True
                    await_line_idx = i
                    break
            
            if not found_await:
                return False
            
            # Check if mounted check already exists between await and context usage
            for i in range(await_line_idx + 1, target_line_idx):
                if 'mounted' in lines[i] and ('if (!mounted)' in lines[i] or 'if (mounted)' in lines[i] or '!mounted' in lines[i]):
                    # Already has mounted check, but analyzer says it's "unrelated"
                    # Need to add explicit check right before context usage
                    break
            else:
                # No mounted check found, add one right before context usage
                indent = len(line) - len(line.lstrip())
                if 'guarded by an unrelated' in line or 'guarded by an unrelated' in '\n'.join(lines[max(0, target_line_idx-5):target_line_idx]):
                    # Add mounted check right before the problematic line
                    lines.insert(target_line_idx, ' ' * indent + 'if (!mounted) return;')
                    full_path.write_text('\n'.join(lines))
                    return True
                else:
                    # Add mounted check after await
                    await_indent = len(lines[await_line_idx]) - len(lines[await_line_idx].lstrip())
                    # Find the line after await (might be in if/for/etc block)
                    next_line_idx = await_line_idx + 1
                    if next_line_idx < len(lines):
                        next_indent = len(lines[next_line_idx]) - len(lines[next_line_idx].lstrip()) if lines[next_line_idx].strip() else await_indent
                        insert_indent = max(await_indent, next_indent)
                        lines.insert(await_line_idx + 1, ' ' * insert_indent + 'if (!mounted) return;')
                        full_path.write_text('\n'.join(lines))
                        return True
            
            return False
        except Exception as e:
            print(f"Error fixing {file_path}:{line_num}: {e}")
            return False
    
    def fix_all(self, dry_run: bool = False) -> int:
        """Fix all issues."""
        fixed = 0
        
        if dry_run:
            print(f"Would fix {len(self.issues)} issues:")
            for file_path, line_num in self.issues:
                print(f"  {file_path}:{line_num}")
            return 0
        
        for file_path, line_num in self.issues:
            if self.fix_file(file_path, line_num):
                fixed += 1
        
        return fixed


def main():
    project_root = Path(__file__).parent.parent
    fixer = BuildContextFixer(str(project_root))
    
    print("🔍 Finding use_build_context_synchronously issues...")
    count = fixer.find_issues()
    print(f"✅ Found {count} issues\n")
    
    dry_run = "--fix" not in sys.argv
    
    if dry_run:
        print("💡 Use --fix to actually apply fixes\n")
    
    fixed = fixer.fix_all(dry_run=dry_run)
    
    if not dry_run:
        print(f"✅ Fixed {fixed} issues")


if __name__ == "__main__":
    main()
