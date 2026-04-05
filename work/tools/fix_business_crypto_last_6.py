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

        # Fix final remaining EncryptionType to String assignments where encrypt() returns EncryptedMessage which has an EncryptionType enum not a String
        # The line is usually `encryptionType = encrypted.encryptionType;` where `encryptionType` is a `String`.
        content = re.sub(r"encryptionType = encrypted.encryptionType;", r"encryptionType = encrypted.encryptionType.name;", content)

        # Let's fix decrypt() where we passed the parsed string but decrypt expects an EncryptedMessage which expects EncryptionType
        # The line looks like:
        # encryptionType: <String>['none', 'aes256gcm'].firstWhere((e) => e == message.encryptionType, orElse: () => 'aes256gcm'),
        # or similar inside the `EncryptedMessage( ... )` constructor call. We need it to be EncryptionType.aes256gcm etc.
        # But wait, we imported EncryptionType in `avrai_network`. 
        content = re.sub(
            r"encryptionType:\s*<String>\['none',\s*'aes256gcm'\]\.firstWhere\(\(e\)\s*=>\s*e\s*==\s*message\.encryptionType,\s*orElse:\s*\(\)\s*=>\s*'aes256gcm'\),",
            r"encryptionType: EncryptionType.values.firstWhere((e) => e.name == message.encryptionType, orElse: () => EncryptionType.aes256gcm),",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
