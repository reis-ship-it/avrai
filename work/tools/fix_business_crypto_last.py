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

        # Fix assignment from EncryptionType back to String (e.g. `String encryptionType = MessageEncryptionService.getEncryptionType(...)`)
        content = re.sub(r"MessageEncryptionService\.getEncryptionType", "MessageEncryptionService.getEncryptionTypeString", content)
        
        # Or if it's returning EncryptionType we just change it to .name
        content = re.sub(r"MessageEncryptionService\.getEncryptionType\((.*?)\)", r"MessageEncryptionService.getEncryptionType(\1).name", content)

        # Let's just fix the method in MessageEncryptionService later. For now, just replace EncryptionType reference in the return
        
        # 1. `A value of type 'EncryptionType' can't be assigned to a variable of type 'String'.`
        # 2. `The argument type 'String' can't be assigned to the parameter type 'EncryptionType'.`
        
        # Fix EncryptionType param types to String
        content = re.sub(r"EncryptionType\?", "String?", content)
        content = re.sub(r"EncryptionType(?![a-zA-Z])", "String", content)

        # Fix list element typed issues
        content = re.sub(r"final encryptionTypeStr = \['none', 'aes256gcm'\]\.firstWhere\((.*?)\);", r"final encryptionTypeStr = ['none', 'aes256gcm'].firstWhere((e) => e == \1, orElse: () => 'aes256gcm');", content)

        # Remove extra `.name` if it exists
        content = re.sub(r"encryptionType\.name", "encryptionType", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
