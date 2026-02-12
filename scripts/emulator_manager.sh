#!/bin/bash
# SPOTS Emulator Manager for Background Agent
# Provides comprehensive emulator control and testing capabilities
# Date: August 3, 2025

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") echo -e "${BLUE}[INFO]${NC} ${timestamp}: ${message}" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} ${timestamp}: ${message}" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} ${timestamp}: ${message}" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp}: ${message}" ;;
        "DEBUG") echo -e "${PURPLE}[DEBUG]${NC} ${timestamp}: ${message}" ;;
    esac
}

# Configuration
EMULATOR_ID="Medium_Phone_API_36.0"
EMULATOR_NAME="Medium Phone API 36.0"
ADB_TIMEOUT=60
FLUTTER_TIMEOUT=120
TEST_TIMEOUT=300

# Email alert function
send_alert() {
    local subject="$1"
    local message="$2"
    local priority="$3"
    
    # For now, log the alert (agent can implement email sending)
    log_message "ERROR" "ALERT [$priority]: $subject - $message"
    echo "ALERT [$priority]: $subject - $message" >> logs/emulator_alerts.log
}

# Check prerequisites
check_prerequisites() {
    log_message "INFO" "Checking emulator prerequisites..."
    
    if ! command -v flutter &> /dev/null; then
        send_alert "Flutter not found" "Flutter SDK is not installed or not in PATH" "CRITICAL"
        return 1
    fi
    
    if ! command -v adb &> /dev/null; then
        log_message "WARNING" "ADB not found in PATH, checking Android SDK..."
        # Try to find adb in common locations
        ADB_PATHS=(
            "$HOME/Library/Android/sdk/platform-tools/adb"
            "/opt/homebrew/bin/adb"
            "/usr/local/bin/adb"
            "/Applications/Android Studio.app/Contents/sdk/platform-tools/adb"
        )
        
        for path in "${ADB_PATHS[@]}"; do
            if [ -f "$path" ]; then
                export PATH="$PATH:$(dirname "$path")"
                log_message "SUCCESS" "Found ADB at: $path"
                break
            fi
        done
        
        if ! command -v adb &> /dev/null; then
            send_alert "ADB not found" "Android Debug Bridge not found in any common location" "CRITICAL"
            return 1
        fi
    fi
    
    log_message "SUCCESS" "All prerequisites satisfied"
    return 0
}

# List available emulators
list_emulators() {
    log_message "INFO" "Listing available emulators..."
    flutter emulators
}

# Launch emulator
launch_emulator() {
    local emulator_id=${1:-$EMULATOR_ID}
    local timeout=${2:-$ADB_TIMEOUT}
    
    log_message "INFO" "Launching emulator: $emulator_id"
    
    # Check if emulator is already running
    if adb devices | grep -q "$emulator_id"; then
        log_message "SUCCESS" "Emulator $emulator_id is already running"
        return 0
    fi
    
    # Launch emulator in background
    log_message "INFO" "Starting emulator (this may take 1-2 minutes)..."
    flutter emulators --launch "$emulator_id" &
    local emulator_pid=$!
    
    # Wait for emulator to start
    local attempts=0
    while [ $attempts -lt $timeout ]; do
        if adb devices | grep -q "$emulator_id"; then
            log_message "SUCCESS" "Emulator $emulator_id is now running"
            return 0
        fi
        sleep 2
        attempts=$((attempts + 2))
        log_message "DEBUG" "Waiting for emulator... ($attempts/$timeout seconds)"
    done
    
    send_alert "Emulator launch timeout" "Emulator $emulator_id failed to start within $timeout seconds" "HIGH"
    return 1
}

# Wait for emulator to be ready
wait_for_emulator_ready() {
    local timeout=${1:-$ADB_TIMEOUT}
    local attempts=0
    
    log_message "INFO" "Waiting for emulator to be fully ready..."
    
    while [ $attempts -lt $timeout ]; do
        if adb shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; then
            log_message "SUCCESS" "Emulator is fully booted and ready"
            return 0
        fi
        sleep 2
        attempts=$((attempts + 2))
        log_message "DEBUG" "Waiting for boot completion... ($attempts/$timeout seconds)"
    done
    
    send_alert "Emulator boot timeout" "Emulator failed to fully boot within $timeout seconds" "HIGH"
    return 1
}

