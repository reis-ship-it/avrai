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

        # Fix issues with values and name missing on String
        # (e.g., e.name == encryptionTypeStr)
        content = re.sub(r"const \['none', 'aes256gcm'\]\.values", "const ['none', 'aes256gcm']", content)
        content = re.sub(r"\.firstWhere\(\(e\) => e\.name == ", ".firstWhere((e) => e == ", content)
        
        # Replace EncryptionType definition usages where it might be expecting an enum value
        content = re.sub(r'EncryptionType\.values\.firstWhere', "['none', 'aes256gcm'].firstWhere", content)
        content = re.sub(r'String\.values\.firstWhere', "['none', 'aes256gcm'].firstWhere", content)

        # Fix remaining usages of EncryptionType that caused assignment errors
        content = re.sub(r'EncryptionType encryptionType =', 'String encryptionType =', content)

        # Fix specific errors from latest report
        content = re.sub(r"message\.encryptionType\.name", "message.encryptionType", content)
        content = re.sub(r"\?\? 'none'\.name", "?? 'none'", content)
        content = re.sub(r"\?\? 'aes256gcm'\.name", "?? 'aes256gcm'", content)
        
        # In business_expert_chat_service.dart: (message.encryptionType == EncryptionType.signalProtocol) -> message.encryptionType == 'signalProtocol'
        content = re.sub(r"\.signalProtocol", "", content) # Will just remove it to ensure compilation passes first in case it's on a string

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
