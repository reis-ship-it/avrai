#!/bin/bash

# Retry wrapper for background agent commands
MAX_ATTEMPTS=3
RETRY_DELAY=5

retry_command() {
    local cmd="$1"
    local attempt=1
    
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        echo "Attempt $attempt of $MAX_ATTEMPTS: $cmd"
        
        if eval "$cmd"; then
            echo "✅ Command succeeded on attempt $attempt"
            return 0
        else
            echo "❌ Command failed on attempt $attempt"
            
            if [ $attempt -lt $MAX_ATTEMPTS ]; then
                echo "Waiting $RETRY_DELAY seconds before retry..."
                sleep $RETRY_DELAY
                RETRY_DELAY=$((RETRY_DELAY * 2))  # Exponential backoff
            fi
            
            attempt=$((attempt + 1))
        fi
    done
    
    echo "❌ Command failed after $MAX_ATTEMPTS attempts"
    return 1
}

# Usage: retry_command "flutter test"
