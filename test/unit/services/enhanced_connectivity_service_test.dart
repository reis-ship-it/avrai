import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:avrai/core/services/network/enhanced_connectivity_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// SPOTS EnhancedConnectivityService Unit Tests
/// Date: December 1, 2025
/// Purpose: Test EnhancedConnectivityService functionality
///
/// Test Coverage:
/// - Basic Connectivity: WiFi/mobile connectivity checks
/// - Internet Access: HTTP ping verification
/// - Caching: Ping result caching
/// - Connectivity Stream: Real-time connectivity changes
/// - Error Handling: Network failures, timeouts
///
/// Dependencies:
/// - Connectivity: Platform connectivity checking
/// - http.Client: HTTP client for ping

class MockConnectivity extends Mock implements Connectivity {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('EnhancedConnectivityService', () {
    late EnhancedConnectivityService service;
    late MockConnectivity mockConnectivity;
    late MockHttpClient mockHttpClient;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    setUp(() {
      mockConnectivity = MockConnectivity();
      mockHttpClient = MockHttpClient();
      service = EnhancedConnectivityService(
        connectivity: mockConnectivity,
        httpClient: mockHttpClient,
      );
    });

    // Removed: Property assignment tests
    // Connectivity tests focus on business logic (connectivity checking, internet access, caching, streams), not property assignment

    group('Basic Connectivity', () {
      test(
          'should return true when WiFi or mobile data is available, return false when no connectivity, and handle connectivity check errors',
          () async {
        // Test business logic: basic connectivity checking
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        final result1 = await service.hasBasicConnectivity();
        expect(result1, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);

        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);
        final result2 = await service.hasBasicConnectivity();
        expect(result2, true);

        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        final result3 = await service.hasBasicConnectivity();
        expect(result3, false);

        when(() => mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Connectivity check failed'));
        final result4 = await service.hasBasicConnectivity();
        expect(result4, false);
      });
    });

    group('Internet Access', () {
      test(
          'should return false when no basic connectivity, return true when ping succeeds, return false when ping fails, use cached result when available, and force refresh when requested',
          () async {
        // Test business logic: internet access checking with caching
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        final result1 = await service.hasInternetAccess();
        expect(result1, false);
        verifyNever(() => mockHttpClient.head(any()));

        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenAnswer((_) async => http.Response('', 200));
        final result2 = await service.hasInternetAccess();
        expect(result2, true);
        verify(() => mockHttpClient.head(any())).called(1);

        // Clear cache by forcing refresh
        when(() => mockHttpClient.head(any()))
            .thenThrow(Exception('Network error'));
        final result3 = await service.hasInternetAccess(forceRefresh: true);
        expect(result3, false);

        clearInteractions(mockHttpClient);
        when(() => mockHttpClient.head(any()))
            .thenAnswer((_) async => http.Response('', 200));
        final result4 = await service.hasInternetAccess(forceRefresh: true);
        expect(result4, true);
        verify(() => mockHttpClient.head(any())).called(1);
        clearInteractions(mockHttpClient);
        final result5 = await service.hasInternetAccess();
        expect(result5, true);
        verifyNever(() => mockHttpClient.head(any()));

        await service.hasInternetAccess(forceRefresh: true);
        verify(() => mockHttpClient.head(any())).called(1);
      });
    });

    group('Connectivity Stream', () {
      test(
          'should emit true when connectivity available and emit false when connectivity lost',
          () async {
        // Test business logic: connectivity stream monitoring
        final streamController1 = StreamController<List<ConnectivityResult>>();
        when(() => mockConnectivity.onConnectivityChanged)
            .thenAnswer((_) => streamController1.stream);
        final stream1 = service.connectivityStream;
        expect(stream1, isNotNull);
        final values1 = <bool>[];
        final subscription1 = stream1.listen((value) {
          values1.add(value);
        });
        streamController1.add([ConnectivityResult.wifi]);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(values1, contains(true));
        await subscription1.cancel();
        await streamController1.close();

        final streamController2 = StreamController<List<ConnectivityResult>>();
        when(() => mockConnectivity.onConnectivityChanged)
            .thenAnswer((_) => streamController2.stream);
        final stream2 = service.connectivityStream;
        expect(stream2, isNotNull);
        final values2 = <bool>[];
        final subscription2 = stream2.listen((value) {
          values2.add(value);
        });
        streamController2.add([ConnectivityResult.none]);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(values2, contains(false));
        await subscription2.cancel();
        await streamController2.close();
      });
    });

    group('Error Handling', () {
      test(
          'should handle HTTP errors, timeout errors, and network exceptions gracefully',
          () async {
        // Test business logic: error handling for internet access
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockHttpClient.head(any()))
            .thenAnswer((_) async => http.Response('', 500));
        final result1 = await service.hasInternetAccess();
        expect(result1, false);

        when(() => mockHttpClient.head(any())).thenThrow(Exception('Timeout'));
        final result2 = await service.hasInternetAccess();
        expect(result2, false);

        when(() => mockHttpClient.head(any()))
            .thenThrow(Exception('Network unreachable'));
        final result3 = await service.hasInternetAccess();
        expect(result3, false);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
