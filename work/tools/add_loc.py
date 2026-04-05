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

        # Add location cases to switch statements in cross_app_consent_service.dart
        content = re.sub(
            r"case CrossAppDataSource\.appUsage:\n\s*return _prefs!\.getBool\(_keyAppUsageEnabled\) \?\? true;",
            "case CrossAppDataSource.appUsage:\n        return _prefs!.getBool(_keyAppUsageEnabled) ?? true;\n      case CrossAppDataSource.location:\n        return true; // or whatever the default should be",
            content
        )
        
        content = re.sub(
            r"case CrossAppDataSource\.appUsage:\n\s*await _prefs!\.setBool\(_keyAppUsageEnabled, enabled\);\n\s*break;",
            "case CrossAppDataSource.appUsage:\n        await _prefs!.setBool(_keyAppUsageEnabled, enabled);\n        break;\n      case CrossAppDataSource.location:\n        // TODO: Handle location pref\n        break;",
            content
        )

        # In cross_app_permission_monitor.dart 
        content = re.sub(
            r"case CrossAppDataSource\.appUsage:\n\s*return Permission\.activityRecognition;",
            "case CrossAppDataSource.appUsage:\n        return Permission.activityRecognition;\n      case CrossAppDataSource.location:\n        return Permission.location;",
            content
        )

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
