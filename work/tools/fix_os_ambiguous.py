import os
import re

files_to_fix = [
    'runtime/avrai_runtime_os/lib/services/cross_app/cross_app_consent_service.dart',
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Remove local enum definition of CrossAppDataSource from cross_app_consent_service
        # (It seems previous regex might have missed it if spaces/newlines were different)
        content = re.sub(r'/// Types of cross-app data sources used for learning\s*enum CrossAppDataSource \{[^\}]+\}\s*', '', content)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
