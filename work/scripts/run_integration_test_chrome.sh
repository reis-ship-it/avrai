#!/bin/bash

# SPOTS Integration Test Runner - Chrome
# 
# This script runs integration tests using flutter drive on Chrome
# Chrome starts automatically, no manual setup needed
# 
# Usage:
#   ./scripts/run_integration_test_chrome.sh [test_file]
# 
# Examples:
#   ./scripts/run_integration_test_chrome.sh                                    # Run deployment_readiness_test
#   ./scripts/run_integration_test_chrome.sh deployment_readiness_test.dart      # Run specific test
#   ./scripts/run_integration_test_chrome.sh onboarding_flow_integration_test.dart

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 SPOTS Integration Test Runner - Chrome${NC}"
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

# Default test file
DEFAULT_TEST="test/integration/deployment_readiness_test.dart"
TEST_FILE="${1:-$DEFAULT_TEST}"

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

# Check if Chrome is available
echo -e "${BLUE}🔍 Checking for Chrome device...${NC}"
if ! flutter devices | grep -q "chrome"; then
    echo -e "${YELLOW}⚠️  Chrome not found in available devices.${NC}"
    echo -e "${BLUE}📱 Available devices:${NC}"
    flutter devices
    echo ""
    echo -e "${YELLOW}💡 Chrome should be available automatically. If not, try:${NC}"
    echo -e "   flutter devices"
    exit 1
fi

echo -e "${GREEN}✅ Chrome device found${NC}"
echo ""

# Check if test uses IntegrationTestWidgetsFlutterBinding
if grep -q "IntegrationTestWidgetsFlutterBinding" "$TEST_FILE"; then
    echo -e "${GREEN}✅ Test uses IntegrationTestWidgetsFlutterBinding (correct for flutter drive)${NC}"
elif grep -q "TestWidgetsFlutterBinding" "$TEST_FILE"; then
    echo -e "${YELLOW}⚠️  Test uses TestWidgetsFlutterBinding. Consider converting to IntegrationTestWidgetsFlutterBinding for flutter drive.${NC}"
    echo -e "${YELLOW}   Continuing anyway...${NC}"
fi

echo ""
echo -e "${BLUE}🚀 Running integration test on Chrome...${NC}"
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

# Function to start chromedriver in background
start_chromedriver() {
    if pgrep -f "chromedriver.*--port=4444" > /dev/null; then
        echo -e "${GREEN}✅ chromedriver already running on port 4444${NC}"
        return 0
    fi
    
    echo -e "${BLUE}🚀 Starting chromedriver on port 4444...${NC}"
    chromedriver --port=4444 > /tmp/chromedriver.log 2>&1 &
    CHROMEDRIVER_PID=$!
    
    # Wait for chromedriver to start
    sleep 2
    
    # Check if it's running
    if pgrep -f "chromedriver.*--port=4444" > /dev/null; then
        echo -e "${GREEN}✅ chromedriver started (PID: $CHROMEDRIVER_PID)${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to start chromedriver${NC}"
        cat /tmp/chromedriver.log 2>/dev/null || true
        return 1
    fi
}

# Function to stop chromedriver
stop_chromedriver() {
    if [ ! -z "$CHROMEDRIVER_PID" ]; then
        echo -e "${BLUE}🛑 Stopping chromedriver (PID: $CHROMEDRIVER_PID)...${NC}"
        kill $CHROMEDRIVER_PID 2>/dev/null || true
    fi
    # Also kill any chromedriver on port 4444
    pkill -f "chromedriver.*--port=4444" 2>/dev/null || true
}

# Trap to ensure chromedriver is stopped on exit
trap stop_chromedriver EXIT

# Check if chromedriver is available (required for web integration tests)
echo -e "${BLUE}🔍 Checking for chromedriver...${NC}"
if ! command -v chromedriver &> /dev/null; then
    echo -e "${YELLOW}⚠️  chromedriver not found. Web integration tests require chromedriver.${NC}"
    echo ""
    echo -e "${BLUE}📦 To install chromedriver:${NC}"
    echo -e "   ${GREEN}Option 1 (macOS with Homebrew):${NC}"
    echo -e "      brew install chromedriver"
    echo ""
    echo -e "   ${GREEN}Option 2 (Manual):${NC}"
    echo -e "      1. Download from: https://chromedriver.chromium.org/downloads"
    echo -e "      2. Extract and add to PATH"
    echo ""
    echo -e "   ${GREEN}Option 3 (Use flutter test for integration_test/ directory):${NC}"
    echo -e "      If test is in integration_test/ directory, you can use:"
    echo -e "      flutter test $TEST_FILE -d chrome"
    echo ""
    echo -e "${YELLOW}💡 For now, trying flutter test approach (may not work for all tests)...${NC}"
    echo ""
    
    # Check if test is in integration_test/ directory
    if [[ "$TEST_FILE" =~ ^integration_test/ ]]; then
        echo -e "${BLUE}📋 Test is in integration_test/ directory, using flutter test...${NC}"
        flutter test "$TEST_FILE" -d chrome
    else
        echo -e "${RED}❌ Cannot run test without chromedriver.${NC}"
        echo -e "${YELLOW}   Please install chromedriver or move test to integration_test/ directory.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ chromedriver found${NC}"
    echo ""
    
    # Start chromedriver
    if ! start_chromedriver; then
        echo -e "${RED}❌ Cannot run test without chromedriver.${NC}"
        exit 1
    fi
    
    echo ""
    
    # Run the test with flutter drive
    echo -e "${BLUE}Running: flutter drive --driver=$DRIVER_FILE --target=$TEST_FILE -d chrome${NC}"
    flutter drive \
        --driver="$DRIVER_FILE" \
        --target="$TEST_FILE" \
        -d chrome
    
    DRIVE_EXIT_CODE=$?
    
    # Stop chromedriver
    stop_chromedriver
    
    EXIT_CODE=$DRIVE_EXIT_CODE
fi

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Integration test completed successfully!${NC}"
else
    echo -e "${RED}❌ Integration test failed with exit code: $EXIT_CODE${NC}"
fi

exit $EXIT_CODE

