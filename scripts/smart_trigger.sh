#!/bin/bash

# Smart trigger script for background agent
# Only run jobs when relevant files have changed

check_changes() {
    local file_pattern="$1"
    local description="$2"
    
    if git diff --name-only HEAD~1 | grep -q "$file_pattern"; then
        echo "✅ Changes detected in $description"
        return 0
    else
        echo "⏭️ No changes in $description, skipping"
        return 1
    fi
}

# Check for source code changes
if check_changes "lib/" "source code"; then
    echo "Running code analysis..."
    # flutter analyze
fi

# Check for test changes
if check_changes "test/" "tests"; then
    echo "Running tests..."
    # flutter test
fi

# Check for dependency changes
if check_changes "pubspec.yaml" "dependencies"; then
    echo "Running dependency check..."
    # flutter pub get
fi

echo "Smart triggering complete"
