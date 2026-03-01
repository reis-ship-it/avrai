#!/bin/bash
# Fix all print() statements in production code by replacing with developer.log()

set -e

echo "🔧 Fixing all print() statements in production code..."

# Find all print() statements in lib/ and packages/ (excluding test/ and examples/)
find lib packages -name "*.dart" \
  -not -path "*/test/*" \
  -not -path "*/examples/*" \
  -not -path "*/build/*" \
  -exec grep -l "^\s*print(" {} \; | while read file; do
  
  echo "Processing: $file"
  
  # Check if file already has developer import
  if ! grep -q "import 'dart:developer'" "$file"; then
    # Add import after other dart: imports
    sed -i.bak "1a\\
import 'dart:developer' as developer;
" "$file"
  fi
  
  # Replace print() with developer.log()
  # Simple pattern: print('message') -> developer.log('message', name: 'ServiceName')
  # Get service name from file path
  service_name=$(basename "$file" .dart | sed 's/_//g' | sed 's/\b\(.\)/\u\1/g')
  
  # Replace print statements (basic pattern)
  sed -i.bak "s/print('\([^']*\)');/developer.log('\1', name: '$service_name');/g" "$file"
  sed -i.bak 's/print("\([^"]*\)");/developer.log("\1", name: "$service_name");/g' "$file"
  
  # Clean up backup files
  rm -f "$file.bak"
done

echo "✅ Done fixing print() statements"
