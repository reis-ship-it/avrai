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

        # Fix where we fallback on String, but we need EncryptionType enum for decrypt() param
        # Error: The argument type 'String' can't be assigned to the parameter type 'EncryptionType'.
        # This usually occurs when we are setting `encryptionType: ...` inside `EncryptedMessage`
        content = re.sub(
            r"encryptionType:\s*<String>\['none',\s*'aes256gcm'\]\.firstWhere\(\(e\)\s*=>\s*e\s*==\s*message\.encryptionType,\s*orElse:\s*\(\)\s*=>\s*'aes256gcm'\),",
            r"encryptionType: EncryptionType.values.firstWhere((e) => e.name == message.encryptionType, orElse: () => EncryptionType.aes256gcm),",
            content
        )
        
        # In business_expert_chat_service.dart: line 222 (for EncryptedMessage)
        content = re.sub(
            r"encryptionType:\s*message\.encryptionType,",
            r"encryptionType: EncryptionType.values.firstWhere((e) => e.name == message.encryptionType, orElse: () => EncryptionType.aes256gcm),",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
