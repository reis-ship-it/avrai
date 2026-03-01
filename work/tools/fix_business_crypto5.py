import re
import os

files_to_fix = [
    'runtime/avrai_runtime_os/lib/ai2ai/chat/incoming_business_business_chat_lane.dart',
    'runtime/avrai_runtime_os/lib/ai2ai/chat/incoming_business_expert_chat_lane.dart',
    'runtime/avrai_runtime_os/lib/services/business/business_business_chat_service_ai2ai.dart',
    'runtime/avrai_runtime_os/lib/services/business/business_expert_chat_service.dart',
    'runtime/avrai_runtime_os/lib/services/business/business_expert_chat_service_ai2ai.dart',
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Fix String.values => just ['none', 'aes256gcm']
        content = re.sub(r'String\.values', "['none', 'aes256gcm']", content)
        
        # In chat services: EncryptionType encryptionType = EncryptionType.aes256gcm (already replaced String encryptionType = ...)
        # But we need to check assignments
        content = re.sub(r"const \['none', 'aes256gcm'\]\.firstWhere", "['none', 'aes256gcm'].firstWhere", content)

        # Fix assignment issue where it's still returning EncryptionType instead of String
        content = re.sub(r"= EncryptionType", "= 'aes256gcm' //", content) # Hack to find left over enums
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
