// Unit tests for KnotDataAPI
// 
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 8: Data Sale & Research Integration

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_knot/services/knot/knot_data_api_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_privacy_service.dart';
import 'package:avrai_knot/models/knot/knot_pattern_analysis.dart';
import 'package:avrai_knot/models/knot/anonymized_knot_data.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';


void main() {
  group('KnotDataAPI', () {
    late KnotDataAPI dataAPI;
    late KnotStorageService storageService;
    late KnotPrivacyService privacyService;

    setUpAll(() async {
      // No-op: Sembast removed in Phase 26
    });

    setUp(() {
      storageService = KnotStorageService(
        storageService: StorageService.instance,
      );
      privacyService = KnotPrivacyService();
      dataAPI = KnotDataAPI(
        knotStorageService: storageService,
        privacyService: privacyService,
      );
    });

    tearDown(() async {
      // No-op: Sembast removed in Phase 26
    });

    group('getKnotDistributions', () {
      test('should return distribution data', () async {
        // Act
        final distribution = await dataAPI.getKnotDistributions();

        // Assert
        expect(distribution, isNotNull);
        expect(distribution.totalKnots, greaterThanOrEqualTo(0));
        expect(distribution.knotTypeDistribution, isNotNull);
        expect(distribution.crossingNumberDistribution, isNotNull);
        expect(distribution.writheDistribution, isNotNull);
        expect(distribution.calculatedAt, isNotNull);
      });

      test('should filter by location when provided', () async {
        // Act
        final distribution = await dataAPI.getKnotDistributions(
          location: 'Brooklyn',
        );

        // Assert
        expect(distribution, isNotNull);
        expect(distribution.location, equals('Brooklyn'));
      });

      test('should filter by category when provided', () async {
        // Act
        final distribution = await dataAPI.getKnotDistributions(
          category: 'coffee',
        );

        // Assert
        expect(distribution, isNotNull);
        expect(distribution.category, equals('coffee'));
      });

      test('should filter by time range when provided', () async {
        // Arrange
        final timeRange = DateTime.now().subtract(const Duration(days: 30));

        // Act
        final distribution = await dataAPI.getKnotDistributions(
          timeRange: timeRange,
        );

        // Assert
        expect(distribution, isNotNull);
        expect(distribution.timeRangeStart, equals(timeRange));
        expect(distribution.timeRangeEnd, isNotNull);
      });
    });

    group('getKnotPatterns', () {
      test('should return pattern analysis for weaving patterns', () async {
        // Act
        final analysis = await dataAPI.getKnotPatterns(
          type: AnalysisType.weavingPatterns,
        );

        // Assert
        expect(analysis, isNotNull);
        expect(analysis.type, equals(AnalysisType.weavingPatterns));
        expect(analysis.patterns, isNotNull);
        expect(analysis.statistics, isNotNull);
        expect(analysis.analyzedAt, isNotNull);
      });

      test('should return pattern analysis for compatibility patterns', () async {
        // Act
        final analysis = await dataAPI.getKnotPatterns(
          type: AnalysisType.compatibilityPatterns,
        );

        // Assert
        expect(analysis, isNotNull);
        expect(analysis.type, equals(AnalysisType.compatibilityPatterns));
      });

      test('should return pattern analysis for evolution patterns', () async {
        // Act
        final analysis = await dataAPI.getKnotPatterns(
          type: AnalysisType.evolutionPatterns,
        );

        // Assert
        expect(analysis, isNotNull);
        expect(analysis.type, equals(AnalysisType.evolutionPatterns));
      });

      test('should return pattern analysis for community formation', () async {
        // Act
        final analysis = await dataAPI.getKnotPatterns(
          type: AnalysisType.communityFormation,
        );

        // Assert
        expect(analysis, isNotNull);
        expect(analysis.type, equals(AnalysisType.communityFormation));
      });
    });

    group('getCorrelations', () {
      test('should return knot-personality correlations', () async {
        // Act
        final correlations = await dataAPI.getCorrelations();

        // Assert
        expect(correlations, isNotNull);
        expect(correlations.correlationMatrix, isNotNull);
        expect(correlations.strongestCorrelations, isNotNull);
        expect(correlations.significance, isNotNull);
        expect(correlations.sampleSize, greaterThanOrEqualTo(0));
        expect(correlations.calculatedAt, isNotNull);
      });
    });

    group('streamKnotData', () {
      test('should return stream for real-time data', () async {
        // Act
        final stream = dataAPI.streamKnotData(type: StreamType.realTime);

        // Assert
        expect(stream, isNotNull);
      });

      test('should return stream for batch data', () async {
        // Act
        final stream = dataAPI.streamKnotData(type: StreamType.batch);

        // Assert
        expect(stream, isNotNull);
      });

      test('should return stream for aggregate data', () async {
        // Act
        final stream = dataAPI.streamKnotData(type: StreamType.aggregate);

        // Assert
        expect(stream, isNotNull);
      });
    });

    group('Error Handling', () {
      test('should handle errors gracefully', () async {
        // Act & Assert: Should not throw
        final distribution = await dataAPI.getKnotDistributions();
        expect(distribution, isNotNull);
      });
    });
  });
}
