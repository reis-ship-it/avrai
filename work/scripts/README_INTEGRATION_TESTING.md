# Integration Test Scripts - Chrome & iOS

This directory contains scripts for running integration tests with `flutter drive` on Chrome and iOS Simulator.

## Quick Start

### Chrome Testing (Fastest - Recommended for Development)

```bash
# Run deployment_readiness_test on Chrome (default)
./scripts/run_integration_test_chrome.sh

# Run specific test file
./scripts/run_integration_test_chrome.sh deployment_readiness_test.dart

# Run onboarding flow test
./scripts/run_integration_test_chrome.sh onboarding_flow_integration_test.dart
```

**Advantages:**
- ✅ Chrome starts automatically (no manual setup)
- ✅ Fastest execution
- ✅ Good for testing UI flows
- ✅ No emulator boot time

### iOS Testing

```bash
# Run deployment_readiness_test on iOS Simulator (default)
./scripts/run_integration_test_ios.sh

# Run specific test file
./scripts/run_integration_test_ios.sh deployment_readiness_test.dart

# Run on specific simulator
./scripts/run_integration_test_ios.sh deployment_readiness_test.dart "iPhone 15 Pro"
```

**Advantages:**
- ✅ Tests iOS-specific behavior
- ✅ Tests native iOS plugins
- ✅ More realistic device testing

**Note:** iOS simulator will be automatically launched if not running (takes 30-60 seconds to boot).

## Prerequisites

1. **Flutter SDK** installed and in PATH
2. **Chrome** installed (for Chrome testing)
3. **Xcode** installed (for iOS testing, macOS only)
4. **Integration Test Driver** - Automatically created at `integration_test_driver/integration_test.dart`

## Test File Requirements

For tests to work with `flutter drive`, they should use:

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // ... your tests
}
```

**Not:**
```dart
TestWidgetsFlutterBinding.ensureInitialized(); // ❌ Use IntegrationTestWidgetsFlutterBinding instead
```

## Converting Tests to Use flutter drive

If a test currently uses `TestWidgetsFlutterBinding`, convert it:

1. Change the import:
   ```dart
   import 'package:integration_test/integration_test.dart';
   ```

2. Change the binding:
   ```dart
   // From:
   TestWidgetsFlutterBinding.ensureInitialized();
   
   // To:
   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
   ```

3. Run with the script:
   ```bash
   ./scripts/run_integration_test_chrome.sh your_test_file.dart
   ```

## Troubleshooting

### Chrome Not Found
- Make sure Chrome is installed
- Run `flutter devices` to verify Chrome is listed
- Chrome should be available automatically

### iOS Simulator Not Found
- Make sure Xcode is installed
- Run `xcrun simctl list devices` to see available simulators
- The script will try to launch one automatically

### Test Fails with Binding Error
- Make sure the test uses `IntegrationTestWidgetsFlutterBinding`
- Check that `integration_test` is in `pubspec.yaml` dev_dependencies

### Test Times Out
- Chrome tests: Usually fast, timeout suggests test issue
- iOS tests: Simulator boot can take 30-60 seconds, be patient

## Available Test Files

Common integration test files:
- `test/integration/deployment_readiness_test.dart` - Deployment readiness validation
- `test/integration/onboarding_flow_integration_test.dart` - Onboarding flow
- `test/integration/offline_online_sync_test.dart` - Offline/online sync

## Differences: flutter test vs flutter drive

| Feature | `flutter test` | `flutter drive` |
|---------|----------------|-----------------|
| **Binding** | `TestWidgetsFlutterBinding` | `IntegrationTestWidgetsFlutterBinding` |
| **Device** | Headless VM | Real device/emulator |
| **Speed** | Fast | Slower (device boot time) |
| **Platform Channels** | Limited | Full access |
| **Use Case** | Unit/widget tests | End-to-end integration tests |

## Next Steps

1. Convert tests that need full app initialization to use `IntegrationTestWidgetsFlutterBinding`
2. Use Chrome for fast iteration during development
3. Use iOS for final validation before deployment

