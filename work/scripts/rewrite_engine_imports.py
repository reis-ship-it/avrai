import os
import re

app_dir = '/Users/reisgordon/AVRAI/apps/avrai_app'

targets = [
    r'import \'package:avrai_knot/.*?\.dart\';',
    r'import \'package:reality_engine/.*?\.dart\';',
    r'import \'package:avrai_quantum/.*?\.dart\';',
    r'import \'package:avrai_ai/.*?\.dart\';',
]

proxy_import = "import 'package:avrai_runtime_os/runtime_api.dart';"

def process_file(path):
    with open(path, 'r') as f:
        content = f.read()

    changed = False
    for t in targets:
        if re.search(t, content):
            changed = True
            content = re.sub(t, proxy_import, content)

    if changed:
        # Avoid duplicate proxy imports
        lines = content.split('\n')
        new_lines = []
        has_proxy = False
        for line in lines:
            if line.strip() == proxy_import:
                if not has_proxy:
                    new_lines.append(line)
                    has_proxy = True
            else:
                new_lines.append(line)
                if line.startswith('import '):
                    # reset if we want. But usually one proxy import at top is fine.
                    pass
        
        with open(path, 'w') as f:
            f.write('\n'.join(new_lines))
        print(f"Updated {path}")

for root, _, files in os.walk(app_dir):
    for fl in files:
        if fl.endswith('.dart'):
            process_file(os.path.join(root, fl))