# Install and run SPOTS app
install_and_run_spots() {
    log_message "INFO" "Building and installing SPOTS app..."
    
    # Build the app
    log_message "INFO" "Building SPOTS app..."
    if ! flutter build apk --debug; then
        send_alert "Build failed" "Failed to build SPOTS app" "CRITICAL"
        return 1
    fi
    
    # Install the app
    log_message "INFO" "Installing SPOTS app on emulator..."
    if ! flutter install; then
        send_alert "Install failed" "Failed to install SPOTS app on emulator" "CRITICAL"
        return 1
    fi
    
    log_message "SUCCESS" "SPOTS app installed successfully"
    return 0
}

# Run automated tests
run_automated_tests() {
    local test_type=${1:-"all"}
    local timeout=${2:-$TEST_TIMEOUT}
    
    log_message "INFO" "Running automated tests: $test_type"
    
    case $test_type in
        "unit")
            log_message "INFO" "Running unit tests..."
            flutter test test/unit/ || {
                send_alert "Unit tests failed" "Unit tests failed during automated testing" "HIGH"
                return 1
            }
            ;;
        "widget")
            log_message "INFO" "Running widget tests..."
            flutter test test/widget/ || {
                send_alert "Widget tests failed" "Widget tests failed during automated testing" "HIGH"
                return 1
            }
            ;;
        "integration")
            log_message "INFO" "Running integration tests..."
            flutter test test/integration/ || {
                send_alert "Integration tests failed" "Integration tests failed during automated testing" "HIGH"
                return 1
            }
            ;;
        "all")
            log_message "INFO" "Running all tests..."
            flutter test || {
                send_alert "Tests failed" "Some tests failed during automated testing" "HIGH"
                return 1
            }
            ;;
    esac
    
    log_message "SUCCESS" "All tests completed successfully"
    return 0
}

# Interactive testing functions
simulate_user_interaction() {
    local action=$1
    local coordinates=$2
    
    log_message "INFO" "Simulating user interaction: $action"
    
    case $action in
        "tap")
            adb shell input tap $coordinates || {
                send_alert "Tap failed" "Failed to simulate tap at $coordinates" "MEDIUM"
                return 1
            }
            ;;
        "swipe")
            adb shell input swipe $coordinates || {
                send_alert "Swipe failed" "Failed to simulate swipe with coordinates $coordinates" "MEDIUM"
                return 1
            }
            ;;
        "text")
            adb shell input text "$coordinates" || {
                send_alert "Text input failed" "Failed to input text: $coordinates" "MEDIUM"
                return 1
            }
            ;;
        "key")
            adb shell input keyevent $coordinates || {
                send_alert "Key event failed" "Failed to simulate key event: $coordinates" "MEDIUM"
                return 1
            }
            ;;
    esac
    
    log_message "SUCCESS" "User interaction simulated: $action"
    return 0
}

# Performance monitoring
monitor_performance() {
    local duration=${1:-60}
    
    log_message "INFO" "Monitoring app performance for $duration seconds..."
    
    # Start performance monitoring
    adb shell dumpsys cpuinfo > logs/performance_cpu.log &
    adb shell dumpsys meminfo > logs/performance_memory.log &
    adb shell dumpsys battery > logs/performance_battery.log &
    
    sleep $duration
    
    # Stop monitoring
    pkill -f "dumpsys" || true
    
    log_message "SUCCESS" "Performance monitoring completed"
    return 0
}

# Screenshot capture
capture_screenshot() {
    local filename=${1:-"screenshot_$(date +%Y%m%d_%H%M%S).png"}
    
    log_message "INFO" "Capturing screenshot: $filename"
    
    adb shell screencap -p /sdcard/screenshot.png
    adb pull /sdcard/screenshot.png "logs/$filename"
    adb shell rm /sdcard/screenshot.png
    
    log_message "SUCCESS" "Screenshot captured: logs/$filename"
    return 0
}

