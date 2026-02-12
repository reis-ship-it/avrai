# SPOTS Integration Tests

This directory contains integration tests for the SPOTS application.

## Onboarding Flow Tests

### Complete Onboarding Flow Test

**File:** `onboarding_flow_complete_integration_test.dart`

**Description:** Comprehensive end-to-end integration test that completes the entire onboarding flow with actual form interactions.

**Features:**
- Tests all 8 onboarding steps (Welcome, Permissions, Age, Homebase, Favorite Places, Preferences, Baseline Lists, Friends)
- Fills in form fields with test data
- Validates button states and form validation
- Tests navigation (forward and backward)
- Verifies data persistence across steps
- Confirms transition to home page after completion

**Usage:**

```bash
# Run on default device
flutter test integration_test/onboarding_flow_complete_integration_test.dart

# Run on specific device
flutter test integration_test/onboarding_flow_complete_integration_test.dart --device-id=chrome

# Or use the helper script
./scripts/run_onboarding_integration_test.sh
./scripts/run_onboarding_integration_test.sh chrome
```

**Test Steps:**
1. ✅ Welcome Screen - Clicks "Next"
2. ✅ Permissions - Clicks "Enable All" (if available)
3. ✅ Age Collection - Enters birthday (25 years old)
4. ✅ Homebase Selection - Enters location "New York, NY"
5. ✅ Favorite Places - Adds "Central Park" and "Brooklyn Bridge"
6. ✅ Preferences Survey - Selects checkboxes, radio buttons, switches
7. ✅ Baseline Lists - Selects 3 baseline lists
8. ✅ Friends & Respect - Optionally selects friends
9. ✅ Completion - Clicks "Complete Setup" and verifies transition to home page

**Timeout:** 5 minutes (allows for slow devices/network)

### Basic Onboarding Flow Test

**File:** `onboarding_flow_integration_test.dart`

**Description:** Basic integration test with minimal form interactions (legacy version).

**Usage:**
```bash
flutter test integration_test/onboarding_flow_integration_test.dart
```

## Running Integration Tests

### Prerequisites

1. Ensure Flutter is installed and configured
2. Have a device/emulator running or Chrome available for web testing
3. Run `flutter pub get` to install dependencies

### Running Tests

**All integration tests:**
```bash
flutter test integration_test/
```

**Specific test:**
```bash
flutter test integration_test/onboarding_flow_complete_integration_test.dart
```

**With device selection:**
```bash
flutter test integration_test/onboarding_flow_complete_integration_test.dart --device-id=chrome
```

**Using helper script:**
```bash
./scripts/run_onboarding_integration_test.sh [device-id]
```

### Device IDs

Common device IDs:
- `chrome` - Chrome browser (web)
- `ios` - iOS simulator
- `android` - Android emulator
- Or use `flutter devices` to list available devices

## Test Structure

Integration tests use Flutter's `integration_test` package and follow this structure:

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('test name', (WidgetTester tester) async {
    // Test code
  });
}
```

## Troubleshooting

**Test times out:**
- Increase timeout in test: `timeout: const Timeout(Duration(minutes: 10))`
- Check device performance
- Verify network connectivity for API calls

**Elements not found:**
- Increase `pumpAndSettle` wait times
- Check if widgets are conditionally rendered
- Verify app state before interactions

**Button disabled:**
- Ensure required fields are filled
- Check validation logic in onboarding page
- Verify step completion requirements

## Notes

- Integration tests run on actual devices/emulators, not in unit test environment
- Tests may take longer than unit tests (minutes vs seconds)
- Some steps may require network access (location services, etc.)
- Web tests may behave differently than mobile tests
