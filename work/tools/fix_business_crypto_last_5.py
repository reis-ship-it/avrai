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

        # Fix parseEnumByName on String
        # IncomingChatPayloadHelpers.parseEnumByName(values: ['none', 'aes256gcm'], ...) won't work because parseEnumByName takes an enum values list.
        # So we just inline the logic or use String
        content = re.sub(r"final String encryptionType =\s*IncomingChatPayloadHelpers\.parseEnumByName\(\s*values: \['none', 'aes256gcm'\],\s*name: encryptionTypeStr,\s*fallback: 'aes256gcm',\s*\);", 
                         "final String encryptionType = ['none', 'aes256gcm'].contains(encryptionTypeStr) ? encryptionTypeStr! : 'aes256gcm';", content)

        # Same for expert lane
        content = re.sub(r"final String encryptionType =\s*IncomingChatPayloadHelpers\.parseEnumByName\(\s*values: \['none', 'aes256gcm'\],\s*name: encryptionTypeStr,\s*fallback: 'aes256gcm',\s*\);", 
                         "final String encryptionType = ['none', 'aes256gcm'].contains(encryptionTypeStr) ? encryptionTypeStr! : 'aes256gcm';", content)

        # Fix remaining assignments in service.dart
        # A value of type 'EncryptionType' can't be assigned to a variable of type 'String'.
        # This could be because of: String encryptionType = MessageEncryptionService.getEncryptionType(...) without the .name attached
        content = re.sub(r"String encryptionType = (MessageEncryptionService\.getEncryptionType[^\.]*);", r"String encryptionType = (\1).name;", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