# Log collection
collect_logs() {
    local log_type=${1:-"all"}
    
    log_message "INFO" "Collecting logs: $log_type"
    
    case $log_type in
        "app")
            adb logcat -d | grep "SPOTS" > logs/app_logs_$(date +%Y%m%d_%H%M%S).log
            ;;
        "system")
            adb logcat -d > logs/system_logs_$(date +%Y%m%d_%H%M%S).log
            ;;
        "all")
            adb logcat -d > logs/all_logs_$(date +%Y%m%d_%H%M%S).log
            ;;
    esac
    
    log_message "SUCCESS" "Logs collected successfully"
    return 0
}

# Cleanup
cleanup_emulator() {
    log_message "INFO" "Cleaning up emulator..."
    
    # Stop the app
    adb shell am force-stop com.avrai.app || true
    
    # Clear app data
    adb shell pm clear com.avrai.app || true
    
    log_message "SUCCESS" "Emulator cleanup completed"
    return 0
}

# Shutdown emulator
shutdown_emulator() {
    log_message "INFO" "Shutting down emulator..."
    
    # Graceful shutdown
    adb emu kill || {
        log_message "WARNING" "Graceful shutdown failed, forcing..."
        pkill -f "emulator" || true
    }
    
    log_message "SUCCESS" "Emulator shutdown completed"
    return 0
}

# Main function for background agent
run_emulator_test_suite() {
    local test_suite=${1:-"basic"}
    
    log_message "INFO" "Starting emulator test suite: $test_suite"
    
    # Check prerequisites
    if ! check_prerequisites; then
        return 1
    fi
    
    # Launch emulator
    if ! launch_emulator; then
        return 1
    fi
    
    # Wait for emulator to be ready
    if ! wait_for_emulator_ready; then
        return 1
    fi
    
    # Install and run app
    if ! install_and_run_spots; then
        return 1
    fi
    
    # Run tests based on suite
    case $test_suite in
        "basic")
            run_automated_tests "unit"
            run_automated_tests "widget"
            ;;
        "full")
            run_automated_tests "all"
            monitor_performance 120
            ;;
        "interactive")
            # Simulate user interactions
            simulate_user_interaction "tap" "500 500"
            sleep 2
            simulate_user_interaction "text" "test_input"
            sleep 1
            simulate_user_interaction "key" "KEYCODE_ENTER"
            ;;
    esac
    
    # Capture screenshot
    capture_screenshot
    
    # Collect logs
    collect_logs "all"
    
    # Cleanup
    cleanup_emulator
    
    log_message "SUCCESS" "Emulator test suite completed successfully"
    return 0
}

# Command line interface
case "${1:-help}" in
    "launch")
        launch_emulator "${2:-$EMULATOR_ID}"
        ;;
    "install")
        install_and_run_spots
        ;;
    "test")
        run_automated_tests "${2:-all}"
        ;;
    "interact")
        simulate_user_interaction "${2:-tap}" "${3:-500 500}"
        ;;
    "monitor")
        monitor_performance "${2:-60}"
        ;;
    "screenshot")
        capture_screenshot "${2:-}"
        ;;
    "logs")
        collect_logs "${2:-all}"
        ;;
    "cleanup")
        cleanup_emulator
        ;;
    "shutdown")
        shutdown_emulator
        ;;
    "suite")
        run_emulator_test_suite "${2:-basic}"
        ;;
    "list")
        list_emulators
        ;;
    "help"|*)
        echo "SPOTS Emulator Manager - Background Agent Tool"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  launch [emulator_id]    - Launch emulator"
        echo "  install                 - Install and run SPOTS app"
        echo "  test [type]             - Run tests (unit/widget/integration/all)"
        echo "  interact [action] [args] - Simulate user interaction"
        echo "  monitor [duration]      - Monitor performance"
        echo "  screenshot [filename]   - Capture screenshot"
        echo "  logs [type]             - Collect logs (app/system/all)"
        echo "  cleanup                 - Clean up emulator"
        echo "  shutdown                - Shutdown emulator"
        echo "  suite [type]            - Run test suite (basic/full/interactive)"
        echo "  list                    - List available emulators"
        echo "  help                    - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 launch"
        echo "  $0 test unit"
        echo "  $0 interact tap 500 500"
        echo "  $0 suite full"
        ;;
esac 