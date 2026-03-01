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

        # Final fix to replace remaining EncryptionType usages with String and replace enum usages
        content = re.sub(r"EncryptionType\?", r"String?", content)
        content = re.sub(r"EncryptionType\.none", r"'none'", content)
        content = re.sub(r"EncryptionType\.values\.firstWhere\([^)]+\)", r"json['encryptionType'] as String? ?? 'none'", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
