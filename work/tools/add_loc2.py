import re
import os

files_to_fix = [
    'runtime/avrai_runtime_os/lib/services/cross_app/cross_app_consent_service.dart',
    'runtime/avrai_runtime_os/lib/services/cross_app/cross_app_permission_monitor.dart'
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Add contacts to cross_app_consent_service.dart
        content = re.sub(
            r"case CrossAppDataSource\.location:\n\s*return true;",
            "case CrossAppDataSource.location:\n        return true;\n      case CrossAppDataSource.contacts:\n        return true;",
            content
        )
        content = re.sub(
            r"case CrossAppDataSource\.location:\n\s*// TODO: Handle location pref\n\s*break;",
            "case CrossAppDataSource.location:\n        break;\n      case CrossAppDataSource.contacts:\n        break;",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")

# For cross_app_permission_monitor.dart, let's just use view_file and multi_replace_file_content to be safer
