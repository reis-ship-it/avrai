import os
import re

files_to_fix = [
    'shared/avrai_core/lib/models/misc/cross_app_learning_insight.dart',
    'shared/avrai_core/lib/models/misc/world_plane_view_state.dart',
    'shared/avrai_core/lib/models/quantum/recommendation_attribution.dart'
]

for filepath in files_to_fix:
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Remove cross_app_consent_service import
        content = re.sub(r"import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service\.dart';\n?", "", content)

        # CrossAppDataSource enum fix (since it was imported from cross_app_consent_service)
        if "CrossAppDataSource" in content and "enum CrossAppDataSource" not in content:
            content += "\n\n/// Types of cross-app data sources used for learning\nenum CrossAppDataSource {\n  calendar,\n  health,\n  media,\n  appUsage,\n  location,\n  contacts,\n  browserHistory,\n  external,\n}\n\n/// Extensions for cross-app data source\nextension CrossAppDataSourceExtension on CrossAppDataSource {\n  String get icon {\n    switch (this) {\n      case CrossAppDataSource.calendar:\n        return 'calendar';\n      case CrossAppDataSource.health:\n        return 'health';\n      case CrossAppDataSource.media:\n        return 'media';\n      case CrossAppDataSource.appUsage:\n        return 'appUsage';\n      case CrossAppDataSource.location:\n        return 'location';\n      case CrossAppDataSource.contacts:\n        return 'contacts';\n      case CrossAppDataSource.browserHistory:\n        return 'browserHistory';\n      case CrossAppDataSource.external:\n        return 'external';\n    }\n  }\n}\n"
        
        # fix knot_worldsheet
        if filepath.endswith('world_plane_view_state.dart'):
            content = re.sub(r"final KnotWorldsheet worldsheet;\n?", "", content)
            content = re.sub(r"required this.worldsheet,\n?", "", content)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Fixed {filepath}")
