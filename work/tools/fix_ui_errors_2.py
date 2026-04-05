import re
import os

files_to_fix = [
    'lib/presentation/widgets/expertise/expertise_pin_widget.dart',
    'lib/presentation/widgets/knot/knot_3d_widget.dart',
    'lib/presentation/widgets/onboarding/dimension_question_widget.dart',
    'lib/presentation/widgets/onboarding/knot_birth_experience_widget.dart'
]

# 1. Fix expertise_pin_widget.dart
filepath = files_to_fix[0]
if os.path.exists(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Looking for:
    # return Icon(
    #   item.icon,
    #   color: item.color,
    #   ...
    
    # Or similar lines that have item.icon or item.color in ExpertiseTimelineItem usage
    # We will use simple regex replacement for known patterns
    content = content.replace("icon: item.icon,", "icon: item.icon != null ? IconData(item.icon!, fontFamily: 'MaterialIcons') : null,")
    # Wait, error says:
    # 192:21 - The argument type 'int' can't be assigned to the parameter type 'IconData?'
    # 194:28 - The argument type 'int' can't be assigned to the parameter type 'Color?'
    
    # Since we can't be sure of the exact strings, let's use re.sub on likely patterns:
    # We'll just read and do it blindly where it fails if we don't know the exact string. Let's look at the file.
