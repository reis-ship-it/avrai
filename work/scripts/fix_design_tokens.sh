#!/bin/bash
# Design Token Compliance Fix Script (Bash wrapper)
# 
# Wrapper script for the Python design token fixer
# Provides easy access and common usage patterns

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/fix_design_tokens.py"

cd "$PROJECT_ROOT"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required but not found"
    exit 1
fi

# Parse arguments
DRY_RUN=""
BACKUP=""
PATH_ARG="lib/"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        --backup)
            BACKUP="--backup"
            shift
            ;;
        --path)
            PATH_ARG="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be changed without making changes"
            echo "  --backup     Create backup files before modifying"
            echo "  --path PATH  Specific path to process (default: lib/)"
            echo "  --help, -h   Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --dry-run                    # See what would change"
            echo "  $0 --backup                     # Apply changes with backups"
            echo "  $0 --path lib/presentation      # Process specific directory"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build command
CMD="python3 $PYTHON_SCRIPT"
if [ -n "$DRY_RUN" ]; then
    CMD="$CMD $DRY_RUN"
fi
if [ -n "$BACKUP" ]; then
    CMD="$CMD $BACKUP"
fi
CMD="$CMD --path $PATH_ARG"

echo "Running design token fixer..."
echo "Command: $CMD"
echo ""

# Run the Python script
$CMD

