import re
import os

# 1. knot_3d_widget.dart
f_knot = 'lib/presentation/widgets/knot/knot_3d_widget.dart'
if os.path.exists(f_knot):
    with open(f_knot, 'r') as f: content = f.read()
    content = content.replace("package:avrai/theme/colors.dart';", "package:avrai/theme/colors.dart';\nimport 'package:avrai/presentation/utils/color_extensions.dart';")
    with open(f_knot, 'w') as f: f.write(content)

# 2. dimension_question_widget.dart
f_dim = 'lib/presentation/widgets/onboarding/dimension_question_widget.dart'
if os.path.exists(f_dim):
    with open(f_dim, 'r') as f: content = f.read()
    content = content.replace("Icon(config.lowIcon, color: AppColors.textSecondary)", "Icon(IconData(config.lowIcon!, fontFamily: 'MaterialIcons'), color: AppColors.textSecondary)")
    content = content.replace("Icon(config.highIcon, color: AppColors.textSecondary)", "Icon(IconData(config.highIcon!, fontFamily: 'MaterialIcons'), color: AppColors.textSecondary)")
    content = re.sub(r"Icon\(\s*option\.icon,\s*color:(.*?),\s*size: 20,\s*\)", r"Icon(IconData(option.icon!, fontFamily: 'MaterialIcons'), color:\1, size: 20,)", content, flags=re.DOTALL)
    with open(f_dim, 'w') as f: f.write(content)

# 3. knot_birth_experience_widget.dart
f_birth = 'lib/presentation/widgets/onboarding/knot_birth_experience_widget.dart'
if os.path.exists(f_birth):
    with open(f_birth, 'r') as f: content = f.read()
    content = content.replace("package:avrai/theme/colors.dart';", "package:avrai/theme/colors.dart';\nimport 'package:avrai/presentation/utils/color_extensions.dart';")
    with open(f_birth, 'w') as f: f.write(content)

# 4. learning_timeline_page.dart
f_timeline = 'lib/presentation/pages/settings/learning_timeline_page.dart'
if os.path.exists(f_timeline):
    with open(f_timeline, 'r') as f: content = f.read()
    content = content.replace("import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service.dart';\n", "")
    content = content.replace("import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';", "import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';\nimport 'package:avrai/presentation/utils/cross_app_ui_extensions.dart';")
    with open(f_timeline, 'w') as f: f.write(content)

# 5. cross_app_settings_page.dart
f_cross_settings = 'lib/presentation/pages/settings/cross_app_settings_page.dart'
if os.path.exists(f_cross_settings):
    with open(f_cross_settings, 'r') as f: content = f.read()
    if "import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:avrai_core/models/misc/cross_app_learning_insight.dart';")
    with open(f_cross_settings, 'w') as f: f.write(content)

# 6. cross_app_learning_page.dart
f_cross_learning = 'lib/presentation/pages/onboarding/cross_app_learning_page.dart'
if os.path.exists(f_cross_learning):
    with open(f_cross_learning, 'r') as f: content = f.read()
    if "import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:avrai_core/models/misc/cross_app_learning_insight.dart';")
    with open(f_cross_learning, 'w') as f: f.write(content)

# 7. combined_permissions_page.dart
f_combined = 'lib/presentation/pages/onboarding/combined_permissions_page.dart'
if os.path.exists(f_combined):
    with open(f_combined, 'r') as f: content = f.read()
    if "import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:avrai_core/models/misc/cross_app_learning_insight.dart';")
    with open(f_combined, 'w') as f: f.write(content)

# Remove unused imports from other specified files
files_to_clean = [
    'lib/presentation/widgets/settings/cross_app_learning_insights_widget.dart',
    'lib/presentation/widgets/settings/learning_effectiveness_widget.dart',
    'runtime/avrai_runtime_os/lib/services/cross_app/cross_app_permission_monitor.dart'
]
for f_clean in files_to_clean:
    if os.path.exists(f_clean):
        with open(f_clean, 'r') as f: content = f.read()
        content = content.replace("import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service.dart';\n", "")
        with open(f_clean, 'w') as f: f.write(content)

print("Applied final UI fixes")
