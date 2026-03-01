import os
import re

files_to_fix = [
    'runtime/avrai_runtime_os/lib/models/quantum/recommendation_attribution.dart',
    'runtime/avrai_runtime_os/lib/models/spots/source_indicator.dart',
    'runtime/avrai_runtime_os/lib/models/misc/visualization_style.dart',
    'runtime/avrai_runtime_os/lib/models/misc/motion_reactivity_config.dart',
    'runtime/avrai_runtime_os/lib/models/user/dimension_question.dart',
    'runtime/avrai_runtime_os/lib/models/expertise/expertise_pin.dart'
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Remove flutter/material import
        content = re.sub(r"import 'package:flutter/material\.dart';\n?", "", content)

        # Remove cross_app_consent_service import
        content = re.sub(r"import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service\.dart';\n?", "", content)

        # Replace Color with int
        content = content.replace("final Color ", "final int ")
        content = content.replace("Color get", "int get")
        
        # Better replace for Color(0xFF...)
        content = re.sub(r'const Color\((0x[A-Fa-f0-9]+)\)', r'\1', content)
        content = re.sub(r'Color\((0x[A-Fa-f0-9]+)\)', r'\1', content)

        # Better replace for IconData
        content = content.replace("final IconData ", "final int ")
        content = content.replace("IconData get", "int get")
        content = content.replace("final IconData? ", "final int? ")
        content = content.replace("IconData? get", "int? get")
        content = re.sub(r'Icons\.([a-zA-Z0-9_]+)', r'0', content) # dummy 0 for icon codepoint
        
        # CrossAppDataSource enum fix (since it was imported from cross_app_consent_service)
        if "CrossAppDataSource" in content and "enum CrossAppDataSource" not in content:
            content += "\n\n/// Types of cross-app data sources used for learning\nenum CrossAppDataSource {\n  calendar,\n  health,\n  media,\n  appUsage,\n  location,\n  contacts,\n  browserHistory,\n  external,\n}\n\n/// Extensions for cross-app data source\nextension CrossAppDataSourceExtension on CrossAppDataSource {\n  String get icon {\n    switch (this) {\n      case CrossAppDataSource.calendar:\n        return 'calendar';\n      case CrossAppDataSource.health:\n        return 'health';\n      case CrossAppDataSource.media:\n        return 'media';\n      case CrossAppDataSource.appUsage:\n        return 'appUsage';\n      case CrossAppDataSource.location:\n        return 'location';\n      case CrossAppDataSource.contacts:\n        return 'contacts';\n      case CrossAppDataSource.browserHistory:\n        return 'browserHistory';\n      case CrossAppDataSource.external:\n        return 'external';\n    }\n  }\n}\n"
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
