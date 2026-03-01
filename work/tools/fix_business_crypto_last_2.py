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

        # Fix assignment from getEncryptionType
        # The return value from getEncryptionType is still the enum EncryptionType
        # We need to add `.name` to that method call
        content = re.sub(r'(MessageEncryptionService\.getEncryptionType\([^)]+\))(?![\.\w])', r'\1.name', content)

        # Let's fix the parameter type passed into MessageEncryptionService.encryptMessage / decryptMessage inside the chat services
        # If encryptMessage takes an EncryptionType, but we are passing a String, we might need to convert it, or change the MessageEncryptionService
        # If it doesn't compile, it's easier to change: `EncryptionType.values.firstWhere((e) => e.name == encryptionType, orElse: () => EncryptionType.none)`
        
        # Actually it says: `The argument type 'String' can't be assigned to the parameter type 'EncryptionType'` for line 326 (encryptMessage)
        content = re.sub(r'(MessageEncryptionService\.encryptMessage\([^,]+,\s*[^,]+,\s*[^,]+,\s*)encryptionType',
                         r"\1EncryptionType.values.firstWhere((e) => e.name == encryptionType, orElse: () => EncryptionType.aes256gcm)", content)
                         
        content = re.sub(r'(MessageEncryptionService\.encryptMessage\(\s*[^,]+,\s*)encryptionType',
                         r"\1EncryptionType.values.firstWhere((e) => e.name == encryptionType, orElse: () => EncryptionType.aes256gcm)", content)
        
        # We need to make sure EncryptionType enum is imported where we're going to use it this way, but it should be since it was used before.

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
