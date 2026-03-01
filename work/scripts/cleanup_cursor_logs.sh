#!/bin/bash
# Cleanup script for Cursor debug logs
# Run this periodically to prevent log accumulation

CURSOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.cursor"
LOG_FILE="$CURSOR_DIR/debug.log"

if [ -f "$LOG_FILE" ]; then
    # Get file size in bytes
    SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null)
    
    # If file is larger than 10MB, truncate it instead of deleting
    if [ "$SIZE" -gt 10485760 ]; then
        echo "Log file is large ($(numfmt --to=iec-i --suffix=B $SIZE 2>/dev/null || echo "${SIZE} bytes")). Truncating..."
        > "$LOG_FILE"
        echo "Log file truncated."
    else
        echo "Deleting debug log file..."
        rm -f "$LOG_FILE"
        echo "Debug log deleted."
    fi
else
    echo "No debug log file found at $LOG_FILE"
fi

# Also clean up any other .log files in .cursor directory
find "$CURSOR_DIR" -name "*.log" -type f -delete 2>/dev/null
echo "Cleanup complete."
