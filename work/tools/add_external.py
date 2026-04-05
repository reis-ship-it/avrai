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

        # Add external 
        content = re.sub(
            r"case CrossAppDataSource\.browserHistory:\n\s*return true;",
            "case CrossAppDataSource.browserHistory:\n        return true;\n      case CrossAppDataSource.external:\n        return true;",
            content
        )
        content = re.sub(
            r"case CrossAppDataSource\.browserHistory:\n\s*break;",
            "case CrossAppDataSource.browserHistory:\n        break;\n      case CrossAppDataSource.external:\n        break;",
            content
        )
        content = re.sub(
            r"case CrossAppDataSource\.browserHistory:\n\s*return null; // no standard perm",
            "case CrossAppDataSource.browserHistory:\n        return null; // no standard perm\n      case CrossAppDataSource.external:\n        return null; // external source",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
