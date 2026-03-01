import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:avrai_runtime_os/services/infrastructure/performance_monitor.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

import '../../mocks/mock_dependencies.mocks.dart';
import '../../mocks/mock_storage_service.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('PerformanceMonitor Tests', () {
    late PerformanceMonitor monitor;
    late MockStorageService mockStorageService;
    late SharedPreferencesCompat prefs;

    setUpAll(() async {
      await setupTestStorage();
      real_prefs.SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      mockStorageService = MockStorageService();
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      prefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);

      monitor = PerformanceMonitor(
        storageService: mockStorageService,
        prefs: prefs,
      );
    });

    tearDown(() async {
      await monitor.stopMonitoring();
      MockGetStorage.reset();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('trackMetric', () {
      test('tracks metric successfully', () async {
        // Arrange
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // Act - track 10 metrics to trigger persistence (trackMetric persists every 10 metrics)
        for (int i = 0; i < 10; i++) {
          await monitor.trackMetric('test_metric_$i', 42.0 + i);
        }

        // Assert - should have persisted after 10 metrics
        verify(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).called(greaterThan(0));
      });

      test('tracks multiple metrics', () async {
        // Arrange
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        // Act - track 10 metrics to trigger persistence
        for (int i = 0; i < 10; i++) {
          await monitor.trackMetric('metric_$i', 10.0 + i);
        }

        // Assert - metrics should be tracked and persisted
        verify(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).called(greaterThan(0));
      });
    });

    group('generateReport', () {
      test('generates report with tracked metrics', () async {
        // Arrange
        when(mockStorageService.setObject(
          any,
          any,
          box: anyNamed('box'),
        )).thenAnswer((_) async => true);

        await monitor.trackMetric('memory_usage', 150.0);
        await monitor.trackMetric('response_time', 500.0);

        // Act
        final report = await monitor.generateReport(const Duration(hours: 1));

        // Assert
        expect(report, isNotNull);
        expect(report.timeWindow, equals(const Duration(hours: 1)));
        expect(report.totalMetrics, greaterThan(0));
      });

      test('generates empty report when no metrics', () async {
        // Act
        final report = await monitor.generateReport(const Duration(hours: 1));

        // Assert
        expect(report, isNotNull);
        expect(report.totalMetrics, equals(0));
      });
    });

    group('monitoring lifecycle', () {
      test('starts and stops monitoring', () async {
        // Act
        await monitor.startMonitoring();
        await monitor.stopMonitoring();

        // Assert - no exceptions thrown
        expect(monitor, isNotNull);
      });
    });
  });
}
