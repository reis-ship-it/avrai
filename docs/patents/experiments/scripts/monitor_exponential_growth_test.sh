#!/bin/bash
# Monitor exponential growth test and notify when complete

RESULTS_DIR="/Users/reisgordon/SPOTS/docs/patents/experiments/results/patent_3"
CHECK_INTERVAL=60  # Check every 60 seconds
MAX_CHECKS=120     # Check for up to 2 hours (120 * 60 seconds)

check_count=0

echo "======================================================================"
echo "Monitoring Exponential Growth Test"
echo "======================================================================"
echo ""
echo "Checking for results file every $CHECK_INTERVAL seconds..."
echo "Results directory: $RESULTS_DIR"
echo ""

while [ $check_count -lt $MAX_CHECKS ]; do
    # Check if results file exists
    if ls "$RESULTS_DIR"/exponential_growth_*.csv 1> /dev/null 2>&1; then
        echo ""
        echo "✅ TEST COMPLETE!"
        echo "======================================================================"
        
        # Get the most recent results file
        LATEST_FILE=$(ls -t "$RESULTS_DIR"/exponential_growth_*.csv | head -1)
        
        echo "Results file: $LATEST_FILE"
        echo ""
        
        # Display results summary
        if command -v python3 &> /dev/null; then
            python3 << EOF
import pandas as pd
import sys

try:
    df = pd.read_csv('$LATEST_FILE')
    print("📊 RESULTS SUMMARY:")
    print("=" * 70)
    for col in df.columns:
        if df[col].dtype in ['float64', 'int64']:
            value = df[col].iloc[0]
            if 'homogenization' in col.lower():
                print(f"  {col}: {value:.4f} ({value*100:.2f}%)")
            elif 'improvement' in col.lower() or 'prevention' in col.lower():
                print(f"  {col}: {value:.4f} ({value*100:.2f}%)")
            elif 'time' in col.lower():
                print(f"  {col}: {value:.2f} seconds ({value/60:.2f} minutes)")
            else:
                print(f"  {col}: {value}")
    print("=" * 70)
except Exception as e:
    print(f"Error reading results: {e}")
EOF
        fi
        
        # Send macOS notification
        osascript -e "display notification \"Exponential growth test complete! Results saved to: $LATEST_FILE\" with title \"Patent #3 Test Complete\" sound name \"Glass\""
        
        echo ""
        echo "✅ Notification sent!"
        exit 0
    fi
    
    # Check if process is still running
    if ! ps -p 55082 > /dev/null 2>&1; then
        echo ""
        echo "⚠️  Process no longer running, but results file not found."
        echo "   The test may have encountered an error."
        echo ""
        osascript -e "display notification \"Test process stopped but no results found. Check for errors.\" with title \"Patent #3 Test Status\" sound name \"Basso\""
        exit 1
    fi
    
    check_count=$((check_count + 1))
    elapsed_minutes=$((check_count * CHECK_INTERVAL / 60))
    
    if [ $((check_count % 5)) -eq 0 ]; then
        echo "[$(date +%H:%M:%S)] Still running... (checked $check_count times, ~${elapsed_minutes} minutes elapsed)"
    fi
    
    sleep $CHECK_INTERVAL
done

echo ""
echo "⏰ Maximum check time reached ($MAX_CHECKS checks = $((MAX_CHECKS * CHECK_INTERVAL / 60)) minutes)"
echo "   Test may still be running. Check manually."
echo ""
osascript -e "display notification \"Monitoring timeout reached. Test may still be running.\" with title \"Patent #3 Test Monitor\" sound name \"Basso\""
exit 2

