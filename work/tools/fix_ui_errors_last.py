import re
import os

# 1. expertise_badge_widget.dart
f_badge = 'lib/presentation/widgets/expertise/expertise_badge_widget.dart'
if os.path.exists(f_badge):
    with open(f_badge, 'r') as f: content = f.read()
    content = content.replace("final badgeColor = badge.getColor();\n    final badgeIcon = badge.getIcon();", "final Color badgeColor = Color(badge.getColor());\n    final IconData badgeIcon = IconData(badge.getIcon(), fontFamily: 'MaterialIcons');")
    with open(f_badge, 'w') as f: f.write(content)

# 2. expertise_display_widget.dart
f_disp = 'lib/presentation/widgets/expertise/expertise_display_widget.dart'
if os.path.exists(f_disp):
    with open(f_disp, 'r') as f: content = f.read()
    content = content.replace("final badgeColor = badge.getColor();\n    final badgeIcon = badge.getIcon();", "final Color badgeColor = Color(badge.getColor());\n    final IconData badgeIcon = IconData(badge.getIcon(), fontFamily: 'MaterialIcons');")
    with open(f_disp, 'w') as f: f.write(content)

# 3. knot_3d_widget.dart
f_knot = 'lib/presentation/widgets/knot/knot_3d_widget.dart'
if os.path.exists(f_knot):
    with open(f_knot, 'r') as f: content = f.read()
    content = content.replace("widget.color?.toHex()", "widget.color?.value")
    content = content.replace("AppColors.electricGreen.toHex()", "AppColors.electricGreen.value")
    with open(f_knot, 'w') as f: f.write(content)

# 4. knot_birth_experience_widget.dart
f_birth = 'lib/presentation/widgets/onboarding/knot_birth_experience_widget.dart'
if os.path.exists(f_birth):
    with open(f_birth, 'r') as f: content = f.read()
    content = content.replace("AppColors.electricGreen.toHex()", "AppColors.electricGreen.value")
    with open(f_birth, 'w') as f: f.write(content)

print("Applied final UI fixes 2")
