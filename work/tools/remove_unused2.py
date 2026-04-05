import re
import os

filepath = 'engine/reality_engine/lib/memory/air_gap/tuple_extraction_engine.dart'
if os.path.exists(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove unused uuid import
    content = re.sub(r"import 'package:uuid/uuid\.dart';[^\n]*\n", "", content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed {filepath}")
