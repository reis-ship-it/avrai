import re
import os

filepaths = [
    'lib/presentation/widgets/search/hybrid_search_results.dart',
    'lib/presentation/widgets/spots/recommendation_attribution_chip.dart',
    'lib/presentation/widgets/settings/cross_app_learning_insights_widget.dart',
    'lib/presentation/widgets/settings/learning_effectiveness_widget.dart'
]

# 1. Create UI extension file
os.makedirs('lib/presentation/utils', exist_ok=True)
with open('lib/presentation/utils/cross_app_ui_extensions.dart', 'w', encoding='utf-8') as f:
    f.write("""import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';

extension CrossAppDataSourceUIExtension on CrossAppDataSource {
  String get displayName {
    switch (this) {
      case CrossAppDataSource.calendar: return 'Calendar';
      case CrossAppDataSource.health: return 'Health & Fitness';
      case CrossAppDataSource.media: return 'Music & Media';
      case CrossAppDataSource.appUsage: return 'App Usage';
      case CrossAppDataSource.location: return 'Location History';
      case CrossAppDataSource.contacts: return 'Contacts & Network';
      case CrossAppDataSource.browserHistory: return 'Browser History';
      case CrossAppDataSource.external: return 'External Source';
    }
  }
}
""")

# 2. Fix search results
with open(filepaths[0], 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("backgroundColor: indicator.badgeColor,", "backgroundColor: Color(indicator.badgeColor),")
content = content.replace("indicator.badgeIcon,", "IconData(indicator.badgeIcon, fontFamily: 'MaterialIcons'),")
with open(filepaths[0], 'w', encoding='utf-8') as f:
    f.write(content)

# 3. Fix attribution chip
with open(filepaths[1], 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("factor.icon,", "IconData(factor.icon, fontFamily: 'MaterialIcons'),")
with open(filepaths[1], 'w', encoding='utf-8') as f:
    f.write(content)

# 4. Fix insights widget
with open(filepaths[2], 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("import 'package:avrai/theme/colors.dart';", "import 'package:avrai/theme/colors.dart';\nimport 'package:avrai/presentation/utils/cross_app_ui_extensions.dart';")
with open(filepaths[2], 'w', encoding='utf-8') as f:
    f.write(content)

# 5. Fix effectiveness widget
with open(filepaths[3], 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("import 'package:avrai/theme/colors.dart';", "import 'package:avrai/theme/colors.dart';\nimport 'package:avrai/presentation/utils/cross_app_ui_extensions.dart';")
# Add switch cases
switch_str = """      case CrossAppDataSource.appUsage:
        return AppColors.success;"""
new_switch = """      case CrossAppDataSource.appUsage:
        return AppColors.success;
      case CrossAppDataSource.location:
        return AppColors.primary;
      case CrossAppDataSource.contacts:
        return AppColors.secondary;
      case CrossAppDataSource.browserHistory:
        return AppColors.warning;
      case CrossAppDataSource.external:
        return AppColors.grey600;"""
content = content.replace(switch_str, new_switch)
with open(filepaths[3], 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed UI errors")
