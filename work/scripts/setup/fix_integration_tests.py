#!/usr/bin/env python3
"""Fix integration test imports from avra to avrai"""
import re
from pathlib import Path

def fix_imports(file_path):
    """Fix imports in a file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Replace package:avra/ -> package:avrai/
        content = re.sub(r'package:avra/', 'package:avrai/', content)
        
        # Replace package:avra_* -> package:avrai_*
        content = re.sub(r'package:avra_(\w+)', r'package:avrai_\1', content)
        
        if content != original:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    root = Path('/Users/reisgordon/AVRA')
    updated = 0
    
    # Update integration_test folder
    for dart_file in root.glob('integration_test/**/*.dart'):
        if fix_imports(dart_file):
            updated += 1
            print(f"Fixed: {dart_file.name}")
    
    # Also check tool folder
    for dart_file in root.glob('tool/**/*.dart'):
        if fix_imports(dart_file):
            updated += 1
            print(f"Fixed: {dart_file.name}")
    
    # Check scripts folder
    for dart_file in root.glob('scripts/**/*.dart'):
        if fix_imports(dart_file):
            updated += 1
            print(f"Fixed: {dart_file.name}")
    
    print(f"\nTotal fixed: {updated} files")

if __name__ == '__main__':
    main()
