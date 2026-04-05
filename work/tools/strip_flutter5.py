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

        # Fix encryptionType type from EncryptionType to String in the fromJson methods
        content = re.sub(r"encryptionType: EncryptionType\.values\.firstWhere\([^)]+\),", r"encryptionType: json['encryptionType'] as String? ?? 'none',", content, flags=re.DOTALL)
        content = re.sub(r"'encryptionType': encryptionType\.name", r"'encryptionType': encryptionType", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
