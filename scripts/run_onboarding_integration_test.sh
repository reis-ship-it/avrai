#!/bin/bash

# SPOTS Onboarding Flow Integration Test Runner
# 
# This script runs the complete onboarding flow integration test
# 
# Usage:
#   ./scripts/run_onboarding_integration_test.sh [device-id]
# 
# Examples:
#   ./scripts/run_onboarding_integration_test.sh                    # Run on default device
#   ./scripts/run_onboarding_integration_test.sh chrome             # Run on Chrome
#   ./scripts/run_onboarding_integration_test.sh ios                # Run on iOS simulator

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 SPOTS Onboarding Flow Integration Test${NC}"
echo ""

# Check if device ID is provided
DEVICE_ID="${1:-}"

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_DIR"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Running onboarding flow integration test...${NC}"
echo ""

# Run the integration test
if [ -z "$DEVICE_ID" ]; then
    echo -e "${GREEN}Running on default device...${NC}"
    flutter test integration_test/onboarding_flow_complete_integration_test.dart
else
    echo -e "${GREEN}Running on device: $DEVICE_ID${NC}"
    flutter test integration_test/onboarding_flow_complete_integration_test.dart --device-id="$DEVICE_ID"
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Integration test completed successfully!${NC}"
else
    echo ""
    echo -e "${YELLOW}⚠️ Integration test failed with exit code: $EXIT_CODE${NC}"
fi

exit $EXIT_CODE
