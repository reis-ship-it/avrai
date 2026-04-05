import os
import glob
import re

def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Skip files that don't need changing or already changed
    if 'flutter_secure_storage' not in content:
        return

    # Replace pubspec dependencies
    if filepath.endswith('pubspec.yaml'):
        new_content = re.sub(
            r'flutter_secure_storage:\s*\^[0-9\.\-betaa-z]+',
            r'flutter_secure_storage_x: ^12.1.4',
            content
        )
        # also replace override or other things if present, but usually just dependencies
    # Replace imports in dart files
    elif filepath.endswith('.dart'):
        new_content = content.replace(
            "import 'package:flutter_secure_storage/flutter_secure_storage.dart';",
            "import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';"
        )
    # Replace in mocks if any
    elif filepath.endswith('.yaml') or filepath.endswith('.txt'):
        new_content = content
    else:
        new_content = content

    if content != new_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

def main():
    root_dir = '/Users/reisgordon/AVRAI'
    for filepath in glob.glob(root_dir + '/**/*', recursive=True):
        if os.path.isfile(filepath):
            # Only check specific extensions
            if filepath.endswith('.dart') or filepath.endswith('.yaml'):
                try:
                    replace_in_file(filepath)
                except Exception as e:
                    print(f"Failed to process {filepath}: {e}")

if __name__ == '__main__':
    main()
