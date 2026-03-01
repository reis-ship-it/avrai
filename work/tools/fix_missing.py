import os
import re

workspace = 'shared/avrai_core/lib/models'

for root, _, files in os.walk(workspace):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            new_content = content
            
            # 1. Remove motion_reactivity_config foundation import and @immutable
            new_content = re.sub(r"import 'package:flutter/foundation\.dart';\n?", "", new_content)
            new_content = re.sub(r"@immutable\n?", "", new_content)
            
            # 2. Fix knot_worldsheet import
            new_content = re.sub(r"import 'package:avrai_knot/models/knot/knot_worldsheet\.dart';\n?", "", new_content)
            new_content = re.sub(r"final KnotWorldsheet worldsheet;\n?", "final dynamic worldsheet;\n", new_content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Fixed {path}")
