import re

filepath = 'runtime/avrai_runtime_os/lib/services/cross_app/cross_app_consent_service.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import back since we removed it globally
content = "import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';\n" + content

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
