import os
import re

files_to_fix = [
    'shared/avrai_core/lib/models/business/business_business_message.dart',
    'shared/avrai_core/lib/models/business/business_expert_message.dart'
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Fix EncryptionType.none to 'none'
        content = re.sub(r"EncryptionType\.none", r"'none'", content)
        # Fix encryptionType.name to encryptionType
        content = re.sub(r"encryptionType\.name", r"encryptionType", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
