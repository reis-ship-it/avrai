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

        # Fix assignment from getEncryptionType -> `.name`
        content = re.sub(r"MessageEncryptionService\.getEncryptionType(\([^)]+\))(?![\.\w])", r"MessageEncryptionService.getEncryptionType\1.name", content)
        
        # In chat services, fixing list element typed issues
        # e.g., final encryptionTypeStr = <String>['none', 'aes256gcm'].firstWhere((e) => e == message.encryptionType, orElse: () => 'aes256gcm');
        content = re.sub(r"final encryptionTypeStr = \['none', 'aes256gcm'\]\.firstWhere", "final encryptionTypeStr = <String>['none', 'aes256gcm'].firstWhere", content)

        # Fix EncryptionType.values.firstWhere => <String>['none', 'aes256gcm'].firstWhere
        content = re.sub(r"EncryptionType\.values\.firstWhere", "<String>['none', 'aes256gcm'].firstWhere", content)

        # Fix where we added `.name` to encryptionType argument by mistake instead of just changing parameter type
        content = re.sub(r"EncryptionType\.values\.firstWhere\(\(e\) => e\.name == encryptionType, orElse: \(\) => EncryptionType\.aes256gcm\)", 
                         r"EncryptionType.values.firstWhere((e) => e.name == encryptionType, orElse: () => EncryptionType.aes256gcm)", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
