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

        # Add browserHistory
        content = re.sub(
            r"case CrossAppDataSource\.contacts:\n\s*return true;",
            "case CrossAppDataSource.contacts:\n        return true;\n      case CrossAppDataSource.browserHistory:\n        return true;",
            content
        )
        content = re.sub(
            r"case CrossAppDataSource\.contacts:\n\s*break;",
            "case CrossAppDataSource.contacts:\n        break;\n      case CrossAppDataSource.browserHistory:\n        break;",
            content
        )
        content = re.sub(
            r"case CrossAppDataSource\.contacts:\n\s*return perm\.Permission\.contacts;",
            "case CrossAppDataSource.contacts:\n        return perm.Permission.contacts;\n      case CrossAppDataSource.browserHistory:\n        return null; // no standard perm",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
