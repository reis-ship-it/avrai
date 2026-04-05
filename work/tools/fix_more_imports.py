import os
import re

workspace = '.'
count = 0
for root, _, files in os.walk(workspace):
    if '.git' in root or '.dart_tool' in root or 'build' in root or 'venv' in root or 'Pods' in root:
        continue
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            new_content = re.sub(r"import 'package:avrai_runtime_os/constants/(.*)';\n?", r"import 'package:avrai_core/constants/\1';\n", content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                count += 1

print(f"Updated further imports in {count} files.")
