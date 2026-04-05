#!/bin/bash

# SPOTS Integration Test Runner - iOS Simulator
# 
# This script runs integration tests using flutter drive on iOS Simulator
# Automatically launches iOS simulator if not running
# 
# Usage:
#   ./scripts/run_integration_test_ios.sh [test_file] [simulator_name]
# 
# Examples:
#   ./scripts/run_integration_test_ios.sh                                    # Run deployment_readiness_test on default simulator
#   ./scripts/run_integration_test_ios.sh deployment_readiness_test.dart      # Run specific test
#   ./scripts/run_integration_test_ios.sh onboarding_flow_integration_test.dart "iPhone 15 Pro"

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍎 SPOTS Integration Test Runner - iOS Simulator${NC}"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

cd "$PROJECT_DIR"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

# Check if running on macOS (required for iOS)
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ iOS testing requires macOS${NC}"
    exit 1
fi

# Default test file
DEFAULT_TEST="test/integration/deployment_readiness_test.dart"
TEST_FILE="${1:-$DEFAULT_TEST}"
SIMULATOR_NAME="${2:-}"

# Convert relative path to full path if needed
if [[ ! "$TEST_FILE" =~ ^/ ]]; then
    if [[ ! "$TEST_FILE" =~ ^test/ ]]; then
        TEST_FILE="test/integration/$TEST_FILE"
    fi
fi

# Check if test file exists
if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}❌ Test file not found: $TEST_FILE${NC}"
    echo -e "${YELLOW}Available test files in test/integration/:${NC}"
    ls -1 test/integration/*.dart 2>/dev/null | head -10 || echo "No test files found"
    exit 1
fi

echo -e "${BLUE}📋 Test file: $TEST_FILE${NC}"
echo ""

# Function to check if simulator is booted
is_simulator_booted() {
    xcrun simctl list devices | grep -i "booted" | grep -q "iPhone" || return 1
}

# Function to get booted simulator UDID
get_booted_simulator() {
    xcrun simctl list devices | grep -i "booted" | grep "iPhone" | head -1 | sed -E 's/.*\(([^)]+)\).*/\1/'
}

# Check if iOS simulator is already running
if is_simulator_booted; then
    BOOTED_SIM=$(get_booted_simulator)
    echo -e "${GREEN}✅ iOS Simulator already running (UDID: $BOOTED_SIM)${NC}"
else
    echo -e "${BLUE}📱 No iOS simulator running. Launching simulator...${NC}"
    
    # List available simulators
    echo -e "${BLUE}Available iOS simulators:${NC}"
    xcrun simctl list devices available | grep -i "iphone" | head -5
    
    # Launch simulator
    if [ -z "$SIMULATOR_NAME" ]; then
        # Use default or first available iPhone
        SIMULATOR_NAME=$(xcrun simctl list devices available | grep -i "iphone" | head -1 | sed -E 's/.*\(([^)]+)\) - (.*)/\2/' | xargs)
        if [ -z "$SIMULATOR_NAME" ]; then
            SIMULATOR_NAME="iPhone 15 Pro"  # Default fallback
        fi
    fi
    
    echo -e "${BLUE}🚀 Launching simulator: $SIMULATOR_NAME${NC}"
    
    # Open Simulator app
    open -a Simulator
    
    # Wait a bit for Simulator to start
    sleep 3
    
    # Boot the simulator
    SIMULATOR_UDID=$(xcrun simctl list devices available | grep -i "$SIMULATOR_NAME" | head -1 | sed -E 's/.*\(([^)]+)\).*/\1/')
    
    if [ -z "$SIMULATOR_UDID" ]; then
        echo -e "${YELLOW}⚠️  Simulator '$SIMULATOR_NAME' not found. Using first available iPhone...${NC}"
        SIMULATOR_UDID=$(xcrun simctl list devices available | grep -i "iphone" | head -1 | sed -E 's/.*\(([^)]+)\).*/\1/')
    fi
    
    if [ -z "$SIMULATOR_UDID" ]; then
        echo -e "${RED}❌ No iOS simulators found. Please create one in Xcode.${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}📱 Booting simulator (UDID: $SIMULATOR_UDID)...${NC}"
    xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || echo -e "${YELLOW}⚠️  Simulator may already be booting...${NC}"
    
    # Wait for simulator to be ready
    echo -e "${BLUE}⏳ Waiting for simulator to be ready (this may take 30-60 seconds)...${NC}"
    MAX_WAIT=120
    ELAPSED=0
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        if is_simulator_booted; then
            echo -e "${GREEN}✅ Simulator is ready!${NC}"
            break
        fi
        sleep 2
        ELAPSED=$((ELAPSED + 2))
        if [ $((ELAPSED % 10)) -eq 0 ]; then
            echo -e "${BLUE}   Still waiting... (${ELAPSED}s)${NC}"
        fi
    done
    
    if ! is_simulator_booted; then
        echo -e "${RED}❌ Simulator failed to boot within ${MAX_WAIT} seconds${NC}"
        exit 1
    fi
