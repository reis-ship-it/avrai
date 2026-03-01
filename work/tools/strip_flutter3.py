import os

filepath = 'runtime/avrai_runtime_os/lib/models/misc/visualization_style.dart'

if os.path.exists(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove the extension and the .toHex() calls that were relying on it
    # Find the extension block
    start_idx = content.find("/// Helper to convert Flutter Color to hex int")
    if start_idx != -1:
        end_idx = content.find("/// Helper to create style from AppColors")
        if end_idx != -1:
            content = content[:start_idx] + content[end_idx:]

    # Remove .toHex() calls
    content = content.replace(".toHex()", "")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed {filepath}")
