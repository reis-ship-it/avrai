import os
import re

files_to_fix = [
    'runtime/avrai_runtime_os/lib/services/onboarding/onboarding_question_bank.dart',
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Better replace for IconData
        content = re.sub(r'Icons\.([a-zA-Z0-9_]+)', r'0', content) # dummy 0 for icon codepoint
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
