#!/bin/bash

# Pattern recognition script
# Learns from recurring issues

echo "🧠 Running pattern recognition..."

# Create patterns directory
mkdir -p logs/patterns

# Analyze current issues
flutter analyze > logs/current_analysis.log 2>&1 || true

# Extract issue patterns
grep -o "error.*" logs/current_analysis.log | sort | uniq -c > logs/patterns/current_patterns.txt

# Compare with historical patterns
if [ -f logs/patterns/historical_patterns.txt ]; then
    echo "Comparing with historical patterns..."
    diff logs/patterns/historical_patterns.txt logs/patterns/current_patterns.txt || true
else
    echo "No historical patterns found, creating baseline..."
    cp logs/patterns/current_patterns.txt logs/patterns/historical_patterns.txt
fi

# Update historical patterns
cp logs/patterns/current_patterns.txt logs/patterns/historical_patterns.txt

echo "✅ Pattern recognition complete"
