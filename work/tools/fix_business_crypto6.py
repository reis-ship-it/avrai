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

        # Fix issues reported by analyzer
        content = re.sub(r"= 'aes256gcm' //aes256gcm", "= 'aes256gcm'", content) 
        
        # In chat services, fixing the assignment `String encryptionType = message.encryptionType ?? 'none';` or similar
        content = re.sub(r"message\.encryptionType \?\? 'none'", "message.encryptionType", content) 
        
        # Ensure EncryptionType is removed from method signatures as well
        content = re.sub(r"EncryptionType\?", "String?", content)
        content = re.sub(r"EncryptionType(?=[ >)])", "String", content)

        # Fix List<String> assignments
        content = re.sub(r"final encryptionTypeStr = \['none', 'aes256gcm'\]\.firstWhere\((.*?)\);", r"final encryptionTypeStr = ['none', 'aes256gcm'].firstWhere(\1);", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
