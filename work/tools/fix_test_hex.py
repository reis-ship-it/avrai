import re
import os

filepath = 'test/unit/services/visualization/visualization_style_test.dart'
if os.path.exists(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove ColorToHex extension test group
    group_str = """  group('ColorToHex extension', () {
    test('should convert Color to hex int correctly', () {
      expect(const Color(0xFF00FF66).toHex(), equals(0x00FF66));
      expect(const Color(0xFFFF0000).toHex(), equals(0xFF0000));
      expect(const Color(0xFF000000).toHex(), equals(0x000000));
      expect(const Color(0xFFFFFFFF).toHex(), equals(0xFFFFFF));
    });
  });"""
    content = content.replace(group_str, "")

    # Replace AppColors...toHex() with .value & 0xFFFFFF
    content = re.sub(r"(AppColors\.[a-zA-Z0-9_]+)\.toHex\(\)", r"(\1.value & 0xFFFFFF)", content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed {filepath}")
