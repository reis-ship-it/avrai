#!/bin/bash
# fix_test_patterns.sh
# Script to apply common pattern fixes to test files
# Usage: ./scripts/fix_test_patterns.sh

set -e

echo "🔧 Applying common test pattern fixes..."

# Pattern 1: UserActionData → UserAction
echo "  Fixing UserActionData → UserAction..."
find test/ -name "*.dart" -type f -exec sed -i '' \
  's/UserActionData(/UserAction(/g' {} \;

# Pattern 2: evolveFromUserActionData → evolveFromUserAction  
echo "  Fixing evolveFromUserActionData → evolveFromUserAction..."
find test/ -name "*.dart" -type f -exec sed -i '' \
  's/evolveFromUserActionData/evolveFromUserAction/g' {} \;

# Pattern 3: hashedUserId → fingerprint (if applicable)
echo "  Fixing hashedUserId → fingerprint..."
find test/ -name "*.dart" -type f -exec sed -i '' \
  's/\.hashedUserId/.fingerprint/g' {} \;

# Pattern 4: lastUpdated → createdAt
echo "  Fixing lastUpdated → createdAt..."
find test/ -name "*.dart" -type f -exec sed -i '' \
  's/\.lastUpdated/.createdAt/g' {} \;

# Pattern 5: confidence → authenticity
echo "  Fixing confidence → authenticity..."
find test/ -name "*.dart" -type f -exec sed -i '' \
  's/\.confidence/.authenticity/g' {} \;

# Pattern 6: Fix PersonalityLearning constructor
echo "  Fixing PersonalityLearning constructor patterns..."
find test/ -name "*.dart" -type f -exec sed -i '' \
  -e 's/PersonalityLearning(prefs: SharedPreferences\.getInstance(), prefs: mockPrefs)/PersonalityLearning.withPrefs(mockPrefs)/g' \
  -e 's/PersonalityLearning(prefs: mockPrefs)/PersonalityLearning.withPrefs(mockPrefs)/g' {} \;

echo "✅ Pattern fixes applied. Please review changes before committing."
echo "⚠️  Note: Some fixes may require manual verification, especially:"
echo "   - UserAction constructor calls (may need metadata parameter)"
echo "   - evolveFromUserAction method calls (may need parameter adjustments)"
echo "   - Property name changes (verify context)"
