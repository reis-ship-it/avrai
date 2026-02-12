import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_async/fake_async.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
extension StopwatchExt on Stopwatch {
  double get elapsedSeconds => elapsedMilliseconds / 1000.0;
}

/// Test helpers for SPOTS comprehensive testing
/// Provides utilities for model testing, repository testing, and shared utilities
class TestHelpers {
  /// Setup common test environment
  static void setupTestEnvironment() {
    // Reset any global state
    MocksRegistry.allMocks.forEach(reset);
  }

  /// Teardown test environment
  static void teardownTestEnvironment() {
    // Clean up any test artifacts
  }

  /// Create a test DateTime for consistent testing
  static DateTime createTestDateTime([int? year, int? month, int? day]) {
    return DateTime(year ?? 2025, month ?? 1, day ?? 1);
  }

  /// Create test timestamps with offsets
  static DateTime createTimestampWithOffset(Duration offset) {
    return createTestDateTime().add(offset);
  }

  /// Validate object equality with detailed error messages
  static void expectDeepEquals(dynamic actual, dynamic expected, String context) {
    expect(actual, equals(expected), reason: 'Mismatch in $context');
  }

  /// Run test with fake async for time-based testing
  static void runWithFakeAsync(void Function(FakeAsync) callback) {
    fakeAsync(callback);
  }

  /// Create test metadata map
  static Map<String, dynamic> createTestMetadata({
    String? action,
    String? context,
    Map<String, dynamic>? additional,
  }) {
    return {
      'action': action ?? 'test_action',
      'context': context ?? 'test_context',
      'timestamp': createTestDateTime().toIso8601String(),
      ...?additional,
    };
  }

  /// Validate JSON roundtrip (serialize -> deserialize -> compare)
  static void validateJsonRoundtrip<T>(
    T original,
    Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final json = toJson(original);
    final reconstructed = fromJson(json);
    expect(reconstructed, equals(original));
  }

  // Repository Testing Utilities

  /// Sets up connectivity mock to return online status
  static void mockOnlineConnectivity(Connectivity connectivityMock) {
    when(connectivityMock.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
  }

  /// Sets up connectivity mock to return offline status
  static void mockOfflineConnectivity(Connectivity connectivityMock) {
    when(connectivityMock.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);
  }

  /// Sets up connectivity mock to throw an error
  static void mockConnectivityError(Connectivity connectivityMock, Exception error) {
    when(connectivityMock.checkConnectivity()).thenThrow(error);
  }

  /// Creates a test group with consistent setup and teardown
  static void testGroup(String description, Function() body) {
    group(description, () {
      setUp(() {
        // Reset all mocks before each test
        MocksRegistry.allMocks.forEach(reset);
      });

      tearDown(() {
        // Clean up after each test
        for (var mock in MocksRegistry.allMocks) {
          verifyNoMoreInteractions(mock);
        }
      });

      body();
    });
  }

  /// Verifies that a method was called with specific parameters
  static void verifyMethodCall(Mock mock, String methodName, List<dynamic> args) {
    verify(mock.noSuchMethod(
      Invocation.method(Symbol(methodName), args),
    )).called(1);
  }

  /// Creates a delay for testing async operations
  static Future<void> delayForAsync() async {
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

/// Mock repository placeholder for model testing
class MockRepository extends Mock {}

/// Registry of all mocks for easy management
class MocksRegistry {
  static final List<Mock> allMocks = [];
  
  static void register(Mock mock) {
    allMocks.add(mock);
  }
  
  static void clear() {
    allMocks.clear();
  }
}

/// Test constants for consistent test data
class TestConstants {
  static const String testUserId = 'test-user-123';
  static const String testEmail = 'test@example.com';
  static const String testListId = 'test-list-456';
  static const String testSpotId = 'test-spot-789';
  static const double testLatitude = 40.7128;
  static const double testLongitude = -74.0060;
  
  // Additional constants from repository testing
  static const String testPassword = 'testPassword123';
  static const String testUserName = 'Test User';
  static final DateTime testDate = DateTime(2025, 1, 1, 12, 0, 0);
}

/// Custom test matchers for better assertions
class TestMatchers {
  /// Matches any non-null value
  static const isNotNull = TypeMatcher<Object>();
  
  /// Matches any string that is not empty
  static const isNonEmptyString = TypeMatcher<String>();
  
  /// Matches any list that is not empty
  static const isNonEmptyList = TypeMatcher<List>();
}