fi

echo ""

# Check if test uses IntegrationTestWidgetsFlutterBinding
if grep -q "IntegrationTestWidgetsFlutterBinding" "$TEST_FILE"; then
    echo -e "${GREEN}✅ Test uses IntegrationTestWidgetsFlutterBinding (correct for flutter drive)${NC}"
elif grep -q "TestWidgetsFlutterBinding" "$TEST_FILE"; then
    echo -e "${YELLOW}⚠️  Test uses TestWidgetsFlutterBinding. Consider converting to IntegrationTestWidgetsFlutterBinding for flutter drive.${NC}"
    echo -e "${YELLOW}   Continuing anyway...${NC}"
fi

echo ""

# Verify Flutter can see the iOS device
echo -e "${BLUE}🔍 Verifying Flutter can see iOS device...${NC}"
if ! flutter devices | grep -qi "ios"; then
    echo -e "${YELLOW}⚠️  iOS device not found in 'flutter devices'. Waiting a bit more...${NC}"
    sleep 5
    if ! flutter devices | grep -qi "ios"; then
        echo -e "${RED}❌ iOS device still not found. Try:${NC}"
        echo -e "   1. Make sure Simulator is fully booted"
        echo -e "   2. Run: flutter devices"
        echo -e "   3. If still not found, try: flutter doctor"
        exit 1
    fi
fi

echo -e "${GREEN}✅ iOS device found${NC}"
echo ""

# Check if integration_test driver exists
DRIVER_FILE="integration_test_driver/integration_test.dart"
if [ ! -f "$DRIVER_FILE" ]; then
    # Create the driver file if it doesn't exist
    echo -e "${YELLOW}📝 Creating integration test driver...${NC}"
    mkdir -p integration_test_driver
    cat > "$DRIVER_FILE" << 'EOF'
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
EOF
    echo -e "${GREEN}✅ Driver created${NC}"
    echo ""
fi

echo -e "${BLUE}🚀 Running integration test on iOS Simulator...${NC}"
echo ""

# Run flutter drive on iOS
# Get the iOS device ID from flutter devices
IOS_DEVICE=$(flutter devices | grep -i "ios" | head -1 | awk '{print $5}' | tr -d '()' || echo "ios")

if [ -z "$IOS_DEVICE" ] || [ "$IOS_DEVICE" = "ios" ]; then
    # Try to get device ID differently
    IOS_DEVICE=$(flutter devices | grep -i "ios" | head -1 | awk '{print $4}' || echo "ios")
fi

echo -e "${BLUE}Using iOS device: $IOS_DEVICE${NC}"
echo ""

flutter drive \
    --driver="$DRIVER_FILE" \
    --target="$TEST_FILE" \
    -d "$IOS_DEVICE"

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Integration test completed successfully!${NC}"
else
    echo -e "${RED}❌ Integration test failed with exit code: $EXIT_CODE${NC}"
fi

exit $EXIT_CODE

