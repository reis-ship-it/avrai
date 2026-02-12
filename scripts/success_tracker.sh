#!/bin/bash

# Success rate tracking script

echo "📈 Tracking success rates..."

# Create tracking directory
mkdir -p logs/tracking

# Record job result
JOB_ID=$(date +%Y%m%d_%H%M%S)
JOB_STATUS="$1"  # Pass status as argument
TIMESTAMP=$(date)

echo "$JOB_ID,$JOB_STATUS,$TIMESTAMP" >> logs/tracking/success_rates.csv

# Calculate success rate
TOTAL_JOBS=$(wc -l < logs/tracking/success_rates.csv)
SUCCESSFUL_JOBS=$(grep -c "success" logs/tracking/success_rates.csv || echo "0")
SUCCESS_RATE=$((SUCCESSFUL_JOBS * 100 / TOTAL_JOBS))

echo "Success Rate: ${SUCCESS_RATE}% (${SUCCESSFUL_JOBS}/${TOTAL_JOBS})"

echo "✅ Success rate tracking complete"
